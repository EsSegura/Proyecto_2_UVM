`include "uvm_macros.svh"
import uvm_pkg::*;

class driver_rx extends uvm_driver #(m_seq_item);

    `uvm_component_utils(driver_rx)

    virtual md_rx_if vif;

    function new(string name = "driver_rx", uvm_component parent = null)
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(virtual md_rx_if)::get (this, "", "vif", vif)) begin      
            `uvm_fatal (get_type_name (), "No se encontró la interfaz md_rx_if")    
        end 
    endfunction


    virtual task run_phase(uvm_phase phase);
        m_seq_item request_item;
        //estado idle, valid en 0
        drive_idle();
        @(posedge vif.clk);
        wait (vif.reset_n === 1'b1);
        @(posedge vif.clk);

        forever begin
            m_seq_item item;
            seq_item_port.get_next_item(item);
            drive_packet(item);
            seq_item_port.item_done();
        end

    endtask

    task drive_idle();
        vif.md_rx_valid  <= 1'b0;
        vif.md_rx_data   <= '0;
        vif.md_rx_offset <= '0;
        vif.md_rx_size   <= '0;
    endtask

    //esta tarea se encarga de manejar el proceso de enviar una transaccion a la interfaz, se mantiene valid en 1 hasta que ready se active, y se mantienen los datos constantes
    task drive_packet(m_seq_item item);

        @(posedge vif.clk);
        vif.md_rx_valid <= 1'b1;
        vif.md_rx_data <= item.data;
        vif.md_rx_offset <= item.offset;
        vif.md_rx_size <= item.size;

        //esperar hasta a que haya un handshake, un ready en 1
        //el DUT puede deassertar el ready si el fifo rx esta full, generando backpressure
        @(posedge vif.clk);
        while (vif.md_rd_ready !== 1'b1) begin
            @(posedge vif.clk);
        end

        item.err = vif.md_rx_err;

        `uvm_info("DRIVER_RX", $sformatf("Enviado: data=0x%08h offset=%0d size=%0d err=%0b",item.data, item.offset, item.size, item.err), UVM_HIGH)
        
        //deassertar valid y limpiar los datos despues dedl handshake
        @(posedge vif.clk);
        drive_idle();
        
    endtask

endclass