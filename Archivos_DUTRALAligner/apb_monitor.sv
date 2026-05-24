class apb_monitor extends uvm_monitor;

    `uvm_component_utils(apb_monitor); // se registra el monitor en la fabrica
    virtual apb_if vif; //declaración de una variable para almacenar el handle de la interfaz virtual

    function new(string name, uvm_component parent);
        super.new(name, parent); //llama al constructor de la clase base uvm_monitor
    endfunction

    uvm_analysis_port #(apb_seq_item) ap; //puerto de análisis para enviar las transacciones monitoreadas a otros componentes de UVM, como el scoreboard o el coverage collector


    function void build_phase(uvm_phase phase); //fase de construcción del monitor
        super.build_phase(phase); //llama a la función de construcción de la clase base uvm_monitor
        ap = new("ap", this); //crea una instancia del puerto de análisis  
        if(!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
            `uvm_fatal("APB_MON", "No se pudo obtener la interfaz virtual")
    endfunction



task run_phase(uvm_phase phase);
    forever begin
        @(vif.monitor_cb);
        if(vif.monitor_cb.PSEL && !vif.monitor_cb.PENABLE) begin
            apb_seq_item trans;
            trans = apb_seq_item :: type_id::create("trans"); //crea una instancia de la clase apb_seq_item para almacenar
            //aca se captura la transaccion
            trans.write = vif.monitor_cb.PWRITE; //captura el tipo de operación (lectura o escritura) desde el bus de control
            trans.addr = vif.monitor_cb.PADDR; //captura la dirección de la transacción desde el bus de direcciones
            do @(vif.monitor_cb); while(!vif.monitor_cb.PREADY); //espera a que la señal de ready se active, para leer la salida del dut
            if(!trans.write) trans.rdata = vif.monitor_cb.PRDATA; //captura los datos de lectura
            trans.slverr = vif.monitor_cb.PSLVERR; 
            ap.write(trans);
        end
    end
endtask



endclass