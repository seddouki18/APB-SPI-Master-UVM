// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// tb_pkg.sv : all UVM classes (include directory = tb/)
package tb_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import spi_pkg::*;

  `include "agents/apb/apb_agent.svh"
  `include "agents/spi/spi_agent.svh"
  `include "env/spi_scoreboard.svh"
  `include "env/spi_coverage.svh"
  `include "env/spi_env.svh"
  `include "spi_seq_lib.svh"
  `include "tests/spi_tests.svh"
endpackage
