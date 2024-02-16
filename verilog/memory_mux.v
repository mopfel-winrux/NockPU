/*
This module will allow a control signal to pick signals to control memory module
*/

`include "memory_unit.vh"

module memory_mux(
  input [1:0] mem_func_a, input [1:0] mem_func_b,
  input execute_a, input execute_b,
  input [`memory_addr_width - 1:0] address1_a, input [`memory_addr_width - 1:0] address2_a,
  input [`memory_addr_width - 1:0] address1_b, input [`memory_addr_width - 1:0] address2_b,
  input [`memory_data_width - 1:0] write_data_a, input [`memory_data_width - 1:0] write_data_b,
  input sel,
  output [1:0] mem_func,
  output execute,
  output [`memory_addr_width - 1:0] address1,
  output [`memory_addr_width - 1:0] address2,
  output [`memory_data_width - 1:0] write_data
);

  assign mem_func     = sel ? mem_func_b    : mem_func_a;
  assign execute      = sel ? execute_b     : execute_a;
  assign address1     = sel ? address1_b    : address1_a;
  assign address2     = sel ? address2_b    : address2_a;
  assign write_data   = sel ? write_data_b  : write_data_a;

endmodule
