class apb_test extends uvm_test;

  `uvm_component_utils(apb_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  apb_env env; // Entorno de verificación

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = apb_env::type_id::create("env", this); // Crear el entorno
  endfunction

  task run_phase(uvm_phase phase);
    apb_sequence seq; // Declarar una variable para la secuencia
    super.run_phase(phase);
    // Aquí se pueden agregar secuencias o estímulos específicos para la prueba
    phase.raise_objection(this);
    seq = apb_sequence::type_id::create("seq"); // Crear una secuencia
    seq.start(env.agent.sequencer);
    phase.drop_objection(this);
    endtask

endclass