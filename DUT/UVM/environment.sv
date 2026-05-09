`include "uvm_macros.svh"
import uvm_pkg::*;

class environment extends uvm_component;

    `uvm_component_utils(environment)

   

    function new(string name = "environment", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
    endfunction


endclass 