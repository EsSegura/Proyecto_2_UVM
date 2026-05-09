`include "uvm_macros.svh"
import uvm_pkg::*;

class monitor_rx extends uvm_monitor;
    `uvm_component_utils(monitor_rx)

    virtual md_rx_if vif;

    //puerto de analisis del TLM para enviar los datos capturados 
    uvm_analysis_port #(m_seq_item) monitor_analysis_port;

    function new(string name = "mu_monitor_rx", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        monitor_analysis_port = new("monitor_analysis_port", this);

        if (!uvm_config_db #(virtual md_rx_if)::get (this, "", "vif", vif)) begin      
            `uvm_fatal (get_type_name (), "No se encontró la interfaz md_rx_if")    
        end 
    endfunction 

    //En este run_phase lo que se hace es, esperar a que el reset se desactive y luego entrar en un loop donde se llama a 
    //la tarea de collect_transfer, para observar cada transaccion que pasa por la interfaz, digamos con valid y ready estan en 1
    task run_phase(uvm_phase phase);
        @(posedge vif.clk);
        wait (vif.reset_n === 1'b1);

        forever begin 
            collect_transfer();
        end
    endtask

    //Esta tarea  se va esperar hasta ver una transaccion valida, al momento de tener la transaccion valida
    //se empaquetan los datos, se muestran y luego se envian al puerto de analisis para que el scoreboard y el coverage
    //pueda recibirlos. Aca tambien se incluye el md_rx_err, donde si es 1 se indica que hubo un error en la transaccion 
    task collect_transfer();
        m_seq_item item;
 
        //aca se espera a un flanco de reloj donde valid y read esten en 1, indicando que hay una transaccion valida 
        @(posedge vif.clk);
        while (!(vif.md_rx_valid === 1'b1 && vif.md_rx_ready === 1'b1)) begin
            @(posedge vif.clk);
        end

        //se crea un item de la transaccion y se llenan los campos con los datos de la interfaz
        item = m_seq_item::type_id::create("item");
        item.data = vif.md_rx_data;
        item.offset = vif.md_rx_offset;
        item.size = vif.md_rx_size;
        item.err = vif.md_rx_err;

        `uvm_info("MONITOR_RX", $sformatf("Observado: data=0x%08h offset=%0d size=%0d err=%0b",
                    item.data, item.offset, item.size, item.err), UVM_HIGH)

        monitor_analysis_port.write(item);
    endtask
endclass