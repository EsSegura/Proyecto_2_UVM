`include "uvm_macros.svh"
import uvm_pkg::*;

class agent_rx extends uvm_agent;

    `uvm_component_utils(agent_rx)

    driver_rx m_driver_rx;
    monitor_rx m_monitor_rx;
    uvm_sequencer #(m_seq_item) m_sequencer_rx;

    uvm_analysis_port #(m_seq_item) analysis_port;

    function new(string name = "my_agente_rx", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_port = new("analysis_port", this);

        // Este agente solo cubre la entrada MD del DUT.
        m_monitor_rx = monitor_rx::type_id::create("m_monitor_rx", this);

        // El driver se activa para generar el flujo de entrada cuando el test lo pida.
        if (get_is_active() == UVM_ACTIVE) begin
            m_sequencer_rx = uvm_sequencer #(m_seq_item)::type_id::create("m_sequencer_rx", this);
            m_driver_rx = driver_rx::type_id::create("m_driver_rx", this);
        end
        
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        m_monitor_rx.monitor_analysis_port.connect(analysis_port);

        if (get_is_active() == UVM_ACTIVE) begin
            m_driver_rx.seq_item_port.connect(m_sequencer_rx.seq_item_export);
        end

    endfunction
    
endclass 