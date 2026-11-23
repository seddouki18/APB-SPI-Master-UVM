// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// spi_shift_engine.sv : SPI master engine (4 modes, MSB first, 8-bit frames)
module spi_shift_engine
  import spi_pkg::*;
(
  input  logic                  clk,
  input  logic                  rst_n,
  // From registers
  input  logic                  en, cpol, cpha,
  input  logic [CLKDIV_W-1:0]   clkdiv,
  output logic                  busy,
  // TX FIFO
  input  logic                  tx_empty,
  input  logic [SPI_DATA_W-1:0] tx_rdata,
  output logic                  tx_pop,
  // RX FIFO
  output logic                  rx_push,
  output logic [SPI_DATA_W-1:0] rx_wdata,
  // SPI pins
  output logic                  sclk, mosi, cs_n,
  input  logic                  miso
);

  typedef enum logic [1:0] {IDLE, XFER, DONE} state_t;

  state_t                state;
  logic [CLKDIV_W-1:0]   cnt;            // clock divider counter
  logic [3:0]            edge_cnt;       // 16 SCLK edges = 8 bits
  logic [SPI_DATA_W-1:0] tx_sr, rx_sr;   // shift registers
  logic                  tick, lead, sample;

  assign tick     = (state == XFER) && (cnt == clkdiv);  // one SCLK edge
  assign lead     = ~edge_cnt[0];                        // edges 0,2,4.. = leading
  assign sample   = cpha ? ~lead : lead;                 // CPHA picks the read edge
  assign tx_pop   = (state == IDLE) && en && !tx_empty;
  assign busy     = (state != IDLE);
  assign mosi     = tx_sr[SPI_DATA_W-1];                 // MSB first
  assign rx_push  = (state == DONE);
  assign rx_wdata = rx_sr;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state    <= IDLE;
      cnt      <= '0;
      edge_cnt <= '0;
      tx_sr    <= '0;
      rx_sr    <= '0;
      sclk     <= 1'b0;
      cs_n     <= 1'b1;
    end else begin
      case (state)
        IDLE: begin
          sclk     <= cpol;                 // SCLK rests at CPOL
          cnt      <= '0;
          edge_cnt <= '0;
          if (tx_pop) begin                 // take a byte, select the slave
            tx_sr <= tx_rdata;
            cs_n  <= 1'b0;
            state <= XFER;
          end
        end
        XFER: begin
          cnt <= tick ? '0 : cnt + 1'b1;
          if (tick) begin
            sclk     <= ~sclk;
            edge_cnt <= edge_cnt + 1'b1;
            if (sample)
              rx_sr <= {rx_sr[SPI_DATA_W-2:0], miso};          // read MISO
            else if (edge_cnt != 0)
              tx_sr <= {tx_sr[SPI_DATA_W-2:0], 1'b0};          // next bit on MOSI
            if (&edge_cnt) state <= DONE;    // edge 15 = last edge
          end
        end
        DONE: begin                         // rx_push = 1 this cycle
          cs_n  <= 1'b1;
          state <= IDLE;
        end
        default: state <= IDLE;
      endcase
    end
  end

endmodule
