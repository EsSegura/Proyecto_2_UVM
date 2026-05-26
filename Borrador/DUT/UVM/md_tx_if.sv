interface md_tx_if #(parameter DATA_WIDTH = 32) (
    input logic clk,
    input logic reset_n
);
    localparam int unsigned OFFSET_WIDTH = DATA_WIDTH <= 8 ? 1 : $clog2(DATA_WIDTH/8);
    localparam int unsigned SIZE_WIDTH   = $clog2(DATA_WIDTH/8)+1;

    logic                    md_tx_valid;
    logic [DATA_WIDTH-1:0]    md_tx_data;
    logic [OFFSET_WIDTH-1:0]  md_tx_offset;
    logic [SIZE_WIDTH-1:0]    md_tx_size;
    logic                    md_tx_ready;
    logic                    md_tx_err;

    modport dut (
        input  clk,
        input  reset_n,
        output md_tx_valid,
        output md_tx_data,
        output md_tx_offset,
        output md_tx_size,
        input  md_tx_ready,
        input  md_tx_err
    );

    modport tb (
        input  clk,
        input  reset_n,
        input  md_tx_valid,
        input  md_tx_data,
        input  md_tx_offset,
        input  md_tx_size,
        output md_tx_ready,
        output md_tx_err
    );
endinterface