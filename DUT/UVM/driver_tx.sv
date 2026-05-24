`include "uvm_macros.svh"
import uvm_pkg::*;

class driver_tx extends uvm_driver #(m_seq_item);

    `uvm_component_utils(driver_tx)

    virtual md_tx_if vif;

    function new(string name = "driver_tx", uvm_component parent = null)
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(virtual md_tx_if)::get(this, "", "vif", vif)) begin      
            `uvm_fatal (get_type_name (), "No se encontró la interfaz md_tx_if")    
        end 
    endfunction


    virtual task run_phase(uvm_phase phase);
        // Arrancamos en reposo para no manejar el bus antes del reset.
        drive_not_ready();
        @(posedge vif.clk);
        wait (vif.reset_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            m_seq_item item;
            seq_item_port.get_next_item(item);
            respond_to_transfer(item);
            seq_item_port.item_done();
        end

    endtask

    task drive_not_ready();
        vif.md_tx_ready <= 1'b0;
        vif.md_tx_err   <= 1'b0;
    endtask

    task respond_to_transfer(m_seq_item item);
        @(posedge vif.clk);
        while (vif.md_tx_valid !== 1'b1) begin
            @(posedge vif.clk);
        end

        vif.md_tx_ready <= 1'b1;
        vif.md_tx_err <= item.err;

        @(posedge vif.clk);


        `uvm_info("DRIVER_TX", $sformatf("Recibido: data=0x%08h offset=%0d size=%0d err=%0b",item.data, item.offset, item.size, item.err), UVM_HIGH)
        
        drive_not_ready();


    endtask


endclass