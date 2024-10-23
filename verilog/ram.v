`include "memory_unit.vh"
module ram(
  input wire clock,
  input wire [`memory_addr_width - 1:0] address1,
  input wire [`memory_addr_width - 1:0] address2,
  input wire [`memory_data_width - 1:0] data,
  input wire wren,
  output reg [`memory_data_width - 1:0] q1,
  output reg [`memory_data_width - 1:0] q2
);

  reg [`memory_data_width - 1:0] ram [`memory_addr_width'h7FF:0];

  always @(posedge clock) begin
    if (wren) begin
      // On a write cycle, store the input data at the specified address.
      ram[address1] <= data;
      q2 <= ram[address2];
    end else begin
      // On a read cycle, output the data at the specified address.
      q1 <= ram[address1];
      q2 <= ram[address2];
    end
  end
endmodule

