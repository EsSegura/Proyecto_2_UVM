class md_seq_item extends uvm_sequence_item;

    `uvm_object_utils_begin(md_seq_item) // registra el item en la fabrica con sus campos
        `uvm_field_int(rx_data,    UVM_ALL_ON)
        `uvm_field_int(rx_offset,  UVM_ALL_ON)
        `uvm_field_int(rx_size,    UVM_ALL_ON)
        `uvm_field_int(rx_err,     UVM_ALL_ON)
        `uvm_field_int(is_illegal, UVM_ALL_ON)
        `uvm_field_int(tx_data,    UVM_ALL_ON)
        `uvm_field_int(tx_offset,  UVM_ALL_ON)
        `uvm_field_int(tx_size,    UVM_ALL_ON)
        `uvm_field_int(tx_err,     UVM_ALL_ON)
        `uvm_field_int(is_rx,      UVM_ALL_ON)
    `uvm_object_utils_end

    // estos pesos controlan que tan probable es cada tamano de transferencia
    // el test los cambia con plusargs antes de randomizar, asi no hardcodeo nada
    // ejemplo: si pongo w_size4=100 y los otros en 0, siempre saldra size 4
    int unsigned w_size1 = 34;  // peso para size de 1 byte
    int unsigned w_size2 = 33;  // peso para size de 2 bytes
    int unsigned w_size4 = 33;  // peso para size de 4 bytes

    // pesos para el offset (de 0 a 3), funcionan igual que los de arriba
    int unsigned w_off0 = 25;
    int unsigned w_off1 = 25;
    int unsigned w_off2 = 25;
    int unsigned w_off3 = 25;

    // peso para forzar transferencias ilegales, va de 0 (nunca) a 100 (siempre)
    // cuando sale ilegal el solver elige un size raro para que el DUT marque error
    int unsigned w_illegal = 0;

    rand logic [31:0] rx_data;    // dato que mando por el canal RX
    rand logic [1:0]  rx_offset;  // desde que byte empieza el dato
    rand logic [2:0]  rx_size;    // cuantos bytes mando
    rand bit          is_illegal; // 1 si quiero que esta transferencia sea ilegal

    logic rx_err; // variable para ver si el DUT respondio con error en el RX

    //se leen en el monitor cuando observa el TX
    logic [31:0] tx_data;
    logic [1:0]  tx_offset;
    logic [2:0]  tx_size;
    logic        tx_err;

    logic is_rx; // 1 si el item lo vi en RX, 0 si lo vi en TX

    // con este constraint se decide si la transferencia es legal o ilegal segun el peso
    constraint c_illegal_weight {
        is_illegal dist { 1'b0 := (100 - w_illegal),
                          1'b1 :=         w_illegal  };
    }


    // si es legal uso la distribucion ponderada entre 1, 2 y 4
    // si es ilegal se saca de un pool de valores que rompen las reglas (0, 2, 3, 4)
    // ojo: el size 1 no entra al pool ilegal porque siempre es legal con cualquier offset
    // tampoco se deja pasar mas de 4 porque el bus es de 32 bits (4 bytes maximo)
    constraint c_size_dist {
        rx_size <= 4;
        if (!is_illegal)
            rx_size dist { 3'h1 := w_size1,
                           3'h2 := w_size2,
                           3'h4 := w_size4 };
        else
            rx_size inside {3'h0, 3'h2, 3'h3, 3'h4};
    }

    // el offset solo se reparte por pesos cuando la transferencia es legal
    // si es ilegal el offset lo fija el constraint de abajo para asegurar el error
    constraint c_offset_dist {
        if (!is_illegal)
            rx_offset dist { 2'h0 := w_off0,
                             2'h1 := w_off1,
                             2'h2 := w_off2,
                             2'h3 := w_off3 };
    }

    // esta es la regla del datasheet: (4 + offset) % size tiene que dar 0 para ser legal
    // cuando se quiere que sea ilegal, se fuerza el offset a un valor que rompa esa cuenta:
    //   con size=3 se evita offset 2 porque (4+2)%3 da 0 y se me colaria como legal
    //   con size=2 los validos son 0 y 2, asi que fuerzo 1 o 3
    //   con size=4 el unico valido es 0, asi que fuerzo cualquier otro
    //   con size=0 no se toca el offset, igual da error (division por cero)
    constraint c_legal_combo {
        if (!is_illegal)
            ((4 + rx_offset) % rx_size) == 0;
        else if (rx_size == 3'h3)
            rx_offset != 2'h2;
        else if (rx_size == 3'h2)
            !(rx_offset inside {2'h0, 2'h2});
        else if (rx_size == 3'h4)
            rx_offset != 2'h0;
    }

    function new(string name = "md_seq_item");
        super.new(name); // llama al constructor de la clase base uvm_sequence_item
        rx_data    = '0;
        rx_offset  = '0;
        rx_size    = 3'h1;
        rx_err     = 1'b0;
        is_illegal = 1'b0;
        tx_data    = '0;
        tx_offset  = '0;
        tx_size    = '0;
        tx_err     = 1'b0;
        is_rx      = 1'b1;
    endfunction

    // funcion para imprimir el item de forma legible en los logs
    virtual function string convert2string();
        return $sformatf(
            "MD[%s] rx_data=0x%08h rx_off=%0d rx_sz=%0d rx_err=%0b illegal=%0b | tx_data=0x%08h tx_off=%0d tx_sz=%0d tx_err=%0b",
            is_rx ? "RX" : "TX",
            rx_data, rx_offset, rx_size, rx_err, is_illegal,
            tx_data, tx_offset, tx_size, tx_err);
    endfunction

endclass
