// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// spi_scoreboard.svh : compares what the processor did with what happened on SPI

`uvm_analysis_imp_decl(_apb)
`uvm_analysis_imp_decl(_spi)

class spi_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(spi_scoreboard)
  uvm_analysis_imp_apb #(apb_item, spi_scoreboard) apb_in;
  uvm_analysis_imp_spi #(spi_item, spi_scoreboard) spi_in;

  bit [7:0]  exp_mosi[$];          // bytes written to TXDATA, not yet seen on MOSI
  bit [7:0]  exp_rx[$];            // sensor answers, not yet read from RXDATA
  bit [31:0] regs[bit [7:0]];      // last value written to CTRL / CLKDIV / IRQ_EN
  int        n_ok, n_err;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    apb_in = new("apb_in", this);
    spi_in = new("spi_in", this);
  endfunction

  function void chk(bit ok, string msg);
    if (ok) n_ok++;
    else begin n_err++; `uvm_error("SB", msg) end
  endfunction

  function void write_apb(apb_item t);
    bit [31:0] exp;
    if (t.write) begin
      case (t.addr)
        ADDR_TXDATA: exp_mosi.push_back(t.data[7:0]);
        ADDR_CTRL:   regs[t.addr] = t.data & 32'h07;
        ADDR_CLKDIV: regs[t.addr] = t.data & 32'hFF;
        ADDR_IRQ_EN: regs[t.addr] = t.data & 32'h03;
        default: ;
      endcase
    end else begin
      case (t.addr)
        ADDR_RXDATA: if (exp_rx.size()) begin
          exp = exp_rx.pop_front();
          chk(t.data == exp, $sformatf("RXDATA exp %02h got %02h", exp, t.data));
        end
        ADDR_CTRL, ADDR_CLKDIV, ADDR_IRQ_EN: begin
          exp = regs.exists(t.addr) ? regs[t.addr] : 0;
          chk(t.data == exp, $sformatf("reg %02h exp %0h got %0h", t.addr, exp, t.data));
        end
        default: ;
      endcase
    end
  endfunction

  function void write_spi(spi_item t);
    bit [7:0] exp;
    if (exp_mosi.size() == 0) begin chk(0, "SPI transfer without TXDATA write"); return; end
    exp = exp_mosi.pop_front();
    chk(t.mosi == exp, $sformatf("MOSI exp %02h got %02h (%s)", exp, t.mosi, t.convert2string()));
    exp_rx.push_back(t.miso);      // the answer must come back in RXDATA
  endfunction

  function void report_phase(uvm_phase phase);
    if (exp_mosi.size() || exp_rx.size())
      `uvm_error("SB", $sformatf("%0d MOSI / %0d RX bytes never checked", exp_mosi.size(), exp_rx.size()))
    `uvm_info("SB", $sformatf("%0d checks OK, %0d errors -> %s", n_ok, n_err, n_err ? "FAIL" : "PASS"), UVM_NONE)
  endfunction
endclass
