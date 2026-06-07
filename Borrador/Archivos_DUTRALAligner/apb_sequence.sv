class apb_sequence extends uvm_sequence#(apb_seq_item);
`uvm_object_utils(apb_sequence) //macro para registrar la clase en el factory de UVM

function new(string name = "apb_sequence"); //constructor de la clase
    super.new(name); //llama al constructor de la clase base uvm_sequence
endfunction

    task body();
        req=apb_seq_item::type_id::create("req"); //crea una instancia de la clase apb_seq_item para almacenar la transacción actual
        start_item(req); //inicia la generación de una nueva transacción y asigna los valores
        req.addr=32'h0000_0004; //asigna una dirección
        req.write=0; //indica que es una operación de lectura
        finish_item(req); //finaliza la generación de la transacción y la envía al driver a través del puerto de transacciones del secuenciador

    endtask



endclass