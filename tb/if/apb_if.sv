// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// apb_if.sv : APB wires between the UVM APB agent and the DUT
interface apb_if (input logic pclk);
  logic        presetn;
  logic        psel, penable, pwrite;
  logic [7:0]  paddr;
  logic [31:0] pwdata, prdata;
  logic        pready, pslverr;
  logic        irq;
endinterface
