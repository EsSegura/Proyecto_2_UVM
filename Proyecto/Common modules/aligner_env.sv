class aligner_env extends uvm_env;

    `uvm_component_utils(aligner_env)

    apb_agent                                     apb_agt;
    md_agent                                      md_agt;
    aligner_scoreboard                            scoreboard;
    apb_adapter                                   reg_adapter;
    aligner_apb_registerfile_model::aligner       reg_model;

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

        // Bloque RAL del DUT y adaptador APB
        reg_model = new("reg_model");
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
        reg_model.default_map.set_auto_predict(1);

        // conexion del monitor APB al scoreboard
        apb_agt.monitor.ap.connect(scoreboard.apb_ap);

        // conexion del monitor MD al scoreboard
        md_agt.ap_rx.connect(scoreboard.md_rx_ap);
        md_agt.ap_tx.connect(scoreboard.md_tx_ap);
    endfunction

endclass : aligner_env