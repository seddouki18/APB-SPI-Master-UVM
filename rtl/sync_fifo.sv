// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// sync_fifo.sv : synchronous FIFO (DEPTH must be a power of 2)
module sync_fifo #(
  parameter int WIDTH = 8,
  parameter int DEPTH = 8
) (
  input  logic             clk,
  input  logic             rst_n,
  input  logic             push,
  input  logic [WIDTH-1:0] wdata,
  output logic             full,
  input  logic             pop,
  output logic [WIDTH-1:0] rdata,
  output logic             empty
);

  localparam int AW = $clog2(DEPTH);

  logic [WIDTH-1:0] mem [DEPTH];
  logic [AW-1:0]    wr_ptr, rd_ptr;
  logic [AW:0]      count;              // 0 .. DEPTH
  logic             do_push, do_pop;

  assign full    = (count == DEPTH[AW:0]);
  assign empty   = (count == 0);
  assign do_push = push & ~full;        // push ignored when full
  assign do_pop  = pop  & ~empty;       // pop ignored when empty
  assign rdata   = mem[rd_ptr];         // head of the queue

  always_ff @(posedge clk)
    if (do_push) mem[wr_ptr] <= wdata;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      wr_ptr <= '0;
      rd_ptr <= '0;
      count  <= '0;
    end else begin
      if (do_push) wr_ptr <= wr_ptr + 1'b1;
      if (do_pop)  rd_ptr <= rd_ptr + 1'b1;
      count <= count + (AW+1)'(do_push) - (AW+1)'(do_pop);
    end
  end

endmodule
