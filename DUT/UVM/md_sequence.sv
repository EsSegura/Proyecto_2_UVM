`include "uvm_macros.svh"
import uvm_pkg::*;

class md_smoke_sequence extends uvm_sequence #(m_seq_item);
    `uvm_object_utils(md_smoke_sequence)

    function new(string name = "md_smoke_sequence");
        super.new(name);
    endfunction

    task body();
        m_seq_item req;
        repeat (8) begin
            req = m_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize()) begin
                `uvm_fatal(get_type_name(), "No se pudo randomizar m_seq_item")
            end
            req.err = 1'b0;
            finish_item(req);
        end
    endtask
endclass

class md_tx_ready_sequence extends uvm_sequence #(m_seq_item);
    `uvm_object_utils(md_tx_ready_sequence)

    function new(string name = "md_tx_ready_sequence");
        super.new(name);
    endfunction

    task body();
        m_seq_item req;
        repeat (8) begin
            req = m_seq_item::type_id::create("req");
            start_item(req);
            req.data = '0;
            req.offset = '0;
            req.size = 3'd1;
            req.err = 1'b0;
            finish_item(req);
        end
    endtask
endclass
