interface md_if #(
    parameter int DATA_WIDTH   = 32,
    // localparams
    parameter int OFFSET_WIDTH = (DATA_WIDTH <= 8) ? 1 : $clog2(DATA_WIDTH/8),
    parameter int SIZE_WIDTH   = $clog2(DATA_WIDTH/8) + 1
)(
    input logic clk,
    input logic reset_n
);

    // Señales RX 
    logic                    md_rx_valid;
    logic [DATA_WIDTH-1:0]   md_rx_data;
    logic [OFFSET_WIDTH-1:0] md_rx_offset;
    logic [SIZE_WIDTH-1:0]   md_rx_size;
    logic                    md_rx_ready;  
    logic                    md_rx_err;    

    // Señales TX
    logic                    md_tx_valid;
    logic [DATA_WIDTH-1:0]   md_tx_data;
    logic [OFFSET_WIDTH-1:0] md_tx_offset;
    logic [SIZE_WIDTH-1:0]   md_tx_size;
    logic                    md_tx_ready;  
    logic                    md_tx_err;    


    clocking rx_driver_cb @(posedge clk);
        output md_rx_valid, md_rx_data, md_rx_offset, md_rx_size;
        input  md_rx_ready, md_rx_err;
    endclocking


    clocking tx_driver_cb @(posedge clk);
        output md_tx_ready, md_tx_err;
        input  md_tx_valid, md_tx_data, md_tx_offset, md_tx_size;
    endclocking


    clocking monitor_cb @(posedge clk);
        input md_rx_valid, md_rx_data, md_rx_offset, md_rx_size;
        input md_rx_ready, md_rx_err;
        input md_tx_valid, md_tx_data, md_tx_offset, md_tx_size;
        input md_tx_ready, md_tx_err;
    endclocking

endinterface 
