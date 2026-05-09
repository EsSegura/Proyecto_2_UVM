`include "uvm_macros.svh"
import uvm_pkg::*;

class monitor_tx extends uvm_component;

    `uvm_component_utils(monitor_tx)

    uvm_analysis_port #(m_seq_item) monitor_analysis_port;

    virtual md_tx_if vif;

    function new(string name = "monitor_tx", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor_analysis_port = new("monitor_analysis_port", this);
        if (!uvm_config_db #(virtual md_tx_if)::get(this, "", "md_tx_vif", vif))`uvm_fatal("MD_TX_MON", "Could not get md_tx_vif from config_db")
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
 
        //aca se espera a un flanco de reloj donde valid y read esten en 1, indicando que hay una transaccion valida 
        @(posedge vif.clk);
        while (!(vif.md_rx_valid === 1'b1 && vif.md_rx_ready === 1'b1)) begin
            @(posedge vif.clk);
        end

        //se crea un item de la transaccion y se llenan los campos con los datos de la interfaz
        item = m_seq_item::type_id::create("item");
        item.data = vif.md_rx_data;
        item.offset = vif.md_rx_offset;
        item.size = vif.md_rx_size;
        item.err = vif.md_rx_err;

        `uvm_info("MONITOR_TX", $sformatf("Observado: data=0x%08h offset=%0d size=%0d err=%0b",
                    item.data, item.offset, item.size, item.err), UVM_HIGH)

        monitor_analysis_port.write(item);
    endtask



endclass 