class aligner_env extends uvm_env;

    `uvm_component_utils(aligner_env)

    apb_agent                                     apb_agt;
    md_agent                                      md_agt;
    aligner_scoreboard                            scoreboard;
    apb_adapter                                   reg_adapter;
  	aligner_reg_cov       reg_model; //para habilitar cobertura de registros
    aligner_md_coverage		md_cov; // cobertura md

    //aligner_apb_registerfile_model::aligner       reg_model;
  uvm_reg_predictor #(apb_seq_item) apb_predictor; // predictor explicito

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // se crean agentes y scoreboard
        apb_agt    = apb_agent::type_id::create("apb_agt",    this);
        md_agt     = md_agent::type_id::create("md_agt",      this);
        scoreboard = aligner_scoreboard::type_id::create("scoreboard", this);
        reg_adapter = apb_adapter::type_id::create("reg_adapter");
      	apb_predictor = uvm_reg_predictor#(apb_seq_item)::type_id::create("apb_predictor", this);
              md_cov     = aligner_md_coverage::type_id::create("md_cov",   this); // collector de cobertura MD

        // Bloque RAL del DUT y adaptador APB
      reg_model = aligner_reg_cov::type_id::create("reg_model", this); // para habilitar cobertura de registros
        //reg_model = new("reg_model");
        reg_model.build();
        reg_model.lock_model();

        // Exponer el modelo RAL en la config DB para que las secuencias lo usen
        uvm_config_db #(aligner_apb_registerfile_model::aligner)::set(
            this, "*", "reg_model", reg_model);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // conectar el mapa RAL al secuenciador APB via el adaptador
        // se usa default_map que ya fue creado por reg_model.build().
        reg_model.default_map.set_sequencer(apb_agt.sequencer, reg_adapter);

        // el predictor automatico actualiza el valor reflejado del RAL con lo que observa el monitor APB
      reg_model.default_map.set_auto_predict(0); // se apaga par ausar predicotr explicito

        // conexion del monitor APB al scoreboard
        apb_agt.monitor.ap.connect(scoreboard.apb_ap);
      // conexion del predictor al monitor del apb
      	apb_predictor.map     = reg_model.default_map;
        apb_predictor.adapter = reg_adapter;
        apb_agt.monitor.ap.connect(apb_predictor.bus_in);

        // conexion del monitor MD al scoreboard
        md_agt.ap_rx.connect(scoreboard.md_rx_ap);
        md_agt.ap_tx.connect(scoreboard.md_tx_ap);
        // conexion del monitor MD al collector de cobertura (en paralelo al scoreboard)
        md_agt.ap_rx.connect(md_cov.rx_ap);
        md_agt.ap_tx.connect(md_cov.tx_ap);
    endfunction

endclass : aligner_env