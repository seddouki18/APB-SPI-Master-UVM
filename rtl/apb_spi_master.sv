// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// apb_spi_master.sv : top of the IP (registers + 2 FIFOs + engine)
module apb_spi_master
  import spi_pkg::*;
(
  // APB
  input  logic                  pclk,
  input  logic                  presetn,
  input  logic                  psel,
  input  logic                  penable,
  input  logic                  pwrite,
  input  logic [APB_ADDR_W-1:0] paddr,
  input  logic [APB_DATA_W-1:0] pwdata,
  output logic [APB_DATA_W-1:0] prdata,
  output logic                  pready,
  output logic                  pslverr,
  // SPI
  output logic                  sclk, mosi, cs_n,
  input  logic                  miso,
  // Interrupt
  output logic                  irq
);

  logic                  en, cpol, cpha, busy;
  logic [CLKDIV_W-1:0]   clkdiv;
  logic                  tx_push, tx_pop, tx_full, tx_empty;
  logic                  rx_push, rx_pop, rx_full, rx_empty;
  logic [SPI_DATA_W-1:0] tx_wdata, tx_rdata, rx_wdata, rx_rdata;

  apb_slave_regs u_regs (.*);

  sync_fifo #(.WIDTH(SPI_DATA_W), .DEPTH(FIFO_DEPTH)) u_tx_fifo (
    .clk(pclk), .rst_n(presetn),
    .push(tx_push), .wdata(tx_wdata), .full(tx_full),
    .pop(tx_pop),   .rdata(tx_rdata), .empty(tx_empty));

  sync_fifo #(.WIDTH(SPI_DATA_W), .DEPTH(FIFO_DEPTH)) u_rx_fifo (
    .clk(pclk), .rst_n(presetn),
    .push(rx_push), .wdata(rx_wdata), .full(rx_full),
    .pop(rx_pop),   .rdata(rx_rdata), .empty(rx_empty));

  spi_shift_engine u_engine (.clk(pclk), .rst_n(presetn), .*);

endmodule
