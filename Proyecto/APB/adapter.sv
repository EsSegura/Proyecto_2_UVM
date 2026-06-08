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

virtual function void bus2reg(input uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    apb_seq_item apb_op;
    if(!$cast(apb_op, bus_item))
        `uvm_fatal("ADAPTER", "Cast fallido")
    rw.addr = apb_op.addr;
    rw.data = apb_op.write ? apb_op.data : apb_op.rdata;
    rw.kind = (apb_op.write) ? UVM_WRITE : UVM_READ;
    // si el slave respondio con error (slverr), el acceso fue rechazado:
    // se marca como NOT_OK para que el predictor NO actualice el RAL con un
    // valor que el DUT no acepto (p.ej. un CTRL con combinacion ilegal)
    rw.status = apb_op.slverr ? UVM_NOT_OK : UVM_IS_OK;
endfunction



endclass