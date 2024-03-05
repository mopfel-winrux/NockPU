`include "memory_unit.vh"
`include "memory_mux.vh"
`include "mem_traversal.vh"
`include "execute.vh"


module execute (
  input clk,
  input rst,
  output reg [7:0] error,
  input [2:0] execute_start,  // wire to begin execution (mux_conroller from traversal)
  input [`memory_addr_width - 1:0] execute_address,
  input [`tag_width - 1:0] execute_tag,
  input [`memory_data_width - 1:0] execute_data,
  output reg [3:0] execute_return_sys_func,
  output reg [3:0] execute_return_state,
  input mem_ready,
  input [`memory_data_width - 1:0] read_data1,
  input [`memory_data_width - 1:0] read_data2,
  input [`memory_addr_width - 1:0] free_addr,
  output reg mem_execute,
  output reg [`memory_addr_width - 1:0] address1,
  output reg [`memory_addr_width - 1:0] address2,
  output reg [`memory_addr_width - 1:0] write_addr_reg,
  output reg [1:0] mem_func,
  output reg [`memory_data_width - 1:0] write_data,
  output wire finished
);
  reg [7:0] debug_sig;

  // Interface with memory traversal
  reg [2:0] execute_start_ff;
  reg is_finished_reg;
  assign finished = is_finished_reg;

  //Interface with memory unit
  reg [`memory_data_width - 1:0] read_data_reg;

  //Registers to treat opcodes as "Functions"
  reg [`noun_width - 1:0] a, opcode, b, c, d;
  reg a_tag, b_tag, c_tag, d_tag;
  reg [`memory_addr_width - 1:0] b_addr, c_addr, d_addr;
  reg [`noun_width - 1:0] func_addr;
  reg [3:0] func_return_exec_func;
  reg [3:0] func_return_state;
  // subject ois a useful register for nouns with a tag.
  // each opcode can use this howver
  reg [`noun_width - 1:0] subject;
  reg [`noun_tag_width - 1:0] subject_tag;
  reg [`noun_width - 1:0] tel_tel;
  reg [`memory_addr_width - 1:0] tel_tel_addr;
  reg [`noun_tag_width - 1:0] tel_tel_tag;

  //Internal Registers
  reg [`tag_width - 1:0] mem_tag;
  reg [`noun_width - 1:0] hed, tel;
  reg [`memory_addr_width - 1:0] mem_addr;
  reg [`memory_data_width - 1:0] mem_data;
  reg [`memory_addr_width - 1:0] execute_address_reg;

  // Traversal Registers needed
  reg [`noun_width - 1:0] trav_P;
  reg [`noun_width - 1:0] trav_B;

  reg [3:0] exec_func;
  reg [3:0] state;

  //Execute Functions
  parameter EXE_FUNC_SLOT     = 4'h0,
            EXE_FUNC_CONSTANT = 4'h1,
            EXE_FUNC_EVAL     = 4'h2,
            EXE_FUNC_CELL     = 4'h3,
            EXE_FUNC_INCR     = 4'h4,
            EXE_FUNC_EQUAL    = 4'h5,
            EXE_FUNC_IF       = 4'h6,
            EXE_FUNC_COMPOSE  = 4'h7,
            EXE_FUNC_EXTEND   = 4'h8,
            EXE_FUNC_INVOKE   = 4'h9,
            EXE_FUNC_REPLACE  = 4'hA,
            EXE_FUNC_HINT     = 4'hB,
            EXE_FUNC_INIT     = 4'hC,
            EXE_FUNC_AUTOCONS = 4'hD,
            EXE_FUNC_ERROR    = 4'hF;

  // slot states
  parameter EXE_SLOT_INIT           = 4'h0,
            EXE_SLOT_INDIRECT       = 4'h1,
            EXE_SLOT_PREP           = 4'h2,
            EXE_SLOT_CHECK          = 4'h3,
            EXE_SLOT_DONE           = 4'h4,
            EXE_SLOT_CELL_OF_NIL    = 4'h5,
            EXE_SLOT_READ_INDIRECT  = 4'h6;

  // Constant states
  parameter EXE_CONSTANT_INIT             = 4'h0, 
            EXE_CONSTANT_READ_B           = 4'h1,
            EXE_CONSTANT_WRITE_WAIT       = 4'h2,
            EXE_CONSTANT_READ_B_INDIRECT  = 4'h3;

  //eval states
  parameter EXE_EVAL_INIT           = 4'h0,
            EXE_EVAL_READ_TEL_TEL   = 4'h1,
            EXE_EVAL_WRIT_1_EXE     = 4'h2,
            EXE_EVAL_WRIT_2_EXE     = 4'h3,
            EXE_EVAL_WRIT_HED       = 4'h5,
            EXE_EVAL_DONE           = 4'h4;

  //cell states
  parameter EXE_CELL_INIT       = 4'h0, 
            EXE_CELL_CHECK      = 4'h1, 
            EXE_CELL_WRITE_WAIT = 4'h2;

  //increment states
  parameter EXE_INCR_INIT       = 4'h0, 
            EXE_INCR_CHECK      = 4'h1, 
            EXE_INCR_WRITE_WAIT = 4'h2;

  //equal states
  parameter EXE_EQUAL_INIT          = 4'h0,
            EXE_EQUAL_WRITE_ROOT    = 4'h1,
            EXE_EQUAL_WRITE_COMP    = 4'h2,
            EXE_EQUAL_READ_TEL      = 4'h3,
            EXE_EQUAL_READ_TEL_TEL  = 4'h4,
            EXE_EQUAL_WRITE_TEL     = 4'h5,
            EXE_EQUAL_WRITE_TEL_TEL = 4'h6,
            EXE_EQUAL_WRITE_MEM     = 4'h7,
            EXE_EQUAL_FINISH        = 4'h8;

  //if then else states
  parameter EXE_IF_INIT    = 4'h0,
            EXE_IF_READ_B  = 4'h1,
            EXE_IF_READ_C  = 4'h2,
            EXE_IF_READ_D  = 4'h3,
            EXE_IF_WRITE1  = 4'h4,
            EXE_IF_WRITE2  = 4'h5,
            EXE_IF_WRITE3  = 4'h6,
            EXE_IF_WRITE4  = 4'h7,
            EXE_IF_WRITE5  = 4'h8,
            EXE_IF_WRITE6  = 4'h9,
            EXE_IF_WRITE7  = 4'hA,
            EXE_IF_WRITE8  = 4'hB,
            EXE_IF_WRITE9  = 4'hC,
            EXE_IF_WRITE10 = 4'hD,
            EXE_IF_FINISH  = 4'hE;

  //compose states
  parameter EXE_COMPOSE_INIT   = 4'h0,
            EXE_COMPOSE_FREE   = 4'h1,
            EXE_COMPOSE_READ   = 4'h2,
            EXE_COMPOSE_WRITE  = 4'h3,
            EXE_COMPOSE_FINISH = 4'h4;

  //extend states
  parameter EXE_EXTEND_INIT   = 4'h0,
            EXE_EXTEND_FREE   = 4'h1,
            EXE_EXTEND_READ1  = 4'h2,
            EXE_EXTEND_READ2  = 4'h3,
            EXE_EXTEND_WRITE1 = 4'h4,
            EXE_EXTEND_WRITE2 = 4'h5,
            EXE_EXTEND_WRITE3 = 4'h6,
            EXE_EXTEND_FINISH = 4'hF;

  //invoke states
  parameter EXE_INVOKE_INIT       = 4'h0,
            EXE_INVOKE_READ       = 4'h1,
            EXE_INVOKE_READ2      = 4'h2,
            EXE_INVOKE_WRITE      = 4'h3,
            EXE_INVOKE_WRITE2     = 4'h4,
            EXE_INVOKE_WRITE3     = 4'h5,
            EXE_INVOKE_WRITE4     = 4'h6,
            EXE_INVOKE_WRITE5     = 4'h7,
            EXE_INVOKE_WRITE6     = 4'h8,
            EXE_INVOKE_FINISH     = 4'hF;

  //replace states
  parameter EXE_REPLACE_INIT = 4'h0;

  //eval states
  parameter EXE_HINT_INIT = 4'h0;

  // Error States
  parameter EXE_ERROR_INIT = 4'h0;

  // Init States
  parameter EXE_INIT_INIT                 = 4'h0,
            EXE_INIT_READ_TEL             = 4'h1,
            EXE_INIT_DECODE               = 4'h2,
            EXE_INIT_WRIT_TEL             = 4'h3,
            EXE_INIT_WRIT_TEL_READ        = 4'h4,
            EXE_INIT_FINISHED             = 4'hF;

  // Autocons States
  parameter EXE_AUTO_INIT                 = 4'h0,
            EXE_AUTO_WRITE_ROOT           = 4'h1,
            EXE_AUTO_READ_TEL             = 4'h2,
            EXE_AUTO_WRITE_TEL            = 4'h3,
            EXE_AUTO_WRITE_MEM            = 4'h4,
            EXE_AUTO_FINISH               = 4'h5;

  always @(posedge clk) begin
    // Flip-flop to store the previous state of execute_start
    execute_start_ff <= execute_start;
  end

  always @(posedge clk or negedge rst) begin
    if (!rst || (execute_start==`MUX_EXECUTE && !(execute_start_ff==`MUX_EXECUTE))) begin
      exec_func <= EXE_FUNC_INIT;
      state <= EXE_INIT_INIT;
      trav_B <= `NIL;
      is_finished_reg <= 0;
      read_data_reg <= 0;
      execute_return_sys_func <= 0;
      execute_return_state <= 0;
      write_data <= 0;
      mem_execute<=0;
      debug_sig <= 0;
      address1 <=0;
    end 
    else if (execute_start == `MUX_EXECUTE) begin
      case (exec_func)
        EXE_FUNC_INIT: begin
          case (state)
            EXE_INIT_INIT: begin
              is_finished_reg <=0;
              if (execute_start == `MUX_EXECUTE) begin
                if (execute_tag[0] == `ATOM) begin
                  debug_sig <= 16;
                  error <= `ERROR_TEL_NOT_CELL;
                  state <= EXE_ERROR_INIT;
                  exec_func <= EXE_FUNC_ERROR;
                /*end else if (execute_data[`hed_tag] == `ATOM) begin
                  // If subject is a direct atom we want to 
                  // write it as an indirect one
                  mem_func <= `GET_FREE;
                  write_data <= 1;
                  mem_execute <= 1;
                  state <= EXE_INIT_WRITE_SUB;*/
                end else begin
                  if (mem_ready) begin
                    mem_tag <= execute_tag;

                    execute_address_reg <= execute_address;
                    trav_P <= execute_address;

                    a <= execute_data[`hed_start:`hed_end];

                    address1 <= execute_data[`tel_start:`tel_end];
                    mem_func <= `GET_CONTENTS;
                    mem_execute <= 1;
                    state <= EXE_INIT_READ_TEL;
                  end
                end
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                is_finished_reg <= 0;
              end
            end

            EXE_INIT_READ_TEL: begin
              if (mem_ready) begin
                // if data is [cell NIL] read hed
                if(read_data1[`tel_start:`tel_end] ==`NIL && read_data1[`tel_tag] == `ATOM) begin
                  if(read_data1[`hed_tag] == `CELL) begin
                    address1 <= read_data1[`hed_start:`hed_end];
                    mem_func <= `GET_CONTENTS;
                    mem_execute <= 1;
                    state <= EXE_INIT_WRIT_TEL;
                  end else begin
                  debug_sig <= 17;
                    error <= `ERROR_TEL_NOT_CELL;
                    exec_func <= EXE_FUNC_ERROR;
                    state <= EXE_ERROR_INIT;
                  end
                end else begin
                  mem_data <= read_data1;
                  mem_tag <= read_data1[`tag_start:`tag_end]; 
                  opcode <= read_data1[`hed_start:`hed_end];
                  b <= read_data1[`tel_start:`tel_end];
                  b_addr <= address1;
                  state <= EXE_INIT_DECODE;
                end
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_INIT_WRIT_TEL: begin
              if (mem_ready) begin
                write_addr_reg <= execute_address;
                mem_execute <= 1;
                write_data <= {
                        execute_data[`tag_start:`tag_end],
                        execute_data[`hed_start:`hed_end],
                        `ADDR_PAD,
                        address1};
                b_addr <= address1;
                address1 <= execute_address;
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state <= EXE_INIT_WRIT_TEL_READ;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_INIT_WRIT_TEL_READ: begin
              if (mem_ready) begin
                // if data is [cell NIL] error
                if(read_data1[`tel_start:`tel_end] ==`NIL && read_data1[`tel_tag] == `ATOM) begin
                  debug_sig <= 18;
                  error <= `ERROR_TEL_NOT_CELL;
                  exec_func <= EXE_FUNC_ERROR;
                  state <= EXE_ERROR_INIT;
                end else begin
                  mem_data <= read_data1;
                  mem_tag <= read_data1[`tag_start:`tag_end]; 
                  opcode <= read_data1[`hed_start:`hed_end];
                  b <= read_data1[`tel_start:`tel_end];
                  state <= EXE_INIT_DECODE;
                end
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_INIT_DECODE: begin
              if (mem_data[`hed_tag] == `CELL) begin
                exec_func <= EXE_FUNC_AUTOCONS;
                state <= EXE_AUTO_INIT;
              end else begin
                if ((opcode < 0) || (opcode > 11)) begin  //If invalid opcode
                  error <= `ERROR_INVALID_OPCODE;
                  exec_func <= EXE_FUNC_ERROR;
                  state <= EXE_ERROR_INIT;
                end else begin
                  case (opcode)
                    `slot: begin
                      if (mem_tag[1] == `ATOM) begin  // if b is an atom
                        exec_func <= EXE_FUNC_SLOT;
                        state <= EXE_SLOT_INIT;
                        func_addr <= trav_P;
                        func_return_exec_func <= EXE_FUNC_INIT;
                        func_return_state <= EXE_INIT_FINISHED;
                      end else begin
                        // Throw error invalid increment formulation
                        error <= `ERROR_INVALID_SLOT;
                        exec_func <= EXE_FUNC_ERROR;
                        state <= EXE_ERROR_INIT;
                      end
                    end

                    `constant: begin
                      exec_func <= EXE_FUNC_CONSTANT;
                      state <= EXE_CONSTANT_INIT;
                      func_addr <= trav_P;
                      func_return_exec_func <= EXE_FUNC_INIT;
                      func_return_state <= EXE_INIT_FINISHED;
                    end

                    `evaluate: begin
                      exec_func <= EXE_FUNC_EVAL;
                      state <= EXE_EVAL_INIT;
                      func_addr <= trav_P;
                      func_return_exec_func <= EXE_FUNC_INIT;
                      func_return_state <= EXE_INIT_FINISHED;
                    end

                    `cell: begin
                      exec_func <= EXE_FUNC_CELL;
                      state <= EXE_CELL_INIT;
                      func_return_exec_func <= EXE_FUNC_INIT;
                      func_return_state <= EXE_INIT_FINISHED;
                     end

                    `increment: begin
                      exec_func <= EXE_FUNC_INCR;
                      state <= EXE_INCR_INIT;
                      func_return_exec_func <= EXE_FUNC_INIT;
                      func_return_state <= EXE_INIT_FINISHED;
                    end

                    `equality: begin
                      exec_func <= EXE_FUNC_EQUAL;
                      state <= EXE_EQUAL_INIT;
                    end

                    `if_then_else: begin
                      exec_func <= EXE_FUNC_IF;
                      state <= EXE_IF_INIT;
                    end

                    `compose: begin
                      exec_func <= EXE_FUNC_COMPOSE;
                      state <= EXE_COMPOSE_INIT;
                    end

                    `extend: begin
                      exec_func <= EXE_FUNC_EXTEND;
                      state <= EXE_EXTEND_INIT;
                    end

                    `invoke: begin
                      exec_func <= EXE_FUNC_INVOKE;
                      state <= EXE_INVOKE_INIT;
                    end

                    `replace: begin
                      exec_func <= EXE_FUNC_REPLACE;
                      state <= EXE_REPLACE_INIT;
                    end

                    `hint: begin
                      exec_func <= EXE_FUNC_HINT;
                      state <= EXE_HINT_INIT;
                    end
                  endcase
                end
              end
            end

            EXE_INIT_FINISHED: begin
              if (execute_start != `MUX_EXECUTE) begin  // If still high don't do anything
                exec_func <= EXE_FUNC_INIT;
                state <= EXE_INIT_INIT;
                trav_B <= `NIL;
                is_finished_reg <= 0;
                execute_return_sys_func <= 0;
                execute_return_state <= 0;
                mem_execute<=0;
              end else begin
                exec_func <= EXE_FUNC_INIT;
                state <= EXE_INIT_INIT;
                trav_B <= `NIL;
                execute_return_sys_func <= 0;
                execute_return_state <= 0;
                mem_execute<=0;
                is_finished_reg <= 1;
              end
            end

          endcase
        end


        EXE_FUNC_SLOT: begin
          case (state)
            EXE_SLOT_INIT: begin
              if(read_data1[`tel_tag] == `ATOM) begin
                b <= (read_data1[`tel_start:`tel_end]<<1) | 1;
                address1 <= execute_data[`hed_start:`hed_end]; // Read subject
                subject <= execute_data[`hed_start:`hed_end];
                subject_tag <= execute_data[`hed_tag];
                state <= EXE_SLOT_PREP;
                mem_execute <= 1;
                mem_func <= `GET_CONTENTS;
              end else begin
                address1 <= read_data1[`tel_start:`tel_end];
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                state <= EXE_SLOT_INDIRECT;
              end
            end

            EXE_SLOT_INDIRECT: begin
              if (mem_ready) begin
                if(read_data1[`tel_start:`tel_end] == `NIL 
                && read_data1[`tel_tag] == `ATOM
                && read_data1[`hed_tag] == `ATOM) begin
                  b <= (read_data1[`hed_start:`hed_end]<<1) | 1;
                  address1 <= execute_data[`hed_start:`hed_end]; // Read subject
                  subject <= execute_data[`hed_start:`hed_end];
                  subject_tag <= execute_data[`hed_tag];
                  state <= EXE_SLOT_PREP;
                  mem_execute <= 1;
                  mem_func <= `GET_CONTENTS;
                end else begin
                  $stop; //XX Throw error
                end
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_SLOT_PREP: begin
              if(b[`noun_width-1] == 1) begin
                state <= EXE_SLOT_CHECK;
              end
              b <= b << 1;
            end

            EXE_SLOT_READ_INDIRECT: begin
              if (mem_ready) begin
                if(read_data1[`hed_tag] == `CELL
                && read_data1[`tel_tag] == `ATOM
                && read_data1[`tel_start:`tel_end] == `NIL) begin
                  address1 <= read_data1[`hed_start:`hed_end];
                  mem_func <= `GET_CONTENTS;
                  mem_execute <= 1;
                  state <= EXE_SLOT_READ_INDIRECT;
                end else begin
                  address1 <= func_addr;
                  write_addr_reg <= func_addr;
                  mem_func <= `SET_CONTENTS;
                  mem_execute <= 1;
                  state <= EXE_SLOT_DONE;
                  write_data <= read_data1;
               end
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data1;
              end
            end

            EXE_SLOT_CELL_OF_NIL: begin
              if (mem_ready) begin

                if(read_data1[`tel_start:`tel_end] == `NIL 
                && read_data1[`tel_tag] == `ATOM) begin
                  if(read_data1[`hed_tag] == `CELL) begin
                    state <= EXE_SLOT_READ_INDIRECT;
                    mem_func <= `GET_CONTENTS;
                    address1 <= read_data1[`hed_start:`hed_end];
                    mem_execute <= 1;
                  end else begin
                    mem_func <= `SET_CONTENTS;
                    address1 <= func_addr;
                    write_addr_reg <= func_addr;
                    mem_execute <= 1;
                    state <= EXE_SLOT_DONE;
                    write_data <= {
                            6'b000000,
                            read_data1[`hed_tag],
                            1'b1,
                            read_data1[`hed_start:`hed_end],
                            `NIL};
                  end
                end else begin
                  if(subject_tag == `CELL) begin
                    state <= EXE_SLOT_READ_INDIRECT;
                    mem_func <= `GET_CONTENTS;
                    address1 <= subject;
                    mem_execute <= 1;
                  end else begin
                    mem_func <= `SET_CONTENTS;
                    address1 <= func_addr;
                    write_addr_reg <= func_addr;
                    mem_execute <= 1;
                    state <= EXE_SLOT_DONE;
                    write_data <= {
                            6'b000000,
                            subject_tag,
                            1'b1,
                            subject,
                            `NIL};
                 end
                end
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            // [[32 33] [42 43]] [0 4]
            EXE_SLOT_CHECK: begin
              if (mem_ready) begin
                if ( b == 28'h8000000) begin
                  // need to do check to make sure the cell isn't [atom NIL]
                  if(subject_tag == `CELL) begin
                    state <= EXE_SLOT_CELL_OF_NIL;
                    address1 <= subject;
                    mem_func <= `GET_CONTENTS;
                    mem_execute <= 1;
                  end else begin
                    state <= EXE_SLOT_DONE;
                    mem_func <= `SET_CONTENTS;
                    address1 <= func_addr;
                    write_addr_reg <= func_addr;
                    mem_execute <= 1;
                    write_data <= {
                            6'b000000,
                            subject_tag,
                            1'b1,
                            subject,
                            `NIL};
                    state <= EXE_SLOT_DONE;
                    a<=1;
                  end
                end
                else if (execute_data[`hed_tag] == `ATOM) begin
                  exec_func <= EXE_FUNC_ERROR;
                  state <= EXE_ERROR_INIT;
                  error <= `ERROR_INVALID_SLOT;
                end
                else begin
                    if (b[`noun_width-1] == 0) begin
                      if(read_data1[`hed_tag] == `CELL) begin
                        address1 <= read_data1[`hed_start:`hed_end];
                        subject <= read_data1[`hed_start:`hed_end];
                        subject_tag <= read_data1[`hed_tag];
                        mem_func <= `GET_CONTENTS;
                        mem_execute <= 1;
                        state <= EXE_SLOT_CHECK;
                      end else if(b == 28'h4000000) begin
                        state <= EXE_SLOT_DONE;
                        mem_func <= `SET_CONTENTS;
                        address1 <= func_addr;
                        write_addr_reg <= func_addr;
                        mem_execute <= 1;
                        write_data <= {
                          6'b000000,
                          read_data1[`hed_tag],
                          1'b1,
                          read_data1[`hed_start:`hed_end],
                          `NIL};
                        state <= EXE_SLOT_DONE;
                      end else begin
                        exec_func <= EXE_FUNC_ERROR;
                        state <= EXE_ERROR_INIT;
                        error <= `ERROR_INVALID_SLOT_HED;
                      end
                    end else begin
                      if(read_data1[`tel_tag] == `CELL) begin
                        address1 <= read_data1[`tel_start:`tel_end];
                        subject <= read_data1[`tel_start:`tel_end];
                        subject_tag <= read_data1[`tel_tag];
                        mem_func <= `GET_CONTENTS;
                        mem_execute <= 1;
                        state <= EXE_SLOT_CHECK;
                      end else if(b == 28'hC000000) begin
                        state <= EXE_SLOT_DONE;
                        mem_func <= `SET_CONTENTS;
                        address1 <= func_addr;
                        write_addr_reg <= func_addr;
                        mem_execute <= 1;
                        write_data <= {
                          6'b000000,
                          read_data1[`tel_tag],
                          1'b1,
                          read_data1[`tel_start:`tel_end],
                          `NIL};
                        state <= EXE_SLOT_DONE;
                      end else begin
                        debug_sig <= 12;
                        exec_func <= EXE_FUNC_ERROR;
                        state <= EXE_ERROR_INIT;
                        error <= `ERROR_INVALID_SLOT_TEL;
                      end
                    end
                  b <= b << 1;
                end
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data1;
              end
           end

           EXE_SLOT_DONE: begin
             if (mem_ready) begin
                exec_func <= func_return_exec_func;
                state <= func_return_state;
                execute_return_sys_func <= `SYS_FUNC_READ;
                execute_return_state <= `SYS_READ_INIT;
             end else begin
               mem_func <= 0;
               mem_execute <= 0;
             end
           end

          endcase
        end

        EXE_FUNC_CONSTANT: begin
          case (state)
            EXE_CONSTANT_INIT: begin
              if (read_data1[`tel_tag] == `CELL) begin
                address1 <= b;
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                exec_func <= EXE_FUNC_CONSTANT;
                state <= EXE_CONSTANT_READ_B;
              end else begin
                address1 <= func_addr;
                write_addr_reg <= func_addr;
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                exec_func <= EXE_FUNC_CONSTANT;
                state <= EXE_CONSTANT_WRITE_WAIT;
                write_data <= {8'b00000011, b, `NIL};
              end
            end

            EXE_CONSTANT_READ_B: begin
              if (mem_ready) begin
                if(read_data_reg[`tel_tag] == `CELL) begin
                  address1 <= read_data_reg[`tel_start:`tel_end];
                  mem_func <= `GET_CONTENTS;
                  mem_execute <= 1;
                  state <= EXE_CONSTANT_READ_B_INDIRECT;
                end else begin
                  address1 <= func_addr;
                  write_addr_reg <= func_addr;
                  mem_func <= `SET_CONTENTS;
                  mem_execute <= 1;
                  state <= EXE_CONSTANT_WRITE_WAIT;
                  write_data <= {6'b000000,
                                 read_data_reg[`tel_tag],
                                 1'b1,
                                 read_data_reg[`tel_start:`tel_end],
                                 `NIL};
               end
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data1;
              end
            end

            EXE_CONSTANT_READ_B_INDIRECT: begin
              if (mem_ready) begin
                if(read_data1[`hed_tag] == `CELL
                && read_data1[`tel_tag] == `ATOM
                && read_data1[`tel_start:`tel_end] == `NIL) begin
                  address1 <= read_data1[`hed_start:`hed_end];
                  mem_func <= `GET_CONTENTS;
                  mem_execute <= 1;
                  state <= EXE_CONSTANT_READ_B_INDIRECT;
                end else begin
                  address1 <= func_addr;
                  write_addr_reg <= func_addr;
                  mem_func <= `SET_CONTENTS;
                  mem_execute <= 1;
                  state <= EXE_CONSTANT_WRITE_WAIT;
                  write_data <= read_data1;
               end
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data1;
              end
            end

            EXE_CONSTANT_WRITE_WAIT: begin
              if (mem_ready) begin
                exec_func <= func_return_exec_func;
                state <= func_return_state;
                execute_return_sys_func <= `SYS_FUNC_READ;
                execute_return_state <= `SYS_READ_INIT;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

          endcase
        end


        EXE_FUNC_EVAL: begin
          case(state)
            EXE_EVAL_INIT: begin
              subject <= execute_data[`hed_start:`hed_end];
              subject_tag <= execute_data[`hed_tag];
              tel_tel <= read_data1[`tel_start:`tel_end];
              tel_tel_tag <= read_data1[`tel_tag];
              tel_tel_addr <= address1;
              write_data <= 2;
              mem_func <= `GET_FREE;
              mem_execute <= 1;
              state <= EXE_EVAL_WRIT_HED;
            end

            EXE_EVAL_WRIT_HED: begin
              if (mem_ready) begin
                a <= free_addr;
                address1 <= execute_address;
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state <= EXE_EVAL_READ_TEL_TEL;
                write_data <= {6'b100000,
                               `CELL,
                               `CELL,
                               `ADDR_PAD,
                               free_addr,
                               `ADDR_PAD,
                               free_addr+2'h1};
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EVAL_READ_TEL_TEL: begin
              if (mem_ready) begin
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                address1 <= tel_tel;
                state <= EXE_EVAL_WRIT_1_EXE;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EVAL_WRIT_1_EXE: begin
              if (mem_ready) begin
                address1 <= a;
                a<= a+1;
                read_data_reg <= read_data1;
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                write_data <= {6'b100000,
                               subject_tag,
                               read_data1[`hed_tag],
                               subject,
                               read_data1[`hed_start:`hed_end]};
                state <= EXE_EVAL_WRIT_2_EXE;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EVAL_WRIT_2_EXE: begin
              if (mem_ready) begin
                address1 <= a;
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                write_data <= {6'b100000,
                               subject_tag,
                               read_data1[`tel_tag],
                               subject,
                               read_data1[`tel_start:`tel_end]};
                state <= EXE_EVAL_DONE;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EVAL_DONE: begin
              if (mem_ready) begin
                exec_func <= func_return_exec_func;
                state <= func_return_state;
                execute_return_sys_func <= `SYS_FUNC_READ;
                execute_return_state <= `SYS_READ_INIT;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

          endcase
        end

        EXE_FUNC_CELL: begin
          case(state)
            EXE_CELL_INIT: begin
              if (mem_ready) begin
                //rewrite value in addr to *[a tel]
                address1 <= address1;
                state <= EXE_CELL_CHECK;
                mem_execute <= 1;
                mem_func <= `SET_CONTENTS;
                write_data <= {
                        6'b100000, // add execute
                        execute_data[`hed_tag], 
                        read_data1[`tel_tag], // Mark as CELL
                        execute_data[`hed_start:`hed_end],
                        read_data1[`tel_start:`tel_end]};
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data1;
              end
            end

            EXE_CELL_CHECK: begin
              if (mem_ready) begin
                address1 <= execute_address;
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                write_data <= {
                        6'b110000, // mark stack bit
                        `ATOM, 
                        `CELL,
                        `noun_width'h3,//opcode 3
                        `ADDR_PAD,
                        address1};
                state <= EXE_CELL_WRITE_WAIT;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data1;
              end
            end

            EXE_CELL_WRITE_WAIT: begin
              if (mem_ready) begin
                exec_func <= func_return_exec_func;
                state <= func_return_state;
                execute_return_sys_func <= `SYS_FUNC_READ;
                execute_return_state <= `SYS_READ_INIT;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data1;
              end
            end

          endcase
        end

        EXE_FUNC_INCR: begin
          case(state)
            EXE_INCR_INIT: begin
              if (mem_ready) begin
                //rewrite value in addr to *[a tel]
                address1 <= b_addr;
                state <= EXE_INCR_CHECK;
                mem_execute <= 1;
                mem_func <= `SET_CONTENTS;
                write_data <= {
                        6'b100000, // add execute
                        execute_data[`hed_tag], 
                        read_data1[`tel_tag], // Mark as CELL
                        execute_data[`hed_start:`hed_end],
                        read_data1[`tel_start:`tel_end]};
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data1;
              end
            end

            EXE_INCR_CHECK: begin
              if (mem_ready) begin
                address1 <= execute_address;
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                write_data <= {
                        6'b110000, // mark stack bit
                        `ATOM, 
                        `CELL,
                        `noun_width'h4,//opcode 4
                        `ADDR_PAD,
                        address1};
                state <= EXE_INCR_WRITE_WAIT;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data1;
              end
            end

            EXE_INCR_WRITE_WAIT: begin
              if (mem_ready) begin
                exec_func <= func_return_exec_func;
                state <= func_return_state;
                execute_return_sys_func <= `SYS_FUNC_READ;
                execute_return_state <= `SYS_READ_INIT;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data1;
              end
            end
          endcase
        end

        EXE_FUNC_EQUAL: begin
          case(state)
            EXE_EQUAL_INIT: begin
              mem_func <= `GET_FREE;
              write_data <= 3;
              mem_execute <= 1;
              state<= EXE_EQUAL_WRITE_ROOT;
            end

            EXE_EQUAL_WRITE_ROOT: begin
              if (mem_ready) begin
                mem_func <= `SET_CONTENTS;
                address1 <= execute_address;
                a<= free_addr;
                mem_execute <= 1;
                write_data <= {
                        6'b110000, // mark as execute opcode
                        `ATOM, // Mark as ATOM
                        `CELL, // Mark as CELL
                        `noun_width'h5,
                        `ADDR_PAD,
                        free_addr};
                state <= EXE_EQUAL_WRITE_COMP;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EQUAL_WRITE_COMP: begin
              if (mem_ready) begin
                mem_func <= `SET_CONTENTS;
                address1 <= a;
                a<= a+1;
                mem_execute <= 1;
                write_data <= {
                        6'b000000, // mark as execute opcode
                        `CELL, // Mark as CELL
                        `CELL, // Mark as CELL
                        a+2'h1,
                        a+2'h2};
                state <= EXE_EQUAL_READ_TEL;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end


            EXE_EQUAL_READ_TEL: begin
              if (mem_ready) begin
                mem_func <= `GET_CONTENTS;
                address1 <= execute_data[`tel_start:`tel_end];
                mem_execute <= 1;
                state <= EXE_EQUAL_READ_TEL_TEL;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EQUAL_READ_TEL_TEL: begin
              if (mem_ready) begin
                mem_func <= `GET_CONTENTS;
                read_data_reg <= read_data1;
                address1 <= read_data1[`tel_start:`tel_end];
                mem_execute <= 1;
                state <= EXE_EQUAL_WRITE_TEL;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end


            EXE_EQUAL_WRITE_TEL: begin
              if (mem_ready) begin
                mem_func <= `SET_CONTENTS;
                address1 <= a;
                a <= a+1;
                mem_execute <= 1;
                write_data <= {
                        6'b100000, // mark as execute opcode
                        execute_data[`hed_tag],
                        read_data1[`hed_tag],
                        execute_data[`hed_start:`hed_end],
                        read_data1[`hed_start:`hed_end]};
                state <= EXE_EQUAL_WRITE_TEL_TEL;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EQUAL_WRITE_TEL_TEL: begin
              if (mem_ready) begin
                mem_func <= `SET_CONTENTS;
                address1 <= a;
                mem_execute <= 1;
                write_data <= {
                        6'b100000, // mark as execute opcode
                        execute_data[`hed_tag],
                        read_data1[`tel_tag],
                        execute_data[`hed_start:`hed_end],
                        read_data1[`tel_start:`tel_end]};
                state <= EXE_EQUAL_FINISH;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EQUAL_WRITE_MEM: begin
              if (mem_ready) begin
                mem_func <= `SET_CONTENTS;
                address1 <= free_addr;
                mem_execute <= 1;
                write_data <= {
                        6'b000000, // mark as execute opcode
                        `CELL,
                        `CELL,
                        execute_data[`tel_start:`tel_end],
                        read_data_reg[`tel_start:`tel_end]};
                state <= EXE_EQUAL_FINISH;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EQUAL_FINISH: begin
              if (mem_ready) begin
                exec_func <= EXE_FUNC_INIT;
                state <= EXE_INIT_FINISHED;
                execute_return_sys_func <= `SYS_FUNC_READ;
                execute_return_state <= `SYS_READ_INIT;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

          endcase
        end

        /*
          EXE_IF_INIT    = 4'h0,
          EXE_IF_READ_B  = 4'h1,
          EXE_IF_READ_C  = 4'h2,
          EXE_IF_READ_D  = 4'h3,
          EXE_IF_WRITE1  = 4'h4,
          EXE_IF_WRITE2  = 4'h5,
          EXE_IF_WRITE3  = 4'h6,
          EXE_IF_WRITE4  = 4'h7,
          EXE_IF_WRITE5  = 4'h8,
          EXE_IF_WRITE6  = 4'h9,
          EXE_IF_WRITE7  = 4'hA,
          EXE_IF_WRITE8  = 4'hB,
          EXE_IF_WRITE9  = 4'hC,
          EXE_IF_WRITE10 = 4'hD,
          EXE_IF_FINISH  = 4'hE;
        */
        EXE_FUNC_IF: begin
          case(state)
            EXE_IF_INIT: begin
              if (mem_ready) begin
                write_data <= 10;
                mem_func <= `GET_FREE;
                mem_execute <= 1;
                state<= EXE_IF_READ_B;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_IF_READ_B: begin
              if (mem_ready) begin
                a <= free_addr;
                read_data_reg <= read_data1;
                address1 <= read_data1[`tel_start:`tel_end];
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_IF_READ_C;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_IF_READ_C: begin
              if (mem_ready) begin
                b <= read_data1[`hed_start:`hed_end];
                b_tag <= read_data1[`hed_tag];
                b_addr <= read_data1[`tel_start:`tel_end];
                address1 <= read_data1[`tel_start:`tel_end];
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_IF_READ_D;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_IF_READ_D: begin
              if (mem_ready) begin
                c <= read_data1[`hed_start:`hed_end];
                c_tag <= read_data1[`hed_tag];
                d <= read_data1[`tel_start:`tel_end];
                d_tag <= read_data1[`tel_tag];
                state<= EXE_IF_WRITE1;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_IF_WRITE1: begin
              if (mem_ready) begin
                address1 <= execute_address;
                write_data <= { 6'b100000,
                                execute_data[`hed_tag],
                                `CELL,
                                execute_data[`hed_start:`hed_end],
                                a};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_IF_WRITE2;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_IF_WRITE2: begin
              if (mem_ready) begin
                //address1 <= execute_data[`tel_start:`tel_end];
                address1 <= a;
                a <= a+1;
                write_data <= { 6'b100000,
                                `CELL,
                                `CELL,
                                a+`noun_width'h1,
                                a+`noun_width'h2};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_IF_WRITE3;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_IF_WRITE3: begin
              if (mem_ready) begin
                address1 <= a;
                a <= a+1;
                write_data <= { 6'b000000,
                                c_tag,
                                d_tag,
                                c,
                                d};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_IF_WRITE4;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_IF_WRITE4: begin
              if (mem_ready) begin
                address1 <= a;
                a <= a+1;
                write_data <= { 6'b000000,
                                `ATOM,
                                `CELL,
                                `noun_width'h0,
                                a+`noun_width'h1};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_IF_WRITE5;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_IF_WRITE5: begin
              if (mem_ready) begin
                address1 <= a;
                a <= a+1;
                write_data <= { 6'b100000,
                                `CELL,
                                `CELL,
                                a+2'h1,
                                a+2'h2};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_IF_WRITE6;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_IF_WRITE6: begin
              if (mem_ready) begin
                address1 <= a;
                a <= a+1;
                write_data <= { 6'b000000,
                                `ATOM,
                                `ATOM,
                                `noun_width'h2,
                                `noun_width'h3};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_IF_WRITE7;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_IF_WRITE7: begin
              if (mem_ready) begin
                address1 <= a;
                a <= a+1;
                write_data <= { 6'b000000,
                                `ATOM,
                                `CELL,
                                `noun_width'h0,
                                a+1'h1};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_IF_WRITE8;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_IF_WRITE8: begin
              if (mem_ready) begin
                address1 <= a;
                a <= a+1;
                write_data <= { 6'b100000,
                                execute_data[`hed_tag],
                                `CELL,
                                execute_data[`hed_start:`hed_end],
                                a+1'h1};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_IF_WRITE9;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_IF_WRITE9: begin
              if (mem_ready) begin
                address1 <= a;
                a <= a+1;
                write_data <= { 6'b000000,
                                `ATOM,
                                `CELL,
                                `noun_width'h4,
                                a+1'h1};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_IF_WRITE10;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_IF_WRITE10: begin
              if (mem_ready) begin
                address1 <= a;
                write_data <= { 6'b000000,
                                `ATOM,
                                b_tag,
                                `noun_width'h4,
                                b};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_IF_FINISH;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_IF_FINISH: begin
              if (mem_ready) begin
                exec_func <= EXE_FUNC_INIT;
                state <= EXE_INIT_FINISHED;
                execute_return_sys_func <= `SYS_FUNC_READ;
                execute_return_state <= `SYS_READ_INIT;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

          endcase
        end

        EXE_FUNC_COMPOSE: begin
          case(state)
            EXE_COMPOSE_INIT: begin
              if (mem_ready) begin
                mem_func <= `GET_FREE;
                write_data <= 1;
                mem_execute <= 1;
                state<= EXE_COMPOSE_FREE;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_COMPOSE_FREE: begin
              if (mem_ready) begin
                a <= free_addr;
                b_addr <= address1;
                address1 <= read_data1[`tel_start:`tel_end];
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_COMPOSE_READ;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_COMPOSE_READ: begin
              if (mem_ready) begin
                read_data_reg <= read_data1;
                address1 <= a;
                write_data <= { 6'b100000,
                                execute_data[`hed_tag],
                                read_data1[`hed_tag],
                                execute_data[`hed_start:`hed_end],
                                read_data1[`hed_start:`hed_end]};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_COMPOSE_WRITE;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_COMPOSE_WRITE: begin
              if (mem_ready) begin
                address1 <= execute_address;
                write_data <= { 6'b100000,
                                `CELL,
                                read_data_reg[`tel_tag],
                                a,
                                read_data_reg[`tel_start:`tel_end]};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_COMPOSE_FINISH;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_COMPOSE_FINISH: begin
              if (mem_ready) begin
                exec_func <= EXE_FUNC_INIT;
                state <= EXE_INIT_FINISHED;
                execute_return_sys_func <= `SYS_FUNC_READ;
                execute_return_state <= `SYS_READ_INIT;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end
          endcase
        end

        EXE_FUNC_EXTEND: begin
          case(state)
            EXE_EXTEND_INIT: begin
              if (mem_ready) begin
                mem_func <= `GET_FREE;
                write_data <= 2;
                mem_execute <= 1;
                state<= EXE_EXTEND_FREE;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EXTEND_FREE: begin
              if (mem_ready) begin
                a <= free_addr;
                address1 <= execute_data[`tel_start:`tel_end];
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_EXTEND_READ1;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EXTEND_READ1: begin
              if (mem_ready) begin
                address1 <= read_data1[`tel_start:`tel_end];
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_EXTEND_READ2;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EXTEND_READ2: begin
              if (mem_ready) begin
                read_data_reg <= read_data1;
                address1 <= execute_address;
                write_data <= { 6'b100000,
                                `CELL,
                                read_data1[`tel_tag],
                                a,
                                read_data1[`tel_start:`tel_end]};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_EXTEND_WRITE1;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EXTEND_WRITE3: begin
              if (mem_ready) begin
                address1 <= execute_address;
                write_data <= { 6'b100000,
                                `CELL,
                                `CELL,
                                a,
                                `ADDR_PAD,
                                c_addr};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_EXTEND_WRITE2;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EXTEND_WRITE1: begin
              if (mem_ready) begin
                address1 <= a;
                a<= a+1;
                write_data <= { 6'b000000,
                                `CELL,
                                execute_data[`hed_tag],
                                a+1'h1,
                                execute_data[`hed_start:`hed_end]};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_EXTEND_WRITE2;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EXTEND_WRITE2: begin
              if (mem_ready) begin
                address1 <= a;
                write_data <= { 6'b100000,
                                execute_data[`hed_tag],
                                read_data_reg[`hed_tag],
                                execute_data[`hed_start:`hed_end],
                                read_data_reg[`hed_start:`hed_end]};
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state<= EXE_EXTEND_FINISH;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EXTEND_FINISH: begin
              if (mem_ready) begin
                exec_func <= EXE_FUNC_INIT;
                state <= EXE_INIT_FINISHED;
                execute_return_sys_func <= `SYS_FUNC_READ;
                execute_return_state <= `SYS_READ_INIT;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end
          endcase
        end

        EXE_FUNC_INVOKE: begin
          case(state)
            EXE_INVOKE_INIT: begin
              if (mem_ready) begin
                mem_func <= `GET_FREE;
                write_data <= 3;
                mem_execute <= 1;
                state <= EXE_INVOKE_READ;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_INVOKE_READ: begin
              if (mem_ready) begin
                a <= free_addr;
                mem_func <= `GET_CONTENTS;
                address1 <= execute_data[`tel_start:`tel_end];
                mem_execute <= 1;
                state <= EXE_INVOKE_READ2;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_INVOKE_READ2: begin
              if (mem_ready) begin
                mem_func <= `GET_CONTENTS;
                b <= read_data1[`tel_start:`tel_end];
                address1 <= read_data1[`tel_start:`tel_end];
                mem_execute <= 1;
                state <= EXE_INVOKE_WRITE;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_INVOKE_WRITE: begin
              if (mem_ready) begin
                read_data_reg <= read_data1;
                mem_func <= `SET_CONTENTS;
                address1 <= address1;
                mem_execute <= 1;
                write_data <= { 6'b000000,
                                `ATOM, 
                                `CELL,
                                `noun_width'h2,
                                a};
                state <= EXE_INVOKE_WRITE2;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_INVOKE_WRITE2: begin
              if (mem_ready) begin
                a <= a+1;
                mem_func <= `SET_CONTENTS;
                address1 <= a;
                mem_execute <= 1;
                write_data <= { 6'b000000,
                                `CELL,
                                `CELL,
                                a + 2'h1,
                                a + 2'h2};
                state <= EXE_INVOKE_WRITE3;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_INVOKE_WRITE3: begin
              if (mem_ready) begin
                a <= a+1;
                mem_func <= `SET_CONTENTS;
                address1 <= a;
                mem_execute <= 1;
                write_data <= { 6'b000000,
                                `ATOM,
                                `ATOM,
                                `noun_width'h0,
                                `noun_width'h1};
                state <= EXE_INVOKE_WRITE4;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_INVOKE_WRITE4: begin
              if (mem_ready) begin
                mem_func <= `SET_CONTENTS;
                address1 <= a;
                mem_execute <= 1;
                write_data <= { 6'b000000,
                                `ATOM,
                                read_data1[`hed_tag], //b
                                `noun_width'h0,
                                read_data1[`hed_start:`hed_end]}; //b
                state <= EXE_INVOKE_WRITE5;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_INVOKE_WRITE5: begin
              if (mem_ready) begin
                mem_func <= `SET_CONTENTS;
                address1 <= execute_data[`tel_start:`tel_end];
                mem_execute <= 1;
                write_data <= { 6'b100000,
                                execute_data[`hed_tag], //a
                                read_data_reg[`tel_tag],//c
                                execute_data[`hed_start:`hed_end],
                                read_data_reg[`tel_start:`tel_end]};  
                state <= EXE_INVOKE_WRITE6;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_INVOKE_WRITE6: begin
              if (mem_ready) begin
                mem_func <= `SET_CONTENTS;
                address1 <= execute_address;
                mem_execute <= 1;
                write_data <= { 6'b100000,
                                `CELL,
                                `CELL,
                                execute_data[`tel_start:`tel_end],
                                b};
                                //read_data_reg[`hed_start:`hed_end]};  
                state <= EXE_INVOKE_FINISH;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_INVOKE_FINISH: begin
              if (mem_ready) begin
                exec_func <= EXE_FUNC_INIT;
                state <= EXE_INIT_FINISHED;
                execute_return_sys_func <= `SYS_FUNC_READ;
                execute_return_state <= `SYS_READ_INIT;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end
          endcase
        end

        EXE_FUNC_REPLACE: begin
          //case(state)
          $stop;
          //endcase
        end

        EXE_FUNC_HINT: begin
          //case(state)
          $stop;
          //endcase
        end
        
        EXE_FUNC_AUTOCONS: begin
          case(state)
            EXE_AUTO_INIT: begin
              mem_func <= `GET_FREE;
              write_data <= 1;
              mem_execute <= 1;
              state<= EXE_AUTO_WRITE_ROOT;
            end

            EXE_AUTO_WRITE_ROOT: begin
              if (mem_ready) begin
                mem_func <= `SET_CONTENTS;
                address1 <= execute_address;
                mem_execute <= 1;
                write_data <= {
                        6'b000000, // remove execute
                        `CELL, // Mark as CELL
                        `CELL, // Mark as CELL
                        execute_data[`tel_start:`tel_end],
                        `ADDR_PAD,
                        free_addr};
                state <= EXE_AUTO_READ_TEL;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end
            
            EXE_AUTO_READ_TEL: begin
              if (mem_ready) begin
                mem_func <= `GET_CONTENTS;
                address1 <= execute_data[`tel_start:`tel_end];
                mem_execute <= 1;
                state <= EXE_AUTO_WRITE_TEL;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end
            
            EXE_AUTO_WRITE_TEL: begin
              if (mem_ready) begin
                mem_func <= `SET_CONTENTS;
                address1 <= execute_data[`tel_start:`tel_end];
                mem_execute <= 1;
                write_data <= {
                        6'b100000, // mark as execute
                        execute_data[`hed_tag], // Mark as CELL
                        read_data1[`tel_tag],
                        execute_data[`hed_start:`hed_end],
                        read_data1[`hed_start:`hed_end]};
                state <= EXE_AUTO_WRITE_MEM;
                read_data_reg <= read_data1;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_AUTO_WRITE_MEM: begin
              if (mem_ready) begin
                mem_func <= `SET_CONTENTS;
                address1 <= free_addr;
                mem_execute <= 1;
                write_data <= {
                        6'b100000, // mark as execute
                        execute_data[`hed_tag], // Mark as CELL
                        read_data_reg[`tel_tag], // Mark as CELL
                        execute_data[`hed_start:`hed_end],
                        read_data_reg[`tel_start:`tel_end]};
                state <= EXE_AUTO_FINISH;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_AUTO_FINISH: begin
              if (mem_ready) begin
                exec_func <= EXE_FUNC_INIT;
                state <= EXE_INIT_FINISHED;
                execute_return_sys_func <= `SYS_FUNC_READ;
                execute_return_state <= `SYS_READ_INIT;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end
          endcase
        end

        EXE_FUNC_ERROR: begin
          execute_return_sys_func <= `SYS_FUNC_EXECUTE;
          execute_return_state <= `SYS_EXECUTE_ERROR;
          is_finished_reg <= 1;
        end
      endcase
    end
  end
endmodule
