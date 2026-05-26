interface apb_if #(
    parameter int ADDR_WIDTH = 16,
    parameter int DATA_WIDTH = 32
) (
    input logic PCLK,
    input logic PRESETn
);
    logic [ADDR_WIDTH-1:0] PADDR;
    logic                  PWRITE;
    logic                  PSEL;
    logic                  PENABLE;
    logic [DATA_WIDTH-1:0] PWDATA;
    logic [DATA_WIDTH-1:0] PRDATA;
    logic                  PREADY;
    logic                  PSLVERR;

    // Driver APB master view.
    clocking master_cb @(posedge PCLK);
        output PADDR, PWRITE, PSEL, PENABLE, PWDATA;
        input  PRDATA, PREADY, PSLVERR;
    endclocking

    // Monitor passive view.
    clocking monitor_cb @(posedge PCLK);
        input PADDR, PWRITE, PSEL, PENABLE, PWDATA;
        input PRDATA, PREADY, PSLVERR;
    endclocking

    modport dut (
        input  PCLK,
        input  PRESETn,
        input  PADDR,
        input  PWRITE,
        input  PSEL,
        input  PENABLE,
        input  PWDATA,
        output PRDATA,
        output PREADY,
        output PSLVERR
    );
endinterface
