//monitor del bus MD observa de forma pasiva los canales RX y TX y publica lo que ve
class md_monitor extends uvm_monitor;

    `uvm_component_utils(md_monitor) //registra el monitor en la fabrica

    virtual md_if vif; //Handle a la interfaz virtual MD

    //Puertos de análisis
    uvm_analysis_port #(md_seq_item) ap_rx; //publica las transferencias vistas en RX
    uvm_analysis_port #(md_seq_item) ap_tx; //publica las transferencias vistas en TX

    function new(string name, uvm_component parent);
        super.new(name, parent); //llama al constructor de la clase base uvm_monitor
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_rx = new("ap_rx", this); //crea el puerto de analisis RX
        ap_tx = new("ap_tx", this); //crea el puerto de analisis TX
        if (!uvm_config_db #(virtual md_if)::get(this, "", "md_vif", vif)) //obtiene la interfaz virtual
            `uvm_fatal("MD_MON", "No se pudo obtener la interfaz virtual md_if")
    endfunction

    // tarea del run_phase con dos threads paralelos, uno por canal
    task run_phase(uvm_phase phase);
        fork
            monitor_rx(); //observa el canal de entrada
            monitor_tx(); //observa el canal de salida
        join
    endtask


    //thread RX para la captura transferencias en el canal de entrada al DUT
    task monitor_rx();
        md_seq_item trans;
        forever begin
            //Esperar el flanco de reloj
            @(vif.monitor_cb);

            //Detectar handshake completo cuando valid=1 y ready=1 al mismo tiempo
            if (vif.monitor_cb.md_rx_valid === 1'b1 &&
                vif.monitor_cb.md_rx_ready === 1'b1) begin

                trans           = md_seq_item::type_id::create("rx_trans"); //crea el item para guardar lo observado
                trans.is_rx     = 1'b1; //marca que es una transferencia RX
                trans.rx_data   = vif.monitor_cb.md_rx_data;   //captura el dato
                trans.rx_offset = vif.monitor_cb.md_rx_offset; //captura el offset
                trans.rx_size   = vif.monitor_cb.md_rx_size;   //captura el size
                trans.rx_err    = vif.monitor_cb.md_rx_err;    //captura si hubo error

                `uvm_info(get_type_name(),
                    $sformatf("MON RX: data=0x%08h off=%0d sz=%0d err=%0b",
                        trans.rx_data, trans.rx_offset, trans.rx_size, trans.rx_err),
                    UVM_MEDIUM)

                ap_rx.write(trans); //publica la transferencia RX
            end
        end
    endtask

    //thread TX para la captura transferencias en el canal de salida del DUT
    task monitor_tx();
        md_seq_item trans;
        forever begin
            @(vif.monitor_cb); //espera el flanco de reloj

            if (vif.monitor_cb.md_tx_valid === 1'b1 &&
                vif.monitor_cb.md_tx_ready === 1'b1) begin //handshake completo en TX

                trans           = md_seq_item::type_id::create("tx_trans"); //crea el item para guardar lo observado
                trans.is_rx     = 1'b0; //marca que es una transferencia TX
                trans.tx_data   = vif.monitor_cb.md_tx_data;   //captura el dato
                trans.tx_offset = vif.monitor_cb.md_tx_offset; //captura el offset
                trans.tx_size   = vif.monitor_cb.md_tx_size;   //captura el size
                trans.tx_err    = vif.monitor_cb.md_tx_err;    //captura si hubo error

                `uvm_info(get_type_name(),
                    $sformatf("MON TX: data=0x%08h off=%0d sz=%0d err=%0b",
                        trans.tx_data, trans.tx_offset, trans.tx_size, trans.tx_err),
                    UVM_MEDIUM)

                ap_tx.write(trans); //publica la transferencia TX
            end
        end
    endtask

endclass
