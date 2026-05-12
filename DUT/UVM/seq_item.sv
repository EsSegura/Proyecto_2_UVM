class seq_item extends uvm_sequence_item ;
    `uvm_object_utils(seq_item)

    // rand logic [3:0] .. ;

    // UVM field macros
    `uvm_object_utils_begin(mem_seq_item)
        `uvm_field_int(adata,UVM_ALL_ON)
        `uvm_field_int(offset,UVM_ALL_ON)
        `uvm_field_int(size,UVM_ALL_ON)
        `uvm_field_int(delay,UVM_ALL_ON)
        `uvm_field_int(err,UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "seq_item");
       super.new(name);
    endfunction

    rand logic [31:0] data;
    rand logic [7:0] offset;
    rand logic [2:0] size;
    rand int unsigned delay;
    rand logic err; 

    constrain



endclass