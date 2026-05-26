`include "uvm_macros.svh"
import uvm_pkg::*;
import aligner_apb_registerfile_model::*;

class apb_sequence extends uvm_sequence #(apb_seq_item);
    `uvm_object_utils(apb_sequence)

	aligner_apb_registerfile_model::aligner reg_model;
    function new(string name = "apb_sequence");
        super.new(name);
    endfunction

    task body();
        uvm_status_e   status;
        uvm_reg_data_t val;

        if(!uvm_config_db #(aligner_apb_registerfile_model::aligner)::get(
            null, get_full_name(), "reg_model", reg_model))
            `uvm_fatal("SEQ", "No se pudo obtener reg_model")

        // 1. Modificar el campo SIZE en el mirror (preparar el valor deseado)
                reg_model.CTRL.OFFSET.set(3'h0);
            reg_model.CTRL.SIZE.set(3'h1);

                `uvm_info("RAL_SEQ", $sformatf("Generando estimulo: Escribiendo SIZE=%0d OFFSET=%0d en CTRL",
                                                     reg_model.CTRL.SIZE.get(), reg_model.CTRL.OFFSET.get()), UVM_LOW)
        
        // 2. Empujar al DUT. Esto genera la transacción WRITE en el bus APB.
   
        reg_model.CTRL.update(status, UVM_FRONTDOOR);
        `uvm_info("RAL_SEQ", $sformatf("CTRL.update status=%s", status.name()), UVM_LOW)
        
        `uvm_info("RAL_SEQ", "Generando estimulo: Leyendo CTRL para que el Scoreboard verifique", UVM_LOW)

        // 3. Leer el registro desde el DUT. Esto genera la transacción READ en el bus APB.

        reg_model.CTRL.read(status, val, UVM_FRONTDOOR);
        
        `uvm_info("RAL_SEQ", "Fin del estimulo APB", UVM_LOW)
    endtask
endclass