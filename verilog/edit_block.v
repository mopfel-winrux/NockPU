`include "memory_unit.vh"
`include "memory_mux.vh"
`include "mem_traversal.vh"
`include "execute.vh"


module cell_block (
  input clk,
  input rst,
  output reg [7:0] cell_error,
  input [2:0] cell_start,  // wire to begin execution (mux_conroller from traversal)
  input [`memory_addr_width - 1:0] cell_address,
  input [`memory_data_width - 1:0] cell_data,
  input mem_ready,
  input [`memory_data_width - 1:0] read_data1,
  input [`memory_data_width - 1:0] read_data2,
  input [`memory_addr_width - 1:0] free_addr,
  output reg mem_execute,
  output reg [`memory_addr_width - 1:0] address1,
  output reg [`memory_addr_width - 1:0] address2,
  output reg [1:0] mem_func,
  output reg [`memory_data_width - 1:0] write_data,
  output wire finished
);

  reg [7:0] cell_debug_sig;
  // Interface with memory traversal
  reg [2:0] cell_start_ff;
  reg is_finished_reg;
  assign finished = is_finished_reg;

  // State Machine Stuff
  reg [3:0] state;
  parameter INIT        = 4'h0,
            PREP        = 4'h1,
            CHECK       = 4'h2,
            DONE        = 4'h3,
            CELL_OF_NIL = 4'h4;

  always @(posedge clk or negedge rst) begin
    if (!rst || (cell_start==`MUX_CELL && !(cell_start_ff==`MUX_CELL))) begin
      write_data <= 0;
      mem_execute<=0;
      address1 <=0;
      state <= INIT;
      cell_debug_sig <=0;
    end 
    else if (cell_start == `MUX_CELL) begin
      case (state)
        INIT: begin
          cell_debug_sig <= 1;
          state <= PREP;
        end

        PREP: begin
          $stop;
        end
      endcase
    end
  end
endmodule
 
