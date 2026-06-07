`include "uvm_macros.svh"
import uvm_pkg::*;
class apb_seq_item extends uvm_sequence_item;
        `uvm_object_utils(apb_seq_item) //macro para registrar la clase en el factory de UVM
    rand logic [31:0] addr; //dirección de la transacción
    rand logic [31:0] data; //datos de la transacción
    rand logic write; //indica si es una operación de escritura o lectura
    logic [31:0] rdata; //datos leídos en una operación de lectura
    logic slverr; //indica si hubo un error en la transacción

    function new(string name = "apb_seq_item"); //constructor de la clase
        super.new(name); //llama al constructor de la clase base uvm_sequence_item
    endfunction

    //función para convertir el objeto a una cadena de texto para facilitar la depuración
    virtual function string convert2string(); //función para convertir el objeto a una cadena de texto para facilitar la depuración
        return $sformatf("APB Transaction: addr=0x%0h, data=0x%0h, write=%0b, rdata=0x%0h, slverr=%0b", addr, data, write, rdata, slverr);
    endfunction


    endclass