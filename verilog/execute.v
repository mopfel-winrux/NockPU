`include "memory_unit.vh"
`include "mem_traversal.vh"
`include "execute.vh"


module execute (
    clk,
    rst,
    error,
    execute_start,
    execute_address,
    execute_tag,
    execute_data,
    mem_ready,
    mem_execute,
    mem_func,
    address,
    free_addr,
    read_data,
    write_data,
    finished,
    execute_return_sys_func,
    execute_return_state
);
  input clk, rst;
  output reg [7:0] error;

  reg [7:0] debug_sig;
  // Interface with memory traversal
  input execute_start;  // wire to begin execution (mux_conroller from traversal)
  reg execute_start_ff;
  input [`memory_addr_width - 1:0] execute_address;
  input [`tag_width - 1:0] execute_tag;
  input [`memory_data_width - 1:0] execute_data;
  output reg [3:0] execute_return_sys_func;
  output reg [3:0] execute_return_state;
  reg is_finished_reg;
  output wire finished;
  assign finished = is_finished_reg;

  //Interface with memory unit
  input mem_ready;
  input [`memory_data_width - 1:0] read_data;
  reg [`memory_data_width - 1:0] read_data_reg;
  input [`memory_addr_width - 1:0] free_addr;

  output reg mem_execute;
  output reg [`memory_addr_width - 1:0] address;
  output reg [`memory_addr_width - 1:0] write_addr_reg;
  output reg [1:0] mem_func;
  output reg [`memory_data_width - 1:0] write_data;

  //Registers to treat opcodes as "Functions"
  reg [`noun_width - 1:0] a, opcode, b, c, d;
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

  // Stack Registers
  reg [`noun_width - 1:0] stack_P, stack_P_tel;
  reg [`noun_width - 1:0] stack_a, stack_b;
  reg [`tag_width - 1:0] stack_mem_tag_1, stack_mem_tag_2;
  reg [3:0] stack_return_exec_func;
  reg [3:0] stack_return_state;
  reg [`memory_data_width - 1:0] mem_reg;

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
              EXE_FUNC_STACK    = 4'hD,
              EXE_FUNC_ERROR    = 4'hF;

  // slot states
  parameter EXE_SLOT_INIT                 = 4'h0,
            EXE_SLOT_PREP                   = 4'h1,
              EXE_SLOT_CHECK                = 4'h2,
              EXE_SLOT_DONE                 = 4'h3,
              EXE_SLOT_CELL_OF_NIL          = 4'h4;

  // Constant states
  parameter EXE_CONSTANT_INIT = 4'h0, EXE_CONSTANT_READ_B = 4'h1, EXE_CONSTANT_WRITE_WAIT = 4'h2;

  //eval states
  parameter EXE_EVAL_INIT           = 4'h0,
            EXE_EVAL_READ_TEL_TEL   = 4'h1,
            EXE_EVAL_WRIT_1_EXE     = 4'h2,
            EXE_EVAL_WRIT_2_EXE     = 4'h3,
            EXE_EVAL_DONE           = 4'h4;

  //cell states
  parameter EXE_CELL_INIT = 4'h0, EXE_CELL_CHECK = 4'h1, EXE_CELL_WRITE_WAIT = 4'h2;

  //increment states
  parameter EXE_INCR_INIT = 4'h0, EXE_INCR_A = 4'h1, EXE_INCR_WAIT = 4'h2;

  //equal states
  parameter EXE_EQUAL_INIT = 4'h0;

  //if then else states
  parameter EXE_IF_INIT = 4'h0;

  //compose states
  parameter EXE_COMPOSE_INIT = 4'h0;

  //extend states
  parameter EXE_EXTEND_INIT = 4'h0;

  //invoke states
  parameter EXE_INVOKE_INIT = 4'h0;

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
              EXE_INIT_FINISHED             = 4'hF;

  //Stacking States
  parameter EXE_STACK_INIT                = 4'h0,
              EXE_STACK_READ_WAIT           = 4'h1,
              EXE_STACK_READ_WAIT_2         = 4'h2,
              EXE_STACK_WRITE_WAIT          = 4'h3,
              EXE_STACK_CHECK_NEXT          = 4'h4,
              EXE_STACK_CHECK_WAIT          = 4'h5,
              EXE_STACK_POP                 = 4'h6,
              EXE_STACK_POP_READ            = 4'h7,
              EXE_STACK_POP_WAIT            = 4'h8,
              EXE_STACK_POP_ERR             = 4'h9;

  always @(posedge clk) begin
    // Flip-flop to store the previous state of execute_start
    execute_start_ff <= execute_start;
  end

  always @(posedge clk or negedge rst) begin
    if (!rst || (execute_start && !execute_start_ff)) begin
      exec_func <= EXE_FUNC_INIT;
      state <= EXE_INIT_INIT;
      trav_B <= `NIL;
      is_finished_reg <= 0;
      read_data_reg <= 0;
      execute_return_sys_func <= 0;
      execute_return_state <= 0;
      stack_mem_tag_1 <= 0;
      stack_mem_tag_2 <= 0;
      write_data <= 0;
      mem_execute<=0;
      debug_sig <= 0;
      address <=0;
    end else if (execute_start) begin
      case (exec_func)
        EXE_FUNC_INIT: begin
          case (state)
            EXE_INIT_INIT: begin
              is_finished_reg <=0;
              if (execute_start) begin
                if (execute_tag[0] == 1) begin
                  error <= `ERROR_TEL_NOT_CELL;
                  state <= EXE_ERROR_INIT;
                  exec_func <= EXE_FUNC_ERROR;
                end else begin
                  if (mem_ready) begin
                    mem_tag <= execute_tag;

                    execute_address_reg <= execute_address;
                    trav_P <= execute_address;

                    b<= 16'hDEAD;

                    a <= execute_data[`hed_start:`hed_end];

                    address <= execute_data[`tel_start:`tel_end];
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
                if(read_data[`tel_start:`tel_end] ==`NIL && read_data[`tel_tag] == `ATOM) begin
                  if(read_data[`hed_tag] == `CELL) begin
                    address <= read_data[`hed_start:`hed_end];
                    mem_func <= `GET_CONTENTS;
                    mem_execute <= 1;
                    state <= EXE_INIT_WRIT_TEL;
                  end else begin
                    error <= `ERROR_TEL_NOT_CELL;
                    exec_func <= EXE_FUNC_ERROR;
                    state <= EXE_ERROR_INIT;
                  end

                end else begin
                  mem_data <= read_data;
                  mem_tag <= read_data[`tag_start:`tag_end]; // read first 4 bits and store into tag for easier access

                  opcode <= read_data[`hed_start:`hed_end];
                  b <= read_data[`tel_start:`tel_end];

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
                write_data <= {execute_data[`tag_start:`tag_end],
                        execute_data[`hed_start:`hed_end],
                        18'b0,address};//data[`tel_start:`tel_end]};
                address <= execute_address;
                mem_func <= `SET_CONTENTS;

                mem_execute <= 1;
                state <= EXE_INIT_READ_TEL;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_INIT_DECODE: begin
              if ((opcode < 0) || (opcode > 11)) begin  //If invalid opcode
                error <= `ERROR_INVALID_OPCODE;

                exec_func <= EXE_FUNC_ERROR;
                state <= EXE_ERROR_INIT;

              end else begin
                case (opcode)
                  `slot: begin
                    if (mem_tag[1] == 1) begin  // if b is an atom
                      stack_P <= trav_P;
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
                    if (mem_tag[0] == `CELL) begin  // if b is a cell
                      stack_P <= trav_P;
                      exec_func <= EXE_FUNC_STACK;
                      state <= EXE_STACK_INIT;
                    end else begin
                      // Throw error invalid increment formulation
                      error <= `ERROR_INVALID_B_CELL;
                      exec_func <= EXE_FUNC_ERROR;
                      state <= EXE_ERROR_INIT;
                    end
                    // exec_func <= EXE_FUNC_CELL;
                    // state <= EXE_CELL_INIT;
                  end

                  `increment: begin
                    if (mem_tag[0] == `CELL) begin  // if b is a cell
                      stack_P <= trav_P;
                      exec_func <= EXE_FUNC_STACK;
                      state <= EXE_STACK_INIT;
                    end else begin
                      // Throw error invalid increment formulation
                      error <= `ERROR_INVALID_B_INCR;
                      exec_func <= EXE_FUNC_ERROR;
                      state <= EXE_ERROR_INIT;
                    end

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

            EXE_INIT_FINISHED: begin
              if (execute_start == 0) begin  // If still high don't do anything
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
              b <= (read_data[`tel_start:`tel_end]<<1) | 1;
              address <= execute_data[`hed_start:`hed_end]; // Read subject
              subject <= execute_data[`hed_start:`hed_end];
              subject_tag <= execute_data[`hed_tag];
              mem_reg <= execute_data;
              state <= EXE_SLOT_PREP;
              mem_execute <= 1;
              mem_func <= `GET_CONTENTS;
            end

            EXE_SLOT_PREP: begin
              if(b[`noun_width-1] == 1) begin
                state <= EXE_SLOT_CHECK;
              end
              b <= b << 1;
            end

            EXE_SLOT_CELL_OF_NIL: begin
              if (mem_ready) begin
                debug_sig <= 6;
                state <= EXE_SLOT_DONE;
                mem_func <= `SET_CONTENTS;
                address <= func_addr;
                write_addr_reg <= func_addr;
                mem_execute <= 1;
                state <= EXE_SLOT_DONE;

                if(read_data[`tel_start:`tel_end] == `NIL && read_data[`tel_tag] == `ATOM) begin
                  write_data <= {
                          6'b000000,
                          read_data[`hed_tag],
                          1'b1,
                          read_data[`hed_start:`hed_end],
                          `NIL};
                end else begin
                  write_data <= {
                          6'b000000,
                          subject_tag,
                          1'b1,
                          subject,
                          `NIL};
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
                  debug_sig <= 5;

                  // need to do check to make sure the cell isn't [atom NIL]
                  if(subject_tag == `CELL) begin
                    state <= EXE_SLOT_CELL_OF_NIL;
                    address <= subject;
                    mem_func <= `GET_CONTENTS;
                    mem_execute <= 1;
                  end else begin
                    state <= EXE_SLOT_DONE;
                    mem_func <= `SET_CONTENTS;
                    address <= func_addr;
                    write_addr_reg <= func_addr;
                    mem_execute <= 1;
                    write_data <= {
                            6'b000000,
                            subject_tag,
                            1'b1,
                            subject,
                            `NIL};
                      //1'b0,
                      //read_data[62:0]};
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
                      if(read_data[`hed_tag] == `CELL) begin
                        address <= read_data[`hed_start:`hed_end];
                        subject <= read_data[`hed_start:`hed_end];
                        subject_tag <= read_data[`hed_tag];
                        mem_func <= `GET_CONTENTS;
                        mem_execute <= 1;
                        state <= EXE_SLOT_CHECK;
                      end else if(b == 28'h4000000) begin
                        state <= EXE_SLOT_DONE;
                        mem_func <= `SET_CONTENTS;
                        address <= func_addr;
                        write_addr_reg <= func_addr;
                        mem_execute <= 1;
                        write_data <= {
                          6'b000000,
                          read_data[`hed_tag],
                          1'b1,
                          read_data[`hed_start:`hed_end],
                          `NIL};
                          //28'h0000};
                        state <= EXE_SLOT_DONE;
                      end else begin
                        exec_func <= EXE_FUNC_ERROR;
                        state <= EXE_ERROR_INIT;
                        error <= `ERROR_INVALID_SLOT_HED;
                      end
                    end else begin
                      if(read_data[`tel_tag] == `CELL) begin
                        address <= read_data[`tel_start:`tel_end];
                        subject <= read_data[`tel_start:`tel_end];
                        subject_tag <= read_data[`tel_tag];
                        mem_func <= `GET_CONTENTS;
                        mem_execute <= 1;
                        state <= EXE_SLOT_CHECK;
                      end else if(b == 28'hC000000) begin
                        state <= EXE_SLOT_DONE;
                        mem_func <= `SET_CONTENTS;
                        address <= func_addr;
                        write_addr_reg <= func_addr;
                        mem_execute <= 1;
                        write_data <= {
                          6'b000000,
                          read_data[`tel_tag],
                          1'b1,
                          read_data[`tel_start:`tel_end],
                          `NIL};
                          //28'h0000};
                        state <= EXE_SLOT_DONE;
                      end else begin
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
                read_data_reg <= read_data;
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
              if (read_data[`tel_tag] == `CELL) begin
                address <= b;
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                exec_func <= EXE_FUNC_CONSTANT;
                state <= EXE_CONSTANT_READ_B;
              end else begin
                address <= func_addr;
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
                address <= func_addr;
                write_addr_reg <= func_addr;
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state <= EXE_CONSTANT_WRITE_WAIT;
                write_data <= {6'b000000,
                               read_data_reg[`tel_tag],
                               1'b1,
                               read_data_reg[`tel_start:`tel_end],
                               `NIL};
                //write_data <= read_data_reg;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data;
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
              tel_tel <= read_data[`tel_start:`tel_end];
              tel_tel_tag <= read_data[`tel_tag];
              tel_tel_addr <= address;
              address <= execute_address;
              mem_func <= `SET_CONTENTS;
              mem_execute <= 1;
              state <= EXE_EVAL_READ_TEL_TEL;
              write_data <= {6'b100000,
                             read_data_reg[`hed_tag],
                             execute_data[`tel_tag],
                             read_data[`tel_start:`tel_end],
                             execute_data[`tel_start:`tel_end]};

            end

            EXE_EVAL_READ_TEL_TEL: begin
              if (mem_ready) begin
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                address <= tel_tel;
                state <= EXE_EVAL_WRIT_1_EXE;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EVAL_WRIT_1_EXE: begin
              if (mem_ready) begin
                read_data_reg <= read_data;
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                address <= address;
                write_data <= {6'b100000,
                               subject_tag,
                               read_data[`hed_tag],
                               subject,
                               read_data[`hed_start:`hed_end]};

                state <= EXE_EVAL_WRIT_2_EXE;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_EVAL_WRIT_2_EXE: begin
              if (mem_ready) begin
                address <= tel_tel_addr;
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                write_data <= {6'b100000,
                               subject_tag,
                               read_data[`tel_tag],
                               subject,
                               read_data[`tel_start:`tel_end]};
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
                address <= write_addr_reg;
                state <= EXE_CELL_CHECK;
                mem_execute <= 1;
                mem_func <= `GET_CONTENTS;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data;
              end
            end

            EXE_CELL_CHECK: begin
              if (mem_ready) begin
                address <= func_addr;
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                write_data <= {6'b000000,
                               2'b11,
                               27'h0, read_data[`hed_tag],
                              `NIL};
                state <= EXE_CELL_WRITE_WAIT;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data;
              end
            end

            EXE_CELL_WRITE_WAIT: begin
              if (mem_ready) begin
                exec_func <= func_return_exec_func;
                state <= func_return_state;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data;
              end
            end

          endcase
        end

        EXE_FUNC_INCR: begin
          case (state)
            EXE_INCR_INIT: begin
              if (mem_ready) begin
                address <= write_addr_reg;
                mem_reg <= execute_data;
                state <= EXE_INCR_A;
                mem_execute <= 1;
                mem_func <= `GET_CONTENTS;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data;
              end
            end

            EXE_INCR_A: begin
              if (mem_ready) begin
                if (read_data[`hed_tag] == `CELL) begin
                  error <= `ERROR_INVALID_B_INCR;
                  exec_func <= EXE_FUNC_ERROR;
                  state <= EXE_ERROR_INIT;
                end else begin
                  address <= func_addr;
                  write_addr_reg <= func_addr;
                  mem_func <= `SET_CONTENTS;
                  mem_execute <= 1;
                  write_data <= {6'b000000,
                                 read_data[`hed_tag],
                                 1'b1,
                                 read_data[`hed_start:`hed_end] + 28'h1,
                                 `NIL};
                  //exec_func <= func_return_exec_func;
                  //state <= func_return_state;
                  state <= EXE_INCR_WAIT;
                end
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data;
              end
            end

            EXE_INCR_WAIT: begin
              if(mem_ready) begin
                  exec_func <= func_return_exec_func;
                  state <= func_return_state;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
                read_data_reg <= read_data;
              end
            end

          endcase
        end

        EXE_FUNC_EQUAL: begin
          //case(state)
          $stop;
          //endcase
        end

        EXE_FUNC_IF: begin
          //case(state)
          $stop;
          //endcase
        end

        EXE_FUNC_COMPOSE: begin
          //case(state)
          $stop;
          //endcase
        end

        EXE_FUNC_EXTEND: begin
          //case(state)
          $stop;
          //endcase
        end

        EXE_FUNC_INVOKE: begin
          //case(state)
          $stop;
          //endcase
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

        EXE_FUNC_STACK: begin
          case (state)
            EXE_STACK_INIT: begin // D0
              address <= stack_P;
              trav_P <= stack_P;
              mem_func <= `GET_CONTENTS;
              mem_execute <= 1;
              state <= EXE_STACK_READ_WAIT;
            end

            EXE_STACK_READ_WAIT: begin // D1
              if (mem_ready) begin
                read_data_reg <= read_data;
                stack_a <= read_data[`hed_start:`hed_end];
                address <= read_data[`tel_start:`tel_end];
                stack_P_tel <= read_data[`tel_start:`tel_end];
                stack_mem_tag_1 <= read_data[`tag_start:`tag_end];

                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                state <= EXE_STACK_READ_WAIT_2;

              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_STACK_READ_WAIT_2: begin //D2
              if (mem_ready) begin
                stack_b <= read_data[`tel_start:`tel_end];
                stack_mem_tag_2 <= read_data[`tag_start:`tag_end];

                address <= stack_P;
                write_data <= {
                  stack_mem_tag_1[7],
                  3'b000,
                  read_data[`tag_start-1],
                  stack_mem_tag_1[2],
                  read_data[`tag_start-3],
                  stack_mem_tag_1[0],
                  read_data[`hed_start:`hed_end],
                  trav_B
                };  //Set data to visited tel and b in tel while swaping opcode and a
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state <= EXE_STACK_WRITE_WAIT;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_STACK_WRITE_WAIT: begin //D3
              if (mem_ready) begin
                address <= stack_P_tel;
                write_data <= {
                  stack_mem_tag_2[7],
                  3'b000,
                  stack_mem_tag_1[3],
                  stack_mem_tag_2[2],
                  stack_mem_tag_1[1],
                  stack_mem_tag_2[0],
                  stack_a,
                  read_data[`tel_start:`tel_end]
                };
                mem_func <= `SET_CONTENTS;
                mem_execute <= 1;
                state <= EXE_STACK_CHECK_NEXT;
                trav_B <= trav_P;


              end else begin

                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_STACK_CHECK_NEXT: begin //D4
              if (mem_ready) begin
                address <= read_data[`tel_start:`tel_end];
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                state <= EXE_STACK_CHECK_WAIT;

              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_STACK_CHECK_WAIT: begin //D5
              if (mem_ready) begin
                if((read_data[`hed_start:`hed_end] < 0) || (read_data[`hed_start:`hed_end] > 11)) begin //If invalid opcode
                  error <= `ERROR_INVALID_OPCODE;
                  exec_func <= EXE_FUNC_ERROR;
                  state <= EXE_ERROR_INIT;
                end else if (read_data[`hed_start:`hed_end] == `slot) begin
                  exec_func <= EXE_FUNC_SLOT;
                  state <= EXE_SLOT_INIT;
                  a <= stack_a;

                  b <= read_data[`tel_start:`tel_end];

                  func_addr <= address;
                  trav_P <= stack_P_tel;

                  func_return_exec_func <= EXE_FUNC_STACK;
                  func_return_state <= EXE_STACK_POP;
                end else if (read_data[`hed_start:`hed_end] == `constant) begin
                  exec_func <= EXE_FUNC_CONSTANT;
                  state <= EXE_CONSTANT_INIT;
                  a <= stack_a;

                  b <= read_data[`tel_start:`tel_end];

                  func_addr <= stack_P_tel;
                  trav_P <= stack_P_tel;

                  func_return_exec_func <= EXE_FUNC_STACK;
                  func_return_state <= EXE_STACK_POP;
                end else begin
                  stack_P <= stack_P_tel;
                  state   <= EXE_STACK_INIT;
                end
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_STACK_POP: begin //D6
              if (mem_ready) begin
                trav_P <= trav_B;
                address <= trav_P;
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                state <= EXE_STACK_POP_READ;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_STACK_POP_READ: begin //D7
              if (mem_ready) begin
                a <= read_data[`hed_start:`hed_end];

                address <= trav_B;
                mem_func <= `GET_CONTENTS;
                mem_execute <= 1;
                state <= EXE_STACK_POP_WAIT;
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_STACK_POP_WAIT: begin //D8
              if (mem_ready) begin
                opcode <= read_data[`hed_start:`hed_end];
                trav_B <= read_data[`tel_start:`tel_end];
                func_addr <= trav_B;

                if(read_data[`tel_end+9:`tel_end] ==  1023) begin // mem_addr is only max when you reach the end and use trav_b's inital value
                  func_return_exec_func <= EXE_FUNC_INIT;
                  func_return_state <= EXE_INIT_FINISHED;
                end else begin
                  func_return_exec_func <= EXE_FUNC_STACK;
                  func_return_state <= EXE_STACK_POP;
                end

                if(read_data[`tel_start:`tel_end] == `NIL && read_data[`tel_tag] == `ATOM) begin
                  exec_func <= EXE_FUNC_INIT;
                  state <= EXE_INIT_FINISHED;
                end else begin

                  case (read_data[`hed_start:`hed_end])
                    `slot: begin
                    end

                    `constant: begin
                    end

                    `evaluate: begin
                    end

                    `cell: begin
                      exec_func <= EXE_FUNC_CELL;
                      state <= EXE_CELL_INIT;
                    end

                    `increment: begin
                      exec_func <= EXE_FUNC_INCR;
                      state <= EXE_INCR_INIT;
                    end

                    `equality: begin
                    end

                    `if_then_else: begin
                    end

                    `compose: begin
                    end

                    `extend: begin
                    end

                    `invoke: begin
                    end

                    `replace: begin
                    end

                    `hint: begin
                    end
                  endcase
                end
              end else begin
                mem_func <= 0;
                mem_execute <= 0;
              end
            end

            EXE_STACK_POP_ERR: begin // D9
              if (mem_ready) begin
                $stop;
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
