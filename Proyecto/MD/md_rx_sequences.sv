//secuencia base, solo tiene el send_item que reutilizan las demas
class md_rx_base_seq extends uvm_sequence #(md_seq_item);

    `uvm_object_utils(md_rx_base_seq) //registra la secuencia en la fabrica

    function new(string name = "md_rx_base_seq");
        super.new(name); //llama al constructor de la clase base uvm_sequence
    endfunction

    //randomiza el item y lo entrega al driver
    //los pesos ya tienen que venir puestos en el item antes de llamar a esta tarea
    protected task send_item(md_seq_item item);
        start_item(item); //pide permiso al sequencer para enviar el item
        if (!item.randomize()) //randomiza respetando los constraints
            `uvm_fatal("MD_RX_SEQ", "Falló randomize() del md_seq_item")
        finish_item(item); //entrega el item al driver y espera que termine
        `uvm_info(get_type_name(),
            $sformatf("SEQ SENT: %s", item.convert2string()), UVM_HIGH)
    endtask

    virtual task body(); //la base no hace nada, la llenan las hijas
    endtask

endclass


//esta secuencia envia N transferencias seguidas, los pesos vienen del test (por plusargs) y se copian a cada item antes de randomizar
class md_rx_multiple_seq extends md_rx_base_seq;

    `uvm_object_utils(md_rx_multiple_seq)

    int unsigned num_transfers = 8; //cuantas transferencias se envian en total

    //pesos del size (1, 2, 3, 4 bytes)
    int unsigned w_size1   = 34;
    int unsigned w_size2   = 33;
    int unsigned w_size3   = 0;
    int unsigned w_size4   = 33;

    //pesos del offset (byte 0 a 3)
    int unsigned w_off0    = 25;
    int unsigned w_off1    = 25;
    int unsigned w_off2    = 25;
    int unsigned w_off3    = 25;

    int unsigned w_illegal = 0; //peso de transferencias ilegales

    function new(string name = "md_rx_multiple_seq");
        super.new(name);
    endfunction

    virtual task body();
        md_seq_item item;

        //se imprime la config con la que arranca la secuencia (solo en modo debug,
        //porque el test ya imprime la configuracion completa una sola vez al inicio;
        //con N_RECONFIG alto este banner se repetiria una vez por bloque)
        `uvm_info(get_type_name(),
            $sformatf({"Iniciando secuencia: %0d transferencias\n",
                       "  size  : w1=%0d  w2=%0d  w3=%0d  w4=%0d\n",
                       "  offset: w0=%0d  w1=%0d  w2=%0d  w3=%0d\n",
                       "  ilegal: w=%0d"},
                num_transfers,
                w_size1, w_size2, w_size3, w_size4,
                w_off0, w_off1, w_off2, w_off3,
                w_illegal),
            UVM_HIGH)

        for (int i = 0; i < num_transfers; i++) begin
            item = md_seq_item::type_id::create($sformatf("item_%0d", i)); //se crea un item nuevo

            //se le pasan los pesos al item para que sus constraints dist los usen
            item.w_size1   = w_size1;
            item.w_size2   = w_size2;
            item.w_size3   = w_size3;
            item.w_size4   = w_size4;
            item.w_off0    = w_off0;
            item.w_off1    = w_off1;
            item.w_off2    = w_off2;
            item.w_off3    = w_off3;
            item.w_illegal = w_illegal;

            send_item(item); //se randomiza y se entrega al driver
        end

        `uvm_info(get_type_name(), "Secuencia completada", UVM_HIGH)
    endtask

endclass
