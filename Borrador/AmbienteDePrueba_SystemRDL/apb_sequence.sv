class apb_sequence extends uvm_sequence #(apb_seq_item);
    `uvm_object_utils(apb_sequence)

    mi_periferico_pkg::MI_PERIFERICO reg_model;

    function new(string name = "apb_sequence");
        super.new(name);
    endfunction

task body();
    uvm_status_e   status;
    uvm_reg_data_t val;

    if(!uvm_config_db #(mi_periferico_pkg::MI_PERIFERICO)::get(
        null, get_full_name(), "reg_model", reg_model))
        `uvm_fatal("SEQ", "No se pudo obtener reg_model")

    
    reg_model.CONTROL.read(status, val, UVM_FRONTDOOR);
    reg_model.CONTROL.write(status, 32'h5, UVM_FRONTDOOR);
    reg_model.CONTROL.read(status, val, UVM_FRONTDOOR);

    reg_model.CONTROL.MODE.set(2'h3);
    reg_model.CONTROL.update(status, UVM_FRONTDOOR);
    reg_model.CONTROL.read(status, val, UVM_FRONTDOOR);

    reg_model.STATUS.read(status, val, UVM_FRONTDOOR);
  
endtask
  
endclass