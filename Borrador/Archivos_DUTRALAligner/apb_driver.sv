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
            vif.master_cb.PADDR <= req.addr; //asigna la dirección de la transacción al bus de direcciones
            vif.master_cb.PWRITE <= req.write; //asigna el  tipo de operación (lectura o escritura) al bus de control
            vif.master_cb.PWDATA <= req.data; //asigna los datos de la transacción al bus de datos              
            vif.master_cb.PSEL <= 1; //activa la señal de selección para iniciar la transacción
            vif.master_cb.PENABLE <= 0; //asegura que la señal de enable esté desactivada durante la fase de setup
            @(vif.master_cb); //espera un ciclo de reloj para iniciar la fase access
            // fase de access 
            vif.master_cb.PENABLE <= 1; //activa la señal de enable para que la transacción se ejecute
            do @(vif.master_cb); while(!vif.master_cb.PREADY); //espera a que la señal de ready se active, para leer la salida del dut
            
            if(!vif.master_cb.PWRITE)req.rdata = vif.master_cb.PRDATA; //lee los datos de salida del bus de datos y los asigna a la variable rdata de la transacción
            req.slverr = vif.master_cb.PSLVERR; //lee el estado de error de la transacción y lo asigna a la variable slverr de la transacción
            vif.master_cb.PSEL <= 0; //desactiva la señal de selección para finalizar la transacción
            vif.master_cb.PENABLE <= 0; //desactiva la señal de enable para finalizar la transacción
        endtask

virtual task run_phase (uvm_phase phase); //fase de ejecucion del driver
    apb_seq_item req; //declara una variable
    forever begin
        drive_idle(); //pone el driver en estado inactivo
        seq_item_port.get_next_item(req); //espera a que se le asigne una transacción desde la secuencia
        drive_transfer(req); //espera a que se le asigne una transacción desde la secuencia y realiza la transacción en la interfaz APB
        seq_item_port.item_done(); //indica que la transacción ha sido completada
    end
endtask


endclass