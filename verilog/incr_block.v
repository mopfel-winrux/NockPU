`include "memory_unit.vh"
`include "memory_mux.vh"
`include "mem_traversal.vh"
`include "execute.vh"


module incr_block (
  input clk,
  input rst,
  output reg [7:0] incr_error,
  input [2:0] incr_start,  // wire to begin execution (mux_conroller from traversal)
  input [`memory_addr_width - 1:0] incr_address,
  input [`memory_data_width - 1:0] incr_data,
  output reg [3:0] incr_return_sys_func,
  output reg [3:0] incr_return_state,
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

  reg [7:0] incr_debug_sig;
  // Interface with memory traversal
  reg [2:0] incr_start_ff;
  reg is_finished_reg;
  assign finished = is_finished_reg;
  reg [`noun_width-1:0] write_value;

  // State Machine Stuff
  reg [3:0] state;
  parameter INIT        = 4'h0,
            WRITE       = 4'h1,
            WRITE_WAIT  = 4'h2,
            READ_TEL    = 4'h3,
            PAUSE       = 4'h4,
            INCR_ERROR  = 4'h5;

  always @(posedge clk) begin
    // Flip-flop to store the previous state of incr_start
    incr_start_ff <= incr_start;
  end

  always @(posedge clk or negedge rst) begin
    if (!rst || (incr_start==`MUX_INCR && !(incr_start_ff==`MUX_INCR))) begin
      write_data <= 0;
      mem_execute<=0;
      address1 <=0;
      state <= INIT;
      is_finished_reg <=0;
      incr_debug_sig <=0;
    end 
    else if (incr_start == `MUX_INCR) begin
      case (state)
        INIT: begin
          if(incr_data[`tel_tag] == `ATOM) begin
            write_value <= incr_data[`tel_start:`tel_end]+`noun_width'h1;
            state <= WRITE;
          end else begin
            address1 <= incr_data[`tel_start:`tel_end];
            mem_func <= `GET_CONTENTS;
            mem_execute <= 1;
            state <= READ_TEL;
          end
        end

        READ_TEL: begin
          if (mem_ready) begin
            if(read_data1[`tel_start:`tel_end] ==`NIL && read_data1[`tel_tag] == `ATOM && read_data1[`hed_tag] == `ATOM) begin
              write_value <= read_data1[`hed_start:`hed_end]+`noun_width'h1;
              state <= WRITE;
            end else begin
              //TODO Check for large atom
              state <= INCR_ERROR;
            end
          end else begin
            mem_func <= 0;
            mem_execute <= 0;
          end
        end

        WRITE: begin
          write_data <= {
            6'b000000,
            `ATOM,
            `ATOM,
            write_value,
            `NIL};
          address1 <= incr_address;
          mem_func <= `SET_CONTENTS;
          mem_execute <= 1;
          state <= WRITE_WAIT;
        end

        WRITE_WAIT: begin
          if (mem_ready) begin
            incr_return_sys_func <= `SYS_FUNC_READ;
            incr_return_state <= `SYS_READ_INIT;
            is_finished_reg <= 1;
            state <= PAUSE;
          end else begin
            mem_func <= 0;
            mem_execute <= 0;
          end
        end

        PAUSE: begin
          if (incr_start == `MUX_INCR) state<= INIT;
        end

        INCR_ERROR: begin
          $stop;
        end
      endcase
    end
  end
endmodule
 
