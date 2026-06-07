interface md_rx_if #(parameter DATA_WIDTH = 32) (
    input logic clk,
    input logic reset_n
);
    localparam int unsigned OFFSET_WIDTH = DATA_WIDTH <= 8 ? 1 : $clog2(DATA_WIDTH/8);
    localparam int unsigned SIZE_WIDTH   = $clog2(DATA_WIDTH/8)+1;

    logic                    md_rx_valid;
    logic [DATA_WIDTH-1:0]    md_rx_data;
    logic [OFFSET_WIDTH-1:0]  md_rx_offset;
    logic [SIZE_WIDTH-1:0]    md_rx_size;
    logic                    md_rx_ready;
    logic                    md_rx_err;

    modport dut (
        input  clk,
        input  reset_n,
        input  md_rx_valid,
        input  md_rx_data,
        input  md_rx_offset,
        input  md_rx_size,
        output md_rx_ready,
        output md_rx_err
    );

    modport tb (
        input  clk,
        input  reset_n,
        input  md_rx_ready,
        input  md_rx_err,
        output md_rx_valid,
        output md_rx_data,
        output md_rx_offset,
        output md_rx_size
    );
endinterface