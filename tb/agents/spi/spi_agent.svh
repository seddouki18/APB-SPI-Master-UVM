// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// spi_agent.svh : SPI side = fake sensor (responder) + monitor

class spi_cfg extends uvm_object;                  // current mode, shared by test and agent
  bit cpol, cpha;
  int clkdiv;
  `uvm_object_utils(spi_cfg)
  function new(string name = "spi_cfg"); super.new(name); endfunction
endclass

class spi_item extends uvm_sequence_item;          // one 8-bit SPI transfer
  bit [7:0] mosi, miso;
  bit [1:0] mode;
  int       clkdiv;
  `uvm_object_utils(spi_item)
  function new(string name = "spi_item"); super.new(name); endfunction
  function string convert2string();
    return $sformatf("mode%0d div=%0d MOSI=%02h MISO=%02h", mode, clkdiv, mosi, miso);
  endfunction
endclass

class spi_responder extends uvm_component;         // fake sensor: answers on MISO
  `uvm_component_utils(spi_responder)
  virtual spi_if vif;
  spi_cfg        cfg;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    bit [7:0] sr;
    vif.miso <= 1'b0;
    forever begin
      @(negedge vif.cs_n);
      sr = 8'($urandom);                           // random answer
      if (!cfg.cpha) vif.miso <= sr[7];            // CPHA=0: 1st bit before 1st edge
      for (int i = 0; i < 8; i++) begin
        if (cfg.cpol == cfg.cpha) @(negedge vif.sclk); else @(posedge vif.sclk);  // change edge
        if (!(cfg.cpha && i == 0)) sr = sr << 1;
        vif.miso <= sr[7];
      end
    end
  endtask
endclass

class spi_monitor extends uvm_monitor;             // rebuilds MOSI and MISO bytes
  `uvm_component_utils(spi_monitor)
  virtual spi_if vif;
  spi_cfg        cfg;
  uvm_analysis_port #(spi_item) ap;
  function new(string name, uvm_component parent); super.new(name, parent); ap = new("ap", this); endfunction
  task run_phase(uvm_phase phase);
    forever begin
      spi_item it;
      @(negedge vif.cs_n);
      it = spi_item::type_id::create("it");
      it.mode   = {cfg.cpol, cfg.cpha};
      it.clkdiv = cfg.clkdiv;
      repeat (8) begin
        if (cfg.cpol == cfg.cpha) @(posedge vif.sclk); else @(negedge vif.sclk);  // read edge
        it.mosi = {it.mosi[6:0], vif.mosi};
        it.miso = {it.miso[6:0], vif.miso};
      end
      ap.write(it);
    end
  endtask
endclass

class spi_agent extends uvm_agent;
  `uvm_component_utils(spi_agent)
  spi_responder rsp;
  spi_monitor   mon;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function void build_phase(uvm_phase phase);
    virtual spi_if vif;
    spi_cfg        cfg;
    rsp = spi_responder::type_id::create("rsp", this);
    mon = spi_monitor::type_id::create("mon", this);
    if (!uvm_config_db#(virtual spi_if)::get(this, "", "spi_vif", vif)) `uvm_fatal("NOVIF", "spi_vif not set")
    if (!uvm_config_db#(spi_cfg)::get(this, "", "cfg", cfg))            `uvm_fatal("NOCFG", "cfg not set")
    rsp.vif = vif; rsp.cfg = cfg;
    mon.vif = vif; mon.cfg = cfg;
  endfunction
endclass
