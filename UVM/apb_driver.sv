class apb_driver extends uvm_driver #(apb_seq_item);

`uvm_component_utils(apb_driver); // se registra el driver en la fabrica 
virtual apb_if vif; // handle de la interfaz virtual para comunicarse en el dut

//constructor del driver
function new(string name, uvm_component parent);
    super.new(name, parent); //llama al constructor de la clase base uvm_driver
endfunction

function void build_phase(uvm_phase phase); //fase de construcción del driver
    super.build_phase(phase); //llama a la fase de construcción de la clase base uvm_driver
    if(!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) begin //se obtiene el handle de la interfaz virtual desde la configuración de UVM
        `uvm_fatal("APB_DRIVER", "No se pudo obtener el handle de la interfaz virtual") //si no se pudo obtener el handle, se reporta un error fatal
    end
endfunction

        task drive_idle();
            vif.master_cb.PSEL <= 0; //desactiva la señal de selección para finalizar la transacción
            vif.master_cb.PWRITE <= 0; //restablece el bus de control a un estado inactivo
            vif.master_cb.PWDATA <= 0; //restablece el bus de datos a un estado inactivo
            vif.master_cb.PENABLE <= 0; //restablece la señal de enable a un estado inactivo
            vif.master_cb.PADDR <= 0; //restablece la señal de dirección a un estado inactivo
            @(vif.master_cb); //se esperar para sincronizar con el reloj antes de continuar
        endtask

        task drive_transfer(apb_seq_item req);
            // fase de setup: se asignan las señales de dirección, control y datos para iniciar la transacción
            // truncate address/data to interface widths (APB_ADDR_WIDTH=16, APB_DATA_WIDTH=32)
            vif.master_cb.PADDR <= req.addr[15:0]; //asigna la dirección de la transacción al bus de direcciones (16 bits)
            vif.master_cb.PWRITE <= req.write; //asigna el  tipo de operación (lectura o escritura) al bus de control
            vif.master_cb.PWDATA <= req.data[31:0]; //asigna los datos de la transacción al bus de datos (32 bits)
            vif.master_cb.PSEL <= 1; //activa la señal de selección para iniciar la transacción
            vif.master_cb.PENABLE <= 0; //asegura que la señal de enable esté desactivada durante la fase de setup
            @(vif.master_cb); //espera un ciclo de reloj para iniciar la fase access
            // fase de access 
            vif.master_cb.PENABLE <= 1; //activa la señal de enable para que la transacción se ejecute
            // wait until PREADY is exactly 1 (avoid exiting early if PREADY is X)
            do @(vif.master_cb); while(vif.master_cb.PREADY !== 1);
            `uvm_info(get_type_name(), $sformatf("DRIVER AFTER PREADY: PRDATA=0x%0h PREADY=%0b", vif.master_cb.PRDATA, vif.master_cb.PREADY), UVM_LOW);

            if(!req.write) req.rdata = vif.master_cb.PRDATA[31:0]; //en lectura, captura PRDATA (32 bits)
            req.slverr = vif.master_cb.PSLVERR; //lee el estado de error de la transacción y lo asigna a la variable slverr de la transacción
            vif.master_cb.PSEL <= 0; //desactiva la señal de selección para finalizar la transacción
            vif.master_cb.PENABLE <= 0; //desactiva la señal de enable para finalizar la transacción
        endtask

virtual task run_phase (uvm_phase phase); //fase de ejecucion del driver
    apb_seq_item req; //declara una variable
    forever begin
        drive_idle(); //pone el driver en estado inactivo
        seq_item_port.get_next_item(req); //espera a que se le asigne una transacción desde la secuencia
        `uvm_info(get_type_name(), $sformatf("DRIVER GOT REQ: %s", req.convert2string()), UVM_LOW)
        drive_transfer(req); //realiza la transacción en la interfaz APB
        `uvm_info(get_type_name(), $sformatf("DRIVER DONE REQ: addr=0x%0h write=%0b rdata=0x%0h slverr=%0b", req.addr, req.write, req.rdata, req.slverr), UVM_LOW)
        seq_item_port.item_done(); //indica que la transacción ha sido completada
    end
endtask


endclass