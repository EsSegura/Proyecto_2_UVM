class aligner_test extends uvm_test;

    `uvm_component_utils(aligner_test) //registra el test en la fabrica

    aligner_env env; //el ambiente que tiene los agentes y el scoreboard

    function new(string name, uvm_component parent);
        super.new(name, parent); //llama al constructor de la clase base uvm_test
     	endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase); //llama a la fase de construccion de la clase base
        env = aligner_env::type_id::create("env", this); //se crea el ambiente
    endfunction

    task run_phase(uvm_phase phase);
        apb_sequence       apb_seq; //secuencia para hablar con el DUT por APB
        md_rx_multiple_seq rx_seq;  //secuencia que manda las transferencias RX

        //pesos para el SIZE de CTRL (como se configura el alineador)
        //ejemplos:
        //  solo size 1 -> +W_CTRL_SIZE1=100 +W_CTRL_SIZE2=0 +W_CTRL_SIZE4=0
        //  solo size 4 -> +W_CTRL_SIZE4=100 +W_CTRL_SIZE1=0 +W_CTRL_SIZE2=0
        int unsigned w_ctrl_size1;
        int unsigned w_ctrl_size2;
        int unsigned w_ctrl_size3;
        int unsigned w_ctrl_size4;

        //pesos para el OFFSET de CTRL (solo entran combos validos por el constraint)
        int unsigned w_ctrl_off0;
        int unsigned w_ctrl_off1;
        int unsigned w_ctrl_off2;
        int unsigned w_ctrl_off3;

        //peso para escrituras de CTRL con combos ilegales (el DUT responde PSLVERR)
        int unsigned w_ctrl_illegal;

        //peso para mandar el bit CLR en las escrituras de CTRL (limpia CNT_DROP)
        int unsigned w_ctrl_clr;

        //pesos para los bits del IRQEN (0 = bit apagado, 100 = bit prendido)
        //bit 4=MAX_DROP, 3=TX_FULL, 2=TX_EMPTY, 1=RX_FULL, 0=RX_EMPTY
        int unsigned w_irqen_rx_empty;
        int unsigned w_irqen_rx_full;
        int unsigned w_irqen_tx_empty;
        int unsigned w_irqen_tx_full;
        int unsigned w_irqen_max_drop;

        //peso para limpiar el IRQ despues de leerlo (0 = nunca, 100 = siempre)
        int unsigned w_irq_clr;

        //cuantas veces se reconfigura CTRL en medio del test
        //0 = un solo bloque de RX, N = N+1 bloques con reconfig entre cada uno
        int unsigned n_reconfig;

        //parametros del driver TX y de la secuencia RX
        int unsigned tx_ready_weight; //que tan rapido acepta datos el TX
        int unsigned num_transfers;   //cuantas transferencias RX en total
        int unsigned w_size1;
        int unsigned w_size2;
        int unsigned w_size3;
        int unsigned w_size4;
        int unsigned w_off0;
        int unsigned w_off1;
        int unsigned w_off2;
        int unsigned w_off3;
        int unsigned w_illegal;

        bit do_irqen; //bandera: si se prendio algun bit del IRQEN, al final se lee el IRQ

        //valores por defecto por si no se pasa el plusarg
        //NOTA: el test base (sin plusargs) debe ser lo mas general posible para
        //maximizar la cobertura en una sola corrida, por eso los defaults activan
        //todo: reconfigs, ilegales, size 3, CLR, IRQEN variado y backpressure.
        //Los plusargs siguen sirviendo para estrechar a un escenario puntual.
        w_ctrl_size1      = 25;
        w_ctrl_size2      = 25;
        w_ctrl_size3      = 25;
        w_ctrl_size4      = 25;
        w_ctrl_off0       = 25;
        w_ctrl_off1       = 25;
        w_ctrl_off2       = 25;
        w_ctrl_off3       = 25;
        w_ctrl_illegal    = 25;
        w_ctrl_clr        = 50;
        w_irqen_rx_empty  = 50;
        w_irqen_rx_full   = 50;
        w_irqen_tx_empty  = 50;
        w_irqen_tx_full   = 50;
        w_irqen_max_drop  = 50;
        w_irq_clr         = 50;
        n_reconfig        = 50;
        tx_ready_weight   = 40;
        num_transfers     = 300;
        w_size1           = 25;
        w_size2           = 25;
        w_size3           = 25;
        w_size4           = 25;
        w_off0            = 25;
        w_off1            = 25;
        w_off2            = 25;
        w_off3            = 25;
        w_illegal         = 30;

        //se leen los plusargs de la linea de comando, si no estan se quedan los defaults
        void'($value$plusargs("W_CTRL_SIZE1=%d",     w_ctrl_size1));
        void'($value$plusargs("W_CTRL_SIZE2=%d",     w_ctrl_size2));
        void'($value$plusargs("W_CTRL_SIZE3=%d",     w_ctrl_size3));
        void'($value$plusargs("W_CTRL_SIZE4=%d",     w_ctrl_size4));
        void'($value$plusargs("W_CTRL_ILLEGAL=%d",   w_ctrl_illegal));
        void'($value$plusargs("W_CTRL_CLR=%d",       w_ctrl_clr));
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
        void'($value$plusargs("W_SIZE3=%d",          w_size3));
        void'($value$plusargs("W_SIZE4=%d",          w_size4));
        void'($value$plusargs("W_OFF0=%d",           w_off0));
        void'($value$plusargs("W_OFF1=%d",           w_off1));
        void'($value$plusargs("W_OFF2=%d",           w_off2));
        void'($value$plusargs("W_OFF3=%d",           w_off3));
        void'($value$plusargs("W_ILLEGAL=%d",        w_illegal));

        //si algun bit del IRQEN quedo prendido, se marca que hay que revisar el IRQ al final
        do_irqen = (w_irqen_rx_empty > 0) || (w_irqen_rx_full  > 0) ||
                   (w_irqen_tx_empty > 0) || (w_irqen_tx_full  > 0) ||
                   (w_irqen_max_drop > 0);

        phase.raise_objection(this); //se levanta la objecion para que la sim no termine antes de tiempo

        `uvm_info(get_type_name(), "=== Test Iniciado ===", UVM_NONE)
        //se imprime toda la config para tenerla a la vista en el log
        `uvm_info(get_type_name(),
            $sformatf({"Configuracion:\n",
                       "  CTRL sz  : W_CTRL_SIZE1=%0d  W_CTRL_SIZE2=%0d  W_CTRL_SIZE3=%0d  W_CTRL_SIZE4=%0d\n",
                       "  CTRL off : W_CTRL_OFF0=%0d   W_CTRL_OFF1=%0d   W_CTRL_OFF2=%0d  W_CTRL_OFF3=%0d\n",
                       "  CTRL err : W_CTRL_ILLEGAL=%0d  W_CTRL_CLR=%0d\n",
                       "  IRQEN    : rx_empty=%0d  rx_full=%0d  tx_empty=%0d  tx_full=%0d  max_drop=%0d\n",
                       "  W1C      : W_IRQ_CLR=%0d\n",
                       "  Reconf   : N_RECONFIG=%0d\n",
                       "  TX drv   : TX_READY_WEIGHT=%0d\n",
                       "  RX seq   : NUM_TRANSFERS=%0d\n",
                       "  RX size  : W_SIZE1=%0d  W_SIZE2=%0d  W_SIZE3=%0d  W_SIZE4=%0d\n",
                       "  RX offset: W_OFF0=%0d  W_OFF1=%0d  W_OFF2=%0d  W_OFF3=%0d\n",
                       "  Ilegal   : W_ILLEGAL=%0d"},
                w_ctrl_size1, w_ctrl_size2, w_ctrl_size3, w_ctrl_size4,
                w_ctrl_off0,  w_ctrl_off1,  w_ctrl_off2,  w_ctrl_off3,
                w_ctrl_illegal, w_ctrl_clr,
                w_irqen_rx_empty, w_irqen_rx_full,
                w_irqen_tx_empty, w_irqen_tx_full, w_irqen_max_drop,
                w_irq_clr,
                n_reconfig,
                tx_ready_weight,
                num_transfers,
                w_size1, w_size2, w_size3, w_size4,
                w_off0, w_off1, w_off2, w_off3,
                w_illegal),
            UVM_NONE)

        //se le pasa al driver TX que tan seguido acepta datos (para simular back-pressure)
        if (env.md_agt.tx_driver != null)
            env.md_agt.tx_driver.set_ready_weight(tx_ready_weight);

        //configurar CTRL por APB
        //el solver elige un SIZE y OFFSET validos segun los pesos, no se fija nada a mano
        `uvm_info(get_type_name(), "Verificacion 1: Configurando CTRL via APB", UVM_LOW)
        begin
            apb_seq = apb_sequence::type_id::create("apb_ctrl_cfg"); //se crea la secuencia
            apb_seq.op           = apb_seq_item::OP_CTRL_CFG; //se le indica que configure CTRL
            apb_seq.w_ctrl_size1 = w_ctrl_size1; //se le pasan los pesos
            apb_seq.w_ctrl_size2 = w_ctrl_size2;
            apb_seq.w_ctrl_size3 = w_ctrl_size3;
            apb_seq.w_ctrl_size4 = w_ctrl_size4;
            apb_seq.w_ctrl_off0  = w_ctrl_off0;
            apb_seq.w_ctrl_off1  = w_ctrl_off1;
            apb_seq.w_ctrl_off2  = w_ctrl_off2;
            apb_seq.w_ctrl_off3  = w_ctrl_off3;
            //la primera configuracion siempre es legal y sin CLR para arrancar
            //de un estado conocido, los pesos de ilegales aplican en las reconfigs
            apb_seq.w_ctrl_illegal = 0;
            apb_seq.w_ctrl_clr     = 0;
            apb_seq.start(env.apb_agt.sequencer); //se arranca la secuencia en el sequencer APB
            //se lee de last_item que SIZE y OFFSET salieron realmente
            `uvm_info(get_type_name(),
                $sformatf("CTRL configurado: SIZE=%0d  OFFSET=%0d",
                    apb_seq.last_item.ctrl_size,
                    apb_seq.last_item.ctrl_offset), UVM_LOW)
        end

        //configurar IRQEN, solo si se prendio algun bit 
        if (do_irqen) begin
            apb_seq = apb_sequence::type_id::create("apb_irqen_cfg");
            apb_seq.op               = apb_seq_item::OP_IRQEN_CFG;
            apb_seq.w_irqen_rx_empty = w_irqen_rx_empty;
            apb_seq.w_irqen_rx_full  = w_irqen_rx_full;
            apb_seq.w_irqen_tx_empty = w_irqen_tx_empty;
            apb_seq.w_irqen_tx_full  = w_irqen_tx_full;
            apb_seq.w_irqen_max_drop = w_irqen_max_drop;
            apb_seq.start(env.apb_agt.sequencer);
            `uvm_info(get_type_name(),
                $sformatf("IRQEN configurado: 0x%0h", apb_seq.last_item.irqen_bits), UVM_LOW)
        end

        #100; //se espera un poco antes de empezar a mandar datos

        //se mandan las transferencias RX en bloques 
        //si no hay reconfig, es un solo bloque con todas las transferencias
        //si hay reconfig, se parte el total en N+1 bloques y se reconfigura CTRL entre cada uno
        `uvm_info(get_type_name(), "Verificacion 2: Transferencias RX por pesos", UVM_LOW)
        begin
            int unsigned tpb; //transferencias por bloque
            int unsigned rem; //lo que sobra para el ultimo bloque

            tpb = num_transfers / (n_reconfig + 1);
            rem = num_transfers % (n_reconfig + 1);

            for (int b = 0; b <= int'(n_reconfig); b++) begin
                //al ultimo bloque se le suma el resto para no perder transferencias
                automatic int unsigned bsz = tpb + ((b == int'(n_reconfig)) ? rem : 0);

                rx_seq = md_rx_multiple_seq::type_id::create(
                             $sformatf("rx_seq_b%0d", b)); //se crea la secuencia del bloque
                rx_seq.num_transfers = bsz; //cuantas se mandan en este bloque
                rx_seq.w_size1       = w_size1; //se le pasan los pesos
                rx_seq.w_size2       = w_size2;
                rx_seq.w_size3       = w_size3;
                rx_seq.w_size4       = w_size4;
                rx_seq.w_off0        = w_off0;
                rx_seq.w_off1        = w_off1;
                rx_seq.w_off2        = w_off2;
                rx_seq.w_off3        = w_off3;
                rx_seq.w_illegal     = w_illegal;
                rx_seq.start(env.md_agt.sequencer); //se arrancan las transferencias

                //si todavia quedan bloques, se reconfigura CTRL con valores nuevos
                //y de paso se ejercitan IRQEN, STATUS e IRQ a mitad del trafico,
                //asi la cobertura de esos registros ve estados intermedios
                if (b < int'(n_reconfig)) begin
                    //antes de reconfigurar hay que esperar a que el DUT drene
                    //sus FIFOs: los paquetes en vuelo se alinean con la config
                    //vieja y si CTRL cambia a mitad, el scoreboard compararia
                    //el TX contra la config nueva y marcaria fallos falsos.
                    //Se lee STATUS hasta que RX_LVL y TX_LVL queden en 0

                    begin
                        int unsigned drain_tries = 0;
                        do begin
                            apb_seq = apb_sequence::type_id::create(
                                          $sformatf("apb_drain_%0d_%0d", b, drain_tries));
                            apb_seq.op = apb_seq_item::OP_STATUS_READ;
                            apb_seq.start(env.apb_agt.sequencer);
                            drain_tries++;
                            //RX_LVL y TX_LVL viven en los bits [19:8] de STATUS
                            //Nota: los bits [19:16] son los bits del nivel de
                            //la fifo tx no los 19:8, tambien se debe
                            //verificar que la fifo de recepcion este vacia,
                            //que son los bits 11:8 del registro de estado

                            //if (apb_seq.last_item.rdata[19:8] != 0)
                            if ((apb_seq.last_item.rdata[19:16] != 0 ||apb_seq.last_item.rdata[11:8] != 0) )
                                #200; //se da tiempo a que el TX siga drenando
                        //se espera a que se drenen ambas fifos
                        end while ((apb_seq.last_item.rdata[19:16] != 0 || apb_seq.last_item.rdata[11:8] !=0 ) && drain_tries < 50);
                    end

                    apb_seq = apb_sequence::type_id::create(
                                  $sformatf("apb_ctrl_reconf_%0d", b));
                    apb_seq.op             = apb_seq_item::OP_CTRL_RECONFIG;
                    apb_seq.w_ctrl_size1   = w_ctrl_size1;
                    apb_seq.w_ctrl_size2   = w_ctrl_size2;
                    apb_seq.w_ctrl_size3   = w_ctrl_size3;
                    apb_seq.w_ctrl_size4   = w_ctrl_size4;
                    apb_seq.w_ctrl_off0    = w_ctrl_off0;
                    apb_seq.w_ctrl_off1    = w_ctrl_off1;
                    apb_seq.w_ctrl_off2    = w_ctrl_off2;
                    apb_seq.w_ctrl_off3    = w_ctrl_off3;
                    apb_seq.w_ctrl_illegal = w_ctrl_illegal;
                    apb_seq.w_ctrl_clr     = w_ctrl_clr;
                    apb_seq.start(env.apb_agt.sequencer);
                    `uvm_info(get_type_name(),
                        $sformatf("Reconf %0d/%0d: CTRL SIZE=%0d OFFSET=%0d ilegal=%0b clr=%0b",
                            b+1, n_reconfig,
                            apb_seq.last_item.ctrl_size,
                            apb_seq.last_item.ctrl_offset,
                            apb_seq.last_item.ctrl_illegal,
                            apb_seq.last_item.do_ctrl_clr), UVM_LOW)

                    //se reescribe IRQEN con bits nuevos segun los pesos, asi cada
                    //bit pasa por habilitado y deshabilitado en una misma corrida
                    if (do_irqen) begin
                        apb_seq = apb_sequence::type_id::create(
                                      $sformatf("apb_irqen_reconf_%0d", b));
                        apb_seq.op               = apb_seq_item::OP_IRQEN_CFG;
                        apb_seq.w_irqen_rx_empty = w_irqen_rx_empty;
                        apb_seq.w_irqen_rx_full  = w_irqen_rx_full;
                        apb_seq.w_irqen_tx_empty = w_irqen_tx_empty;
                        apb_seq.w_irqen_tx_full  = w_irqen_tx_full;
                        apb_seq.w_irqen_max_drop = w_irqen_max_drop;
                        apb_seq.start(env.apb_agt.sequencer);
                    end

                    //lectura de STATUS a mitad del trafico, captura niveles de
                    //fifo distintos de vacio y el contador de drops avanzando
                    apb_seq = apb_sequence::type_id::create(
                                  $sformatf("apb_status_mid_%0d", b));
                    apb_seq.op = apb_seq_item::OP_STATUS_READ;
                    apb_seq.start(env.apb_agt.sequencer);

                    //lectura de IRQ a mitad del trafico (y limpieza por peso),
                    //captura interrupciones activas e inactivas
                    if (do_irqen) begin
                        apb_seq = apb_sequence::type_id::create(
                                      $sformatf("apb_irq_mid_%0d", b));
                        apb_seq.op        = apb_seq_item::OP_IRQ_READ;
                        apb_seq.w_irq_clr = w_irq_clr;
                        apb_seq.start(env.apb_agt.sequencer);
                    end
                end
            end
        end

        #200; //se espera a que el DUT termine de procesar todo

        //se leee STATUS por APB 
        //STATUS trae el contador de drops, el nivel del RX y el nivel del TX
        `uvm_info(get_type_name(), "Verificacion 3: Leyendo STATUS via APB", UVM_LOW)
        begin
            apb_seq = apb_sequence::type_id::create("apb_status_read");
            apb_seq.op = apb_seq_item::OP_STATUS_READ;
            apb_seq.start(env.apb_agt.sequencer);
            //se saca cada campo del rdata segun donde esta en el registro
            `uvm_info(get_type_name(),
                $sformatf("STATUS=0x%0h  CNT_DROP=%0d  RX_LVL=%0d  TX_LVL=%0d",
                    apb_seq.last_item.rdata,
                    apb_seq.last_item.rdata[7:0],
                    apb_seq.last_item.rdata[11:9],
                    apb_seq.last_item.rdata[19:16]), UVM_LOW)
        end

        //se lee IRQ por APB, solo si se configuro el IRQEN 
        //si el peso de W1C es mayor a 0, la secuencia limpia el IRQ sola
        if (do_irqen) begin
            `uvm_info(get_type_name(), "Verificacion 3b: Leyendo IRQ via APB", UVM_LOW)
            apb_seq = apb_sequence::type_id::create("apb_irq_read");
            apb_seq.op        = apb_seq_item::OP_IRQ_READ;
            apb_seq.w_irq_clr = w_irq_clr;
            apb_seq.start(env.apb_agt.sequencer);
            `uvm_info(get_type_name(),
                $sformatf("IRQ=0x%0h  (do_irq_clr=%0b)",
                    apb_seq.last_item.rdata,
                    apb_seq.last_item.do_irq_clr), UVM_LOW)
        end

        #50;

        `uvm_info(get_type_name(), "=== Test finalizado ===", UVM_NONE)
        phase.drop_objection(this); //se baja la objecion para que la sim pueda terminar
    endtask

    //reporte de cobertura al final de la simulacion, se hace aqui porque el
    //test es quien conoce el modelo de registros con cobertura y el collector MD
    function void report_phase(uvm_phase phase);
        aligner__CTRL_cov   ctrl_cov;
        aligner__STATUS_cov status_cov;
        aligner__IRQEN_cov  irqen_cov;
        aligner__IRQ_cov    irq_cov;

        //se castean los registros del modelo a sus versiones con cobertura
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

        //reporte de cobertura md
        `uvm_info("COV", $sformatf("\n=== Cobertura MD ===\n  RX (size/offset/err) : %.1f%%\n  TX (size/offset)     : %.1f%%\n",
            env.md_cov.rx_cg.get_coverage(),
            env.md_cov.tx_cg.get_coverage()),
            UVM_NONE)

    endfunction

endclass : aligner_test
