`include "uvm_macros.svh"
import uvm_pkg::*;
import aligner_apb_registerfile_model::*;

class environment extends uvm_component;

    `uvm_component_utils(environment)

    //agentes
    agent_tx ag_tx;
    agent_rx ag_rx;
    apb_agent apb_ag;

    scoreboard m_scoreboard;
    apb_adapter reg_adapter;
    uvm_reg_predictor #(apb_seq_item) apb_predictor;
	aligner_apb_registerfile_model::aligner reg_model;// declaracion del modelo de registros
    function new(string name = "environment", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ag_tx = agent_tx::type_id::create("ag_tx", this);
        ag_rx = agent_rx::type_id::create("ag_rx", this);
        apb_ag = apb_agent::type_id::create("apb_ag", this);
        m_scoreboard = scoreboard::type_id::create("m_scoreboard", this);

        // Bloque RAL del DUT y adaptador APB.
        reg_model = new("reg_model");
        reg_model.build();
        reg_model.lock_model();
        reg_model.reset();
        reg_model.default_map.set_auto_predict(0);

        // Make reg_model available via uvm_config_db for sequences
        uvm_config_db#(aligner_apb_registerfile_model::aligner)::set(null, "*", "reg_model", reg_model);

        reg_adapter = apb_adapter::type_id::create("reg_adapter");
        apb_predictor = uvm_reg_predictor #(apb_seq_item)::type_id::create("apb_predictor", this);
        m_scoreboard.reg_model = reg_model;

        // Los tres agentes se dejan activos para manejar estimulo y respuesta.
        uvm_config_db #(uvm_active_passive_enum)::set(this, "ag_rx", "is_active", UVM_ACTIVE);
        uvm_config_db #(uvm_active_passive_enum)::set(this, "ag_tx", "is_active", UVM_ACTIVE);
        uvm_config_db #(uvm_active_passive_enum)::set(this, "apb_ag", "is_active", UVM_ACTIVE);


    endfunction

    virtual function void connect_phase(uvm_phase phase);
        // Conectamos cada monitor a su canal para que el scoreboard vea ambos lados.
        ag_rx.analysis_port.connect(m_scoreboard.rx_export);
        ag_tx.analysis_port.connect(m_scoreboard.tx_export);
        apb_ag.monitor.ap.connect(m_scoreboard.apb_export);

        // Conexion RAL <-> APB agent.
        reg_model.default_map.set_sequencer(apb_ag.sequencer, reg_adapter);
        apb_predictor.map = reg_model.default_map;
        apb_predictor.adapter = reg_adapter;
        apb_ag.monitor.ap.connect(apb_predictor.bus_in);

    endfunction


endclass 