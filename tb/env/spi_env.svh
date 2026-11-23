// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// spi_env.svh : 2 agents + scoreboard + coverage

class spi_env extends uvm_env;
  `uvm_component_utils(spi_env)
  apb_agent      apb;
  spi_agent      spi;
  spi_scoreboard sb;
  spi_coverage   cov;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function void build_phase(uvm_phase phase);
    apb = apb_agent::type_id::create("apb", this);
    spi = spi_agent::type_id::create("spi", this);
    sb  = spi_scoreboard::type_id::create("sb", this);
    cov = spi_coverage::type_id::create("cov", this);
  endfunction
  function void connect_phase(uvm_phase phase);
    apb.mon.ap.connect(sb.apb_in);
    spi.mon.ap.connect(sb.spi_in);
    spi.mon.ap.connect(cov.analysis_export);
  endfunction
endclass
