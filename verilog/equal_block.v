`include "memory_unit.vh"
`include "memory_mux.vh"
`include "mem_traversal.vh"
`include "execute.vh"


module equal_block (
  input clk,
  input rst,
  output reg [7:0] equal_error,
  input [2:0] equal_start,  // wire to begin execution (mux_conroller from traversal)
  input [`memory_addr_width - 1:0] equal_address,
  input [`memory_data_width - 1:0] equal_data,
  output reg [3:0] equal_return_sys_func,
  output reg [3:0] equal_return_state,
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
  reg [2:0] equal_start_ff;
  reg is_finished_reg;
  assign finished = is_finished_reg;
  reg [`noun_width-1:0] write_value;

  // Memory Registers
  reg [`memory_data_width - 1:0] read_data1_reg;
  reg [`memory_data_width - 1:0] read_data2_reg;
  reg [`memory_addr_width - 1:0] mem_addr1;
  reg [`memory_addr_width - 1:0] mem_addr2;
  reg [`noun_width - 1:0] hed1, tel1;
  reg [`noun_width - 1:0] hed2, tel2;

  // Traversal Registers needed
  reg [`noun_width - 1:0] trav1_P;
  reg [`noun_width - 1:0] trav1_B;

  reg [`noun_width - 1:0] trav2_P;
  reg [`noun_width - 1:0] trav2_B;

  // Write Registers needed
  reg [3:0] write_return_func;
  reg [3:0] write_return_state;

  // State Machine Stuff
  reg [3:0] func;
  reg [3:0] state;

  //System Level Functions
  parameter FUNC_INIT     = 4'h0,
            FUNC_READ     = 4'h1,
            FUNC_WRITE    = 4'h2,
            FUNC_TRAVERSE = 4'h3,
            FUNC_RETURN   = 4'h5;

  // Init States
  parameter INIT_INIT       = 4'h0,
            INIT_READ_ROOT  = 4'h1,
            INIT_DECODE     = 4'h2;

  // Read States
  parameter READ_INIT   = 4'h0,
            READ_WAIT   = 4'h1,
            READ_DECODE = 4'h2;

  // Write States
  parameter WRITE_INIT = 4'h0,
            WRITE_2    = 4'h1,
            WRITE_WAIT = 4'h2;

  // Traverse States
  parameter TRAVERSE_INIT  = 4'h0,
            TRAVERSE_PUSH  = 4'h1,
            TRAVERSE_POP   = 4'h2,
            TRAVERSE_TEL   = 4'h3;

  // Return States
  parameter RETURN_INIT       = 4'h0,
            RETURN_WAIT       = 4'h1,
            RETURN_PAUSE      = 4'h2;


  always @(posedge clk) begin
    // Flip-flop to store the previous state of equal_start
    equal_start_ff <= equal_start;
  end

  always @(posedge clk or negedge rst) begin
    if (!rst || (equal_start==`MUX_EQUAL && !(equal_start_ff==`MUX_EQUAL))) begin
      write_data <= 0;
      mem_execute<=0;
      address1 <=0;
      trav1_B <= `NIL;
      trav2_B <= `NIL;
      state <= INIT_INIT;
      func <= FUNC_INIT;
      is_finished_reg <=0;
      debug_sig <=0;
    end 
    else if (equal_start == `MUX_EQUAL) begin
      case (func)
        FUNC_INIT: begin
          case (state)
            INIT_INIT: begin
              mem_func <= `GET_CONTENTS;
              mem_execute <=1;
              address1 <= equal_data[`tel_start:`tel_end];
              state <= INIT_READ_ROOT;
            end

            INIT_READ_ROOT: begin
              if (mem_ready) begin
                if(read_data1[`hed_tag] != read_data1[`tel_tag]) begin
                  write_value <= `NO;
                  func <= FUNC_RETURN;
                  state <= RETURN_INIT;
                end
                else begin
                  address1 <= read_data1[`hed_start:`hed_end];
                  address2 <= read_data1[`tel_start:`tel_end];
                  trav1_P <= read_data1[`hed_start:`hed_end];
                  trav2_P <= read_data1[`tel_start:`tel_end];
                  mem_func <= `GET_CONTENTS;
                  mem_execute <=1;
                  state <= READ_DECODE;
                  func <= FUNC_READ;
                end
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end
          endcase
        end

        FUNC_READ: begin
          case(state)
            READ_INIT: begin
              // mem_addr is only max when you reach the end and use 
              // trav_b's inital value
              if(mem_addr1 == 1023) begin 
                write_value <= `YES;
                func <= FUNC_RETURN;
                state <= RETURN_INIT;
              end
              else begin
                is_finished_reg <= 0;
                address1 <= mem_addr1;
                address2 <= mem_addr2;
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                state <= READ_WAIT;
              end
            end

            READ_WAIT: begin
              if (mem_ready) begin
                read_data1_reg <= read_data1;
                read_data2_reg <= read_data2;
                hed1 <= read_data1[`hed_start:`hed_end];
                tel1 <= read_data1[`tel_start:`tel_end];
                hed2 <= read_data2[`hed_start:`hed_end];
                tel2 <= read_data2[`tel_start:`tel_end];
                state <= READ_DECODE;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            READ_DECODE: begin
              if (mem_ready) begin
                read_data1_reg <= read_data1;
                read_data2_reg <= read_data2;
                hed1 <= read_data1[`hed_start:`hed_end];
                tel1 <= read_data1[`tel_start:`tel_end];
                hed2 <= read_data2[`hed_start:`hed_end];
                tel2 <= read_data2[`tel_start:`tel_end];
                // If tags aren't equal then the subtrees arent equal
                if(read_data1[`hed_tag:`tel_tag] 
                != read_data2[`hed_tag:`tel_tag]) begin
                  debug_sig <=2;
                  write_value <= `NO;
                  func <= FUNC_RETURN;
                  state <= RETURN_INIT;
                end
                else begin
                  // If the data is equal we just pop up the tree
                  if(read_data1[`hed_start:`tel_end]
                  == read_data2[`hed_start:`tel_end]) begin
                    if(trav1_B != `NIL) mem_addr1 <= trav1_B;
                    if(trav2_B != `NIL) mem_addr2 <= trav2_B;
                    func <= FUNC_TRAVERSE;
                    state <= TRAVERSE_POP;
                  end else begin
                    case (read_data1[`hed_tag:`tel_tag])
                      `ATOM_ATOM: begin
                        debug_sig <=3;
                        //if two atoms arent equal the whole thing isnt equal
                        write_value <= `NO;
                        func <= FUNC_RETURN;
                        state <= RETURN_INIT;
                      end

                      `ATOM_CELL: begin
                        if(read_data1[`hed_start:`hed_end] 
                        != read_data2[`hed_start:`hed_end]) begin
                        debug_sig <=4;
                        write_value <= `NO;
                        func <= FUNC_RETURN;
                        state <= RETURN_INIT;
                      end else begin
                        func <= FUNC_TRAVERSE;
                        state <= TRAVERSE_INIT;
                      end
                    end

                    `CELL_ATOM: begin
                      if(read_data1[`tel_start:`tel_end] 
                      != read_data2[`tel_start:`tel_end]) begin
                        debug_sig <=5;
                        write_value <= `NO;
                        func <= FUNC_RETURN;
                        state <= RETURN_INIT;
                      end else begin
                        func <= FUNC_TRAVERSE;
                        state <= TRAVERSE_INIT;
                      end
                    end

                    `CELL_CELL: begin
                      func <= FUNC_TRAVERSE;
                      state <= TRAVERSE_INIT;
                    end
                  endcase
                end
              end
            end else begin
              mem_func <= 0;
              mem_execute <= 0;
            end
          end
        endcase
      end

      FUNC_WRITE: begin
        case(state)
          WRITE_INIT: begin
            address1 <= mem_addr1;
            write_data <= {read_data1_reg[`tag_start:`tag_end], hed1,tel1};
            mem_func <= `SET_CONTENTS;
            mem_execute <= 1;
            state <= WRITE_2;
          end

          WRITE_2: begin
            if (mem_ready) begin
              address1 <= mem_addr2;
              write_data <= {read_data2_reg[`tag_start:`tag_end], hed2,tel2};
              mem_func <= `SET_CONTENTS;
              mem_execute <= 1;
              state <= WRITE_WAIT;
            end else begin
              mem_func <= 0;
              mem_execute <= 0;
            end
          end

          WRITE_WAIT: begin
            if (mem_ready) begin
              func <= write_return_func;
              state <= write_return_state;
            end else begin
              address1 <=mem_addr1;
              address2 <=mem_addr2;
              write_data <=0;
              mem_func <= 0;
              mem_execute <= 0;
            end
          end
        endcase
        end

        FUNC_TRAVERSE: begin
          case(state)
            // To enter traverse_init we already know that the tags are equal
            TRAVERSE_INIT: begin
              case(read_data1_reg[`hed_tag:`tel_tag]) 
                `CELL_CELL: begin
                   debug_sig <=1;
                   // if the hed cell hasn't been visited we push into it
                   if(read_data1_reg[`hed_trav:`tel_trav] == 2'b00) begin 
                     // Verified
                     // Set the command after write to traverse the hed
                     write_return_func <= FUNC_TRAVERSE;
                     write_return_state <= TRAVERSE_PUSH;
                     //set tag to visited hed
                     read_data1_reg[`hed_trav] <= 1;
                     read_data2_reg[`hed_trav] <= 1;
                     //Store pointer to previous value in B
                     trav1_P <= hed1;
                     hed1 <= trav1_B;
                     trav1_B <= trav1_P;
                     trav2_P <= hed2;
                     hed2 <= trav2_B;
                     trav2_B <= trav2_P;


                     //Write Data
                     func <= FUNC_WRITE;
                     state <= WRITE_INIT;
                   end
                   else if(read_data1_reg[`hed_trav:`tel_trav]  == 2'b10) begin // if hed was visited and tel wasnt
                     // Verified
                     // Set the command after write to traverse the tel
                     write_return_func <= FUNC_TRAVERSE;
                     write_return_state <= TRAVERSE_PUSH;
                     //pop the hed
                     trav1_B <= hed1;
                     trav1_P <= trav1_B;
                     hed1 <= trav1_P;
                     trav2_B <= hed2;
                     trav2_P <= trav2_B;
                     hed2 <= trav2_P;
                     //Wait for a clock cycle to push the tel
                     state <= TRAVERSE_TEL;
                   end
                   else if(read_data1_reg[`hed_trav:`tel_trav] == 2'b11) begin // if both were visited
                     write_return_func <= FUNC_TRAVERSE;
                     write_return_state <= TRAVERSE_POP;
                     read_data1_reg[`hed_trav:`tel_trav] <= 2'b00;
                     read_data2_reg[`hed_trav:`tel_trav] <= 2'b00;

                     trav1_B <= tel1;
                     trav1_P <= trav1_B;
                     tel1 <= trav1_P;
                     trav2_B <= tel2;
                     trav2_P <= trav2_B;
                     tel2 <= trav2_P;
                     //Write Data
                     func <= FUNC_WRITE;
                     state <= WRITE_INIT;
                  end
                end

                `ATOM_ATOM: begin
                  // Pop
                  mem_addr1 <= trav1_B;
                  mem_addr2 <= trav2_B;
                  func <= FUNC_READ;
                  state <= READ_INIT;
                end
                
                `ATOM_CELL: begin
                  // if cell is not execute
                  if(read_data1_reg[`tel_trav] == 1'b0) begin 
                    // if both were visited
                    // Set the command after write to traverse the tel
                    write_return_func <= FUNC_TRAVERSE;
                    write_return_state <= TRAVERSE_PUSH;
                    //set tag to visited tel
                    read_data1_reg[`tel_trav] <= 1;
                    read_data2_reg[`tel_trav] <= 1;
                    //Store pointer to previous value in B
                    trav1_P <= tel1;
                    tel1 <= trav1_B;
                    trav1_B <= trav1_P;
                    trav2_P <= tel2;
                    tel2 <= trav2_B;
                    trav2_B <= trav2_P;
                    //Write Data
                    func <= FUNC_WRITE;
                    state <= WRITE_INIT;
                  end
                  else begin
                    // Set the command after write to pop
                    write_return_func <= FUNC_TRAVERSE;
                    write_return_state <= TRAVERSE_POP;
                    read_data1_reg[`tel_trav] <= 0;
                    read_data2_reg[`tel_trav] <= 0;
                    trav1_B <= tel1;
                    trav1_P <= trav1_B;
                    tel1 <= trav1_P;
                    trav2_B <= tel2;
                    trav2_P <= trav2_B;
                    tel2 <= trav2_P;
                    //Write Data
                    func <= FUNC_WRITE;
                    state <= WRITE_INIT;
                  end
                end

                `CELL_ATOM: begin
                  // if the hed cell hasn't been visited we push into it
                  if(read_data1_reg[`hed_trav] == 0) begin 
                   debug_sig <=10;
                    // Set the command after write to traverse the hed
                    write_return_func <= FUNC_TRAVERSE;
                    write_return_state <= TRAVERSE_PUSH;
                    //set tag to visited hed
                    read_data1_reg[`hed_trav] <= 1;
                    read_data2_reg[`hed_trav] <= 1;
                    //Store pointer to previous value in B
                    trav1_P <= hed1;
                    hed1 <= trav1_B;
                    trav1_B <= trav1_P;
                    trav2_P <= hed2;
                    hed2 <= trav2_B;
                    trav2_B <= trav2_P;
                    //Write Data
                    mem_addr1 <= trav1_P;
                    mem_addr2 <= trav2_P;
                    func <= FUNC_WRITE;
                    state <= WRITE_INIT;
                  end
                  else begin
                    // Set the command after write to pop
                    write_return_func <= FUNC_TRAVERSE;
                    write_return_state <= TRAVERSE_POP;
                    read_data1_reg[`hed_trav] <= 0;
                    read_data2_reg[`hed_trav] <= 0;
                    trav1_B <= hed1;
                    trav1_P <= trav1_B;
                    hed1 <= trav1_P;
                    trav2_B <= hed2;
                    trav2_P <= trav2_B;
                    hed2 <= trav2_P;
                    //Write Data
                    mem_addr1 <= trav1_P;
                    mem_addr2 <= trav2_P;
                    func <= FUNC_WRITE;
                    state <= WRITE_INIT;
                  end
                end
              endcase
            end

            TRAVERSE_PUSH: begin
              mem_addr1 <= trav1_P;
              mem_addr2 <= trav2_P;
              func <= FUNC_READ;
              state <= READ_INIT;
            end

            TRAVERSE_POP: begin
              if(hed1 == `NIL) begin
                write_value <= `YES;
                func <= FUNC_RETURN;
                state <= RETURN_INIT;
              end else begin
                mem_addr1 <= trav1_B;
                mem_addr2 <= trav2_B;
                func <= FUNC_READ;
                state <= READ_INIT;
              end
            end

            TRAVERSE_TEL: begin
              //set telvisted tag
              read_data1_reg[`tel_trav] <= 1;
              read_data2_reg[`tel_trav] <= 1;
              //Store pointer to previous value in B
              trav1_P <= tel1;
              tel1 <= trav1_B;
              trav1_B <= trav1_P;
              trav2_P <= tel2;
              tel2 <= trav2_B;
              trav2_B <= trav2_P;
              func <= FUNC_WRITE;
              state <= WRITE_INIT;
            end
          endcase
        end

        FUNC_RETURN: begin
          case(state)
            RETURN_INIT: begin
              write_data <= {
                6'b000000,
                `ATOM,
                `ATOM,
                write_value,
                `NIL};
              address1 <= equal_address;
              mem_func <= `SET_CONTENTS;
              mem_execute <= 1;
              state <= RETURN_WAIT;
            end

            RETURN_WAIT: begin
              if (mem_ready) begin
                equal_return_sys_func <= `SYS_FUNC_READ;
                equal_return_state <= `SYS_READ_INIT;
                is_finished_reg <= 1;
                state <= RETURN_PAUSE;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            RETURN_PAUSE: begin
              is_finished_reg <=0;
              if (equal_start == `MUX_EQUAL) begin
                func <= FUNC_INIT;
                state<= INIT_INIT;
              end
            end
          endcase
        end
      endcase
    end
  end
endmodule
 
