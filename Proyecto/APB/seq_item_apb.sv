class apb_seq_item extends uvm_sequence_item;

    `uvm_object_utils_begin(apb_seq_item) // registra el item en la fabrica con sus campos
        `uvm_field_int(addr,       UVM_ALL_ON)
        `uvm_field_int(data,       UVM_ALL_ON)
        `uvm_field_int(write,      UVM_ALL_ON)
        `uvm_field_int(rdata,      UVM_ALL_ON)
        `uvm_field_int(slverr,     UVM_ALL_ON)
        `uvm_field_int(ctrl_size,  UVM_ALL_ON)
        `uvm_field_int(ctrl_offset,UVM_ALL_ON)
        `uvm_field_int(irqen_bits, UVM_ALL_ON)
        `uvm_field_int(do_irq_clr, UVM_ALL_ON)
    `uvm_object_utils_end

    // este enum dice que operacion APB se va a hacer
    // la secuencia lo lee para armar la direccion, el dato y el write correctos
    typedef enum bit [2:0] {
        OP_CTRL_CFG    = 3'h0,  // escribe CTRL con un SIZE y OFFSET randomizados
        OP_IRQEN_CFG   = 3'h1,  // escribe IRQEN con los bits randomizados
        OP_STATUS_READ = 3'h2,  // lee el registro STATUS
        OP_IRQ_READ    = 3'h3,  // lee el registro IRQ
        OP_IRQ_CLR     = 3'h4,  // limpia el IRQ escribiendo 1 en los bits (W1C)
        OP_CTRL_RECONFIG = 3'h5 // vuelve a randomizar y reescribir CTRL en medio del test
    } apb_op_e;

    apb_op_e op_type; // la operacion que toca, la pone la secuencia (no es rand)

    // campos de bajo nivel, son los que usa directamente el driver APB
    rand logic [31:0] addr;
    rand logic [31:0] data;
    rand logic        write;
    logic [31:0]      rdata;  // dato leido (lo rellena el driver en las lecturas)
    logic             slverr; // error del slave (lo rellena el driver)

    // pesos para el SIZE de CTRL, reparten entre 1, 2 y 4 bytes
    // notar que solo valen combos validos: (4+offset)%size == 0
    //   size=1 -> sirve cualquier offset
    //   size=2 -> offset 0 o 2
    //   size=4 -> offset 0
    int unsigned w_ctrl_size1 = 34;
    int unsigned w_ctrl_size2 = 33;
    int unsigned w_ctrl_size4 = 33;

    // pesos para el OFFSET de CTRL (0 a 3)
    int unsigned w_ctrl_off0 = 25;
    int unsigned w_ctrl_off1 = 25;
    int unsigned w_ctrl_off2 = 25;
    int unsigned w_ctrl_off3 = 25;

    rand logic [2:0] ctrl_size;   // tamano que se va a configurar en CTRL
    rand logic [1:0] ctrl_offset; // offset que se va a configurar en CTRL

    // el SIZE solo puede ser 1, 2 o 4
    constraint c_ctrl_size {
        ctrl_size dist { 3'h1 := w_ctrl_size1,
                         3'h2 := w_ctrl_size2,
                         3'h4 := w_ctrl_size4 };
    }

    // el OFFSET se reparte segun sus pesos
    constraint c_ctrl_offset {
        ctrl_offset dist { 2'h0 := w_ctrl_off0,
                           2'h1 := w_ctrl_off1,
                           2'h2 := w_ctrl_off2,
                           2'h3 := w_ctrl_off3 };
    }

    // se garantiza que el par (size, offset) siempre sea valido para el DUT
    constraint c_ctrl_valid_combo {
        ((4 + ctrl_offset) % ctrl_size) == 0;
    }

    // pesos para cada bit del IRQEN, cada uno se prende por separado
    // los bits son: 4=MAX_DROP, 3=TX_FIFO_FULL, 2=TX_FIFO_EMPTY, 1=RX_FIFO_FULL, 0=RX_FIFO_EMPTY
    // peso 0 -> el bit queda siempre en 0, peso 100 -> siempre en 1
    int unsigned w_irqen_rx_empty = 0;
    int unsigned w_irqen_rx_full  = 0;
    int unsigned w_irqen_tx_empty = 0;
    int unsigned w_irqen_tx_full  = 0;
    int unsigned w_irqen_max_drop = 0;

    rand logic [4:0] irqen_bits; // valor que se escribe en IRQEN

    // se randomiza bit por bit segun su peso
    constraint c_irqen_bits {
        irqen_bits[0] dist { 1'b0 := (100 - w_irqen_rx_empty),
                             1'b1 :=         w_irqen_rx_empty  };
        irqen_bits[1] dist { 1'b0 := (100 - w_irqen_rx_full),
                             1'b1 :=         w_irqen_rx_full   };
        irqen_bits[2] dist { 1'b0 := (100 - w_irqen_tx_empty),
                             1'b1 :=         w_irqen_tx_empty  };
        irqen_bits[3] dist { 1'b0 := (100 - w_irqen_tx_full),
                             1'b1 :=         w_irqen_tx_full   };
        irqen_bits[4] dist { 1'b0 := (100 - w_irqen_max_drop),
                             1'b1 :=         w_irqen_max_drop  };
    }

    // peso para decidir si despues de leer el IRQ se limpia o no
    // 0 -> nunca se limpia, 100 -> siempre se limpia
    int unsigned w_irq_clr = 0;

    rand bit do_irq_clr; // 1 si toca limpiar el IRQ

    constraint c_irq_clr {
        do_irq_clr dist { 1'b0 := (100 - w_irq_clr),
                          1'b1 :=         w_irq_clr  };
    }

    function new(string name = "apb_seq_item");
        super.new(name); // llama al constructor de la clase base uvm_sequence_item
        addr        = '0;
        data        = '0;
        write       = 1'b0;
        rdata       = '0;
        slverr      = 1'b0;
        op_type     = OP_CTRL_CFG;
        ctrl_size   = 3'h1;
        ctrl_offset = 2'h0;
        irqen_bits  = 5'h0;
        do_irq_clr  = 1'b0;
    endfunction

    // funcion para imprimir el item de forma legible en los logs
    virtual function string convert2string();
        return $sformatf(
            "APB[%s] addr=0x%0h data=0x%0h wr=%0b rdata=0x%0h slverr=%0b | ctrl_sz=%0d ctrl_off=%0d irqen=0x%0h w1c=%0b",
            op_type.name(), addr, data, write, rdata, slverr,
            ctrl_size, ctrl_offset, irqen_bits, do_irq_clr);
    endfunction

endclass
