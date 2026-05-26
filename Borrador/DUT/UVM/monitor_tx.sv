`include "uvm_macros.svh"
import uvm_pkg::*;

class monitor_tx extends uvm_monitor;

    `uvm_component_utils(monitor_tx)

    uvm_analysis_port #(m_seq_item) monitor_analysis_port;

    virtual md_tx_if vif;

    function new(string name = "monitor_tx", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor_analysis_port = new("monitor_analysis_port", this);

        if (!uvm_config_db #(virtual md_tx_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MD_TX_MON", "No se encontró la interfaz md_tx_if")
        end
    endfunction

    task run_phase(uvm_phase phase);
    	@(posedge vif.clk);
        wait (vif.reset_n === 1'b1);

        forever begin 
            collect_transfer();
        end
        
    endtask

    task collect_transfer();
        m_seq_item item;
 
        // Esperamos el handshake real de TX para capturar una transacción completa.
        @(posedge vif.clk);
        while (!(vif.md_tx_valid === 1'b1 && vif.md_tx_ready === 1'b1)) begin
            @(posedge vif.clk);
        end

        // Guardamos lo que salió del DUT para que lo vea el scoreboard.
        item = m_seq_item::type_id::create("item");
        item.data = vif.md_tx_data;
        item.offset = vif.md_tx_offset;
        item.size = vif.md_tx_size;
        item.err = vif.md_tx_err;

        `uvm_info("MONITOR_TX", $sformatf("Observado: data=0x%08h offset=%0d size=%0d err=%0b",
                    item.data, item.offset, item.size, item.err), UVM_HIGH)

        monitor_analysis_port.write(item);
    endtask



endclass 