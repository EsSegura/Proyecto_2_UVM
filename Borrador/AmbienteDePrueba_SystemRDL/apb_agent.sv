class apb_agent extends uvm_agent; //declara la clase apb_agent que extiende de uvm_agent, lo que significa que es un agente de verificación en UVM

`uvm_component_utils(apb_agent); //registra la clase apb_agent en la fábrica de UVM para que pueda ser instanciada dinámicamente
uvm_active_passive_enum is_active=UVM_ACTIVE; //declara una variable para indicar si el agente es activo o pasivo, en este caso se establece como activo

virtual apb_if vif; //declaración de una variable para almacenar el handle de la interfaz virtual
apb_driver driver; //declaración de una variable para el driver del agente
apb_monitor monitor; //declaración de una variable para el monitor del agente
uvm_sequencer#(apb_seq_item) sequencer; //declaración de una variable para el secuenciador del agente, que se encargará de generar las transacciones para el driver

function new(string name, uvm_component parent);
    super.new(name, parent); //llama al constructor de la clase base uvm_agent
endfunction

virtual function void build_phase(uvm_phase phase); //fase de construcción del agente
    super.build_phase(phase); //llama a la función de construcción de la clase base uvm_agent
    monitor = apb_monitor::type_id::create("monitor", this); //crea una instancia del monitor y la asigna a la variable monitor
    if(is_active == UVM_ACTIVE) begin //si el agente es activo, se crean las instancias del driver y el secuenciador
    driver = apb_driver::type_id::create("driver", this); //crea una instancia del driver y la asigna a la variable driver
    sequencer = uvm_sequencer#(apb_seq_item)::type_id::create("sequencer", this); //crea una instancia del secuenciador y la asigna a la variable sequencer
    end
endfunction

virtual function void  connect_phase(uvm_phase phase); //fase de conexión del agente
    super.connect_phase(phase); //llama a la función de conexión de la clase base uvm_agent
    if(is_active == UVM_ACTIVE) begin //si el agente es activo, se conectan el secuenciador con el driver
    driver.seq_item_port.connect(sequencer.seq_item_export); //conecta el puerto de transacciones del driver con el puerto de exportación del secuenciador para que las transacciones generadas por el secuenciador puedan ser enviadas al driver
    end
endfunction


endclass


