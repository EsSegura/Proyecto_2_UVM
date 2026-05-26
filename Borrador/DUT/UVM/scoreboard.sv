`include "uvm_macros.svh"
import uvm_pkg::*;

`uvm_analysis_imp_decl(_rx)
`uvm_analysis_imp_decl(_tx)

class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    uvm_analysis_imp_rx #(m_seq_item, scoreboard) rx_export;
    uvm_analysis_imp_tx #(m_seq_item, scoreboard) tx_export;

    m_seq_item last_rx;
    m_seq_item last_tx;
    int unsigned rx_count;
    int unsigned tx_count;

    function new(string name = "scoreboard", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        rx_export = new("rx_export", this);
        tx_export = new("tx_export", this);
    endfunction

    virtual function void write_rx(m_seq_item data);
        last_rx = data;
        rx_count++;
        `uvm_info(get_type_name(), $sformatf("RX observado: data=0x%0h offset=%0d size=%0d err=%0b",
                                            data.data, data.offset, data.size, data.err), UVM_MEDIUM)
    endfunction

    virtual function void write_tx(m_seq_item data);
        last_tx = data;
        tx_count++;
        `uvm_info(get_type_name(), $sformatf("TX observado: data=0x%0h offset=%0d size=%0d err=%0b",
                                            data.data, data.offset, data.size, data.err), UVM_MEDIUM)
    endfunction

    function report_phase(uvm_phase phase);
        `uvm_info(get_type_name(), $sformatf("Resumen MD: RX=%0d TX=%0d", rx_count, tx_count), UVM_LOW)
    endfunction 

endclass 
