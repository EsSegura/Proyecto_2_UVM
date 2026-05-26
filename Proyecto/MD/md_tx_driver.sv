class md_tx_driver extends uvm_driver #(md_seq_item);

    `uvm_component_utils(md_tx_driver)

    virtual md_if vif; // Handle a la interfaz virtual MD

    // Control de backpressure en tiempo de ejecución
    local logic ready_value = 1'b1;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual md_if)::get(this, "", "md_vif", vif))
            `uvm_fatal("MD_TX_DRV", "No se pudo obtener la interfaz virtual md_if")
    endfunction

    // run_phase, simplemente mantiene md_tx_ready y md_tx_err estables
    task run_phase(uvm_phase phase);
        // Inicializar señales
        @(vif.tx_driver_cb);
        vif.tx_driver_cb.md_tx_ready <= ready_value;
        vif.tx_driver_cb.md_tx_err   <= 1'b0;

        forever begin
            @(vif.tx_driver_cb);
            vif.tx_driver_cb.md_tx_ready <= ready_value;
            vif.tx_driver_cb.md_tx_err   <= 1'b0;
        end
    endtask

    // cambiar el valor de ready en tiempo de simulación esto para inyectar backpressure desde una secuencia o el test.
    function void set_ready(logic val);
        ready_value = val;
    endfunction

endclass
