//driver del canal TX: mantiene md_tx_ready/err para que el DUT pueda sacar datos
class md_tx_driver extends uvm_driver #(md_seq_item);

    `uvm_component_utils(md_tx_driver) //registra el driver en la fabrica

    virtual md_if vif; //Handle a la interfaz virtual MD

    //Control de backpressure en tiempo de ejecución
    local logic ready_value = 1'b1;       //valor actual de md_tx_ready
    local int unsigned ready_weight = 100; //probabilidad de aceptar (0 a 100)

    function new(string name, uvm_component parent);
        super.new(name, parent); //llama al constructor de la clase base uvm_driver
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual md_if)::get(this, "", "md_vif", vif)) //obtiene la interfaz virtual
            `uvm_fatal("MD_TX_DRV", "No se pudo obtener la interfaz virtual md_if")
    endfunction

    //run_phase, simplemente mantiene md_tx_ready y md_tx_err estables
    task run_phase(uvm_phase phase);
        //Inicializar señales
        @(vif.tx_driver_cb);
        update_ready_value();
        vif.tx_driver_cb.md_tx_ready <= ready_value;
        vif.tx_driver_cb.md_tx_err   <= 1'b0;

        forever begin
            @(vif.tx_driver_cb); //cada ciclo recalcula y aplica el ready
            update_ready_value();
            vif.tx_driver_cb.md_tx_ready <= ready_value;
            vif.tx_driver_cb.md_tx_err   <= 1'b0;
        end
    endtask

    //Cambiar el valor de ready en tiempo de simulación para inyectar backpressure desde una secuencia o el test.
    function void set_ready(logic val);
        ready_weight = val ? 100 : 0; //fija el peso al extremo segun el valor
        ready_value  = val;
    endfunction

    //ajusta el peso (probabilidad) con que el TX acepta datos, limitado a 100
    function void set_ready_weight(int unsigned weight);
        if (weight > 100)
            ready_weight = 100;
        else
            ready_weight = weight;
        update_ready_value();
    endfunction

    //recalcula md_tx_ready: 100 siempre acepta, 0 nunca, intermedio al azar segun el peso
    local function void update_ready_value();
        if (ready_weight == 100) begin
            ready_value = 1'b1;
        end else if (ready_weight == 0) begin
            ready_value = 1'b0;
        end else begin
            ready_value = ($urandom_range(0, 99) < ready_weight);
        end
    endfunction

endclass
