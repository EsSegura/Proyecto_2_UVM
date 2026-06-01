`include "uvm_macros.svh"
import uvm_pkg::*;
import aligner_apb_registerfile_model::*;

class apb_sequence extends uvm_sequence #(apb_seq_item);
    `uvm_object_utils(apb_sequence)

	aligner_apb_registerfile_model::aligner reg_model;
    uvm_reg       target_reg;
    uvm_reg_field target_field;
    uvm_reg_data_t target_value;
    bit           do_read;
    function new(string name = "apb_sequence");
        super.new(name);
        target_reg   = null;
        target_field = null;
        target_value = '0;
        do_read      = 1'b0;
    endfunction

    function void set_write_field(uvm_reg reg_h, uvm_reg_field field_h, uvm_reg_data_t value);
        target_reg   = reg_h;
        target_field = field_h;
        target_value = value;
        do_read      = 1'b0;
    endfunction

    function void set_write_reg(uvm_reg reg_h, uvm_reg_data_t value);
        target_reg   = reg_h;
        target_field = null;
        target_value = value;
        do_read      = 1'b0;
    endfunction

    function void set_read_reg(uvm_reg reg_h);
        target_reg   = reg_h;
        target_field = null;
        target_value = '0;
        do_read      = 1'b1;
    endfunction

    task body();
        uvm_status_e   status;
        uvm_reg_data_t val;

        if(!uvm_config_db #(aligner_apb_registerfile_model::aligner)::get(
            null, get_full_name(), "reg_model", reg_model))
            `uvm_fatal("SEQ", "No se pudo obtener reg_model")

        if (target_reg == null)
            target_reg = reg_model.CTRL;

        if (do_read) begin
            `uvm_info("RAL_SEQ",
                $sformatf("Leyendo registro %s via RAL", target_reg.get_name()),
                UVM_LOW)
            target_reg.read(status, val, UVM_FRONTDOOR);
            `uvm_info("RAL_SEQ", $sformatf("READ status=%s data=0x%0h", status.name(), val), UVM_LOW)
        end else if (target_field != null) begin
            `uvm_info("RAL_SEQ",
                $sformatf("Escribiendo campo %s.%s = 0x%0h", target_reg.get_name(), target_field.get_name(), target_value),
                UVM_LOW)
            target_field.set(target_value);
            target_reg.update(status, UVM_FRONTDOOR);
            `uvm_info("RAL_SEQ", $sformatf("WRITE status=%s", status.name()), UVM_LOW)
        end else begin
            `uvm_info("RAL_SEQ",
                $sformatf("Escribiendo registro %s = 0x%0h", target_reg.get_name(), target_value),
                UVM_LOW)
            target_reg.write(status, target_value, UVM_FRONTDOOR);
            `uvm_info("RAL_SEQ", $sformatf("WRITE status=%s", status.name()), UVM_LOW)
        end

        `uvm_info("RAL_SEQ", "Fin del estimulo APB", UVM_LOW)
    endtask
endclass