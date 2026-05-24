`include "uvm_macros.svh"
import uvm_pkg::*;

class m_seq_item extends uvm_sequence_item;
    `uvm_object_utils_begin(m_seq_item)
        `uvm_field_int(data,   UVM_ALL_ON)
        `uvm_field_int(offset, UVM_ALL_ON)
        `uvm_field_int(size,   UVM_ALL_ON)
        `uvm_field_int(err,    UVM_ALL_ON)
    `uvm_object_utils_end

    rand bit [31:0] data;
    rand bit [1:0]  offset;
    rand bit [2:0]  size;
         bit        err;

    constraint c_size {
        size inside {[1:4]};
    }

    constraint c_offset {
        (4 + offset) % size == 0;
    }

    function new(string name = "m_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("data=0x%08h offset=%0d size=%0d err=%0b", data, offset, size, err);
    endfunction
endclass