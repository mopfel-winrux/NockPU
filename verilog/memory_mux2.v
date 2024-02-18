/*
This module will allow a control signal to pick signals to control memory module
*/

`include "memory_unit.vh"
`include "memory_mux.vh"

module memory_mux(
  input [2:0] sel,
  input [1:0] mem_func_a, input [1:0] mem_func_b, input [1:0] mem_func_c, input [1:0] mem_func_d, input [1:0] mem_func_e, input [1:0] mem_func_f,
  input execute_a, input execute_b, input execute_c, input execute_d, input execute_e, input execute_f
  input [`memory_addr_width - 1:0] address1_a, input [`memory_addr_width - 1:0] address1_b, input [`memory_addr_width - 1:0] address1_c, input [`memory_addr_width - 1:0] address1_d, input [`memory_addr_width - 1:0] address1_e, input [`memory_addr_width - 1:0] address1_f,
  input [`memory_addr_width - 1:0] address2_a, input [`memory_addr_width - 1:0] address2_b, input [`memory_addr_width - 1:0] address2_c, input [`memory_addr_width - 1:0] address2_d, input [`memory_addr_width - 1:0] address2_e, input [`memory_addr_width - 1:0] address2_f,
  input [`memory_data_width - 1:0] write_data_a, input [`memory_data_width - 1:0] write_data_b, input [`memory_data_width - 1:0] write_data_c, input [`memory_data_width - 1:0] write_data_d, input [`memory_data_width - 1:0] write_data_e, input [`memory_data_width - 1:0] write_data_f,
  output reg [1:0] mem_func,
  output reg execute,
  output reg [`memory_addr_width - 1:0] address1,
  output reg [`memory_addr_width - 1:0] address2,
  output reg [`memory_data_width - 1:0] write_data
);

always @(*) begin
  case(sel)
    MUX_TRAVERSAL: begin
      mem_func = mem_func_a;
      execute = execute_a;
      address1 = address1_a;
      address2 = address2_a;
      write_data = write_data_a;
    end
    MUX_EXECUTE: begin
      mem_func = mem_func_b;
      execute = execute_b;
      address1 = address1_b;
      address2 = address2_b;
      write_data = write_data_b;
    end
    MUX_CELL: begin
      mem_func = mem_func_c;
      execute = execute_c;
      address1 = address1_c;
      address2 = address2_c;
      write_data = write_data_c;
    end
    MUX_INCR: begin
      mem_func = mem_func_d;
      execute = execute_d;
      address1 = address1_d;
      address2 = address2_d;
      write_data = write_data_d;
    end
    MUX_EQUAL: begin
      mem_func = mem_func_e;
      execute = execute_e;
      address1 = address1_e;
      address2 = address2_e;
      write_data = write_data_e;
    end
    MUX_EDIT: begin
      mem_func = mem_func_f;
      execute = execute_f;
      address1 = address1_f;
      address2 = address2_f;
      write_data = write_data_f;
    end
    default: begin // Default case can be used to handle unexpected values
      mem_func = 2'b00;
      execute = 0;
      address1 = 0;
      address2 = 0;
      write_data = 0;
    end
  endcase
end

endmodule

