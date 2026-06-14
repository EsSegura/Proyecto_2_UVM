//Ambos agentes tanto de RX como de TX unidos:
//  - md_rx_driver  : conduce estímulos hacia el canal RX del DUT.
//  - md_tx_driver  : mantiene md_tx_ready/err hacia el canal TX del DUT.
//  - md_monitor    : observa pasivamente RX y TX.
//  - sequencer     : genera ítems para el driver RX.
class md_agent extends uvm_agent;

    `uvm_component_utils(md_agent) //registra el agente en la fabrica

    //Subcomponentes
    md_rx_driver                 rx_driver; //driver del canal RX
    md_tx_driver                 tx_driver; //driver del canal TX
    md_monitor                   monitor;   //monitor de ambos canales
    uvm_sequencer #(md_seq_item) sequencer; //secuenciador que alimenta al driver RX

    //Puertos de análisis
    uvm_analysis_port #(md_seq_item) ap_rx; //reenvia lo observado en RX
    uvm_analysis_port #(md_seq_item) ap_tx; //reenvia lo observado en TX

    function new(string name, uvm_component parent);
        super.new(name, parent); //llama al constructor de la clase base uvm_agent
    endfunction


    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        //El monitor siempre se crea (activo o pasivo)
        monitor = md_monitor::type_id::create("monitor", this);

        //Puertos de análisis del agente
        ap_rx = new("ap_rx", this);
        ap_tx = new("ap_tx", this);

        if (is_active == UVM_ACTIVE) begin //solo en modo activo se crean drivers y secuenciador
            rx_driver = md_rx_driver::type_id::create("rx_driver", this);
            tx_driver = md_tx_driver::type_id::create("tx_driver", this);
            sequencer = uvm_sequencer #(md_seq_item)::type_id::create("sequencer", this);
        end
    endfunction


    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        //Conectar los puertos del monitor hacia el agente
        monitor.ap_rx.connect(ap_rx);
        monitor.ap_tx.connect(ap_tx);

        if (is_active == UVM_ACTIVE) begin
            //Conectar el secuenciador al driver RX
            rx_driver.seq_item_port.connect(sequencer.seq_item_export);
            //se conecta el secuenciador al driver TX también aunque no se use, para evitar warnings de conexión no utilizada en el log
            //se podria debuggear esto para eliminar la conexion y que quede limpio
            tx_driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass
