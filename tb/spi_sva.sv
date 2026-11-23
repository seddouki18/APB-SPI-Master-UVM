// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// spi_sva.sv : protocol assertions, bound inside apb_spi_master
module spi_sva (
  input logic pclk, presetn,
  input logic psel, penable, pready,
  input logic sclk, cs_n, cpol, busy,
  input logic tx_push, tx_full, rx_pop, rx_empty
);
  a_enable_needs_sel: assert property (@(posedge pclk) disable iff (!presetn) penable |-> psel);
  a_setup_access:     assert property (@(posedge pclk) disable iff (!presetn) psel && !penable |=> psel && penable);
  a_no_wait_state:    assert property (@(posedge pclk) disable iff (!presetn) psel && penable |-> pready);
  a_cs_only_busy:     assert property (@(posedge pclk) disable iff (!presetn) !cs_n |-> busy);
  a_sclk_idle:        assert property (@(posedge pclk) disable iff (!presetn) $fell(cs_n) |-> sclk == cpol);
  a_no_push_full:     assert property (@(posedge pclk) disable iff (!presetn) tx_push |-> !tx_full);
  a_no_pop_empty:     assert property (@(posedge pclk) disable iff (!presetn) rx_pop |-> !rx_empty);
endmodule

bind apb_spi_master spi_sva u_sva (.*);
