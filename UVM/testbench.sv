`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "md_rx_if.sv"
`include "md_tx_if.sv"
`include "apb_if.sv"

`include "aligner_apb_registerfile_model.sv"

`include "m_seq_item.sv"
`include "seq_item_apb.sv"
`include "md_sequence.sv"
`include "apb_sequence.sv"
`include "adapter.sv"

`include "driver_rx.sv"
`include "driver_tx.sv"
`include "monitor_rx.sv"
`include "monitor_tx.sv"
`include "agent_rx.sv"
`include "agent_tx.sv"

`include "apb_driver.sv"
`include "apb_monitor.sv"
`include "apb_agent.sv"

`include "scoreboard.sv"
`include "environment.sv"
`include "single_test.sv"

`include "design.sv"

module tb_top;
    logic clk;
    logic reset_n;
    logic irq;

    md_rx_if md_rx_vif(.clk(clk), .reset_n(reset_n));
    md_tx_if md_tx_vif(.clk(clk), .reset_n(reset_n));
    apb_if #(.ADDR_WIDTH(16), .DATA_WIDTH(32)) apb_vif(.PCLK(clk), .PRESETn(reset_n));

    cfs_aligner dut (
        .clk        (clk),
        .reset_n    (reset_n),
        .paddr      (apb_vif.PADDR),
        .pwrite     (apb_vif.PWRITE),
        .psel       (apb_vif.PSEL),
        .penable    (apb_vif.PENABLE),
        .pwdata     (apb_vif.PWDATA),
        .pready     (apb_vif.PREADY),
        .prdata     (apb_vif.PRDATA),
        .pslverr    (apb_vif.PSLVERR),
        .md_rx_valid(md_rx_vif.md_rx_valid),
        .md_rx_data (md_rx_vif.md_rx_data),
        .md_rx_offset(md_rx_vif.md_rx_offset),
        .md_rx_size (md_rx_vif.md_rx_size),
        .md_rx_ready(md_rx_vif.md_rx_ready),
        .md_rx_err  (md_rx_vif.md_rx_err),
        .md_tx_valid(md_tx_vif.md_tx_valid),
        .md_tx_data (md_tx_vif.md_tx_data),
        .md_tx_offset(md_tx_vif.md_tx_offset),
        .md_tx_size (md_tx_vif.md_tx_size),
        .md_tx_ready(md_tx_vif.md_tx_ready),
        .md_tx_err  (md_tx_vif.md_tx_err),
        .irq        (irq)
    );

    initial begin
        clk = 1'b0;
        forever #5ns clk = ~clk;
    end

    initial begin
        reset_n = 1'b0;

        md_rx_vif.md_rx_valid = 1'b0;
        md_rx_vif.md_rx_data = '0;
        md_rx_vif.md_rx_offset = '0;
        md_rx_vif.md_rx_size = '0;

        md_tx_vif.md_tx_ready = 1'b0;
        md_tx_vif.md_tx_err = 1'b0;

        apb_vif.PADDR = '0;
        apb_vif.PWRITE = 1'b0;
        apb_vif.PSEL = 1'b0;
        apb_vif.PENABLE = 1'b0;
        apb_vif.PWDATA = '0;

        repeat (5) @(posedge clk);
        reset_n = 1'b1;
    end

    initial begin
        uvm_config_db#(virtual md_rx_if)::set(null, "uvm_test_top.env.ag_rx*", "vif", md_rx_vif);
        uvm_config_db#(virtual md_tx_if)::set(null, "uvm_test_top.env.ag_tx*", "vif", md_tx_vif);
        uvm_config_db#(virtual apb_if)::set(null, "uvm_test_top.env.apb_ag*", "vif", apb_vif);

        // Default test traffic configuration (can be overridden via uvm_config_db)
        // Number of MD transactions (randomized) and TX ready packets
       // uvm_config_db#(int)::set(null, "*", "md_num", 100);
       // uvm_config_db#(int)::set(null, "*", "md_tx_num", 100);

        // APB traffic: generate 50 transactions, randomized by default, 100 ns delay for write->read pairs
       // uvm_config_db#(int)::set(null, "*", "apb_num", 50);
       // uvm_config_db#(bit)::set(null, "*", "apb_randomize", 1);
       // uvm_config_db#(int)::set(null, "*", "apb_delay_ns", 100);

        run_test("single_test");
    end
endmodule
