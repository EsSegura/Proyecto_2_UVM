class md_rx_driver extends uvm_driver #(md_seq_item);

    `uvm_component_utils(md_rx_driver)

    virtual md_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual md_if)::get(this, "", "md_vif", vif))
            `uvm_fatal("MD_RX_DRV", "No se pudo obtener la interfaz virtual md_if")
    endfunction

    task run_phase(uvm_phase phase);
        md_seq_item req;
        drive_idle();
        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info(get_type_name(),
                $sformatf("RX DRV GOT: data=0x%08h offset=%0d size=%0d",
                    req.rx_data, req.rx_offset, req.rx_size), UVM_MEDIUM)
            drive_transfer(req);
            `uvm_info(get_type_name(),
                $sformatf("RX DRV DONE: rx_err=%0b", req.rx_err), UVM_MEDIUM)
            seq_item_port.item_done();
        end
    endtask

    //valid = 0, data=0, offset=0, size=0 para no enviar transferencias no deseadas al DUT durante el tiempo que el driver no tenga items para enviar
    task drive_idle();
        @(vif.rx_driver_cb);
        vif.rx_driver_cb.md_rx_valid  <= 1'b0;
        vif.rx_driver_cb.md_rx_data   <= '0;
        vif.rx_driver_cb.md_rx_offset <= '0;
        vif.rx_driver_cb.md_rx_size   <= '0;
    endtask


    task drive_transfer(md_seq_item req);
        // Presentar estimulo en el siguiente flanco de reloj
        @(vif.rx_driver_cb);
        vif.rx_driver_cb.md_rx_valid  <= 1'b1;
        vif.rx_driver_cb.md_rx_data   <= req.rx_data;
        vif.rx_driver_cb.md_rx_offset <= req.rx_offset[$bits(vif.md_rx_offset)-1:0];
        vif.rx_driver_cb.md_rx_size   <= req.rx_size  [$bits(vif.md_rx_size)  -1:0];

        // se esperar handshake, para leer md_rx_ready directo del wire
        do begin
            @(vif.rx_driver_cb);
        end while (vif.md_rx_ready !== 1'b1);

        // capturar error directamente del wire de la interfaz
        req.rx_err = vif.md_rx_err;

        // pone valid en 0
        vif.rx_driver_cb.md_rx_valid <= 1'b0;
    endtask

endclass : md_rx_driver