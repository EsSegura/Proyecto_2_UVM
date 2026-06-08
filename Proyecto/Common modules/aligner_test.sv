class aligner_test extends uvm_test;

    `uvm_component_utils(aligner_test) // registra el test en la fabrica

    aligner_env env; // el ambiente que tiene los agentes y el scoreboard


    function new(string name, uvm_component parent);
        super.new(name, parent); // llama al constructor de la clase base uvm_test
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase); // llama a la fase de construccion de la clase base
      //  Le dice a UVM que prepare las estructuras de cobertura antes de crear el modelo
        uvm_reg::include_coverage("*", UVM_CVR_ALL);
      // reemplaza el modelo de registros con el modelo de registros con cobertura
    aligner_apb_registerfile_model::aligner::type_id::set_type_override(aligner_reg_cov::get_type(), 1);
        env = aligner_env::type_id::create("env", this); // se crea el ambiente

    endfunction

    task run_phase(uvm_phase phase);
        //  se eliminan apb_seq y el tipo apb_sequence porque el test
        // ahora habla con RAL directamente a través de env.reg_model, sin necesitar
        // una secuencia intermediaria para cada operacion de registro.
        md_rx_multiple_seq rx_seq;  // secuencia que manda las transferencias RX

        // variables RAL para capturar el resultado de cada operacion
        uvm_status_e   status;
        uvm_reg_data_t rdata;

        // CORRECCIÓN: variables para guardar el SIZE y OFFSET elegidos por los pesos,
        // antes se leian de apb_seq.last_item, ahora se calculan aqui y se usan directo
        uvm_reg_data_t ctrl_size_val;
        uvm_reg_data_t ctrl_off_val;

        // pesos para el SIZE de CTRL (como se configura el alineador)
        // ejemplos:
        //   solo size 1 -> +W_CTRL_SIZE1=100 +W_CTRL_SIZE2=0 +W_CTRL_SIZE4=0
        //   solo size 4 -> +W_CTRL_SIZE4=100 +W_CTRL_SIZE1=0 +W_CTRL_SIZE2=0
        int unsigned w_ctrl_size1;
        int unsigned w_ctrl_size2;
        int unsigned w_ctrl_size4;

        // pesos para el OFFSET de CTRL (solo entran combos validos por el constraint)
        int unsigned w_ctrl_off0;
        int unsigned w_ctrl_off1;
        int unsigned w_ctrl_off2;
        int unsigned w_ctrl_off3;

        // pesos para los bits del IRQEN (0 = bit apagado, 100 = bit prendido)
        // bit 4=MAX_DROP, 3=TX_FULL, 2=TX_EMPTY, 1=RX_FULL, 0=RX_EMPTY
        int unsigned w_irqen_rx_empty;
        int unsigned w_irqen_rx_full;
        int unsigned w_irqen_tx_empty;
        int unsigned w_irqen_tx_full;
        int unsigned w_irqen_max_drop;

        // peso para limpiar el IRQ despues de leerlo (0 = nunca, 100 = siempre)
        int unsigned w_irq_clr;

        // cuantas veces se reconfigura CTRL en medio del test
        // 0 = un solo bloque de RX, N = N+1 bloques con reconfig entre cada uno
        int unsigned n_reconfig;

        // parametros del driver TX y de la secuencia RX
        int unsigned tx_ready_weight; // que tan rapido acepta datos el TX
        int unsigned num_transfers;   // cuantas transferencias RX en total
        int unsigned w_size1;
        int unsigned w_size2;
        int unsigned w_size4;
        int unsigned w_off0;
        int unsigned w_off1;
        int unsigned w_off2;
        int unsigned w_off3;
        int unsigned w_illegal;

        bit do_irqen; // bandera: si se prendio algun bit del IRQEN, al final se lee el IRQ

        // valores por defecto por si no se pasa el plusarg
        w_ctrl_size1      = 34;
        w_ctrl_size2      = 33;
        w_ctrl_size4      = 33;
        w_ctrl_off0       = 25;
        w_ctrl_off1       = 25;
        w_ctrl_off2       = 25;
        w_ctrl_off3       = 25;
        w_irqen_rx_empty  = 0;
        w_irqen_rx_full   = 0;
        w_irqen_tx_empty  = 0;
        w_irqen_tx_full   = 0;
        w_irqen_max_drop  = 0;
        w_irq_clr         = 0;
        n_reconfig        = 0;
        tx_ready_weight   = 100;
        num_transfers     = 8;
        w_size1           = 34;
        w_size2           = 33;
        w_size4           = 33;
        w_off0            = 25;
        w_off1            = 25;
        w_off2            = 25;
        w_off3            = 25;
        w_illegal         = 0;

        // se leen los plusargs de la linea de comando, si no estan se quedan los defaults
        void'($value$plusargs("W_CTRL_SIZE1=%d",     w_ctrl_size1));
        void'($value$plusargs("W_CTRL_SIZE2=%d",     w_ctrl_size2));
        void'($value$plusargs("W_CTRL_SIZE4=%d",     w_ctrl_size4));
        void'($value$plusargs("W_CTRL_OFF0=%d",      w_ctrl_off0));
        void'($value$plusargs("W_CTRL_OFF1=%d",      w_ctrl_off1));
        void'($value$plusargs("W_CTRL_OFF2=%d",      w_ctrl_off2));
        void'($value$plusargs("W_CTRL_OFF3=%d",      w_ctrl_off3));
        void'($value$plusargs("W_IRQEN_RX_EMPTY=%d", w_irqen_rx_empty));
        void'($value$plusargs("W_IRQEN_RX_FULL=%d",  w_irqen_rx_full));
        void'($value$plusargs("W_IRQEN_TX_EMPTY=%d", w_irqen_tx_empty));
        void'($value$plusargs("W_IRQEN_TX_FULL=%d",  w_irqen_tx_full));
        void'($value$plusargs("W_IRQEN_MAX_DROP=%d", w_irqen_max_drop));
        void'($value$plusargs("W_IRQ_CLR=%d",        w_irq_clr));
        void'($value$plusargs("N_RECONFIG=%d",       n_reconfig));
        void'($value$plusargs("TX_READY_WEIGHT=%d",  tx_ready_weight));
        void'($value$plusargs("NUM_TRANSFERS=%d",    num_transfers));
        void'($value$plusargs("W_SIZE1=%d",          w_size1));
        void'($value$plusargs("W_SIZE2=%d",          w_size2));
        void'($value$plusargs("W_SIZE4=%d",          w_size4));
        void'($value$plusargs("W_OFF0=%d",           w_off0));
        void'($value$plusargs("W_OFF1=%d",           w_off1));
        void'($value$plusargs("W_OFF2=%d",           w_off2));
        void'($value$plusargs("W_OFF3=%d",           w_off3));
        void'($value$plusargs("W_ILLEGAL=%d",        w_illegal));

        // si algun bit del IRQEN quedo prendido, se marca que hay que revisar el IRQ al final
        do_irqen = (w_irqen_rx_empty > 0) || (w_irqen_rx_full  > 0) ||
                   (w_irqen_tx_empty > 0) || (w_irqen_tx_full  > 0) ||
                   (w_irqen_max_drop > 0);

        phase.raise_objection(this); // se levanta la objecion para que la sim no termine antes de tiempo

        `uvm_info(get_type_name(), "=== Test Iniciado ===", UVM_NONE)
        // se imprime toda la config para tenerla a la vista en el log
        `uvm_info(get_type_name(),
            $sformatf({"Configuracion:\n",
                       "  CTRL sz  : W_CTRL_SIZE1=%0d  W_CTRL_SIZE2=%0d  W_CTRL_SIZE4=%0d\n",
                       "  CTRL off : W_CTRL_OFF0=%0d   W_CTRL_OFF1=%0d   W_CTRL_OFF2=%0d  W_CTRL_OFF3=%0d\n",
                       "  IRQEN    : rx_empty=%0d  rx_full=%0d  tx_empty=%0d  tx_full=%0d  max_drop=%0d\n",
                       "  W1C      : W_IRQ_CLR=%0d\n",
                       "  Reconf   : N_RECONFIG=%0d\n",
                       "  TX drv   : TX_READY_WEIGHT=%0d\n",
                       "  RX seq   : NUM_TRANSFERS=%0d\n",
                       "  RX size  : W_SIZE1=%0d  W_SIZE2=%0d  W_SIZE4=%0d\n",
                       "  RX offset: W_OFF0=%0d  W_OFF1=%0d  W_OFF2=%0d  W_OFF3=%0d\n",
                       "  Ilegal   : W_ILLEGAL=%0d"},
                w_ctrl_size1, w_ctrl_size2, w_ctrl_size4,
                w_ctrl_off0,  w_ctrl_off1,  w_ctrl_off2,  w_ctrl_off3,
                w_irqen_rx_empty, w_irqen_rx_full,
                w_irqen_tx_empty, w_irqen_tx_full, w_irqen_max_drop,
                w_irq_clr,
                n_reconfig,
                tx_ready_weight,
                num_transfers,
                w_size1, w_size2, w_size4,
                w_off0, w_off1, w_off2, w_off3,
                w_illegal),
            UVM_NONE)

        // se le pasa al driver TX que tan seguido acepta datos (para simular back-pressure)
        if (env.md_agt.tx_driver != null)
            env.md_agt.tx_driver.set_ready_weight(tx_ready_weight);

        // Paso 1: configurar CTRL por APB ----
        // el solver elige un SIZE y OFFSET validos segun los pesos, no se fija nada a mano
        `uvm_info(get_type_name(), "Verificacion 1: Configurando CTRL via APB", UVM_LOW)
        begin
            //en lugar de crear apb_sequence y asignar op/pesos,
            // se resuelve el SIZE y OFFSET aqui mismo con los pesos usando $urandom_range,
            // igual que hacia el constraint del seq_item, y se escribe RAL directo.
            begin
                int unsigned ts = w_ctrl_size1 + w_ctrl_size2 + w_ctrl_size4;
                int unsigned to = w_ctrl_off0  + w_ctrl_off1  + w_ctrl_off2 + w_ctrl_off3;
                int unsigned rnd;
                if (ts == 0) ts = 1; // evitar division por cero si todos los pesos son 0
                if (to == 0) to = 1;
                rnd = $urandom_range(0, ts - 1);
                if      (rnd < w_ctrl_size1)                      ctrl_size_val = 1;
                else if (rnd < w_ctrl_size1 + w_ctrl_size2)       ctrl_size_val = 2;
                else                                               ctrl_size_val = 4;
                rnd = $urandom_range(0, to - 1);
                if      (rnd < w_ctrl_off0)                        ctrl_off_val = 0;
                else if (rnd < w_ctrl_off0 + w_ctrl_off1)          ctrl_off_val = 1;
                else if (rnd < w_ctrl_off0 + w_ctrl_off1
                             + w_ctrl_off2)                        ctrl_off_val = 2;
                else                                               ctrl_off_val = 3;
            end
            // se escriben SIZE y OFFSET al DUT via RAL
            env.reg_model.CTRL.SIZE.set(ctrl_size_val);
            env.reg_model.CTRL.OFFSET.set(ctrl_off_val);
            env.reg_model.CTRL.update(status, UVM_FRONTDOOR);
            if (status != UVM_IS_OK)
                `uvm_error("TEST", "CTRL update fallo")
            // se verifica con read, equivalente al last_item que usaba apb_seq antes
            env.reg_model.CTRL.read(status, rdata, UVM_FRONTDOOR);
            // se lee de reg_model que SIZE y OFFSET salieron realmente
            `uvm_info(get_type_name(),
                $sformatf("CTRL configurado: SIZE=%0d  OFFSET=%0d",
                    ctrl_size_val, ctrl_off_val), UVM_LOW)
        end

        // ---- Paso 1b: configurar IRQEN, solo si se prendio algun bit ----
        if (do_irqen) begin
            // CORRECCIÓN: se escribe IRQEN directo al RAL campo por campo
            // segun si el peso de cada bit es mayor a 0
            env.reg_model.IRQEN.RX_FIFO_EMPTY.set(w_irqen_rx_empty > 0 ? 1 : 0);
            env.reg_model.IRQEN.RX_FIFO_FULL.set( w_irqen_rx_full  > 0 ? 1 : 0);
            env.reg_model.IRQEN.TX_FIFO_EMPTY.set(w_irqen_tx_empty > 0 ? 1 : 0);
            env.reg_model.IRQEN.TX_FIFO_FULL.set( w_irqen_tx_full  > 0 ? 1 : 0);
            env.reg_model.IRQEN.MAX_DROP.set(     w_irqen_max_drop > 0 ? 1 : 0);
            env.reg_model.IRQEN.update(status, UVM_FRONTDOOR);
            if (status != UVM_IS_OK)
                `uvm_error("TEST", "IRQEN update fallo")
            `uvm_info(get_type_name(),
                $sformatf("IRQEN configurado: RX_EMPTY=%0b RX_FULL=%0b TX_EMPTY=%0b TX_FULL=%0b MAX_DROP=%0b",
                    w_irqen_rx_empty > 0, w_irqen_rx_full  > 0,
                    w_irqen_tx_empty > 0, w_irqen_tx_full  > 0,
                    w_irqen_max_drop > 0), UVM_LOW)
        end

        #100; // se espera un poco antes de empezar a mandar datos

        // ---- Paso 2: mandar las transferencias RX en bloques ----
        // si no hay reconfig, es un solo bloque con todas las transferencias
        // si hay reconfig, se parte el total en N+1 bloques y se reconfigura CTRL entre cada uno
        `uvm_info(get_type_name(), "Verificacion 2: Transferencias RX por pesos", UVM_LOW)
        begin
            int unsigned tpb; // transferencias por bloque
            int unsigned rem; // lo que sobra para el ultimo bloque

            tpb = num_transfers / (n_reconfig + 1);
            rem = num_transfers % (n_reconfig + 1);

            for (int b = 0; b <= int'(n_reconfig); b++) begin
                // al ultimo bloque se le suma el resto para no perder transferencias
                automatic int unsigned bsz = tpb + ((b == int'(n_reconfig)) ? rem : 0);

                rx_seq = md_rx_multiple_seq::type_id::create(
                             $sformatf("rx_seq_b%0d", b)); // se crea la secuencia del bloque
                rx_seq.num_transfers = bsz; // cuantas se mandan en este bloque
                rx_seq.w_size1       = w_size1; // se le pasan los pesos
                rx_seq.w_size2       = w_size2;
                rx_seq.w_size4       = w_size4;
                rx_seq.w_off0        = w_off0;
                rx_seq.w_off1        = w_off1;
                rx_seq.w_off2        = w_off2;
                rx_seq.w_off3        = w_off3;
                rx_seq.w_illegal     = w_illegal;
                rx_seq.start(env.md_agt.sequencer); // se arrancan las transferencias

                // si todavia quedan bloques, se reconfigura CTRL con valores nuevos
                if (b < int'(n_reconfig)) begin
                    #100; // se deja un margen para que el TX termine de drenar
                    // CORRECCIÓN: reconfig de CTRL via RAL directo, igual que el Paso 1
                    // se eligen nuevos SIZE y OFFSET con los mismos pesos
                    begin
                        int unsigned ts = w_ctrl_size1 + w_ctrl_size2 + w_ctrl_size4;
                        int unsigned to = w_ctrl_off0  + w_ctrl_off1  + w_ctrl_off2 + w_ctrl_off3;
                        int unsigned rnd;
                        if (ts == 0) ts = 1;
                        if (to == 0) to = 1;
                        rnd = $urandom_range(0, ts - 1);
                        if      (rnd < w_ctrl_size1)                 ctrl_size_val = 1;
                        else if (rnd < w_ctrl_size1 + w_ctrl_size2)  ctrl_size_val = 2;
                        else                                          ctrl_size_val = 4;
                        rnd = $urandom_range(0, to - 1);
                        if      (rnd < w_ctrl_off0)                  ctrl_off_val = 0;
                        else if (rnd < w_ctrl_off0 + w_ctrl_off1)    ctrl_off_val = 1;
                        else if (rnd < w_ctrl_off0 + w_ctrl_off1
                                     + w_ctrl_off2)                  ctrl_off_val = 2;
                        else                                          ctrl_off_val = 3;
                    end
                    env.reg_model.CTRL.SIZE.set(ctrl_size_val);
                    env.reg_model.CTRL.OFFSET.set(ctrl_off_val);
                    env.reg_model.CTRL.update(status, UVM_FRONTDOOR);
                    `uvm_info(get_type_name(),
                        $sformatf("Reconf %0d/%0d: CTRL SIZE=%0d OFFSET=%0d",
                            b+1, n_reconfig,
                            ctrl_size_val, ctrl_off_val), UVM_LOW)
                end
            end
        end

        #200; // se espera a que el DUT termine de procesar todo

        //  leer STATUS por APB ----
        // STATUS trae el contador de drops, el nivel del RX y el nivel del TX
        `uvm_info(get_type_name(), "Verificacion 3: Leyendo STATUS via APB", UVM_LOW)
        begin
            // se lee STATUS via RAL y se accede a los campos directamente
            // del mirror en lugar de hacer bit-slicing manual sobre rdata
            env.reg_model.STATUS.read(status, rdata, UVM_FRONTDOOR);
            // se saca cada campo del rdata segun donde esta en el registro
            `uvm_info(get_type_name(),
                $sformatf("STATUS=0x%0h  CNT_DROP=%0d  RX_LVL=%0d  TX_LVL=%0d",
                    rdata,
                    env.reg_model.STATUS.CNT_DROP.get(),
                    env.reg_model.STATUS.RX_LVL.get(),
                    env.reg_model.STATUS.TX_LVL.get()), UVM_LOW)
        end

        //  leer IRQ por APB, solo si se configuro el IRQEN 
        // si el peso de W1C es mayor a 0, la secuencia limpia el IRQ sola
        if (do_irqen) begin
            `uvm_info(get_type_name(), "Verificacion 3b: Leyendo IRQ via APB", UVM_LOW)
            // CORRECCIÓN: lectura del IRQ via RAL
            env.reg_model.IRQ.read(status, rdata, UVM_FRONTDOOR);
            `uvm_info(get_type_name(),
                $sformatf("IRQ=0x%0h  (do_irq_clr=%0b)",
                    rdata,
                    (w_irq_clr > 0)), UVM_LOW)
            // si w_irq_clr > 0 se limpia escribiendo los bits activos de vuelta (W1C)
            if (w_irq_clr > 0 && rdata[4:0] != 5'h0)
                env.reg_model.IRQ.write(status, rdata, UVM_FRONTDOOR);
        end

        #50;

        `uvm_info(get_type_name(), "=== Test finalizado ===", UVM_NONE)
        phase.drop_objection(this); // se baja la objecion para que la sim pueda terminar
    endtask
  // esto genera el reporte de la cobertura de los registros, se pone aca ya que el test debe generar el modelo de los registros y las clases para su cobertura, entonces aca se debe de poner el reporte
  function void report_phase(uvm_phase phase);
        aligner__CTRL_cov   ctrl_cov;
        aligner__STATUS_cov status_cov;
        aligner__IRQEN_cov  irqen_cov;
        aligner__IRQ_cov    irq_cov;

        if (!$cast(ctrl_cov,   env.reg_model.CTRL))
            `uvm_fatal("COV", "Cast CTRL fallo")
        if (!$cast(status_cov, env.reg_model.STATUS))
            `uvm_fatal("COV", "Cast STATUS fallo")
        if (!$cast(irqen_cov,  env.reg_model.IRQEN))
            `uvm_fatal("COV", "Cast IRQEN fallo")
        if (!$cast(irq_cov,    env.reg_model.IRQ))
            `uvm_fatal("COV", "Cast IRQ fallo")

        `uvm_info("COV", $sformatf("\n=== Cobertura de registros ===\n  CTRL   : %.1f%%\n  STATUS : %.1f%%\n  IRQEN  : %.1f%%\n  IRQ    : %.1f%%",
            ctrl_cov.ctrl_cg.get_coverage(),
            status_cov.status_cg.get_coverage(),
            irqen_cov.irqen_cg.get_coverage(),
            irq_cov.irq_cg.get_coverage()),
            UVM_NONE)
  // reporte de cobertura md
  `uvm_info("COV", $sformatf("\n=== Cobertura MD ===\n  RX (size/offset/err) : %.1f%%\n  TX (size/offset)     : %.1f%%\n",
      env.md_cov.rx_cg.get_coverage(),
      env.md_cov.tx_cg.get_coverage()),
      UVM_NONE)

    endfunction

endclass : aligner_test