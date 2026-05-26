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
            trans = apb_seq_item::type_id::create("trans"); 
            
            // Captura de control y dirección en la fase de Setup
            trans.write = vif.monitor_cb.PWRITE; 
            trans.addr  = vif.monitor_cb.PADDR; 
            
            // Espera a que el esclavo responda (Fase de Acceso / PREADY de hardware)
            do @(vif.monitor_cb); while(!vif.monitor_cb.PREADY); 
            
            // Captura de datos dependiendo del tipo de operación
            if(trans.write) begin
                trans.data  = vif.monitor_cb.PWDATA; // <- Corregido usando tu variable 'data'
            end else begin
                trans.rdata = vif.monitor_cb.PRDATA; // <- Mapeado correctamente a 'rdata'
            end
            
            trans.slverr = vif.monitor_cb.PSLVERR; 
            ap.write(trans);
        end
    end
endtask



endclass