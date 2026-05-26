// Agente MD.
// Encapsula todos los componentes relacionados con la interfaz MD:
//   - md_rx_driver  : conduce estímulos hacia el canal RX del DUT.
//   - md_tx_driver  : mantiene md_tx_ready/err hacia el canal TX del DUT.
//   - md_monitor    : observa pasivamente RX y TX.
//   - sequencer     : genera ítems para el driver RX.
//
// El agente puede operar en modo ACTIVE (con drivers y secuenciador)
// o PASSIVE (solo monitor).
class md_agent extends uvm_agent;

    `uvm_component_utils(md_agent)

    // Modo activo/pasivo heredado de uvm_agent
    // is_active = UVM_ACTIVE por defecto

    // Sub-componentes
    md_rx_driver                 rx_driver;
    md_tx_driver                 tx_driver;
    md_monitor                   monitor;
    uvm_sequencer #(md_seq_item) sequencer;

    // Puertos de análisis expuestos al ambiente (re-exportados del monitor)
    uvm_analysis_port #(md_seq_item) ap_rx;
    uvm_analysis_port #(md_seq_item) ap_tx;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // -----------------------------------------------------------------------
    // build_phase
    // -----------------------------------------------------------------------
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // El monitor siempre se crea (activo o pasivo)
        monitor = md_monitor::type_id::create("monitor", this);

        // Puertos de análisis del agente
        ap_rx = new("ap_rx", this);
        ap_tx = new("ap_tx", this);

        if (is_active == UVM_ACTIVE) begin
            rx_driver = md_rx_driver::type_id::create("rx_driver", this);
            tx_driver = md_tx_driver::type_id::create("tx_driver", this);
            sequencer = uvm_sequencer #(md_seq_item)::type_id::create("sequencer", this);
        end
    endfunction

    // -----------------------------------------------------------------------
    // connect_phase
    // -----------------------------------------------------------------------
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        // Conectar los puertos del monitor hacia el agente
        monitor.ap_rx.connect(ap_rx);
        monitor.ap_tx.connect(ap_tx);

        if (is_active == UVM_ACTIVE) begin
            // Conectar el secuenciador al driver RX
            rx_driver.seq_item_port.connect(sequencer.seq_item_export);
            // Conectar el secuenciador al driver TX también (evita warning DRVCONNECT)
            tx_driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass : md_agent
