`include "uvm_macros.svh"
import uvm_pkg::*;

class agent_tx extends uvm_agent;

    `uvm_component_utils(agent_tx)

    driver_rx m_driver_tx;
    monitor_rx m_monitor_tx;
    uvm_sequencer #(m_seq_item) m_sequencer_tx;

    uvm_analysis_port #(m_seq_item) analysis_port;

    function new(string name = "my_agente_tx", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_port = new("analysis_port", this);

        //ahora se construyen los componentes del agente, como monitor, driver y sequencer
        m_monitor_rx = monitor_rx::type_id::create("m_monitor_tx", this);

        //se crea el sequencer y driver, este tiene que ser activo porque maneja el flujo  de transacciones
        if(get_is_active() == UVM_ACTIVE) begin
            m_sequencer_tx = uvm_sequencer #(m_seq_item)::type_id::create("m_sequencer_tx", this);
            m_driver_tx = driver_rx::type_id::create("m_driver_tx", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        m_monitor_tx.analysis_port.connect(analysis_port);
        if(get_is_active() == UVM_ACTIVE) begin
            m_driver_tx.seq_item_port.connect(m_sequencer_tx.seq_item_export);
        end

    endfunction
    
endclass 