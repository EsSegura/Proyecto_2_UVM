class apb_scoreboard extends uvm_scoreboard;
`uvm_component_utils(apb_scoreboard)

function new(string name, uvm_component parent);
    super.new(name, parent);
endfunction

uvm_analysis_imp #(apb_seq_item, apb_scoreboard) ap; // Impresión de la transacción para el scoreboard

mi_periferico_pkg::MI_PERIFERICO reg_model; // Modelo de registro 

function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this); // Crear la instancia del análisis de impresión
endfunction

virtual function void write(apb_seq_item trans);
    uvm_reg reg_obj; //registro del modelo de registro
    uvm_reg_data_t exp_val; //valor esperado del registro, se obtiene del modelo de registro

    reg_obj = reg_model.default_map.get_reg_by_offset(trans.addr);
    if(reg_obj == null) return; 

    if(!trans.write) begin
        exp_val = reg_obj.get();
        if(exp_val != trans.rdata)
            `uvm_error("SCOREBOARD", $sformatf("MISMATCH addr=0x%0h exp=0x%0h got=0x%0h",
                        trans.addr, exp_val, trans.rdata))
        else
            `uvm_info("SCOREBOARD", "OK", UVM_MEDIUM)
    end
endfunction

endclass