`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_md_rx)
`uvm_analysis_imp_decl(_md_tx)


class aligner_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(aligner_scoreboard)

    // Puertos de análisis de entrada
    uvm_analysis_imp_apb   #(apb_seq_item, aligner_scoreboard) apb_ap;
    uvm_analysis_imp_md_rx #(md_seq_item,  aligner_scoreboard) md_rx_ap;
    uvm_analysis_imp_md_tx #(md_seq_item,  aligner_scoreboard) md_tx_ap;

    // Handle para el modelo de registros
    aligner_apb_registerfile_model::aligner reg_model;

    // cola de bytes RX pendientes de verificar en el TX
    local byte unsigned rx_byte_queue[$];

    // contador de chequeos
    local int unsigned checks_passed;
    local int unsigned checks_failed;

    //funcion new para inicializar contadores
    function new(string name, uvm_component parent);
        super.new(name, parent);
        checks_passed = 0;
        checks_failed = 0;
    endfunction

    //build phase para crear los puertos de analisis y obtener el modelo de registros 
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        apb_ap   = new("apb_ap",   this);
        md_rx_ap = new("md_rx_ap", this);
        md_tx_ap = new("md_tx_ap", this);

        // obtener handle del modelo de registros desde el config DB
        if (!uvm_config_db#(aligner_apb_registerfile_model::aligner)::get(this, "", "reg_model", reg_model)) begin
            `uvm_fatal(get_type_name(), "No se pudo obtener el reg_model del uvm_config_db")
        end
    endfunction

    // un report phase para mostrar un resumen de resultados al final de simulacion
    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(),
            $sformatf("=== Resumen de verificaciones: PASSED=%0d  FAILED=%0d ===", checks_passed, checks_failed),
            UVM_NONE)
        if (checks_failed > 0)
            `uvm_error(get_type_name(), "Existen verificaciones fallidas. Revisar log.")
    endfunction

    // write_apb: recibe transacciones del monitor APB
    // se implementa chequeos especificos para cada registro y tipo de acceso
    function void write_apb(apb_seq_item trans);
        logic [15:0] aligned_addr;
        logic [2:0]  read_size;
        logic [1:0]  read_offset;

        // Offsets de registros 
        localparam logic [15:0] CTRL_ADDR   = 16'h0000;
        localparam logic [15:0] STATUS_ADDR = 16'h000C;
        localparam logic [15:0] IRQEN_ADDR  = 16'h00F0;
        localparam logic [15:0] IRQ_ADDR    = 16'h00F4;

        aligned_addr = {trans.addr[15:2], 2'b00};

        // La sincronizacion del RAL la realiza ahora el PREDICTOR EXPLICITO
        // (uvm_reg_predictor en el env), que observa este mismo monitor APB.
        // Por eso aqui ya NO se llama predict() manualmente; solo se consulta
        // el valor reflejado con get() donde haga falta.

        // Verificar read-back de CTRL: lo leído debe coincidir con el RAL
        if (!trans.write && (aligned_addr == CTRL_ADDR) && !trans.slverr) begin
            read_size   = trans.rdata[2:0];
            read_offset = trans.rdata[9:8];
            do_check("CTRL.SIZE read-back",   (read_size   == reg_model.CTRL.SIZE.get()));
            do_check("CTRL.OFFSET read-back", (read_offset == reg_model.CTRL.OFFSET.get()));
        end

        // Write a STATUS debe devolver PSLVERR
        if (trans.write && (aligned_addr == STATUS_ADDR))
            do_check("Write STATUS debe generar PSLVERR", (trans.slverr === 1'b1));

        // Acceso a direccion no mapeada debe devolver PSLVERR
        if ((aligned_addr != CTRL_ADDR)   &&
            (aligned_addr != STATUS_ADDR) &&
            (aligned_addr != IRQEN_ADDR)  &&
            (aligned_addr != IRQ_ADDR))
            do_check("Acceso no mapeado debe generar PSLVERR", (trans.slverr === 1'b1));
    endfunction

    // write_md_rx: recibe transferencias observadas en el canal RX
    function void write_md_rx(md_seq_item trans);
        bit is_legal;
        int b;

        // utilizando la ecuacion dada por el datasheet se usa ((ALGN_DATA_WIDTH/8) + offset) % size == 0
        // para DATA_WIDTH=32 daria ALGN_DATA_WIDTH/8 = 4
        is_legal = (trans.rx_size != 0) &&
                   (((4 + trans.rx_offset) % trans.rx_size) == 0);

        if (!is_legal) begin
            do_check("RX ilegal debe tener rx_err=1", (trans.rx_err === 1'b1));
        end else begin
            do_check("RX legal no debe tener rx_err",  (trans.rx_err === 1'b0));

            // Encolar bytes validos para comparacion con TX
            for (b = trans.rx_offset; b < int'(trans.rx_offset + trans.rx_size); b++)
                rx_byte_queue.push_back(trans.rx_data[b*8 +: 8]);

            `uvm_info(get_type_name(),
                $sformatf("SB RX: %0d bytes encolados (total=%0d)", trans.rx_size, rx_byte_queue.size()),
                UVM_MEDIUM)
        end
    endfunction

    // write_md_tx: recibe transferencias observadas en el canal TX
    function void write_md_tx(md_seq_item trans);
        int b;
        byte unsigned expected;
        byte unsigned actual;
        logic [2:0] ctrl_size_val;
        logic [1:0] ctrl_offset_val;

        // Leer valores actuales desde el modelo de registros (mantenido
        // sincronizado via predict() en write_apb cada vez que se escribe CTRL)
        ctrl_size_val   = reg_model.CTRL.SIZE.get();
        ctrl_offset_val = reg_model.CTRL.OFFSET.get();

        do_check("TX offset == CTRL.OFFSET", (trans.tx_offset == ctrl_offset_val));
        do_check("TX size == CTRL.SIZE",     (trans.tx_size   == ctrl_size_val));

        if (rx_byte_queue.size() >= ctrl_size_val) begin
            for (b = 0; b < int'(ctrl_size_val); b++) begin
                expected = rx_byte_queue.pop_front();
                // El byte b del TX está en posición (ctrl_offset + b) del bus
                actual   = trans.tx_data[(int'(ctrl_offset_val) + b)*8 +: 8];
                do_check($sformatf("TX data byte[%0d] correcto", b), (actual == expected));
            end
        end
    endfunction

    // funcion para registrar resultado de un chequeo
    local function void do_check(string name, bit result);
        if (result) begin
            checks_passed++;
            `uvm_info(get_type_name(), $sformatf("  PASS: %s", name), UVM_HIGH)
        end else begin
            checks_failed++;
            `uvm_error(get_type_name(), $sformatf("  FAIL: %s", name))
        end
    endfunction

endclass : aligner_scoreboard
