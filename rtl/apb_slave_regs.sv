// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// apb_slave_regs.sv : APB register file of the SPI master
module apb_slave_regs
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
  // To / from shift engine
  output logic                  en, cpol, cpha,
  output logic [CLKDIV_W-1:0]   clkdiv,
  input  logic                  busy,
  // To / from FIFOs
  output logic                  tx_push,
  output logic [SPI_DATA_W-1:0] tx_wdata,
  input  logic                  tx_full, tx_empty,
  output logic                  rx_pop,
  input  logic [SPI_DATA_W-1:0] rx_rdata,
  input  logic                  rx_full, rx_empty,
  // Interrupt
  output logic                  irq
);

  logic [2:0] ctrl;
  logic [1:0] irq_en;
  logic       wr_en, rd_en;

  // 1. Decode
  assign wr_en    = psel & penable &  pwrite;
  assign rd_en    = psel & penable & ~pwrite;
  assign tx_push  = wr_en & (paddr == ADDR_TXDATA) & ~tx_full;
  assign tx_wdata = pwdata[SPI_DATA_W-1:0];
  assign rx_pop   = rd_en & (paddr == ADDR_RXDATA) & ~rx_empty;

  // 2. Registers (13 flip-flops)
  always_ff @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      ctrl   <= '0;
      clkdiv <= '0;
      irq_en <= '0;
    end else if (wr_en) begin
      case (paddr)
        ADDR_CTRL:   ctrl   <= pwdata[2:0];
        ADDR_CLKDIV: clkdiv <= pwdata[CLKDIV_W-1:0];
        ADDR_IRQ_EN: irq_en <= pwdata[1:0];
        default: ;
      endcase
    end
  end

  assign en   = ctrl[CTRL_EN];
  assign cpol = ctrl[CTRL_CPOL];
  assign cpha = ctrl[CTRL_CPHA];

  // 3. Read mux (unused bits = 0)
  always_comb begin
    prdata = '0;
    case (paddr)
      ADDR_CTRL:   prdata[2:0]          = ctrl;
      ADDR_STATUS: prdata[4:0]          = {rx_empty, rx_full, tx_empty, tx_full, busy};
      ADDR_CLKDIV: prdata[CLKDIV_W-1:0] = clkdiv;
      ADDR_RXDATA: if (!rx_empty) prdata[SPI_DATA_W-1:0] = rx_rdata;
      ADDR_IRQ_EN: prdata[1:0]          = irq_en;
      default: ;
    endcase
  end

  // 4. APB response + interrupt
  assign pready  = 1'b1;
  assign pslverr = 1'b0;
  assign irq     = (tx_empty & irq_en[IRQ_TX_EMPTY]) | (~rx_empty & irq_en[IRQ_RX_AVAIL]);

endmodule
