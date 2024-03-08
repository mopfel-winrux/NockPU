`include "memory_unit.vh"
`include "memory_mux.vh"
`include "mem_traversal.vh"
`include "execute.vh"


module edit_block (
  input clk,
  input rst,
  output reg [7:0] edit_error,
  input [2:0] edit_start,  // wire to begin execution (mux_conroller from traversal)
  input [`memory_addr_width - 1:0] edit_address,
  input [`memory_data_width - 1:0] edit_data,
  output reg [3:0] edit_return_sys_func,
  output reg [3:0] edit_return_state,
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

  reg [7:0] debug_sig;
  // Interface with memory traversal
  reg [2:0] edit_start_ff;
  reg is_finished_reg;
  assign finished = is_finished_reg;

  reg [`noun_width - 1:0] tree_addr;
  reg [`noun_width - 1:0] new_val;
  reg [`memory_data_width - 1:0] new_val_reg;
  reg [`noun_width - 1:0] target;
  reg new_val_tag;
  reg target_tag;

  // State Machine Stuff
  reg [3:0] state;
  parameter INIT                = 4'h0,
            READ_COMMAND        = 4'h1,
            PREP_TREE           = 4'h2,
            SLOT_CHECK          = 4'h3,
            SLOT_CHECK_INDIRECT = 4'h4,
            READ_INIT           = 4'h5,
            CELL_OF_NIL         = 4'h6,
            READ_TREE           = 4'h7,
            WRITE_ROOT          = 4'h8,
            DONE                = 4'h9,
            PAUSE               = 4'hA,
            ERROR               = 4'hF;

  always @(posedge clk) begin
    // Flip-flop to store the previous state of edit_start                        
    edit_start_ff <= edit_start;
  end
 
  always @(posedge clk or negedge rst) begin
    if (!rst || (edit_start==`MUX_EDIT && !(edit_start_ff==`MUX_EDIT))) begin
      write_data <= 0;
      mem_execute<=0;
      address1 <=0;
      state <= INIT;
      debug_sig <=0;
    end 
    else if (edit_start == `MUX_EDIT) begin
      case (state)
        INIT: begin
          address1 <= edit_data[`tel_start:`tel_end];
          mem_execute <= 1;
          mem_func <= `GET_CONTENTS;
          state <= READ_COMMAND;
        end

        READ_COMMAND: begin
          if (mem_ready) begin
            state <= PREP_TREE;
            tree_addr <= (read_data1[`hed_start:`hed_end]<<1) | 1;
            address1 <= read_data1[`tel_start:`tel_end];
            mem_execute <= 1;
            mem_func <= `GET_CONTENTS;
          end else begin
            mem_execute <= 0;
            mem_func <=0;
          end
        end

        PREP_TREE: begin
          if(tree_addr[`noun_width-1] == 1) begin
            state <= READ_INIT;
          end
          tree_addr <= tree_addr << 1;
        end
        
        READ_INIT: begin
          if (mem_ready) begin
            new_val_tag <= read_data1[`hed_tag];
            new_val <= read_data1[`hed_start:`hed_end];
            target_tag <= read_data1[`tel_tag];
            target <= read_data1[`tel_start:`tel_end];
            
            if(read_data1[`hed_tag] ==`CELL) begin
              address1 <= read_data1[`hed_start:`hed_end];
              mem_func <= `GET_CONTENTS;
              mem_execute <= 1;
              state <= SLOT_CHECK_INDIRECT;
            end else begin 
              state <= SLOT_CHECK;
              address1 <= read_data1[`tel_start:`tel_end];
              mem_func <= `GET_CONTENTS;
              mem_execute <= 1;
            end
          end else begin
            mem_execute <= 0;
            mem_func <=0;
          end
        end

        SLOT_CHECK_INDIRECT: begin
          if (mem_ready) begin
            new_val_reg <= read_data1;
            state <= SLOT_CHECK;
            address1 <= target[`tel_start:`tel_end];
            mem_func <= `GET_CONTENTS;
            mem_execute <= 1;
            if(read_data1[`tel_start:`tel_end] == `NIL 
            && read_data1[`tel_tag] == `ATOM
            && read_data1[`hed_tag] == `ATOM) begin
              new_val <= read_data1[`hed_start:`hed_end];
              new_val_tag <= read_data1[`hed_tag];
            end
          end else begin
            mem_execute <= 0;
            mem_func <=0;
          end
        end

        SLOT_CHECK: begin
          if (mem_ready) begin
            if ( tree_addr == 28'h8000000) begin
              mem_func <= `SET_CONTENTS;
              address1 <= address1;
              mem_execute <= 1;
              state <= READ_TREE;
              if(new_val_tag == `CELL) begin
                write_data <= new_val_reg;
              end else begin
                write_data <= {
                6'b000000,
                `ATOM,
                `ATOM,
                new_val,
                `NIL};
              end
            end else begin
              if (tree_addr[`noun_width-1] == 0) begin
                if(tree_addr == 28'h4000000) begin
                  mem_func <= `SET_CONTENTS;
                  address1 <= address1;
                  mem_execute <= 1;
                  write_data <= {
                    read_data1[`execute_bit],
                    5'b00000,
                    new_val_tag,
                    read_data1[`tel_tag],
                    new_val,
                    read_data1[`tel_start:`tel_end]};
                  state <= READ_TREE;
                end else if(read_data1[`hed_tag] == `CELL) begin
                  address1 <= read_data1[`hed_start:`hed_end];
                  mem_func <= `GET_CONTENTS;
                  mem_execute <= 1;
                  state <= SLOT_CHECK;
                end else begin
                  debug_sig <= 1;
                  state <= ERROR;
                end
              end else begin
                if(tree_addr == 28'hC000000) begin
                  mem_func <= `SET_CONTENTS;
                  address1 <= address1;
                  mem_execute <= 1;
                  write_data <= {
                    read_data1[`execute_bit],
                    5'b00000,
                    read_data1[`hed_tag],
                    new_val_tag,
                    read_data1[`hed_start:`hed_end],
                    new_val};
                  state <= READ_TREE;
                end else if(read_data1[`tel_tag] == `CELL) begin
                  address1 <= read_data1[`tel_start:`tel_end];
                  mem_func <= `GET_CONTENTS;
                  mem_execute <= 1;
                  state <= SLOT_CHECK;
                end else begin
                  debug_sig <= 2;
                  state <= ERROR;
                end
              end
              tree_addr <= tree_addr << 1;
            end
          end else begin
            mem_func <= 0;
            mem_execute <= 0;
          end
        end

        READ_TREE: begin
          if (mem_ready) begin
            mem_func <= `GET_CONTENTS;
            address1 <= target ;
            mem_execute <= 1;
            state <= WRITE_ROOT;
          end else begin
            mem_func <= 0;
            mem_execute <= 0;
          end
        end

        WRITE_ROOT: begin
          if (mem_ready) begin
            mem_func <= `SET_CONTENTS;
            address1 <= edit_address;
            mem_execute <= 1;
            write_data <= read_data1;
            state <= DONE;
          end else begin
            mem_func <= 0;
            mem_execute <= 0;
          end
        end

        DONE: begin
          if (mem_ready) begin
            edit_return_sys_func <= `SYS_FUNC_READ;
            edit_return_state <= `SYS_READ_INIT;
            is_finished_reg <= 1;
            state <= PAUSE;
          end else begin
            mem_func <= 0;
            mem_execute <= 0;
          end
        end
        PAUSE: begin
          is_finished_reg <=0;
          if (edit_start == `MUX_EDIT) state<= INIT;
        end

        ERROR: begin
          $stop;
        end
      endcase
    end
  end
endmodule
 
