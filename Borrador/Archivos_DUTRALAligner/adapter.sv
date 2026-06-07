class apb_adapter extends uvm_reg_adapter;
`uvm_object_utils(apb_adapter)

function new(string name = "apb_adapter");
    super.new(name);
endfunction

virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    apb_seq_item apb_op;
    apb_op = apb_seq_item::type_id::create("apb_op");
    apb_op.addr = rw.addr;
    apb_op.data = rw.data;
    apb_op.write=(rw.kind == UVM_WRITE);
    return apb_op;

endfunction

virtual function void bus2reg(const ref uvm_sequence_item bus_op, ref uvm_reg_bus_op rw);
    apb_seq_item apb_op;
    if(!$cast(apb_op, bus_op))
        `uvm_fatal("ADAPTER", "Cast fallido")
    rw.addr = apb_op.addr;
    rw.data = apb_op.write ? apb_op.data : apb_op.rdata;
    rw.kind = (apb_op.write) ? UVM_WRITE : UVM_READ;
endfunction



endclass