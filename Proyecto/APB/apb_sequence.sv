`include "uvm_macros.svh"
import uvm_pkg::*;

// esta es la secuencia de APB, hace una sola operacion por vez
// la operacion se indica con el campo op antes de llamar a start()
// los valores concretos (size, offset, irqen, etc) los decide el solver del
// seq_item usando los pesos que se le copian

// despues de start() se puede mirar last_item para ver que valores salieron realmente

// las direcciones de los registros del DUT son:
//   CTRL   0x0000   SIZE en bits[2:0], OFFSET en bits[9:8]
//   STATUS 0x000C
//   IRQEN  0x00F0   bits[4:0]
//   IRQ    0x00F4   bits[4:0]  (se limpia escribiendo 1, W1C)
class apb_sequence extends uvm_sequence #(apb_seq_item);

    `uvm_object_utils(apb_sequence) // registra la secuencia en la fabrica

    apb_seq_item::apb_op_e op; // la operacion que se va a hacer, la fija el test

    // pesos del SIZE de CTRL (se usan cuando op es config de CTRL)
    int unsigned w_ctrl_size1 = 34;
    int unsigned w_ctrl_size2 = 33;
    int unsigned w_ctrl_size4 = 33;

    // pesos del OFFSET de CTRL
    int unsigned w_ctrl_off0 = 25;
    int unsigned w_ctrl_off1 = 25;
    int unsigned w_ctrl_off2 = 25;
    int unsigned w_ctrl_off3 = 25;

    // pesos de cada bit del IRQEN
    int unsigned w_irqen_rx_empty = 0;
    int unsigned w_irqen_rx_full  = 0;
    int unsigned w_irqen_tx_empty = 0;
    int unsigned w_irqen_tx_full  = 0;
    int unsigned w_irqen_max_drop = 0;

    // peso para limpiar el IRQ despues de leerlo
    int unsigned w_irq_clr = 0;

    // aqui se guarda el ultimo item enviado, asi el test puede leer
    // los valores que salieron (el size real, el rdata, etc) despues del start()
    apb_seq_item last_item;

    // direcciones de los registros del DUT
    localparam logic [31:0] ADDR_CTRL   = 32'h0000;
    localparam logic [31:0] ADDR_STATUS = 32'h000C;
    localparam logic [31:0] ADDR_IRQEN  = 32'h00F0;
    localparam logic [31:0] ADDR_IRQ    = 32'h00F4;

    function new(string name = "apb_sequence");
        super.new(name); // llama al constructor de la clase base uvm_sequence
        op = apb_seq_item::OP_CTRL_CFG; // por defecto configura CTRL
    endfunction

    // el body crea un item, le copia los pesos, lo randomiza y segun la
    // operacion arma la direccion, el dato y el write para mandarlo al driver
    virtual task body();
        apb_seq_item item;
        item = apb_seq_item::type_id::create($sformatf("apb_%s", op.name())); // se crea el item

        // se le pasan todos los pesos al item para que sus constraints los usen
        item.w_ctrl_size1     = w_ctrl_size1;
        item.w_ctrl_size2     = w_ctrl_size2;
        item.w_ctrl_size4     = w_ctrl_size4;
        item.w_ctrl_off0      = w_ctrl_off0;
        item.w_ctrl_off1      = w_ctrl_off1;
        item.w_ctrl_off2      = w_ctrl_off2;
        item.w_ctrl_off3      = w_ctrl_off3;
        item.w_irqen_rx_empty = w_irqen_rx_empty;
        item.w_irqen_rx_full  = w_irqen_rx_full;
        item.w_irqen_tx_empty = w_irqen_tx_empty;
        item.w_irqen_tx_full  = w_irqen_tx_full;
        item.w_irqen_max_drop = w_irqen_max_drop;
        item.w_irq_clr        = w_irq_clr;
        item.op_type          = op;

        start_item(item); // pide permiso al sequencer
        if (!item.randomize()) // randomiza respetando los constraints del item
            `uvm_fatal("APB_SEQ", $sformatf("randomize() falló [op=%s]", op.name()))

        // segun la operacion se arman los campos de bajo nivel que entiende el driver
        case (op)
            apb_seq_item::OP_CTRL_CFG,
            apb_seq_item::OP_CTRL_RECONFIG: begin
                // en CTRL se pone el SIZE en bits[2:0] y el OFFSET en bits[9:8]
                item.addr  = ADDR_CTRL;
                item.data  = (32'(item.ctrl_offset) << 8) | 32'(item.ctrl_size);
                item.write = 1'b1;
            end

            apb_seq_item::OP_IRQEN_CFG: begin
                item.addr  = ADDR_IRQEN;
                item.data  = 32'(item.irqen_bits);
                item.write = 1'b1;
            end

            apb_seq_item::OP_STATUS_READ: begin
                item.addr  = ADDR_STATUS;
                item.data  = 32'h0;
                item.write = 1'b0; // es lectura
            end

            apb_seq_item::OP_IRQ_READ: begin
                item.addr  = ADDR_IRQ;
                item.data  = 32'h0;
                item.write = 1'b0; // es lectura
            end

            default:
                `uvm_fatal("APB_SEQ",
                    $sformatf("op_type no soportado en esta secuencia: %s", op.name()))
        endcase

        finish_item(item); // se manda el item, el driver lo ejecuta y rellena rdata/slverr

        `uvm_info(get_type_name(),
            $sformatf("[%s] addr=0x%0h data=0x%0h wr=%0b | ctrl_sz=%0d ctrl_off=%0d irqen=0x%0h w1c=%0b rdata=0x%0h slverr=%0b",
                op.name(), item.addr, item.data, item.write,
                item.ctrl_size, item.ctrl_offset, item.irqen_bits,
                item.do_irq_clr, item.rdata, item.slverr),
            UVM_LOW)

        last_item = item; // se guarda el item para que el test lo pueda revisar

        // si se leyo el IRQ y el solver decidio limpiar (do_irq_clr=1) y hay bits
        // prendidos, se manda una segunda transaccion para limpiarlo
        if (op == apb_seq_item::OP_IRQ_READ &&
            item.do_irq_clr                 &&
            item.rdata[4:0] != 5'h0)
            send_w1c(item.rdata[4:0]);
    endtask

    // manda un write al IRQ con 1s en los bits que se quieren limpiar (W1C)
    // lo llama el body solo cuando toca limpiar
    protected task send_w1c(logic [4:0] clr_bits);
        apb_seq_item clr_item;
        clr_item = apb_seq_item::type_id::create("apb_irq_clr");
        clr_item.op_type = apb_seq_item::OP_IRQ_CLR;
        clr_item.addr    = ADDR_IRQ;
        clr_item.data    = 32'(clr_bits);
        clr_item.write   = 1'b1;
        start_item(clr_item);
        void'(clr_item.randomize()); // randomiza lo que no se fijo a mano
        finish_item(clr_item);
        `uvm_info(get_type_name(),
            $sformatf("[IRQ_CLR W1C] addr=0x%0h data=0x%0h wr=1",
                clr_item.addr, clr_item.data), UVM_LOW)
    endtask

endclass
