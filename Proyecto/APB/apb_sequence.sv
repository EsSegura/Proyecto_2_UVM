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

    // como modificacion se instancia del modelo de registros necesaria para usar RAL
    aligner_apb_registerfile_model::aligner reg_model;

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
    //  Se omitieron los localparam (ADDR_CTRL, etc.) ya que RAL internamente conoce el mapa de memoria.

    function new(string name = "apb_sequence");
        super.new(name); // llama al constructor de la clase base uvm_sequence
        op = apb_seq_item::OP_CTRL_CFG; // por defecto configura CTRL
    endfunction

    // el body crea un item, le copia los pesos, lo randomiza y segun la
    // operacion arma la direccion, el dato y el write para mandarlo al driver
    virtual task body();
        apb_seq_item item;
        // Variables para almacenar el estado y el dato devuelto por RAL
        uvm_status_e status;
        uvm_reg_data_t rdata;

        //  se obtiene reg_model del config_db antes de usarlo.
        // El scope es "" para que coincida con el set(this, "*", ...) que hace el env.
        // Sin este get, reg_model queda null y provoca el error NOA en tiempo de simulacion.
        if (!uvm_config_db #(aligner_apb_registerfile_model::aligner)::get(
                null, "", "reg_model", reg_model))
            `uvm_fatal("APB_SEQ", "No se pudo obtener reg_model del config_db")

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

        //  Se quita el start_item(item); // pide permiso al sequencer (RAL gestiona esto internamente)

        if (!item.randomize()) // randomiza respetando los constraints del item
            `uvm_fatal("APB_SEQ", $sformatf("randomize() falló [op=%s]", op.name()))

        // segun la operacion se arman los campos de bajo nivel que entiende el driver
        case (op)
            apb_seq_item::OP_CTRL_CFG,
            apb_seq_item::OP_CTRL_RECONFIG: begin
                // en CTRL se pone el SIZE en bits[2:0] y el OFFSET en bits[9:8]
                //  Se usa RAL en lugar de corrimientos manuales, respetando la randomización del item
                reg_model.CTRL.SIZE.set(item.ctrl_size);
                reg_model.CTRL.OFFSET.set(item.ctrl_offset);
                reg_model.CTRL.update(status);
                item.write = 1'b1; 
            end

            apb_seq_item::OP_IRQEN_CFG: begin
                // MODIFICACIÓN: Escritura mediante RAL
                reg_model.IRQEN.write(status, item.irqen_bits);
                item.write = 1'b1;
            end

            apb_seq_item::OP_STATUS_READ: begin
                // modificacion: Lectura mediante RAL y se almacena en la variable del item para que last_item sirva
                reg_model.STATUS.read(status, rdata);
                item.rdata = rdata; 
                item.write = 1'b0; // es lectura
            end

            apb_seq_item::OP_IRQ_READ: begin
                // MODIFICACIÓN: Lectura mediante RAL
                reg_model.IRQ.read(status, rdata);
                item.rdata = rdata; 
                item.write = 1'b0; // es lectura
            end

            default:
                `uvm_fatal("APB_SEQ",
                    $sformatf("op_type no soportado en esta secuencia: %s", op.name()))
        endcase

        // modificacion: Se quita el finish_item(item); // se manda el item, el driver lo ejecuta y rellena rdata/slverr

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
        // modificacion: Se eliminan las creaciones y envío de transacciones (clr_item) y se resuelve en una sola línea de RAL
        uvm_status_e local_status;
        reg_model.IRQ.write(local_status, clr_bits);
        
        `uvm_info(get_type_name(),
            $sformatf("[IRQ_CLR W1C] data=0x%0h wr=1", clr_bits), UVM_LOW)
    endtask

endclass