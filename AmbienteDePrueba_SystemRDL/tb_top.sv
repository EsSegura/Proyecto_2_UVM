`include "uvm_macros.svh"
import uvm_pkg::*;
module tb_top;
    // 1. Señales de reloj y reset
    logic clk;
    logic rst;

    // 2. Instancia de la interfaz
     apb_if apb_if_inst(clk, rst);

    // 3. Generación del reloj
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz

    // 4. Reset inicial
    initial begin
      
        rst = 1; // Reset activo alto
        #20 rst = 0; // Liberar reset después de 20ns
        // esperar algunos ciclos
        // soltar reset
    end
  
  MI_PERIFERICO_pkg::MI_PERIFERICO__in_t hwif_in_default = '{default:'0};



    // 5. Instancia del DUT

     MI_PERIFERICO dut(
        .clk   (clk),
        .rst   (rst),
        .s_apb_psel(apb_if_inst.PSEL),
        .s_apb_penable(apb_if_inst.PENABLE),
        .s_apb_pwrite(apb_if_inst.PWRITE),
        .s_apb_paddr(apb_if_inst.PADDR[20:0]), // solo los bits de dirección
        .s_apb_pwdata(apb_if_inst.PWDATA),
        .s_apb_pready(apb_if_inst.PREADY),
        .s_apb_prdata(apb_if_inst.PRDATA),
        .s_apb_pslverr(apb_if_inst.PSLVERR),
        .s_apb_pprot('0),
        .s_apb_pstrb('1), // todos los bytes habilitados
        .hwif_in(hwif_in_default),
        .hwif_out()
    );


    // 6. Config db y run_test
    initial begin
    uvm_config_db #(virtual apb_if)::set(null, "uvm_test_top.*", "vif", apb_if_inst);        
     run_test();
    end
endmodule