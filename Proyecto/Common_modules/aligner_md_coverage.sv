`uvm_analysis_imp_decl(_rx_cov)
`uvm_analysis_imp_decl(_tx_cov)

//collector de cobertura funcional del bus MD: muestrea lo que entra (RX) y sale (TX) del DUT
class aligner_md_coverage extends uvm_subscriber #(md_seq_item);

    `uvm_component_utils(aligner_md_coverage) //registra el collector en la fabrica

    //Puerto de analisis RX
    uvm_analysis_imp_rx_cov #(md_seq_item, aligner_md_coverage) rx_ap;
    //Puerto de analisis TX
    uvm_analysis_imp_tx_cov #(md_seq_item, aligner_md_coverage) tx_ap;

    //Variables auxiliares para los covergroups
    local md_seq_item  trans_rx;     //ultima transferencia RX muestreada
    local md_seq_item  trans_tx;     //ultima transferencia TX muestreada
    local logic [2:0]  last_rx_size; //ultimo size legal visto en RX

    //Covergroup RX: lo que entra al DUT
    covergroup rx_cg;

        //Tamaño de la transferencia RX
        cp_rx_size: coverpoint trans_rx.rx_size {
            bins size_0 = {3'h0}; //size=0: siempre ilegal
            bins size_1 = {3'h1};
            bins size_2 = {3'h2};
            bins size_3 = {3'h3}; //size=3: solo legal con offset=2, porque (4+2)%3 == 0
            bins size_4 = {3'h4};
        }

        //Byte de inicio de la transferencia RX
        cp_rx_offset: coverpoint trans_rx.rx_offset {
            bins off_0 = {2'h0};
            bins off_1 = {2'h1};
            bins off_2 = {2'h2};
            bins off_3 = {2'h3};
        }

        //El DUT rechazo la transferencia con rx_err
        cp_rx_err: coverpoint trans_rx.rx_err {
            bins no_error = {1'b0};
            bins error    = {1'b1};
        }

        //Transferencias legales: (4 + offset) % size == 0
        //Solo los pares validos segun el datasheet (DATA_WIDTH=32 : 4 bytes)
        cx_legales: cross cp_rx_size, cp_rx_offset {
            //size=1 acepta cualquier offset
            bins legal_s1_o0 = binsof(cp_rx_size.size_1) && binsof(cp_rx_offset.off_0);
            bins legal_s1_o1 = binsof(cp_rx_size.size_1) && binsof(cp_rx_offset.off_1);
            bins legal_s1_o2 = binsof(cp_rx_size.size_1) && binsof(cp_rx_offset.off_2);
            bins legal_s1_o3 = binsof(cp_rx_size.size_1) && binsof(cp_rx_offset.off_3);
            //size=2: offset 0 y 2 son validos
            bins legal_s2_o0 = binsof(cp_rx_size.size_2) && binsof(cp_rx_offset.off_0);
            bins legal_s2_o2 = binsof(cp_rx_size.size_2) && binsof(cp_rx_offset.off_2);
            //size=3: solo offset=2 es valido por la formula (4+2)%3 == 0
            bins legal_s3_o2 = binsof(cp_rx_size.size_3) && binsof(cp_rx_offset.off_2);
            //size=4: solo offset=0
            bins legal_s4_o0 = binsof(cp_rx_size.size_4) && binsof(cp_rx_offset.off_0);
        }

        //Transferencias ilegales: los pares que deben provocar rx_err=1
        cx_ilegales: cross cp_rx_size, cp_rx_offset {
            bins ilegal_s0_o0 = binsof(cp_rx_size.size_0) && binsof(cp_rx_offset.off_0); //size=0 siempre ilegal
            bins ilegal_s0_o1 = binsof(cp_rx_size.size_0) && binsof(cp_rx_offset.off_1);
            bins ilegal_s0_o2 = binsof(cp_rx_size.size_0) && binsof(cp_rx_offset.off_2);
            bins ilegal_s0_o3 = binsof(cp_rx_size.size_0) && binsof(cp_rx_offset.off_3);
            bins ilegal_s2_o1 = binsof(cp_rx_size.size_2) && binsof(cp_rx_offset.off_1);
            bins ilegal_s2_o3 = binsof(cp_rx_size.size_2) && binsof(cp_rx_offset.off_3);
            //size=3 es ilegal con todos los offsets menos el 2 (ese es legal)
            bins ilegal_s3_o0 = binsof(cp_rx_size.size_3) && binsof(cp_rx_offset.off_0);
            bins ilegal_s3_o1 = binsof(cp_rx_size.size_3) && binsof(cp_rx_offset.off_1);
            bins ilegal_s3_o3 = binsof(cp_rx_size.size_3) && binsof(cp_rx_offset.off_3);
            bins ilegal_s4_o1 = binsof(cp_rx_size.size_4) && binsof(cp_rx_offset.off_1);
            bins ilegal_s4_o2 = binsof(cp_rx_size.size_4) && binsof(cp_rx_offset.off_2);
            bins ilegal_s4_o3 = binsof(cp_rx_size.size_4) && binsof(cp_rx_offset.off_3);
        }

        //Verificar que el DUT responde con error en pares ilegales y sin error en legales
        //Este cross une el resultado del DUT con el par
        //para asegurarse de que los dos coinciden
        cx_err_vs_size: cross cp_rx_err, cp_rx_size {
            //Transferencias legales no deben tener error
            bins ok_s1  = binsof(cp_rx_err.no_error) && binsof(cp_rx_size.size_1);
            bins ok_s2  = binsof(cp_rx_err.no_error) && binsof(cp_rx_size.size_2);
            bins ok_s3  = binsof(cp_rx_err.no_error) && binsof(cp_rx_size.size_3); //size=3 con offset=2
            bins ok_s4  = binsof(cp_rx_err.no_error) && binsof(cp_rx_size.size_4);
            //Transferencias ilegales deben tener error
            bins err_s0 = binsof(cp_rx_err.error) && binsof(cp_rx_size.size_0);
            bins err_s3 = binsof(cp_rx_err.error) && binsof(cp_rx_size.size_3); //size=3 con offset != 2
        }

    endgroup : rx_cg

    //Covergroup TX lo que sale del DUT
    covergroup tx_cg;

        //Tamano de la transferencia TX
        cp_tx_size: coverpoint trans_tx.tx_size {
            bins size_1 = {3'h1};
            bins size_2 = {3'h2};
            bins size_3 = {3'h3}; //sale cuando CTRL queda en size=3, offset=2
            bins size_4 = {3'h4};
        }

        //Offset de la transferencia TX
        cp_tx_offset: coverpoint trans_tx.tx_offset {
            bins off_0 = {2'h0};
            bins off_1 = {2'h1};
            bins off_2 = {2'h2};
            bins off_3 = {2'h3};
        }

        //El DUT nunca saca un paquete con error en TX, asi que el valor 1 es inalcanzable por
        //diseno: se marca como ignore_bins para que no penalice la cobertura
        cp_tx_err: coverpoint trans_tx.tx_err {
            bins no_error      = {1'b0};
            ignore_bins jamas  = {1'b1};
        }

        //Pares (size, offset) que deben salir por TX segun las configuraciones
        //legales del CTRL (misma regla que RX: (4+offset)%size == 0)
        cx_tx_size_offset: cross cp_tx_size, cp_tx_offset {
            bins tx_s1_o0 = binsof(cp_tx_size.size_1) && binsof(cp_tx_offset.off_0);
            bins tx_s1_o1 = binsof(cp_tx_size.size_1) && binsof(cp_tx_offset.off_1);
            bins tx_s1_o2 = binsof(cp_tx_size.size_1) && binsof(cp_tx_offset.off_2);
            bins tx_s1_o3 = binsof(cp_tx_size.size_1) && binsof(cp_tx_offset.off_3);
            bins tx_s2_o0 = binsof(cp_tx_size.size_2) && binsof(cp_tx_offset.off_0);
            bins tx_s2_o2 = binsof(cp_tx_size.size_2) && binsof(cp_tx_offset.off_2);
            bins tx_s3_o2 = binsof(cp_tx_size.size_3) && binsof(cp_tx_offset.off_2);
            bins tx_s4_o0 = binsof(cp_tx_size.size_4) && binsof(cp_tx_offset.off_0);
        }

    endgroup : tx_cg

    function new(string name, uvm_component parent);
        super.new(name, parent); //llama al constructor de la clase base uvm_subscriber
        trans_rx     = md_seq_item::type_id::create("cov_rx_dummy"); //item auxiliar para muestrear RX
        trans_tx     = md_seq_item::type_id::create("cov_tx_dummy"); //item auxiliar para muestrear TX
        last_rx_size = 3'h1;
        rx_cg        = new(); //instancia el covergroup RX
        tx_cg        = new(); //instancia el covergroup TX
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        rx_ap = new("rx_ap", this); //crea el puerto de analisis RX
        tx_ap = new("tx_ap", this); //crea el puerto de analisis TX
    endfunction

    //Llamado cuando el monitor publica una transaccion RX (valid && ready)
    virtual function void write_rx_cov(md_seq_item trans);
        trans_rx = trans;
        rx_cg.sample(); //muestrea la cobertura RX
        //Solo actualiza last_rx_size si la transferencia fue legal (rx_err=0)
        //para que flow_cg tenga sentido: el TX deberia corresponder a ese RX
        if (!trans.rx_err)
            last_rx_size = trans.rx_size;
        `uvm_info(get_type_name(),
            $sformatf("COV RX: sz=%0d off=%0d err=%0b",
                trans.rx_size, trans.rx_offset, trans.rx_err),
            UVM_HIGH)
    endfunction

    //Llamado cuando el monitor publica una transaccion TX (valid && ready)
    virtual function void write_tx_cov(md_seq_item trans);
        trans_tx = trans;
        tx_cg.sample(); //muestrea la cobertura TX
        `uvm_info(get_type_name(),
            $sformatf("COV TX: sz=%0d off=%0d err=%0b",
                trans.tx_size, trans.tx_offset, trans.tx_err),
            UVM_HIGH)
    endfunction

    //Implementacion requerida por uvm_subscriber (puerto analysis implicito)
    //No se usa porque manejamos los dos puertos manualmente
    virtual function void write(md_seq_item t);
    endfunction

    //el resumen de cobertura MD lo imprime el report_phase del test,
    //que accede a rx_cg y tx_cg a traves de env.md_cov

endclass : aligner_md_coverage
