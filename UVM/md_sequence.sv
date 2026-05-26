`include "uvm_macros.svh"
import uvm_pkg::*;

class md_tx_sequence extends uvm_sequence #(m_seq_item); // salida
    `uvm_object_utils(md_tx_sequence)

    function new(string name = "md_tx_sequence");
        super.new(name);
    endfunction

    task body();
        m_seq_item req;
        int        md_tx_num;
        bit        md_tx_backpressure;

        if (!uvm_config_db#(int)::get(null, "*", "md_tx_num", md_tx_num))
            md_tx_num = 8;

        // Backpressure, si es 1 el slave introduce ciclos de ready=0 aleatorios
        if (!uvm_config_db#(bit)::get(null, "*", "md_tx_backpressure", md_tx_backpressure))
            md_tx_backpressure = 0;

        repeat (md_tx_num) begin
            req = m_seq_item::type_id::create("req");
            start_item(req);

            if (md_tx_backpressure) begin
                // Randomiza el delay de ready para simular un receptor lento
                if (!req.randomize() with {
                    size   inside {[1:4]};
                    offset inside {[0:3]};
                    ((4 + offset) % size) == 0;
                }) `uvm_fatal(get_type_name(), "Randomize fallido (TX backpressure mode)")
            end else begin
                // el slave siempre listo, acepta inmediatamente lo que mande el dut
                if (!req.randomize()) 
                    `uvm_fatal(get_type_name(), "Randomize fallido (TX ready mode)")
            end

            finish_item(req);
        end
    endtask

endclass

              class md_rx_sequence extends uvm_sequence #(m_seq_item); //entrada
    `uvm_object_utils(md_rx_sequence)

    function new(string name = "md_rx_sequence");
        super.new(name);
    endfunction

    task body();
        m_seq_item req;
        int        md_num;
        bit        md_allow_illegal;

        if (!uvm_config_db#(int)::get(null, "*", "md_num", md_num))
            md_num = 1;

        if (!uvm_config_db#(bit)::get(null, "*", "md_allow_illegal", md_allow_illegal))
            md_allow_illegal = 0;

        repeat (md_num) begin
            req = m_seq_item::type_id::create("req");
            start_item(req);

            if (md_allow_illegal) begin
                // Genera combinaciones potencialmente ilegales para verificar md_rx_err
                if (!req.randomize() with {
                    size   inside {[0:4]};
                    offset inside {[0:3]};
                }) `uvm_fatal(get_type_name(), "Randomize fallido (RX illegal mode)")
            end else begin
                // solo se deberia generar transacciones legales con size>0 y ((4+offset)%size)==0
                if (!req.randomize() with {
                    size   inside {[1:4]};
                    offset inside {[0:3]};
                    size > 0;
                    ((4 + offset) % size) == 0;
                }) `uvm_fatal(get_type_name(), "Randomize fallido (RX legal mode)")
            end

            finish_item(req);
        end
    endtask

endclass

