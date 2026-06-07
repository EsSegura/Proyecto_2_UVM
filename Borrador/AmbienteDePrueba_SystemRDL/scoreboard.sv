class apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(apb_scoreboard)

    uvm_analysis_imp #(apb_seq_item, apb_scoreboard) ap;
    mi_periferico_pkg::MI_PERIFERICO reg_model;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
    endfunction

    virtual function void write(apb_seq_item trans);
        uvm_reg        reg_obj;
        uvm_reg_field  fields[$];
        uvm_reg_data_t exp_val;
        uvm_reg_data_t mirror_val;

        // Obtener el registro por dirección
        reg_obj = reg_model.default_map.get_reg_by_offset(trans.addr);
        if(reg_obj == null) begin
            `uvm_warning("SCOREBOARD", $sformatf(
                "Direccion 0x%0h no encontrada en el modelo", trans.addr))
            return;
        end

        if(!trans.write) begin
            // ── Verificación de LECTURA ───────────────────────────
            exp_val = reg_obj.get(); // valor reflejado del modelo

            if(exp_val !== trans.rdata) begin
                `uvm_error("SCOREBOARD", $sformatf(
                    "LECTURA MISMATCH | reg=%s addr=0x%0h | esperado=0x%0h obtenido=0x%0h",
                    reg_obj.get_name(), trans.addr, exp_val, trans.rdata))
            end else begin
                `uvm_info("SCOREBOARD", $sformatf(
                    "LECTURA OK | reg=%s addr=0x%0h | valor=0x%0h",
                    reg_obj.get_name(), trans.addr, trans.rdata), UVM_MEDIUM)

                // Desglose por campos
                reg_obj.get_fields(fields);
                foreach(fields[i]) begin
                    `uvm_info("SCOREBOARD", $sformatf(
                        "  |-- %s = %0d",
                        fields[i].get_name(), fields[i].get()), UVM_MEDIUM)
                end
            end

        end else begin
            // Verificación de escritura asumiendo que el predictor ya actualizó el mirror con el valor escrito
            mirror_val = reg_obj.get();

            if(mirror_val !== trans.data) begin
                `uvm_error("SCOREBOARD", $sformatf(
                    "ESCRITURA MISMATCH | reg=%s addr=0x%0h | escrito=0x%0h mirror=0x%0h",
                    reg_obj.get_name(), trans.addr, trans.data, mirror_val))
            end else begin
                `uvm_info("SCOREBOARD", $sformatf(
                    "ESCRITURA OK | reg=%s addr=0x%0h | valor=0x%0h",
                    reg_obj.get_name(), trans.addr, trans.data), UVM_MEDIUM)
            end
        end
    endfunction

endclass