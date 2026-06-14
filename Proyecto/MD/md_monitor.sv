class md_monitor extends uvm_monitor;

    `uvm_component_utils(md_monitor)

    virtual md_if vif; // Handle a la interfaz virtual MD

    // Puertos de análisis
    uvm_analysis_port #(md_seq_item) ap_rx;
    uvm_analysis_port #(md_seq_item) ap_tx;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_rx = new("ap_rx", this);
        ap_tx = new("ap_tx", this);
        if (!uvm_config_db #(virtual md_if)::get(this, "", "md_vif", vif))
            `uvm_fatal("MD_MON", "No se pudo obtener la interfaz virtual md_if")
    endfunction

    //  tarea del run_phase con dos threads paralelos, uno por canal
    task run_phase(uvm_phase phase);
        fork
            monitor_rx();
            monitor_tx();
        join
    endtask


    // thread RX para la captura transferencias en el canal de entrada al DUT
    task monitor_rx();
        md_seq_item trans;
        forever begin
            // Esperar el flanco de reloj
            @(vif.monitor_cb);

            // Detectar handshake completo cuando valid=1 y ready=1 al mismo tiempo
            if (vif.monitor_cb.md_rx_valid === 1'b1 &&
                vif.monitor_cb.md_rx_ready === 1'b1) begin

                trans           = md_seq_item::type_id::create("rx_trans");
                trans.is_rx     = 1'b1;
                trans.rx_data   = vif.monitor_cb.md_rx_data;
                trans.rx_offset = vif.monitor_cb.md_rx_offset;
                trans.rx_size   = vif.monitor_cb.md_rx_size;
                trans.rx_err    = vif.monitor_cb.md_rx_err;

                `uvm_info(get_type_name(),
                    $sformatf("MON RX: data=0x%08h off=%0d sz=%0d err=%0b",
                        trans.rx_data, trans.rx_offset, trans.rx_size, trans.rx_err),
                    UVM_MEDIUM)

                ap_rx.write(trans);
            end
        end
    endtask

    // thread TX para la captura transferencias en el canal de salida del DUT
    task monitor_tx();
        md_seq_item trans;
        forever begin
            @(vif.monitor_cb);

            if (vif.monitor_cb.md_tx_valid === 1'b1 &&
                vif.monitor_cb.md_tx_ready === 1'b1) begin

                trans           = md_seq_item::type_id::create("tx_trans");
                trans.is_rx     = 1'b0;
                trans.tx_data   = vif.monitor_cb.md_tx_data;
                trans.tx_offset = vif.monitor_cb.md_tx_offset;
                trans.tx_size   = vif.monitor_cb.md_tx_size;
                trans.tx_err    = vif.monitor_cb.md_tx_err;

                `uvm_info(get_type_name(),
                    $sformatf("MON TX: data=0x%08h off=%0d sz=%0d err=%0b",
                        trans.tx_data, trans.tx_offset, trans.tx_size, trans.tx_err),
                    UVM_MEDIUM)

                ap_tx.write(trans);
            end
        end
    endtask

endclass 
