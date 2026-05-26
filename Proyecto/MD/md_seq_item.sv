class md_seq_item extends uvm_sequence_item;

    `uvm_object_utils_begin(md_seq_item)
        `uvm_field_int(rx_data,   UVM_ALL_ON)
        `uvm_field_int(rx_offset, UVM_ALL_ON)
        `uvm_field_int(rx_size,   UVM_ALL_ON)
        `uvm_field_int(rx_err,    UVM_ALL_ON)
        `uvm_field_int(tx_data,   UVM_ALL_ON)
        `uvm_field_int(tx_offset, UVM_ALL_ON)
        `uvm_field_int(tx_size,   UVM_ALL_ON)
        `uvm_field_int(tx_err,    UVM_ALL_ON)
        `uvm_field_int(is_rx,     UVM_ALL_ON)
    `uvm_object_utils_end

    //rx
    rand logic [31:0] rx_data;    // Datos sin alinear recibidos por el DUT
    rand logic [2:0]  rx_offset;  // Offset en bytes sobre md_rx_data
    rand logic [2:0]  rx_size;    // Tamaño en bytes del dato válido

    // Respuesta del DUT al  RX
    logic rx_err;

    //tx
    logic [31:0] tx_data;
    logic [2:0]  tx_offset;
    logic [2:0]  tx_size;
    logic        tx_err;

    // Flag de canal: 1 = ítem observado en RX, 0 = ítem observado en TX
    logic is_rx;


    // size entre 1 y 4 bytes
    constraint c_size_range {
        rx_size inside {3'h1, 3'h2, 3'h3, 3'h4};
    }

    // offset dentro del bus 
    constraint c_offset_range {
        rx_offset inside {[0:3]};
    }

    // Combinación legal ((4 + offset) % size) == 0
    constraint c_legal_combo {
        ((4 + rx_offset) % rx_size) == 0;
    }


    function new(string name = "md_seq_item");
        super.new(name);
        rx_data   = '0;
        rx_offset = '0;
        rx_size   = 3'h1;
        rx_err    = 1'b0;
        tx_data   = '0;
        tx_offset = '0;
        tx_size   = '0;
        tx_err    = 1'b0;
        is_rx     = 1'b1;
    endfunction

    virtual function string convert2string();
        return $sformatf("MD[%s] rx_data=0x%08h rx_off=%0d rx_sz=%0d rx_err=%0b | tx_data=0x%08h tx_off=%0d tx_sz=%0d tx_err=%0b", is_rx ? "RX" : "TX", rx_data, rx_offset, rx_size, rx_err, tx_data, tx_offset, tx_size, tx_err);
    endfunction

endclass 