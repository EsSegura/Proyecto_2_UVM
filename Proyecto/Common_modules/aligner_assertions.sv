`include "uvm_macros.svh"
//modulo de aserciones SVA: vigila las reglas del protocolo APB y de los canales MD
module aligner_assertions #(
    parameter int ADDR_WIDTH = 16, //ancho del bus de direcciones
    parameter int DATA_WIDTH = 32  //ancho del bus de datos
)(
    input logic                  clk,     //reloj
    input logic                  reset_n, //reset activo en bajo

    //senales APB
    input logic                  psel,
    input logic                  penable,
    input logic                  pwrite,
    input logic                  pready,
    input logic                  pslverr,
    input logic [ADDR_WIDTH-1:0] paddr,
    input logic [DATA_WIDTH-1:0] pwdata,

    //senales MD RX
    input logic                  md_rx_valid,
    input logic                  md_rx_ready,
    input logic                  md_rx_err,
    input logic [2:0]            md_rx_size,
    input logic [1:0]            md_rx_offset,

    //senales MD TX
    input logic                  md_tx_valid,
    input logic                  md_tx_ready,
    input logic                  md_tx_err,
    input logic [2:0]            md_tx_size,
    input logic [1:0]            md_tx_offset
);

    import uvm_pkg::*;

    //funcion auxiliar con la regla de alineamiento del datasheet
    //un par (size, offset) es legal si size != 0 y (4 + offset) % size == 0
    function automatic bit es_legal(logic [2:0] size, logic [1:0] offset);
        if (size == 0)
            return 1'b0;
        return (((DATA_WIDTH/8) + offset) % size) == 0;
    endfunction

    //tras la fase SETUP (psel sin penable) debe venir la fase ACCESS (penable en 1)
    property p_apb_setup_to_access;
        @(posedge clk) disable iff (!reset_n)
        (psel && !penable) |=> (psel && penable);
    endproperty
    a_apb_setup_to_access: assert property (p_apb_setup_to_access)
        else `uvm_error("SVA_APB", "Despues del SETUP no llego la fase ACCESS (PENABLE no subio)")

    //penable nunca puede estar activo sin psel
    property p_apb_penable_con_psel;
        @(posedge clk) disable iff (!reset_n)
        penable |-> psel;
    endproperty
    a_apb_penable_con_psel: assert property (p_apb_penable_con_psel)
        else `uvm_error("SVA_APB", "PENABLE activo sin PSEL")

    //durante la fase ACCESS con el esclavo ocupado (pready=0) la direccion,
    //la direccion de escritura y el dato deben mantenerse estables
    property p_apb_senales_estables;
        @(posedge clk) disable iff (!reset_n)
        (psel && penable && !pready) |=>
            (psel && penable && $stable(paddr) && $stable(pwrite) && $stable(pwdata));
    endproperty
    a_apb_senales_estables: assert property (p_apb_senales_estables)
        else `uvm_error("SVA_APB", "Senales APB cambiaron en medio de la fase ACCESS")

    //pslverr solo tiene sentido en el ciclo final del acceso (con pready)
    property p_apb_slverr_valido;
        @(posedge clk) disable iff (!reset_n)
        pslverr |-> (psel && penable && pready);
    endproperty
    a_apb_slverr_valido: assert property (p_apb_slverr_valido)
        else `uvm_error("SVA_APB", "PSLVERR activo fuera del ciclo de fin de acceso")



    //el error del DUT debe coincidir exactamente con la regla del datasheet:
    //pares ilegales levantan md_rx_err y los legales no
    property p_rx_err_correcto;
        @(posedge clk) disable iff (!reset_n)
        md_rx_valid |-> (md_rx_err == !es_legal(md_rx_size, md_rx_offset));
    endproperty
    a_rx_err_correcto: assert property (p_rx_err_correcto)
        else `uvm_error("SVA_MD", $sformatf(
            "md_rx_err=%0b no corresponde con size=%0d offset=%0d",
            md_rx_err, md_rx_size, md_rx_offset))

    //una vez levantado valid, el driver debe mantenerlo hasta el handshake
    property p_rx_valid_estable;
        @(posedge clk) disable iff (!reset_n)
        (md_rx_valid && !md_rx_ready) |=> md_rx_valid;
    endproperty
    a_rx_valid_estable: assert property (p_rx_valid_estable)
        else `uvm_error("SVA_MD", "md_rx_valid se bajo antes del handshake con ready")



    //el DUT nunca debe sacar un paquete marcado con error en el TX
    property p_tx_sin_error;
        @(posedge clk) disable iff (!reset_n)
        md_tx_valid |-> !md_tx_err;
    endproperty
    a_tx_sin_error: assert property (p_tx_sin_error)
        else `uvm_error("SVA_MD", "El DUT saco un paquete TX con md_tx_err=1")

    //todo paquete que sale por TX debe ser un par (size, offset) legal,
    //porque la salida siempre respeta la configuracion valida de CTRL
    property p_tx_legal;
        @(posedge clk) disable iff (!reset_n)
        md_tx_valid |-> es_legal(md_tx_size, md_tx_offset);
    endproperty
    a_tx_legal: assert property (p_tx_legal)
        else `uvm_error("SVA_MD", $sformatf(
            "El DUT saco un paquete TX ilegal: size=%0d offset=%0d",
            md_tx_size, md_tx_offset))

    //una vez levantado valid en TX, el DUT debe mantenerlo hasta el handshake
    property p_tx_valid_estable;
        @(posedge clk) disable iff (!reset_n)
        (md_tx_valid && !md_tx_ready) |=> md_tx_valid;
    endproperty
    a_tx_valid_estable: assert property (p_tx_valid_estable)
        else `uvm_error("SVA_MD", "md_tx_valid se bajo antes del handshake con ready")
endmodule : aligner_assertions
