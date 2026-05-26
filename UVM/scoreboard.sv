`include "uvm_macros.svh"
import uvm_pkg::*;
import aligner_apb_registerfile_model::*;

`uvm_analysis_imp_decl(_rx)
`uvm_analysis_imp_decl(_tx)
`uvm_analysis_imp_decl(_apb)

class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    uvm_analysis_imp_rx #(m_seq_item, scoreboard) rx_export;
    uvm_analysis_imp_tx #(m_seq_item, scoreboard) tx_export;
    uvm_analysis_imp_apb #(apb_seq_item, scoreboard) apb_export;

	aligner_apb_registerfile_model::aligner reg_model;
    m_seq_item md_pending_rx_q[$];
    int unsigned md_pending_progress_q[$];
    int unsigned rx_count;
    int unsigned tx_count;
    int unsigned md_match_count;
    int unsigned md_mismatch_count;
    int unsigned apb_write_count;
    int unsigned apb_read_count;
    int unsigned apb_match_count;
    int unsigned apb_mismatch_count;

    function new(string name = "scoreboard", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        rx_export = new("rx_export", this);
        tx_export = new("tx_export", this);
        apb_export = new("apb_export", this);
    endfunction

    virtual function void write_rx(m_seq_item data);
    rx_count++;
    `uvm_info(get_type_name(), $sformatf("RX observado: data=0x%0h offset=%0d size=%0d err=%0b",
                                        data.data, data.offset, data.size, data.err), UVM_MEDIUM)

    if (data.err) begin
        return;
    end

    begin
        m_seq_item item_copy;
        $cast(item_copy, data.clone());
        md_pending_rx_q.push_back(item_copy);
        md_pending_progress_q.push_back(0);
    end
endfunction

    virtual function void write_tx(m_seq_item data);



        m_seq_item pending_rx;
        int unsigned pending_progress;
        int unsigned ctrl_size;
        int unsigned ctrl_offset;
        int unsigned remaining_bytes;
        int unsigned chunk_bytes;
        bit [31:0] expected_data;

   

        if (md_pending_rx_q.size() == 0) begin
            md_mismatch_count++;
            `uvm_error(get_type_name(), $sformatf("TX observado sin esperado pendiente: data=0x%0h offset=%0d size=%0d err=%0b",
                                                 data.data, data.offset, data.size, data.err))
        end else begin
            pending_rx = md_pending_rx_q[0];
            pending_progress = md_pending_progress_q[0];
            ctrl_size = get_ctrl_size();
            ctrl_offset = get_ctrl_offset();

            remaining_bytes = pending_rx.size - pending_progress;
            chunk_bytes = (remaining_bytes >= ctrl_size) ? ctrl_size : remaining_bytes;
            expected_data = extract_tx_data(pending_rx.data,
                                            pending_rx.offset + pending_progress,
                                            chunk_bytes,
                                            ctrl_offset);

            if ((expected_data === data.data) && (ctrl_offset[1:0] === data.offset) && (chunk_bytes[2:0] === data.size)) begin
                md_match_count++;
            end else begin
                md_mismatch_count++;
                `uvm_error(get_type_name(),
           $sformatf("MD MISMATCH esperado=(data=0x%0h offset=%0d size=%0d) got=(data=0x%0h offset=%0d size=%0d err=%0b) rx_pend=(data=0x%0h offset=%0d size=%0d prog=%0d ctrl_size=%0d ctrl_offset=%0d)",
                     expected_data, ctrl_offset[1:0], chunk_bytes[2:0],
                     data.data, data.offset, data.size, data.err,
                     pending_rx.data, pending_rx.offset, pending_rx.size,
                     pending_progress,
                     ctrl_size, ctrl_offset))
            end

            if (remaining_bytes <= ctrl_size) begin
                void'(md_pending_rx_q.pop_front());
                void'(md_pending_progress_q.pop_front());
            end else begin
                md_pending_progress_q[0] = pending_progress + chunk_bytes;
            end
        end

        tx_count++;
        `uvm_info(get_type_name(), $sformatf("TX observado: data=0x%0h offset=%0d size=%0d err=%0b",
                                            data.data, data.offset, data.size, data.err), UVM_MEDIUM)
    endfunction

    function automatic int unsigned get_ctrl_size();
        uvm_reg_data_t ctrl_value;
        ctrl_value = reg_model.CTRL.get_mirrored_value();
        if (ctrl_value[2:0] == 0) begin
            return 1;
        end
        return ctrl_value[2:0];
    endfunction

    function automatic int unsigned get_ctrl_offset();
        uvm_reg_data_t ctrl_value;
        ctrl_value = reg_model.CTRL.get_mirrored_value();
        return ctrl_value[9:8];
    endfunction

    function automatic bit [31:0] extract_tx_data(bit [31:0] source_data,
                                                 int unsigned source_offset,
                                                 int unsigned byte_count,
                                                 int unsigned ctrl_offset);
        bit [31:0] mask;
        if (byte_count >= 4) begin
            mask = 32'hffff_ffff;
        end else begin
            mask = (32'h1 << (byte_count * 8)) - 1;
        end
        return ((source_data >> (source_offset * 8)) & mask) << (ctrl_offset * 8);
    endfunction

  virtual function void write_apb(apb_seq_item trans); // cambiado a funcion del scoreboard del ambiente de prueba
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


    virtual function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(),
                  $sformatf("Resumen MD: RX=%0d TX=%0d MATCH=%0d MISMATCH=%0d PEND=%0d",
                            rx_count, tx_count, md_match_count, md_mismatch_count, md_pending_rx_q.size()),
                  UVM_LOW)
        `uvm_info(get_type_name(),
                  $sformatf("Resumen APB: WR=%0d RD=%0d MATCH=%0d MISMATCH=%0d",
                            apb_write_count, apb_read_count, apb_match_count, apb_mismatch_count),
                  UVM_LOW)
    endfunction 

endclass 
