class apb_env extends uvm_env;

  `uvm_component_utils(apb_env)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

    apb_scoreboard scoreboard; // Scoreboard
    apb_agent agent; // Agente
    apb_adapter adapter; // Adaptador
    uvm_reg_predictor #(apb_seq_item) predictor; // Predictor de registros
	mi_periferico_pkg::MI_PERIFERICO reg_model; // solo declaración
  
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        scoreboard = apb_scoreboard::type_id::create("scoreboard", this);
        agent = apb_agent::type_id::create("agent", this);
        adapter = apb_adapter::type_id::create("adapter", this);
        predictor = uvm_reg_predictor #(apb_seq_item)::type_id::create("predictor", this);
	reg_model = new("reg_model");

        reg_model.build();
        reg_model.lock_model();
      // se publica el modelo para que el test lo use
          uvm_config_db #(mi_periferico_pkg::MI_PERIFERICO)::set(
        this, "*", "reg_model", reg_model
    );
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // monitor → predictor y scoreboard
        agent.monitor.ap.connect(predictor.bus_in);
        agent.monitor.ap.connect(scoreboard.ap);

        // configurar predictor
        predictor.adapter = adapter;
        predictor.map = reg_model.default_map;

        // pasar reg_model al scoreboard
        scoreboard.reg_model = reg_model;
      	// conectar modelo al adaptador
         reg_model.default_map.set_sequencer(agent.sequencer, adapter);

    endfunction


endclass