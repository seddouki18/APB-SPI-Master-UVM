// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// spi_coverage.svh : functional coverage of SPI transfers

class spi_coverage extends uvm_subscriber #(spi_item);
  `uvm_component_utils(spi_coverage)
  spi_item t;

  covergroup cg;
    mode: coverpoint t.mode;                                   // 4 SPI modes
    div:  coverpoint t.clkdiv { bins fast = {0}; bins mid = {[1:3]}; bins slow = {[4:255]}; }
    data: coverpoint t.mosi   { bins zero = {8'h00}; bins ones = {8'hFF}; }
    mode_x_div: cross mode, div;
  endgroup

  function new(string name, uvm_component parent); super.new(name, parent); cg = new(); endfunction
  function void write(spi_item t); this.t = t; cg.sample(); endfunction
  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("Functional coverage = %.1f%%", cg.get_coverage()), UVM_NONE)
  endfunction
endclass
