//secuencia base
class md_rx_base_seq extends uvm_sequence #(md_seq_item);

    `uvm_object_utils(md_rx_base_seq)

    function new(string name = "md_rx_base_seq");
        super.new(name);
    endfunction

    // se crea un ítem, lo aleatoriza con el constraint que se pase,
    // lo envía y devuelve el ítem completado y con rx_err capturado
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

    protected task send_illegal_item(md_seq_item item);
        item.c_size_range.constraint_mode(0);
        item.c_offset_range.constraint_mode(0);
        item.c_legal_combo.constraint_mode(0);

        item.rx_data   = $urandom;
        item.rx_offset = 2'h1;
        item.rx_size   = 3'h3;

        send_prebuilt_item(item);
    endtask

    virtual task body();
        // Clase base vacía; las clases derivadas implementan body()
    endtask

endclass 


// secuencia de N transferencias legales aleatorias
class md_rx_multiple_seq extends md_rx_base_seq;

    `uvm_object_utils(md_rx_multiple_seq)

    // Número de transferencias a enviar 
    int unsigned num_transfers = 8;
    // Porcentaje de transferencias ilegales a inyectar
    int unsigned illegal_ratio = 0;

    function new(string name = "md_rx_multiple_seq");
        super.new(name);
    endfunction

    virtual task body();
        md_seq_item item;

        `uvm_info(get_type_name(),
            $sformatf("Iniciando secuencia: %0d transferencias RX (illegal_ratio=%0d%%)", num_transfers, illegal_ratio),
            UVM_LOW)

        for (int i = 0; i < num_transfers; i++) begin
            item = md_seq_item::type_id::create($sformatf("item_%0d", i));
            if ((illegal_ratio != 0) && ($urandom_range(0, 99) < int'(illegal_ratio)))
                send_illegal_item(item);
            else
                send_item(item);
        end

        `uvm_info(get_type_name(), "Secuencia múltiple completada", UVM_LOW)
    endtask

endclass


// secuencia de transferencia dirigida con valores fijos
// Permite al test controlar exactamente qué dato, offset y size se envían
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

endclass 
