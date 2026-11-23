// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// apb_agent.svh : APB side = fake processor (sequencer + driver + monitor)

class apb_item extends uvm_sequence_item;          // one APB read or write
  bit        write;
  bit [7:0]  addr;
  bit [31:0] data;
  `uvm_object_utils(apb_item)
  function new(string name = "apb_item"); super.new(name); endfunction
  function string convert2string();
    return $sformatf("%s addr=%02h data=%08h", write ? "WR" : "RD", addr, data);
  endfunction
endclass

class apb_driver extends uvm_driver #(apb_item);   // SETUP then ACCESS
  `uvm_component_utils(apb_driver)
  virtual apb_if vif;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_phase(uvm_phase phase);
    vif.psel <= 0; vif.penable <= 0; vif.pwrite <= 0; vif.paddr <= 0; vif.pwdata <= 0;
    wait (vif.presetn === 1'b1);
    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.pclk);                                   // SETUP
      vif.psel <= 1; vif.pwrite <= req.write; vif.paddr <= req.addr; vif.pwdata <= req.data;
      @(posedge vif.pclk);                                   // ACCESS
      vif.penable <= 1;
      do @(posedge vif.pclk); while (!vif.pready);           // transfer done
      if (!req.write) req.data = vif.prdata;                 // give read data back
      vif.psel <= 0; vif.penable <= 0;
      seq_item_port.item_done();
    end
  endtask
endclass

class apb_monitor extends uvm_monitor;             // records every APB transfer
  `uvm_component_utils(apb_monitor)
  virtual apb_if vif;
  uvm_analysis_port #(apb_item) ap;
  function new(string name, uvm_component parent); super.new(name, parent); ap = new("ap", this); endfunction
  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.pclk);
      if (vif.psel && vif.penable && vif.pready) begin
        apb_item it = apb_item::type_id::create("it");
        it.write = vif.pwrite;
        it.addr  = vif.paddr;
        it.data  = vif.pwrite ? vif.pwdata : vif.prdata;
        ap.write(it);
      end
    end
  endtask
endclass

class apb_agent extends uvm_agent;
  `uvm_component_utils(apb_agent)
  uvm_sequencer #(apb_item) sqr;
  apb_driver                drv;
  apb_monitor               mon;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function void build_phase(uvm_phase phase);
    virtual apb_if vif;
    sqr = uvm_sequencer#(apb_item)::type_id::create("sqr", this);
    drv = apb_driver::type_id::create("drv", this);
    mon = apb_monitor::type_id::create("mon", this);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", vif))
      `uvm_fatal("NOVIF", "apb_vif not set")
    drv.vif = vif;
    mon.vif = vif;
  endfunction
  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction
endclass
