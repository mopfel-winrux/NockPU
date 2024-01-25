`include "memory_unit.vh"
`include "mem_traversal.vh"
`include "execute.vh"


module mem_traversal(
  input power, clk, rst,
  input [`memory_addr_width - 1:0] start_addr,
  input execute,
  output wire finished,
  input mem_ready,
  input [`memory_data_width - 1:0] read_data,
  input [`memory_addr_width - 1:0] free_addr,
  output reg mem_execute,
  output reg [`memory_addr_width - 1:0] address,
  output reg [1:0] mem_func,
  output reg [`memory_data_width - 1:0] write_data,
  input [7:0] error,
  output reg [`memory_addr_width - 1:0] execute_address,
  output reg [`tag_width - 1:0] execute_tag,
  output reg [`memory_data_width - 1:0] execute_data,
  output reg mux_controller,
  input execute_finished,
  input [3:0] execute_return_sys_func,
  input [3:0] execute_return_state
);
  // finish signal
  reg is_finished_reg;
  assign finished = is_finished_reg;

  // Internal registers needed
  reg [3:0] sys_func;
  reg [3:0] state;
  reg [`tag_width - 1:0] mem_tag;
  reg [`noun_width - 1:0] hed, tel;
  reg [`memory_addr_width - 1:0] mem_addr;
  reg [`memory_data_width - 1:0] mem_data;
  reg [7:0] debug_sig;
  wire is_running;
  assign is_running = !finished && execute;

  // General Purpose Regsiters
  reg [`memory_addr_width - 1:0] address_gp;
  reg [`memory_data_width - 1:0] mem_data_gp;
  reg [`noun_width - 1:0] noun_gp;
  reg [`noun_tag_width - 1:0] noun_tag_gp;

  // Traversal Registers needed
  reg [`noun_width - 1:0] trav_P;
  reg [`noun_width - 1:0] trav_B;

  // Write Registers needed
  reg [3:0] write_return_sys_func;
  reg [3:0] write_return_state;

  //System Level Functions
  parameter SYS_FUNC_READ     = 4'h0,
            SYS_FUNC_WRITE    = 4'h1,
            SYS_FUNC_TRAVERSE = 4'h2,
            SYS_FUNC_EXECUTE  = 4'h3;

  // Read States
  parameter SYS_READ_INIT   = 4'h0,
            SYS_READ_WAIT   = 4'h1,
            SYS_READ_DECODE = 4'h2;

  // Write States
  parameter SYS_WRITE_INIT = 4'h0,
            SYS_WRITE_WAIT = 4'h1;

  // Traverse States
  parameter SYS_TRAVERSE_INIT  = 4'h0,
            SYS_TRAVERSE_PUSH  = 4'h1,
            SYS_TRAVERSE_POP   = 4'h2,
            SYS_TRAVERSE_TEL   = 4'h3;

  // Execute States
  parameter SYS_EXECUTE_INIT       = 4'h0,
            SYS_EXECUTE_READ_HED   = 4'h1,
            SYS_EXECUTE_READ_TEL   = 4'h2,
            SYS_EXECUTE_WAIT       = 4'h3,
            SYS_EXECUTE_DECODE     = 4'h4,
            SYS_EXECUTE_READ_ADDR  = 4'h5,
            SYS_EXECUTE_ERROR      = 4'hF;

  always@(posedge clk or negedge rst) begin
    if(!rst) begin
      sys_func <= SYS_FUNC_READ;
      state <= SYS_READ_INIT;
      mem_addr <= start_addr;
      trav_B <= `NIL;
      trav_P <= start_addr;
      mem_execute <= 0;
      debug_sig <= 0;
      mux_controller <= 0;
    end
    else if (execute) begin
      case (sys_func)
        SYS_FUNC_EXECUTE: begin
          case(state)
            SYS_EXECUTE_INIT: begin
              if(read_data[`hed_tag] == `CELL) begin
                //Read head and check if it is execute
                mem_data_gp <= read_data;
                address <= read_data[`hed_start:`hed_end];
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                state <= SYS_EXECUTE_READ_HED;
              end else if (read_data[`tel_tag] == `CELL) begin
                //Read head and check if it is execute
                mem_data_gp <= read_data;
                address <= read_data[`tel_start:`tel_end];
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                state <= SYS_EXECUTE_READ_TEL;
              end
              else begin
                address <= mem_data[`tel_start:`tel_end];
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                execute_address <= mem_addr;
                execute_data <= mem_data;
                execute_tag <= mem_tag;
                mux_controller <= 1;
                debug_sig <= 3;
                state <= SYS_EXECUTE_WAIT;
              end
            end

            SYS_EXECUTE_READ_HED: begin
              if(mem_ready) begin
                if(read_data[`execute_bit]==1) begin
                  // If we need to execute the hed
                  sys_func <= SYS_FUNC_TRAVERSE;
                  state <= SYS_TRAVERSE_INIT;
                end
                else if (mem_data_gp[`tel_tag]==`CELL) begin
                  // if the tel of the parent is a cell
                  mem_data_gp <= read_data;
                  address <= mem_data_gp[`tel_start:`tel_end];
                  mem_func <= `GET_CONTENTS;
                  mem_execute <= 1;
                  state <= SYS_EXECUTE_READ_TEL;
                end
                else begin
                  // if not executing hed and parent then pass data to
                  // the execute block
                  address <= mem_data_gp[`tel_start:`tel_end];
                  mem_func <= `GET_CONTENTS;
                  mem_execute <= 1;
                  execute_address <= mem_addr;
                  execute_data <= mem_data;
                  execute_tag <= mem_tag;
                  mux_controller <= 1;
                  debug_sig <= 2;
                  state <= SYS_EXECUTE_WAIT;
                end
              end
              else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            SYS_EXECUTE_READ_TEL: begin
              if(mem_ready) begin
                if(read_data[`execute_bit]==1) begin
                  // If we need to execute the tel
                  sys_func <= SYS_FUNC_TRAVERSE;
                  state <= SYS_TRAVERSE_INIT;
                end
                else begin
                  // if not executing hed and parent then pass data to
                  // the execute block
                  if(trav_B != `NIL) mem_addr <= trav_B;
                  execute_address <= mem_addr;
                  execute_data <= {mem_tag,hed,tel};
                  execute_tag <= mem_tag;
                  mux_controller <= 1;
                  state <= SYS_EXECUTE_WAIT;
                end
              end
              else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
           end

           SYS_EXECUTE_READ_ADDR: begin
             if(mem_ready) begin
               if(trav_B != `NIL) mem_addr <= trav_B;
               execute_address <= mem_addr;
               execute_data <= {mem_tag,hed,tel};//read_data;
               execute_tag <= mem_tag;//read_data[`tag_start:`tag_end];
               mux_controller <= 1;
               state <= SYS_EXECUTE_WAIT;
             end else begin
               mem_func <= 0;
               mem_execute <= 0;
             end
           end

           SYS_EXECUTE_WAIT: begin
             if(execute_finished) begin
               sys_func = execute_return_sys_func;
               state = execute_return_state;
               mux_controller <= 0;
             end
           end

           SYS_EXECUTE_ERROR: begin
             state <= SYS_EXECUTE_ERROR;
             is_finished_reg <= 1;
           end
          endcase
        end

        SYS_FUNC_READ: begin
          case(state)
            SYS_READ_INIT: begin
              // mem_addr is only max when you reach the end and use 
              // trav_b's inital value
              if(mem_addr == 1023) begin 
                is_finished_reg <= 1;
              end
              else begin
                is_finished_reg <= 0;
                address <= mem_addr;
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                state <= SYS_READ_WAIT;
              end
            end

            SYS_READ_WAIT: begin
              if(mem_ready) begin
                mem_data <= read_data;
                mem_tag <= read_data[`tag_start:`tag_end];
                hed <= read_data[`hed_start:`hed_end];
                tel <= read_data[`tel_start:`tel_end];
                if(read_data[`execute_bit] == 1) begin
                  if (read_data[`tel_start:`tel_end] == `NIL) begin
                    sys_func <= SYS_FUNC_TRAVERSE;
                    state <= SYS_TRAVERSE_INIT;
                  end else begin
                    sys_func <= SYS_FUNC_EXECUTE;
                    state <= SYS_EXECUTE_INIT;
                  end
                end else begin
                 sys_func <= SYS_FUNC_TRAVERSE;
                 state <= SYS_TRAVERSE_INIT;
                end
              end
              else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end
          endcase
        end

        SYS_FUNC_WRITE: begin
          case(state)
            SYS_WRITE_INIT: begin
              address <= mem_addr;
              write_data <= {mem_tag, hed, tel};
              mem_func <= `SET_CONTENTS;
              mem_execute <= 1;
              state <= SYS_WRITE_WAIT;
            end

            SYS_WRITE_WAIT: begin
              if(mem_ready) begin
                  sys_func <= write_return_sys_func;
                  state <= write_return_state;
              end
              else begin
                address <= 0;
                write_data <= 0;
                mem_func <= 0;
                mem_execute <= 0;
              end
            end
          endcase
        end

        SYS_FUNC_TRAVERSE: begin
          case(state)
            SYS_TRAVERSE_INIT: begin
                case(mem_tag[1:0])
                  `CELL_CELL: begin
                     // if the hed cell hasn't been visited we push into it
                     if(mem_tag[3:2] == 2'b00) begin 
                       // Verified
                       // Set the command after write to traverse the hed
                       write_return_sys_func <= SYS_FUNC_TRAVERSE;
                       write_return_state <= SYS_TRAVERSE_PUSH;
                       //set tag to visited hed
                       mem_tag[3] <= 1;
                       //Store pointer to previous value in B
                       trav_P <= hed;
                       hed <= trav_B;
                       trav_B <= trav_P;
                       //Write Data
                       sys_func <= SYS_FUNC_WRITE;
                       state <= SYS_WRITE_INIT;
                     end
                     else if(mem_tag[3:2] == 2'b10) begin // if hed was visited and tel wasnt
                       // Verified
                       // Set the command after write to traverse the tel
                       write_return_sys_func <= SYS_FUNC_TRAVERSE;
                       write_return_state <= SYS_TRAVERSE_PUSH;
                       //pop the hed
                       trav_B <= hed;
                       trav_P <= trav_B;
                       hed <= trav_P;
                       //Wait for a clock cycle to push the tel
                       state <= SYS_TRAVERSE_TEL;
                     end
                     else if(mem_tag[3:2] == 2'b11) begin // if both were visited
                       // Set the command after write to pop
                       if(mem_tag[7] == 1) begin // If we still need to execute
                         write_return_sys_func <= SYS_FUNC_EXECUTE;
                         write_return_state <= SYS_EXECUTE_INIT;
                       end else begin
                         write_return_sys_func <= SYS_FUNC_TRAVERSE;
                         write_return_state <= SYS_TRAVERSE_POP;
                       end
                       mem_tag[3:2] <= 2'b00;
                       trav_B <= tel;
                       trav_P <= trav_B;
                       tel <= trav_P;
                       //Write Data
                       sys_func <= SYS_FUNC_WRITE;
                       state <= SYS_WRITE_INIT;
                    end
                  end

                  `ATOM_ATOM: begin
                    // Pop
                    mem_addr <= trav_B;
                    sys_func <= SYS_FUNC_READ;
                    state <= SYS_READ_INIT;
                  end
                  
                  `ATOM_CELL: begin
                    if(mem_tag[2] == 1'b0) begin // if both were visited
                      // Set the command after write to traverse the tel
                      write_return_sys_func <= SYS_FUNC_TRAVERSE;
                      write_return_state <= SYS_TRAVERSE_PUSH;
                      //set tag to visited tel
                      mem_tag[2] <= 1;
                      //Store pointer to previous value in B
                      trav_P <= tel;
                      tel <= trav_B;
                      trav_B <= trav_P;
                      //Write Data
                      sys_func <= SYS_FUNC_WRITE;
                      state <= SYS_WRITE_INIT;
                    end
                    else begin
                      debug_sig <= 2;
                      // Set the command after write to pop
                      if(mem_tag[7] == 1) begin // If we still need to execute
                        write_return_sys_func <= SYS_FUNC_EXECUTE;
                        write_return_state <= SYS_EXECUTE_INIT;
                      end else begin
                        write_return_sys_func <= SYS_FUNC_TRAVERSE;
                        write_return_state <= SYS_TRAVERSE_POP;
                      end
                      mem_tag[3:2] <= 2'b00;
                      trav_B <= tel;
                      trav_P <= trav_B;
                      tel <= trav_P;
                      //Write Data
                      sys_func <= SYS_FUNC_WRITE;
                      state <= SYS_WRITE_INIT;
                    end
                  end
                  `CELL_ATOM: begin
                    // if the hed cell hasn't been visited we push into it
                    if(mem_tag[3] == 0) begin 
                      // Set the command after write to traverse the hed
                      write_return_sys_func <= SYS_FUNC_TRAVERSE;
                      write_return_state <= SYS_TRAVERSE_PUSH;
                      //set tag to visited hed
                      mem_tag[3] <= 1;
                      //Store pointer to previous value in B
                      trav_P <= hed;
                      hed <= trav_B;
                      trav_B <= trav_P;
                      //Write Data
                      sys_func <= SYS_FUNC_WRITE;
                      state <= SYS_WRITE_INIT;
                    end
                    else begin
                      // Set the command after write to pop
                      if(mem_tag[7] == 1) begin // If we still need to execute
                        write_return_sys_func <= SYS_FUNC_EXECUTE;
                        write_return_state <= SYS_EXECUTE_INIT;
                      end else begin
                        write_return_sys_func <= SYS_FUNC_TRAVERSE;
                        write_return_state <= SYS_TRAVERSE_POP;
                      end
                      mem_tag[3:2] <= 2'b00;
                      trav_B <= hed;
                      trav_P <= trav_B;
                      hed <= trav_P;
                      //Write Data
                      sys_func <= SYS_FUNC_WRITE;
                      state <= SYS_WRITE_INIT;
                    end
                  end
                endcase
            end
            SYS_TRAVERSE_PUSH: begin
              mem_addr <= trav_P;
              sys_func <= SYS_FUNC_READ;
              state <= SYS_READ_INIT;
            end

            SYS_TRAVERSE_POP: begin
              mem_addr <= trav_B;
              sys_func <= SYS_FUNC_READ;
              state <= SYS_READ_INIT;
            end

            SYS_TRAVERSE_TEL: begin
              //set tag to visited tel
              mem_tag[2] <= 1;
              //Store pointer to previous value in B
              trav_P <= tel;
              tel <= trav_B;
              trav_B <= trav_P;
              //Write Data
              sys_func <= SYS_FUNC_WRITE;
              state <= SYS_WRITE_INIT;
            end
          endcase
        end

      endcase
    end
  end

endmodule
