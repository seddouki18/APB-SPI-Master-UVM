// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// spi_pkg.sv : constants shared by the RTL and the testbench
package spi_pkg;

  // Parameters
  localparam int APB_ADDR_W = 8;
  localparam int APB_DATA_W = 32;
  localparam int SPI_DATA_W = 8;
  localparam int FIFO_DEPTH = 8;
  localparam int FIFO_AW    = $clog2(FIFO_DEPTH);
  localparam int CLKDIV_W   = 8;

  // Register addresses
  localparam logic [APB_ADDR_W-1:0] ADDR_CTRL   = 8'h00;
  localparam logic [APB_ADDR_W-1:0] ADDR_STATUS = 8'h04;
  localparam logic [APB_ADDR_W-1:0] ADDR_CLKDIV = 8'h08;
  localparam logic [APB_ADDR_W-1:0] ADDR_TXDATA = 8'h0C;
  localparam logic [APB_ADDR_W-1:0] ADDR_RXDATA = 8'h10;
  localparam logic [APB_ADDR_W-1:0] ADDR_IRQ_EN = 8'h14;

  // CTRL bits
  localparam int CTRL_EN   = 0;
  localparam int CTRL_CPOL = 1;
  localparam int CTRL_CPHA = 2;

  // STATUS bits
  localparam int ST_BUSY     = 0;
  localparam int ST_TX_FULL  = 1;
  localparam int ST_TX_EMPTY = 2;
  localparam int ST_RX_FULL  = 3;
  localparam int ST_RX_EMPTY = 4;

  // IRQ_EN bits
  localparam int IRQ_TX_EMPTY = 0;
  localparam int IRQ_RX_AVAIL = 1;

endpackage
