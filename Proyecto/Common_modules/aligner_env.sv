//ambiente de verificacion: agrupa los agentes, el scoreboard, la cobertura y el RAL
class aligner_env extends uvm_env;

    `uvm_component_utils(aligner_env) //registra el ambiente en la fabrica

    apb_agent                                     apb_agt;       //agente del bus APB
    md_agent                                      md_agt;        //agente del bus MD
    aligner_scoreboard                            scoreboard;    //compara lo esperado contra lo observado
    apb_adapter                                   reg_adapter;   //traduce entre RAL y bus APB
    uvm_reg_predictor #(apb_seq_item)             apb_predictor; //predictor explicito
    aligner_reg_cov                               reg_model;     //modelo RAL con cobertura
    aligner_md_coverage                           md_cov;        //collector de cobertura del canal MD

    function new(string name, uvm_component parent);
        super.new(name, parent); //llama al constructor de la clase base uvm_env
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        //se crean agentes y scoreboard
        apb_agt    = apb_agent::type_id::create("apb_agt",    this);
        md_agt     = md_agent::type_id::create("md_agt",      this);
        scoreboard = aligner_scoreboard::type_id::create("scoreboard", this);
        md_cov     = aligner_md_coverage::type_id::create("md_cov", this); //cobertura MD
        reg_adapter = apb_adapter::type_id::create("reg_adapter");

        //predictor explicito el cual convierte lo que observa el monitor APB en
        //accesos al RAL para actualizar el valor reflejado y la cobertura
        apb_predictor = uvm_reg_predictor #(apb_seq_item)::type_id::create("apb_predictor", this);

        //Bloque RAL del DUT con cobertura (aligner_reg_cov)
        //se habilita la cobertura de campos ANTES de construir el modelo
        uvm_reg::include_coverage("*", UVM_CVR_FIELD_VALS);
        reg_model = new("reg_model");
        reg_model.build();
        reg_model.lock_model();
        void'(reg_model.set_coverage(UVM_CVR_FIELD_VALS)); //activa el muestreo de cobertura

        //Exponer el modelo RAL en la config DB para que las secuencias lo usen
        uvm_config_db #(aligner_apb_registerfile_model::aligner)::set(
            this, "*", "reg_model", reg_model);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        //conectar el mapa RAL al secuenciador APB via el adaptador
        reg_model.default_map.set_sequencer(apb_agt.sequencer, reg_adapter);

        //predictor explicito
        reg_model.default_map.set_auto_predict(0);

        //se configura el predictor con el mapa y el adaptador
        apb_predictor.map     = reg_model.default_map;
        apb_predictor.adapter = reg_adapter;

        //el monitor APB alimenta al predictor (bus_in), donde el predictor
        //actualiza el RAL y dispara el muestreo de cobertura de registros
        apb_agt.monitor.ap.connect(apb_predictor.bus_in);

        //el monitor APB tambien alimenta al scoreboard
        apb_agt.monitor.ap.connect(scoreboard.apb_ap);

        //conexion del monitor MD al scoreboard
        md_agt.ap_rx.connect(scoreboard.md_rx_ap);
        md_agt.ap_tx.connect(scoreboard.md_tx_ap);

        //conexion del monitor MD al collector de cobertura
        md_agt.ap_rx.connect(md_cov.rx_ap);
        md_agt.ap_tx.connect(md_cov.tx_ap);
    endfunction

endclass : aligner_env
