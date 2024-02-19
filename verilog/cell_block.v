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

  reg write_value;

  // State Machine Stuff
  reg [3:0] state;
  parameter INIT        = 4'h0,
            WRITE       = 4'h1,
            WRITE_WAIT  = 4'h2,
            READ_TEL    = 4'h3;

  always @(posedge clk or negedge rst) begin
    if (!rst || (cell_start==`MUX_CELL && !(cell_start_ff==`MUX_CELL))) begin
      write_data <= 0;
      mem_execute <= 0;
      address1 <=0;
      state <= INIT;
      cell_debug_sig <=0;
    end 
    else if (cell_start == `MUX_CELL) begin
      case (state)
        INIT: begin
          cell_debug_sig <=1;
          if(cell_data[`tel_tag] == `ATOM) begin
            write_value <= `ATOM;
            state <= WRITE;
          end else begin
            address1 <= cell_data[`tel_start:`tel_end];
            mem_func <= `GET_CONTENTS;
            mem_execute <= 1;
            state <= READ_TEL;
          end
        end

        READ_TEL: begin
          if (mem_ready) begin
            if(read_data1[`tel_start:`tel_end] ==`NIL && read_data1[`tel_tag] == `ATOM && read_data1[`hed_tag] == `ATOM) begin
          cell_debug_sig <=2;
              write_value <= `ATOM;
            end else begin
          cell_debug_sig <=3;
              write_value <= `CELL;
            end
            state <= WRITE;
          end else begin
          cell_debug_sig <=4;
            mem_func <= 0;
            mem_execute <= 0;
          end
        end

        WRITE: begin
          write_data <= {
            6'b000000,
            `ATOM,
            `ATOM,
            27'h0,
            write_value,
            `NIL};
          address1 <= cell_address;
          mem_func <= `SET_CONTENTS;
          mem_execute <= 1;
          state <= WRITE_WAIT;
        end

        WRITE_WAIT: begin
          if (mem_ready) begin
            $stop;
          end else begin
            mem_func <= 0;
            mem_execute <= 0;
          end
        end
      endcase
    end
  end
endmodule
 
