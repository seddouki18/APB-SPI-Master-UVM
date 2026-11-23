// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// tb_top.sv : DUT + interfaces + clock/reset, then start UVM
module tb_top;
  import uvm_pkg::*;
  import tb_pkg::*;

  logic pclk = 1'b0;
  always #5 pclk = ~pclk;                       // 100 MHz

  apb_if apb (pclk);
  spi_if spi ();

  apb_spi_master dut (
    .pclk(pclk),         .presetn(apb.presetn),
    .psel(apb.psel),     .penable(apb.penable), .pwrite(apb.pwrite),
    .paddr(apb.paddr),   .pwdata(apb.pwdata),   .prdata(apb.prdata),
    .pready(apb.pready), .pslverr(apb.pslverr),
    .sclk(spi.sclk),     .mosi(spi.mosi),       .cs_n(spi.cs_n), .miso(spi.miso),
    .irq(apb.irq));

  initial begin                                 // reset: 5 cycles
    apb.presetn = 1'b0;
    repeat (5) @(posedge pclk);
    apb.presetn = 1'b1;
  end

  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", apb);
    uvm_config_db#(virtual spi_if)::set(null, "*", "spi_vif", spi);
    run_test("all_test");                       // +UVM_TESTNAME=... overrides
  end
endmodule
