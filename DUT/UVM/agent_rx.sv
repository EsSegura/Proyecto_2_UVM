`include "uvm_macros.svh"
import uvm_pkg::*;

class agent_rx extends uvm_agent;

    `uvm_component_utils(agent_rx)

    driver_rx m_driver_rx;
    monitor_rx m_monitor_rx;
    uvm_sequencer #(m_seq_item) m_sequencer_rx;

    function new(string name = "my_agente_rx", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        //ahora se construyen los componentes del agente, como monitor, driver y sequencer
        m_monitor_rx = m_monitor_rx::type_id::create("m_monitor_rx", this);

        //se crea el sequencer y driver, este tiene que ser activo porque maneja el flujo  de transacciones
        if(get_is_active() == 1) begin
            m_sequencer_rx = uvm_sequencer #(m_seq_item)::type_id::create("m_sequencer_rx", this);
            m_driver_rx = driver_rx::type_id::create("m_driver_rx", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        if(get_is_active() == 1) begin
            m_driver_rx.seq_item_port.connect(m_sequencer_rx.seq_item_export);
        end

    endfunction
    
endclass 