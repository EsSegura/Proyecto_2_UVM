`include "uvm_macros.svh"
import uvm_pkg::*;

class environment extends uvm_component;

    `uvm_component_utils(environment)

    //agentes
    agent_tx ag_tx;
    agent_rx ag_rx;

    //scoreboard y coverge

    function new(string name = "environment", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        ag_tx = agent_tx::type_id::create("ag_tx", this);
        ag_rx = agent_rx::type_id::create("ag_rx", this);


    endfunction

    virtual function void connect_phase(uvm_phase phase);

    endfunction


endclass 