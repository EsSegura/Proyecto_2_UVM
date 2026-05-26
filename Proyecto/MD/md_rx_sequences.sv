// ============================================================================
// Secuencias del canal RX del protocolo MD.
//
// Jerarquía:
//   md_rx_base_seq        – clase base con utilidades comunes
//   md_rx_single_seq      – envía una transferencia legal aleatoria
//   md_rx_multiple_seq    – envía N transferencias legales aleatorias
//   md_rx_directed_seq    – envía una transferencia con valores fijos (dirigida)
//   md_rx_illegal_seq     – envía una transferencia con combo (offset,size) ilegal
//                           para verificar que el DUT responda con md_rx_err=1
// ============================================================================

// ----------------------------------------------------------------------------
// Clase base: herramienta de conveniencia para crear y enviar ítems
// ----------------------------------------------------------------------------
class md_rx_base_seq extends uvm_sequence #(md_seq_item);

    `uvm_object_utils(md_rx_base_seq)

    function new(string name = "md_rx_base_seq");
        super.new(name);
    endfunction

    // Utilidad: crea un ítem, lo aleatoriza con el constraint que se pase,
    // lo envía y devuelve el ítem completado (con rx_err capturado).
    protected task send_item(md_seq_item item);
        start_item(item);
        if (!item.randomize())
            `uvm_fatal("MD_RX_SEQ", "Falló randomize() del md_seq_item")
        finish_item(item);
        `uvm_info(get_type_name(),
            $sformatf("SEQ SENT: %s", item.convert2string()), UVM_HIGH)
    endtask

    // Utilidad: envía un ítem ya construido sin re-randomizar
    protected task send_prebuilt_item(md_seq_item item);
        start_item(item);
        finish_item(item);
        `uvm_info(get_type_name(),
            $sformatf("SEQ SENT (prebuilt): %s", item.convert2string()), UVM_HIGH)
    endtask

    virtual task body();
        // Clase base vacía; las clases derivadas implementan body()
    endtask

endclass : md_rx_base_seq


// ----------------------------------------------------------------------------
// Secuencia: una sola transferencia legal aleatoria
// ----------------------------------------------------------------------------
class md_rx_single_seq extends md_rx_base_seq;

    `uvm_object_utils(md_rx_single_seq)

    function new(string name = "md_rx_single_seq");
        super.new(name);
    endfunction

    virtual task body();
        md_seq_item item = md_seq_item::type_id::create("item");
        `uvm_info(get_type_name(), "Iniciando secuencia: transferencia RX única legal", UVM_LOW)
        send_item(item);
        `uvm_info(get_type_name(),
            $sformatf("Transferencia completada: rx_err=%0b", item.rx_err), UVM_LOW)
    endtask

endclass : md_rx_single_seq


// ----------------------------------------------------------------------------
// Secuencia: N transferencias legales aleatorias
// ----------------------------------------------------------------------------
class md_rx_multiple_seq extends md_rx_base_seq;

    `uvm_object_utils(md_rx_multiple_seq)

    // Número de transferencias a enviar (configurable desde el test)
    int unsigned num_transfers = 8;

    function new(string name = "md_rx_multiple_seq");
        super.new(name);
    endfunction

    virtual task body();
        md_seq_item item;

        `uvm_info(get_type_name(),
            $sformatf("Iniciando secuencia: %0d transferencias RX legales", num_transfers),
            UVM_LOW)

        for (int i = 0; i < num_transfers; i++) begin
            item = md_seq_item::type_id::create($sformatf("item_%0d", i));
            send_item(item);
        end

        `uvm_info(get_type_name(), "Secuencia múltiple completada", UVM_LOW)
    endtask

endclass : md_rx_multiple_seq


// ----------------------------------------------------------------------------
// Secuencia: transferencia dirigida con valores fijos
// Permite al test controlar exactamente qué dato, offset y size se envían.
// ----------------------------------------------------------------------------
class md_rx_directed_seq extends md_rx_base_seq;

    `uvm_object_utils(md_rx_directed_seq)

    // Valores configurables desde el test
    logic [31:0] data   = 32'hDEAD_BEEF;
    logic [2:0]  offset = 3'h0;
    logic [2:0]  size   = 3'h1; // 1 byte

    function new(string name = "md_rx_directed_seq");
        super.new(name);
    endfunction

    virtual task body();
        md_seq_item item = md_seq_item::type_id::create("directed_item");

        `uvm_info(get_type_name(),
            $sformatf("Secuencia dirigida: data=0x%08h off=%0d sz=%0d",
                data, offset, size), UVM_LOW)

        // Desactivar constraints automáticas y asignar valores directamente
        item.c_size_range.constraint_mode(0);
        item.c_offset_range.constraint_mode(0);
        item.c_legal_combo.constraint_mode(0);

        item.rx_data   = data;
        item.rx_offset = offset;
        item.rx_size   = size;

        send_prebuilt_item(item);

        `uvm_info(get_type_name(),
            $sformatf("Dirigida completada: rx_err=%0b", item.rx_err), UVM_LOW)
    endtask

endclass : md_rx_directed_seq


// ----------------------------------------------------------------------------
// Secuencia: transferencia ilegal
// Envía una combinación (offset, size) que NO satisface la ecuación:
//   ((ALGN_DATA_WIDTH/8) + offset) % size == 0
// El DUT debe responder con md_rx_err=1.
// ----------------------------------------------------------------------------
class md_rx_illegal_seq extends md_rx_base_seq;

    `uvm_object_utils(md_rx_illegal_seq)

    // Por defecto genera un combo ilegal conocido:
    // (4 + 1) % 3 = 2  ≠ 0  → ilegal para DATA_WIDTH=32
    logic [31:0] data         = 32'hBAD_C0FFE;
    logic [2:0]  bad_offset   = 3'h1;
    logic [2:0]  bad_size     = 3'h3;

    function new(string name = "md_rx_illegal_seq");
        super.new(name);
    endfunction

    virtual task body();
        md_seq_item item = md_seq_item::type_id::create("illegal_item");

        `uvm_info(get_type_name(),
            $sformatf("Secuencia ILEGAL: data=0x%08h off=%0d sz=%0d → esperando rx_err=1",
                data, bad_offset, bad_size), UVM_LOW)

        // Deshabilitar todas las constraints y forzar combo ilegal
        item.c_size_range.constraint_mode(0);
        item.c_offset_range.constraint_mode(0);
        item.c_legal_combo.constraint_mode(0);

        item.rx_data   = data;
        item.rx_offset = bad_offset;
        item.rx_size   = bad_size;

        send_prebuilt_item(item);

        if (item.rx_err !== 1'b1)
            `uvm_error(get_type_name(),
                "FALLO: se esperaba rx_err=1 para transferencia ilegal")
        else
            `uvm_info(get_type_name(), "OK: DUT respondió con rx_err=1", UVM_LOW)
    endtask

endclass : md_rx_illegal_seq
