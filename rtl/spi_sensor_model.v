// Copyright (c) 2026 Nacereddine Seddouki. All rights reserved.
// spi_sensor_model.v : fake SPI sensor (mode 0)
// Byte 1 = register address, byte 2 = answer: 0x0F -> 0x33 (WHO_AM_I), 0x20 -> temperature
module spi_sensor_model (
  input  wire clk, rst_n,          // same clock as the SPI master (PCLK)
  input  wire sclk, mosi, cs_n,
  output wire miso
);
  reg       sclk_d;
  reg [2:0] cnt;
  reg [6:0] rx;
  reg [7:0] tx, addr, temp;
  wire      rise = sclk & ~sclk_d;

  assign miso = tx[7];

  always @(posedge clk or negedge rst_n)
    if (!rst_n) begin
      sclk_d <= 0; cnt <= 0; rx <= 0; tx <= 0; addr <= 0; temp <= 8'd25;
    end else begin
      sclk_d <= sclk;
      if (cs_n) begin                          // between bytes: prepare the answer
        cnt <= 0;
        tx  <= (addr == 8'h0F) ? 8'h33 : (addr == 8'h20) ? temp : 8'h00;
      end else if (rise) begin                 // each SCLK rising edge
        rx  <= {rx[5:0], mosi};                // read MOSI
        tx  <= {tx[6:0], 1'b0};                // next bit on MISO
        cnt <= cnt + 1'b1;
        if (cnt == 3'd7) begin                 // byte complete
          addr <= {rx, mosi};
          if (addr == 8'h20) temp <= temp + 1'b1;
        end
      end
    end
endmodule
