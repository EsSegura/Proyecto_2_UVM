class apb_monitor extends uvm_monitor;

    `uvm_component_utils(apb_monitor); //se registra el monitor en la fabrica
    virtual apb_if vif; //declaración de una variable para almacenar el handle de la interfaz virtual

    function new(string name, uvm_component parent);
        super.new(name, parent); //llama al constructor de la clase base uvm_monitor
    endfunction

    uvm_analysis_port #(apb_seq_item) ap; //puerto de análisis para enviar las transacciones monitoreadas a otros componentes de UVM, como el scoreboard o el coverage collector


    function void build_phase(uvm_phase phase); //fase de construcción del monitor
        super.build_phase(phase); //llama a la función de construcción de la clase base uvm_monitor
        ap = new("ap", this); //crea una instancia del puerto de análisis
        if(!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif)) //se obtiene el handle de la interfaz virtual
            `uvm_fatal("APB_MON", "No se pudo obtener la interfaz virtual"); //si no se obtiene, se reporta error fatal
    endfunction


    //run_phase: observa el bus y arma una transaccion por cada acceso APB completo
task run_phase(uvm_phase phase);
    apb_seq_item trans;  //declaración del item, fuera del if para poder reusarlo
    forever begin
        @(vif.monitor_cb); //espera el flanco de reloj
            if(vif.monitor_cb.PSEL && vif.monitor_cb.PENABLE) begin //detecta la fase access de un acceso APB
            `uvm_info(get_type_name(), $sformatf("APB MON ACCESS: PSEL=%0b PEN=%0b",
                vif.monitor_cb.PSEL, vif.monitor_cb.PENABLE), UVM_LOW);

            trans = apb_seq_item::type_id::create("trans"); //crea el item para guardar lo observado
            trans.write  = vif.monitor_cb.PWRITE; //captura si es escritura o lectura
            trans.addr   = vif.monitor_cb.PADDR; //captura la direccion del acceso
            if (trans.write) trans.data = vif.monitor_cb.PWDATA; //en escritura captura el dato escrito

            //espera hasta que el monitor vea PREADY exactamente en alto
            do @(vif.monitor_cb); while(vif.monitor_cb.PREADY !== 1);

            `uvm_info(get_type_name(), $sformatf("APB MON AFTER READY: PRDATA=0x%0h PREADY=%0b",
                vif.monitor_cb.PRDATA, vif.monitor_cb.PREADY), UVM_LOW);

            if(!trans.write) begin //en lectura captura el dato leido
                trans.rdata = vif.monitor_cb.PRDATA[31:0];
                trans.data  = trans.rdata;
            end
            trans.slverr = vif.monitor_cb.PSLVERR; //captura el estado de error del slave

            `uvm_info(get_type_name(), $sformatf("APB MON: %s", trans.convert2string()), UVM_LOW);
            ap.write(trans); //publica la transaccion hacia el scoreboard, predictor y cobertura
        end
    end
endtask



endclass
