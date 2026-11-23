// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// apb_spi_master_top.v : Verilog wrapper for Vivado Block Design (Add Module)
module apb_spi_master_top (
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 pclk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_APB, ASSOCIATED_RESET presetn" *)
  input  wire        pclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 presetn RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
  input  wire        presetn,
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PSEL" *)    input  wire        psel,
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PENABLE" *) input  wire        penable,
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PWRITE" *)  input  wire        pwrite,
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PADDR" *)   input  wire [31:0] paddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PWDATA" *)  input  wire [31:0] pwdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PRDATA" *)  output wire [31:0] prdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PREADY" *)  output wire        pready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:apb:1.0 S_APB PSLVERR" *) output wire        pslverr,
  output wire        sclk,
  output wire        mosi,
  output wire        cs_n,
  input  wire        miso,
  (* X_INTERFACE_INFO = "xilinx.com:signal:interrupt:1.0 irq INTERRUPT" *)
  (* X_INTERFACE_PARAMETER = "SENSITIVITY LEVEL_HIGH" *)
  output wire        irq
);

  apb_spi_master u_ip (
    .pclk(pclk), .presetn(presetn),
    .psel(psel), .penable(penable), .pwrite(pwrite),
    .paddr(paddr[7:0]),                 // the IP only decodes the low 8 bits
    .pwdata(pwdata), .prdata(prdata), .pready(pready), .pslverr(pslverr),
    .sclk(sclk), .mosi(mosi), .cs_n(cs_n), .miso(miso),
    .irq(irq));

endmodule
