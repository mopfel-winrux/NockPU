`include "memory_unit.vh"
module ram(
  input wire clock,
  input wire [`memory_addr_width - 1:0] address,
  input wire [`memory_data_width - 1:0] data,
  input wire wren,
  output reg [`memory_data_width - 1:0] q
);

  reg [`memory_data_width - 1:0] ram [1023:0];

  always @(posedge clock) begin
    if (wren) begin
      // On a write cycle, store the input data at the specified address.
      ram[address] <= data;
    end else begin
      // On a read cycle, output the data at the specified address.
      q <= ram[address];
    end
  end
endmodule

