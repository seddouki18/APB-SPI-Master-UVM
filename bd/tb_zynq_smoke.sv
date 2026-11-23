// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// tb_zynq_smoke.sv : system test of the Block Design with the Zynq-7000 VIP
// Reads WHO_AM_I of the fake sensor through Zynq -> AXI -> APB -> SPI master -> sensor.
// ADAPT the 3 names marked below to your Block Design.
`timescale 1ns/1ps
module tb_zynq_smoke;
  localparam logic [31:0] BASE = 32'h43C0_0000;              // ADAPT: Address Editor
  `define PS dut.design_1_i.processing_system7_0.inst         // ADAPT: BD / PS names

  logic          ps_clk = 1'b0, ps_rst_n = 1'b0;
  logic [1:0]    resp;
  logic [1023:0] rd;
  always #10 ps_clk = ~ps_clk;                                // 50 MHz PS_CLK

 wire clk_w = ps_clk, rst_w = ps_rst_n;   // inout ports need wires
  design_1_wrapper dut (
    .FIXED_IO_ps_clk  (clk_w),
    .FIXED_IO_ps_porb (rst_w),
    .FIXED_IO_ps_srstb(rst_w));

  task automatic wr(input [7:0] off, input [31:0] d);
    `PS.write_data(BASE + off, 4, d, resp);
  endtask
  task automatic rd8(input [7:0] off, output [7:0] d);
    `PS.read_data(BASE + off, 4, rd, resp);
    d = rd[7:0];
  endtask

  initial begin
    logic [7:0] st, b0, b1;
    repeat (20) @(posedge ps_clk);
    ps_rst_n = 1'b1;
    repeat (5) @(posedge ps_clk);
    `PS.fpga_soft_reset(32'h1);
    `PS.fpga_soft_reset(32'h0);

    wr(8'h08, 32'h04);                               // CLKDIV = 4
    wr(8'h00, 32'h01);                               // CTRL: EN, mode 0
    wr(8'h0C, 32'h0F);                               // byte 1: register WHO_AM_I
    wr(8'h0C, 32'h00);                               // byte 2: dummy, carries the answer
    do rd8(8'h04, st); while (st[0] || !st[2]);      // wait !BUSY && TX_EMPTY
    rd8(8'h10, b0);                                  // answer to byte 1 (ignored)
    rd8(8'h10, b1);                                  // answer to byte 2 = WHO_AM_I
    if (b1 == 8'h33) $display("PASS: WHO_AM_I = %h", b1);
    else             $display("FAIL: WHO_AM_I = %h (expected 33)", b1);
    $finish;
  end

  initial begin #1ms; $display("TIMEOUT"); $finish; end      // watchdog
endmodule
