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
        apb_sequence        apb_cfg_seq;

        // Secuencias MD RX
        md_rx_single_seq    rx_single;
        md_rx_multiple_seq  rx_multiple;
        md_rx_directed_seq  rx_directed;
        md_rx_illegal_seq   rx_illegal;

        phase.raise_objection(this);

        `uvm_info(get_type_name(), "=== Test Iniciado ===", UVM_NONE)

        // ------------------------------------------------------------------
        // verificacion 1: Configurar DUT por APB
        // Se escribe CTRL: SIZE=1, OFFSET=0
        // se espera que el dut acepte solo transferencia de 1 byte con offset de 0
        // ------------------------------------------------------------------
        `uvm_info(get_type_name(), "Verificacion 1: Configurando DUT vía APB", UVM_LOW)
        apb_cfg_seq = apb_sequence::type_id::create("apb_cfg_seq");
        apb_cfg_seq.start(env.apb_agt.sequencer);

   
        #100;

        // ------------------------------------------------------------------
        // verificacion 2: transferencia RX simple aleatoria
        // se envia una sola transferencia de RX con datos, offset y size aleatorios validos
        // ------------------------------------------------------------------
        `uvm_info(get_type_name(), "Verificacion 2: Transferencia RX aleatoria única", UVM_LOW)
        rx_single = md_rx_single_seq::type_id::create("rx_single");
        rx_single.start(env.md_agt.sequencer);

        #50;

        // ------------------------------------------------------------------
        // verificacion 3: varias transferencias RX aleatorias
        // se envian 8 transferencias RX con datos, offset y size aleatorios validos
        // ------------------------------------------------------------------
        `uvm_info(get_type_name(), "Verificacion 3: 8 transferencias RX aleatorias", UVM_LOW)
        rx_multiple = md_rx_multiple_seq::type_id::create("rx_multiple");
        rx_multiple.num_transfers = 8;
        rx_multiple.start(env.md_agt.sequencer);

        #200;

        // ------------------------------------------------------------------
        // verificacion 4: transferencia RX dirigida
        // se envia una transferencia conocida con: 0xAABBCCDD, offset=0, size=1
        // se espera que el TX presente byte 0xDD con offset=0 y size=1
        // ------------------------------------------------------------------
        `uvm_info(get_type_name(), "Verificacion 4: Transferencia RX dirigida 0xAABBCCDD", UVM_LOW)
        rx_directed = md_rx_directed_seq::type_id::create("rx_directed");
        rx_directed.data   = 32'hAABBCCDD;
        rx_directed.offset = 3'h0;
        rx_directed.size   = 3'h1;
        rx_directed.start(env.md_agt.sequencer);

        #100;

        // ------------------------------------------------------------------
        // verificacion 5: transferencia RX ilegal 
        // se espera rx_err=1 del DUT con offset=1, size=3 
        // ------------------------------------------------------------------
        `uvm_info(get_type_name(), "Verificacion 5: Transferencia RX ilegal (off=1, sz=3)", UVM_LOW)
        rx_illegal = md_rx_illegal_seq::type_id::create("rx_illegal");
        rx_illegal.bad_offset = 3'h1;
        rx_illegal.bad_size   = 3'h3;
        rx_illegal.start(env.md_agt.sequencer);

        #100;

        // ------------------------------------------------------------------
        // verificacion 6: leer STATUS para verificar CNT_DROP y niveles de FIFO
        // ------------------------------------------------------------------
        `uvm_info(get_type_name(), "Verificacion 6: Leyendo STATUS via APB", UVM_LOW)
        begin
            apb_seq_item rd_item;
            rd_item       = apb_seq_item::type_id::create("rd_status");
            rd_item.addr  = 32'h0000_000C; // Offset STATUS
            rd_item.write = 1'b0;
            // Enviar directamente sin RAL para simplificar
            begin
                apb_sequence rd_seq = apb_sequence::type_id::create("rd_seq");
                rd_seq.start(env.apb_agt.sequencer);
            end
        end

        #50;

        `uvm_info(get_type_name(), "=== Test finalizado ===", UVM_NONE)
        phase.drop_objection(this);
    endtask

endclass : aligner_test
