//adaptador que traduce entre el modelo de registros (RAL) y las transacciones del bus APB
class apb_adapter extends uvm_reg_adapter;
`uvm_object_utils(apb_adapter) //registra el adaptador en la fabrica de UVM

function new(string name = "apb_adapter");
    super.new(name); //llama al constructor de la clase base uvm_reg_adapter
endfunction

//reg2bus: convierte una operacion del RAL en un item APB que entiende el driver
virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    apb_seq_item apb_op; //item APB que se va a armar
    apb_op = apb_seq_item::type_id::create("apb_op"); //se crea el item
    apb_op.addr = rw.addr; //se copia la direccion del acceso
    apb_op.data = rw.data; //se copia el dato a escribir
    apb_op.write=(rw.kind == UVM_WRITE); //marca si es escritura o lectura
    return apb_op; //se devuelve el item ya armado

endfunction

//bus2reg: convierte lo que se vio en el bus de vuelta a una operacion del RAL
virtual function void bus2reg(input uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    apb_seq_item apb_op; //item APB recibido desde el bus
    if(!$cast(apb_op, bus_item)) //se castea el item generico al tipo APB
        `uvm_fatal("ADAPTER", "Cast fallido") //si el cast falla se reporta error fatal
    rw.addr = apb_op.addr; //se copia la direccion observada
    rw.data = apb_op.write ? apb_op.data : apb_op.rdata; //en escritura el dato escrito, en lectura el dato leido
    rw.kind = (apb_op.write) ? UVM_WRITE : UVM_READ; //tipo de acceso segun el item
    //si el slave respondio con error (slverr), el acceso fue rechazado:
    //se marca como NOT_OK para que el predictor NO actualice el RAL con un
    //valor que el DUT no acepto (p.ej. un CTRL con combinacion ilegal)
    rw.status = apb_op.slverr ? UVM_NOT_OK : UVM_IS_OK;
endfunction



endclass
