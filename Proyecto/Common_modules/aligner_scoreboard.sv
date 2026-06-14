`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_md_rx)
`uvm_analysis_imp_decl(_md_tx)


class aligner_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(aligner_scoreboard) //registra el scoreboard en la fabrica

    //Puertos de análisis de entrada
    uvm_analysis_imp_apb   #(apb_seq_item, aligner_scoreboard) apb_ap;   //recibe accesos APB
    uvm_analysis_imp_md_rx #(md_seq_item,  aligner_scoreboard) md_rx_ap; //recibe transferencias RX
    uvm_analysis_imp_md_tx #(md_seq_item,  aligner_scoreboard) md_tx_ap; //recibe transferencias TX

    //Handle para el modelo de registros
    aligner_apb_registerfile_model::aligner reg_model;

    local logic [2:0] sb_ctrl_size   = 3'h1; //copia local del SIZE configurado en CTRL
    local logic [1:0] sb_ctrl_offset = 2'h0; //copia local del OFFSET configurado en CTRL

    local byte unsigned rx_byte_queue[$]; //cola con los bytes que entraron por RX

    local bit sb_data_check_en = 1'b0; //habilitado en la 1a config valida
    local bit sb_first_cfg     = 1'b1; //marca la configuracion inicial

    //contador de chequeos
    local int unsigned checks_passed; //cuantos chequeos pasaron
    local int unsigned checks_failed; //cuantos chequeos fallaron

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

        //obtener handle del modelo de registros desde el config DB
        if (!uvm_config_db#(aligner_apb_registerfile_model::aligner)::get(this, "", "reg_model", reg_model)) begin
            `uvm_fatal(get_type_name(), "No se pudo obtener el reg_model del uvm_config_db")
        end
    endfunction

    //un report phase para mostrar un resumen de resultados al final de simulacion
    function void report_phase(uvm_phase phase);
        `uvm_info(get_type_name(),
            $sformatf("=== Resumen de verificaciones: PASSED=%0d  FAILED=%0d ===", checks_passed, checks_failed),
            UVM_NONE)
        if (checks_failed > 0)
            `uvm_error(get_type_name(), "Existen verificaciones fallidas. Revisar log.")
    endfunction

    //write_apb: recibe transacciones del monitor APB
    //se implementa chequeos especificos para cada registro y tipo de acceso
    function void write_apb(apb_seq_item trans);
        logic [15:0] aligned_addr; //direccion alineada a palabra
        logic [2:0]  read_size;    //size leido en un read-back de CTRL
        logic [1:0]  read_offset;  //offset leido en un read-back de CTRL

        //Offsets de registros
        localparam logic [15:0] CTRL_ADDR   = 16'h0000;
        localparam logic [15:0] STATUS_ADDR = 16'h000C;
        localparam logic [15:0] IRQEN_ADDR  = 16'h00F0;
        localparam logic [15:0] IRQ_ADDR    = 16'h00F4;

        aligned_addr = {trans.addr[15:2], 2'b00}; //alinea la direccion a multiplo de 4

        //Escritura aceptada a CTRL: se actualiza la copia local con lo que
        //realmente quedo configurado en el DUT
        if (trans.write && (aligned_addr == CTRL_ADDR) && !trans.slverr) begin
            sb_ctrl_size   = trans.data[2:0];
            sb_ctrl_offset = trans.data[9:8];

            rx_byte_queue.delete(); //al reconfigurar se descarta lo que habia en la cola

            //El chequeo de datos solo se habilita en la PRIMERA config valida
            sb_data_check_en = sb_first_cfg;
            sb_first_cfg     = 1'b0;

            `uvm_info(get_type_name(),
                $sformatf("SB CTRL shadow: SIZE=%0d OFFSET=%0d (data=0x%0h) [data_check=%0b]",
                    sb_ctrl_size, sb_ctrl_offset, trans.data, sb_data_check_en),
                UVM_MEDIUM)
        end

        //Escritura rechazada a CTRL, el PSLVERR debe corresponder a un combo
        //realmente ilegal segun la formula del datasheet (o size 0)
        if (trans.write && (aligned_addr == CTRL_ADDR) && trans.slverr) begin
            do_check("PSLVERR en CTRL solo con combo ilegal",
                (trans.data[2:0] == 0) ||
                (((4 + trans.data[9:8]) % trans.data[2:0]) != 0));
        end

        //Verificar read-back de CTRL, lo leido debe coincidir con la copia local
        if (!trans.write && (aligned_addr == CTRL_ADDR) && !trans.slverr) begin
            read_size   = trans.rdata[2:0];
            read_offset = trans.rdata[9:8];
            do_check("CTRL.SIZE read-back",   (read_size   == sb_ctrl_size));
            do_check("CTRL.OFFSET read-back", (read_offset == sb_ctrl_offset));
        end

        //Write a STATUS debe devolver PSLVERR
        if (trans.write && (aligned_addr == STATUS_ADDR))
            do_check("Write STATUS debe generar PSLVERR", (trans.slverr === 1'b1));

        //Acceso a direccion no mapeada debe devolver PSLVERR
        if ((aligned_addr != CTRL_ADDR)   &&
            (aligned_addr != STATUS_ADDR) &&
            (aligned_addr != IRQEN_ADDR)  &&
            (aligned_addr != IRQ_ADDR))
            do_check("Acceso no mapeado debe generar PSLVERR", (trans.slverr === 1'b1));
    endfunction

    //write_md_rx: recibe transferencias observadas en el canal RX
    function void write_md_rx(md_seq_item trans);
        bit is_legal; //si el par (size, offset) es valido
        int b;        //indice de byte
        int pos;      //posicion del byte en el bus

        //utilizando la ecuacion dada por el datasheet se usa ((ALGN_DATA_WIDTH/8) + offset) % size == 0
        //para DATA_WIDTH=32 daria ALGN_DATA_WIDTH/8 = 4
        is_legal = (trans.rx_size != 0) &&
                   (((4 + trans.rx_offset) % trans.rx_size) == 0);

        if (!is_legal) begin
            do_check("RX ilegal debe tener rx_err=1", (trans.rx_err === 1'b1));
        end else begin
            do_check("RX legal no debe tener rx_err",  (trans.rx_err === 1'b0));

            //Encolar los 'size' bytes que el DUT extrae
            if (sb_data_check_en) begin
                for (b = 0; b < int'(trans.rx_size); b++) begin
                    pos = int'(trans.rx_offset) + b;
                    if (pos <= 3)
                        rx_byte_queue.push_back(trans.rx_data[pos*8 +: 8]);
                    else
                        rx_byte_queue.push_back(8'h00);
                end
            end
        end
    endfunction

    //write_md_tx: recibe transferencias observadas en el canal TX
    function void write_md_tx(md_seq_item trans);
        logic [2:0] ctrl_size_val;   //size vigente de CTRL
        logic [1:0] ctrl_offset_val; //offset vigente de CTRL
        int b;             //indice de byte
        int pos;           //posicion del byte en el bus
        byte unsigned expected; //byte esperado (del RX)
        byte unsigned actual;   //byte realmente observado en TX

        //Leer la configuracion vigente desde la copia local del scoreboard
        ctrl_size_val   = sb_ctrl_size;
        ctrl_offset_val = sb_ctrl_offset;

        //chequeo de paquetes legales
        do_check("TX (size,offset) es un par legal",
                 (trans.tx_size != 0) &&
                 (((4 + trans.tx_offset) % trans.tx_size) == 0));

        //chequeo del offset y size para comparar si saca bien la configuracion establecida
        if (sb_data_check_en) begin
            do_check("TX offset == CTRL.OFFSET", (trans.tx_offset == ctrl_offset_val));
            do_check("TX size == CTRL.SIZE",     (trans.tx_size   == ctrl_size_val));
        end


        //Se consumen tx_size bytes del stream
        //el byte b sale en la posicion (tx_offset + b) del bus. Las posiciones
        //> 3 no son observables en 32 bits (3er byte de size3): se hace pop
        //para no desfasar la cola
        if (sb_data_check_en && (rx_byte_queue.size() >= int'(trans.tx_size))) begin
            for (b = 0; b < int'(trans.tx_size); b++) begin
                expected = rx_byte_queue.pop_front();
                pos      = int'(trans.tx_offset) + b;
                if (pos <= 3) begin
                    actual = trans.tx_data[pos*8 +: 8];
                    do_check($sformatf("TX data byte[%0d] correcto", b), (actual == expected));
                end
            end
        end
    endfunction

    //funcion para registrar resultado de un chequeo
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
