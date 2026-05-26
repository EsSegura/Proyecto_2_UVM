interface apb_if (input logic PCLK, input logic PRESETN);


    // APB Signals
    logic [31:0] PADDR;   // Address bus 
    logic PSEL;          // Select signal
    logic PENABLE;       // Enable signal
    logic PWRITE;        // Write signal
    logic [31:0] PWDATA;  // Write data bus
    logic [31:0] PRDATA;  // Read data bus
    logic PREADY;        // Ready signal
    logic PSLVERR;       // Slave error signal

    //clocking blocks para sincronizar señales entre el DUT con el master y el monitor
    clocking master_cb @(posedge PCLK); //clockingblock para el master
    default input #1 output #1;
    output  PADDR, PSEL, PENABLE, PWRITE, PWDATA; //señales de salida que genera el master
    input  PRDATA, PREADY, PSLVERR; //señales que recibe el master
endclocking

    clocking monitor_cb @(posedge PCLK); //clockingblock para el monitor
    default input #1 output #1;
    input PADDR, PSEL, PENABLE, PWRITE, PWDATA, PRDATA, PREADY, PSLVERR; //señales que recibe el monitor
endclocking

modport master (clocking master_cb, input PCLK, PRESETN); //modport para el master declara las señales del cloking block del master para que se usen con ese clocking block, ademas declara como input el clk y el rst pq deben estar siempre se necesitan ver
modport monitor (clocking monitor_cb, input PCLK, PRESETN); //modport para el monitor declara las señales del cloking block del monitor

endinterface