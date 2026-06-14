//interfaz APB que agrupa todas las señales del bus para conectar el TB con el DUT
interface apb_if #(
    parameter int ADDR_WIDTH = 16, //ancho del bus de direcciones
    parameter int DATA_WIDTH = 32  //ancho del bus de datos
) (
    input logic PCLK,    //reloj del bus APB
    input logic PRESETn  //reset activo en bajo
);
    logic [ADDR_WIDTH-1:0] PADDR;   //direccion del acceso
    logic                  PWRITE;  //1 = escritura, 0 = lectura
    logic                  PSEL;    //seleccion del slave
    logic                  PENABLE; //marca la fase access del acceso
    logic [DATA_WIDTH-1:0] PWDATA;  //dato a escribir
    logic [DATA_WIDTH-1:0] PRDATA;  //dato leido del slave
    logic                  PREADY;  //el slave indica que termino el acceso
    logic                  PSLVERR; //el slave indica error en el acceso

    //vista del bus para el driver (master): maneja las salidas y lee las respuestas
    clocking master_cb @(posedge PCLK);
        output PADDR, PWRITE, PSEL, PENABLE, PWDATA;
        input  PRDATA, PREADY, PSLVERR;
    endclocking

    //vista pasiva para el monitor: solo observa todas las señales
    clocking monitor_cb @(posedge PCLK);
        input PADDR, PWRITE, PSEL, PENABLE, PWDATA;
        input PRDATA, PREADY, PSLVERR;
    endclocking

    //modport del DUT: define la direccion de cada señal vista desde el diseño
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
