// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// spi_seq_lib.svh : scenarios played by the fake processor

class apb_base_seq extends uvm_sequence #(apb_item);   // register helpers
  `uvm_object_utils(apb_base_seq)
  spi_cfg cfg;
  function new(string name = "apb_base_seq"); super.new(name); endfunction

  task wr(bit [7:0] a, bit [31:0] d);
    apb_item it = apb_item::type_id::create("it");
    start_item(it); it.write = 1; it.addr = a; it.data = d; finish_item(it);
  endtask

  task rd(bit [7:0] a, output bit [31:0] d);
    apb_item it = apb_item::type_id::create("it");
    start_item(it); it.write = 0; it.addr = a; it.data = 0; finish_item(it);
    d = it.data;
  endtask

  task set_mode(bit [1:0] mode, int div);              // CLKDIV + CTRL (EN = 1)
    cfg.cpol = mode[1]; cfg.cpha = mode[0]; cfg.clkdiv = div;
    wr(ADDR_CLKDIV, div);
    wr(ADDR_CTRL, {29'b0, mode[0], mode[1], 1'b1});
  endtask

  task send(bit [7:0] bytes[$]);                       // send bytes, wait, read answers
    bit [31:0] st, d;
    foreach (bytes[i]) begin
      do rd(ADDR_STATUS, st); while (st[ST_TX_FULL]);
      wr(ADDR_TXDATA, bytes[i]);
    end
    do rd(ADDR_STATUS, st); while (st[ST_BUSY] || !st[ST_TX_EMPTY]);
    forever begin
      rd(ADDR_STATUS, st);
      if (st[ST_RX_EMPTY]) break;
      rd(ADDR_RXDATA, d);                              // checked by the scoreboard
    end
  endtask
endclass

class reg_seq extends apb_base_seq;                    // write / read back registers
  `uvm_object_utils(reg_seq)
  function new(string name = "reg_seq"); super.new(name); endfunction
  task body();
    bit [31:0] d;
    rd(ADDR_STATUS, d);
    if (d[4:0] != 5'b10100) `uvm_error("REG", $sformatf("STATUS after reset = %b", d[4:0]))
    repeat (10) begin
      wr(ADDR_CTRL,   $urandom & ~32'h1); rd(ADDR_CTRL, d);    // EN stays 0
      wr(ADDR_CLKDIV, $urandom);          rd(ADDR_CLKDIV, d);
      wr(ADDR_IRQ_EN, $urandom);          rd(ADDR_IRQ_EN, d);
    end
    wr(ADDR_CTRL, 0);
    wr(ADDR_IRQ_EN, 0);
  endtask
endclass

class random_seq extends apb_base_seq;                 // all modes x speeds, then random
  `uvm_object_utils(random_seq)
  int n = 30;
  function new(string name = "random_seq"); super.new(name); endfunction
  task body();
    bit [7:0] bytes[$];
    int       divs[3] = '{0, 2, 6};
    for (int m = 0; m < 4; m++)
      foreach (divs[k]) begin                          // 4 modes x 3 speeds
        set_mode(m, divs[k]);
        bytes = '{8'h00, 8'hFF, 8'($urandom)};
        send(bytes);
      end
    repeat (n) begin                                   // random traffic
      bytes.delete();
      repeat ($urandom_range(1, 8)) bytes.push_back(8'($urandom));
      set_mode($urandom_range(0, 3), $urandom_range(0, 7));
      send(bytes);
    end
  endtask
endclass

class irq_seq extends apb_base_seq;                    // TX_EMPTY and RX_AVAIL interrupts
  `uvm_object_utils(irq_seq)
  function new(string name = "irq_seq"); super.new(name); endfunction
  task body();
    virtual apb_if vif;
    bit [31:0]     d;
    if (!uvm_config_db#(virtual apb_if)::get(null, "", "apb_vif", vif)) `uvm_fatal("NOVIF", "apb_vif not set")
    wr(ADDR_IRQ_EN, 32'h1); @(posedge vif.pclk);       // TX FIFO empty -> irq = 1
    if (vif.irq !== 1) `uvm_error("IRQ", "TX_EMPTY irq not raised")
    wr(ADDR_IRQ_EN, 32'h2); @(posedge vif.pclk);       // RX empty -> irq = 0
    if (vif.irq !== 0) `uvm_error("IRQ", "irq should be 0 while RX is empty")
    set_mode(0, 1);
    wr(ADDR_TXDATA, 8'h5A);
    fork
      wait (vif.irq === 1);
      begin repeat (1000) @(posedge vif.pclk); `uvm_error("IRQ", "RX_AVAIL irq timeout") end
    join_any
    disable fork;
    rd(ADDR_RXDATA, d); @(posedge vif.pclk);           // read -> RX empty -> irq = 0
    if (vif.irq !== 0) `uvm_error("IRQ", "irq not cleared after RXDATA read")
    else               `uvm_info("IRQ", "RX_AVAIL irq raised and cleared", UVM_LOW)
    wr(ADDR_IRQ_EN, 0);
  endtask
endclass
