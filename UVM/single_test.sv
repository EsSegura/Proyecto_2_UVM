class single_test extends uvm_test;
    `uvm_component_utils(single_test)

    environment env;

    function new(string name = "single_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = environment::type_id::create("env", this);
    endfunction

task run_phase(uvm_phase phase);
    	apb_sequence apb_seq; // Declarar una variable para la secuencia
	    md_rx_sequence    md_seq;
        md_tx_sequence tx_ready_seq;
    	super.run_phase(phase);

        phase.raise_objection(this);

        // Limita el trafico MD para evitar que el TX espere mas transferencias de las generadas.
  uvm_config_db#(int)::set(null, "*", "md_num", 1); // el 2 limita el numero de transacciones
      //uvm_config_db#(int)::set(null, "*", "md_tx_num", 2);
		apb_seq = apb_sequence::type_id::create("seq"); // Crear una secuencia
        md_seq = md_rx_sequence::type_id::create("md_seq");
        //tx_ready_seq = md_tx_sequence::type_id::create("tx_ready_seq");

        // Configura primero el DUT por APB para que el TX tenga datos.
        apb_seq.start(env.apb_ag.sequencer); // 3. Disparamos la secuencia RAL        
          	//tx_ready_seq.start(env.ag_tx.m_sequencer_tx);
         md_seq.start(env.ag_rx.m_sequencer_rx);
       

        #5000ns;
        phase.drop_objection(this);
    endtask
endclass