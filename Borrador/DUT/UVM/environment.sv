`include "uvm_macros.svh"
import uvm_pkg::*;

class environment extends uvm_component;

    `uvm_component_utils(environment)

    //agentes
    agent_tx ag_tx;
    agent_rx ag_rx;

    scoreboard m_scoreboard;

    function new(string name = "environment", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // El ambiente solo cubre el flujo MD; APB queda fuera por ahora.
        ag_tx = agent_tx::type_id::create("ag_tx", this);
        ag_rx = agent_rx::type_id::create("ag_rx", this);
        m_scoreboard = scoreboard::type_id::create("m_scoreboard", this);

        // Dejamos ambos agentes activos porque uno inyecta tráfico y el otro responde.
        uvm_config_db #(uvm_active_passive_enum)::set(this, "ag_rx", "is_active", UVM_ACTIVE);
        uvm_config_db #(uvm_active_passive_enum)::set(this, "ag_tx", "is_active", UVM_ACTIVE);


    endfunction

    virtual function void connect_phase(uvm_phase phase);
        // Conectamos cada monitor a su canal para que el scoreboard vea ambos lados.
        ag_rx.analysis_port.connect(m_scoreboard.rx_export);
        ag_tx.analysis_port.connect(m_scoreboard.tx_export);

    endfunction


endclass 