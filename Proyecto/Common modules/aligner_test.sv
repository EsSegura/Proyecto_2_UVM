class aligner_test extends uvm_test;

    `uvm_component_utils(aligner_test)

    aligner_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction


    // build_phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = aligner_env::type_id::create("env", this);
    endfunction

    // run_phase
    task run_phase(uvm_phase phase);
        // Secuencias APB
        apb_sequence        apb_seq;
        apb_sequence        apb_read_seq;

        // Secuencias MD RX
        md_rx_multiple_seq  rx_multiple;
        md_rx_directed_seq  rx_directed;

        int unsigned ctrl_size;
        int unsigned ctrl_offset;
        int unsigned num_transfers;
        int unsigned tx_ready_weight;
        int unsigned illegal_ratio;
        int unsigned irqen_value;
        bit          irqen_present;

        ctrl_size       = 1;
        ctrl_offset     = 0;
        num_transfers   = 8;
        tx_ready_weight = 100;
        illegal_ratio   = 0;
        irqen_value     = 0;
        irqen_present   = 1'b0;

        void'($value$plusargs("SIZE=%d", ctrl_size));
        void'($value$plusargs("OFFSET=%d", ctrl_offset));
        void'($value$plusargs("NUM_TRANSFERS=%d", num_transfers));
        void'($value$plusargs("TX_READY_WEIGHT=%d", tx_ready_weight));
        void'($value$plusargs("ILLEGAL_RATIO=%d", illegal_ratio));
        irqen_present = $value$plusargs("IRQEN=%d", irqen_value);

        phase.raise_objection(this);

        `uvm_info(get_type_name(), "=== Test Iniciado ===", UVM_NONE)
        `uvm_info(get_type_name(),
            $sformatf("Plusargs: SIZE=%0d OFFSET=%0d NUM_TRANSFERS=%0d TX_READY_WEIGHT=%0d ILLEGAL_RATIO=%0d IRQEN=%s%0d",
                ctrl_size, ctrl_offset, num_transfers, tx_ready_weight, illegal_ratio,
                irqen_present ? "" : "(default)", irqen_value),
            UVM_LOW)

        if (env.md_agt.tx_driver != null)
            env.md_agt.tx_driver.set_ready_weight(tx_ready_weight);

        // ------------------------------------------------------------------
        // verificacion 1: Configurar DUT por APB
        // Se escriben CTRL.SIZE y CTRL.OFFSET con los plusargs recibidos
        // ------------------------------------------------------------------
        `uvm_info(get_type_name(), "Verificacion 1: Configurando DUT vía APB", UVM_LOW)
        apb_seq = apb_sequence::type_id::create("apb_cfg_size_seq");
        apb_seq.set_write_field(env.reg_model.CTRL, env.reg_model.CTRL.SIZE, ctrl_size);
        apb_seq.start(env.apb_agt.sequencer);

        apb_seq = apb_sequence::type_id::create("apb_cfg_offset_seq");
        apb_seq.set_write_field(env.reg_model.CTRL, env.reg_model.CTRL.OFFSET, ctrl_offset);
        apb_seq.start(env.apb_agt.sequencer);

        if (irqen_present) begin
            `uvm_info(get_type_name(),
                $sformatf("Escribiendo IRQEN=0x%0h via APB", irqen_value),
                UVM_LOW)
            apb_seq = apb_sequence::type_id::create("apb_irqen_seq");
            apb_seq.set_write_reg(env.reg_model.IRQEN, irqen_value);
            apb_seq.start(env.apb_agt.sequencer);
        end

        #100;

        // ------------------------------------------------------------------
        // verificacion 2: transferencia RX aleatoria
        // se envian NUM_TRANSFERS transferencias RX, con inyeccion opcional de ilegales
        // ------------------------------------------------------------------
        `uvm_info(get_type_name(), "Verificacion 2: Transferencias RX aleatorias", UVM_LOW)
        rx_multiple = md_rx_multiple_seq::type_id::create("rx_multiple");
        rx_multiple.num_transfers = num_transfers;
        rx_multiple.illegal_ratio = illegal_ratio;
        rx_multiple.start(env.md_agt.sequencer);

        #200;

        // ------------------------------------------------------------------
        // verificacion 3: transferencia RX dirigida
        // se envia una transferencia conocida con: 0xAABBCCDD, offset=0, size=1
        // se espera que el TX presente byte 0xDD con offset=0 y size=1
        // ------------------------------------------------------------------
        `uvm_info(get_type_name(), "Verificacion 3: Transferencia RX dirigida 0xAABBCCDD", UVM_LOW)
        rx_directed = md_rx_directed_seq::type_id::create("rx_directed");
        rx_directed.data   = 32'hAABBCCDD;
        rx_directed.offset = 3'h0;
        rx_directed.size   = 3'h1;
        rx_directed.start(env.md_agt.sequencer);

        #100;

        // ------------------------------------------------------------------
        // verificacion 4: leer STATUS por APB
        // lectura real del registro para dejar de generar codigo muerto
        // ------------------------------------------------------------------
        `uvm_info(get_type_name(), "Verificacion 4: Leyendo STATUS via APB", UVM_LOW)
        apb_read_seq = apb_sequence::type_id::create("apb_read_status_seq");
        apb_read_seq.set_read_reg(env.reg_model.STATUS);
        apb_read_seq.start(env.apb_agt.sequencer);

        #50;

        `uvm_info(get_type_name(), "=== Test finalizado ===", UVM_NONE)
        phase.drop_objection(this);
    endtask

endclass : aligner_test
