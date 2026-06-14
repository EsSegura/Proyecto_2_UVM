//interfaz MD que agrupa las señales de los canales RX (entrada) y TX (salida) del DUT
interface md_if #(
    parameter int DATA_WIDTH   = 32, //ancho del bus de datos
    //localparams
    parameter int OFFSET_WIDTH = (DATA_WIDTH <= 8) ? 1 : $clog2(DATA_WIDTH/8), //bits para el offset segun el ancho
    parameter int SIZE_WIDTH   = $clog2(DATA_WIDTH/8) + 1                       //bits para el size segun el ancho
)(
    input logic clk,     //reloj
    input logic reset_n  //reset activo en bajo
);

    //Señales RX (datos que entran al DUT)
    logic                    md_rx_valid;  //hay un dato valido para enviar
    logic [DATA_WIDTH-1:0]   md_rx_data;   //dato de entrada
    logic [OFFSET_WIDTH-1:0] md_rx_offset; //byte de inicio del dato
    logic [SIZE_WIDTH-1:0]   md_rx_size;   //cuantos bytes se envian
    logic                    md_rx_ready;  //el DUT acepta el dato
    logic                    md_rx_err;    //el DUT marca error en la transferencia

    //Señales TX (datos que salen del DUT)
    logic                    md_tx_valid;  //el DUT tiene un dato valido de salida
    logic [DATA_WIDTH-1:0]   md_tx_data;   //dato de salida
    logic [OFFSET_WIDTH-1:0] md_tx_offset; //byte de inicio del dato
    logic [SIZE_WIDTH-1:0]   md_tx_size;   //cuantos bytes salen
    logic                    md_tx_ready;  //el receptor acepta el dato
    logic                    md_tx_err;    //error en la transferencia de salida


    //vista para el driver RX: maneja las salidas y lee las respuestas del DUT
    clocking rx_driver_cb @(posedge clk);
        output md_rx_valid, md_rx_data, md_rx_offset, md_rx_size;
        input  md_rx_ready, md_rx_err;
    endclocking


    //vista para el driver TX: maneja ready/err y observa lo que saca el DUT
    clocking tx_driver_cb @(posedge clk);
        output md_tx_ready, md_tx_err;
        input  md_tx_valid, md_tx_data, md_tx_offset, md_tx_size;
    endclocking


    //vista pasiva para el monitor: solo observa ambos canales
    clocking monitor_cb @(posedge clk);
        input md_rx_valid, md_rx_data, md_rx_offset, md_rx_size;
        input md_rx_ready, md_rx_err;
        input md_tx_valid, md_tx_data, md_tx_offset, md_tx_size;
        input md_tx_ready, md_tx_err;
    endclocking

endinterface
