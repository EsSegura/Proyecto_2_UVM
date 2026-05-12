`include "uvm_macros.svh"
import uvm_pkg::*;

class scoreboard extends uvm_component;
    `uvm_component_utils(scoreboard);

    uvm_analysis_imp #(m_seq_item, scoreboard) analysis_port;

    function new(string name = "scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction
	
	virtual function void build_phase (uvm_phase phase);
		super.build_phase(phase);
		m_seq_item	=	new("m_seq_item", this);
	endfunction
	
	//ffuncion write cada vez que el monitor reporta algo, aunque hay que editarlo mas, esta muy pero muy simple
	virtual function void write (m_seq_item m_seq_item);
		`uvm_info ("SCOREBOARD", $sformatf("El paquete se ha recibido. Dato .......", m_seq_item.m_seq_item), UVM_MEDIUM)
	endfunction
	
	 virtual function void check_phase (uvm_phase phase); 
		super.check_phase(phase);    
    // Aquí podemos revisar si quedaron paquetes huérfanos o transacciones incompletas
		`uvm_info ("SCOREBOARD", "Revisión final de la simulación completada.", UVM_LOW)  
	endfunction

endclass