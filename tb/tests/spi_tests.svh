// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// spi_tests.svh : base_test + reg_test, random_test, irq_test, all_test

class base_test extends uvm_test;
  `uvm_component_utils(base_test)
  spi_env env;
  spi_cfg cfg;
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  function void build_phase(uvm_phase phase);
    cfg = spi_cfg::type_id::create("cfg");
    uvm_config_db#(spi_cfg)::set(this, "*", "cfg", cfg);
    env = spi_env::type_id::create("env", this);
  endfunction
  task play(apb_base_seq s);                          // run one sequence on the APB agent
    s.cfg = cfg;
    s.start(env.apb.sqr);
  endtask
  virtual task run_seqs(); endtask
  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    run_seqs();
    phase.drop_objection(this);
  endtask
endclass

class reg_test extends base_test;
  `uvm_component_utils(reg_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_seqs(); play(reg_seq::type_id::create("reg")); endtask
endclass

class random_test extends base_test;
  `uvm_component_utils(random_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_seqs(); play(random_seq::type_id::create("rand")); endtask
endclass

class irq_test extends base_test;
  `uvm_component_utils(irq_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_seqs(); play(irq_seq::type_id::create("irq")); endtask
endclass

class all_test extends base_test;                     // default test: everything
  `uvm_component_utils(all_test)
  function new(string name, uvm_component parent); super.new(name, parent); endfunction
  task run_seqs();
    play(reg_seq::type_id::create("reg"));
    play(irq_seq::type_id::create("irq"));
    play(random_seq::type_id::create("rand"));
  endtask
endclass
