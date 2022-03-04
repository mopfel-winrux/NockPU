`include "memory_unit.vh"
`include "mem_traversal.vh"
`include "execute.vh"


module execute(clk, rst, error, execute_start, execute_address, execute_tag, execute_data,
                     mem_ready, mem_execute, mem_func, address, free_addr, read_data, write_data,
                     finished, execute_return_sys_func, execute_return_state);
    input clk, rst;
    output reg [7:0] error;

    // Interface with memory traversal
    input execute_start; // wire to begin execution (mux_conroller from traversal)
    input [`memory_addr_width - 1:0] execute_address;
    input [4:0] execute_tag;
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
    output reg [1:0] mem_func;
    output reg [`memory_data_width - 1:0] write_data; 

    //Internal Registers
    reg [(`memory_data_width-4)/2 - 1:0] a, opcode, b, c, d;

    reg [4:0] mem_tag;
    reg [(`memory_data_width-4)/2 - 1:0] hed, tel;
    reg [`memory_addr_width - 1:0] mem_addr;
    reg [`memory_data_width - 1:0] mem_data;

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
              EXE_FUNC_ERROR    = 4'hD;

    // slot states
    parameter EXE_SLOT_INIT                 = 4'h0;

    // Constant states
    parameter EXE_CONSTANT_INIT             = 4'h0,
              EXE_CONSTANT_WRITE_WAIT       = 4'h1;

    //eval states
    parameter EXE_EVAL_INIT                 = 4'h0;

    //cell states
    parameter EXE_CELL_INIT                 = 4'h0;
    
    //increment states
    parameter EXE_INCR_INIT                 = 4'h0;
    
    //equal states
    parameter EXE_EQUAL_INIT                = 4'h0;
    
    //if then else states
    parameter EXE_IF_INIT                   = 4'h0;
    
    //compose states
    parameter EXE_COMPOSE_INIT              = 4'h0;
    
    //extend states
    parameter EXE_EXTEND_INIT               = 4'h0;
    
    //invoke states
    parameter EXE_INVOKE_INIT               = 4'h0;
    
    //replace states
    parameter EXE_REPLACE_INIT              = 4'h0;
    
    //eval states
    parameter EXE_HINT_INIT                 = 4'h0;
    
    // Error States
    parameter EXE_ERROR_INIT                = 4'h0; 

    // Init States
    parameter EXE_INIT_INIT                 = 4'h0,
              EXE_INIT_READ_TEL             = 4'h1,
              EXE_INIT_DECODE               = 4'h2,
              EXE_INIT_FINISHED             = 4'hF;


    
    always@(posedge clk or negedge rst) begin
        if(!rst) begin
            exec_func <= EXE_FUNC_INIT;
            state <= EXE_INIT_INIT;
            is_finished_reg <=0;
            read_data_reg <= 0;
            execute_return_sys_func <=  0;
            execute_return_state <= 0;
        end
        else if (execute_start) begin
            case (exec_func)
                EXE_FUNC_INIT: begin
                    case(state)
                        EXE_INIT_INIT: begin
                            if(execute_start) begin
                                if(execute_tag[0] == 1) begin
                                    error <= `ERROR_TEL_NOT_CELL;
                                    state <= EXE_ERROR_INIT;
                                    exec_func <= EXE_FUNC_ERROR;
                                end
                                else begin
                                    mem_tag <= execute_tag; 

                                    a <= execute_data[`hed_start:`hed_end];
                                    address <= execute_data[`tel_start:`tel_end];
                                    mem_func <= `GET_CONTENTS;
                                    mem_execute <= 1;
                                    state <= EXE_INIT_READ_TEL;

                                end
                            end
                            else begin
                                mem_func <= 0;
                                mem_execute <= 0;
                                is_finished_reg <=0;
                            end
                        end

                        EXE_INIT_READ_TEL: begin
                            if(mem_ready) begin
                                mem_data <= read_data;
                                mem_tag <= read_data[`tag_start:`tag_end]; // read first 4 bits and store into tag for easier access
                                
                                opcode <= read_data[`hed_start:`hed_end];
                                b <= read_data[`tel_start:`tel_end];
                                state <= EXE_INIT_DECODE;
                            end
                            else begin
                                mem_func <= 0;
                                mem_execute <= 0;
                            end
                        end

                        EXE_INIT_DECODE: begin
                            if((opcode < 0) || (opcode > 11)) begin //If invalid opcode
                                error <= `ERROR_INVALID_OPCODE;

                                exec_func <= EXE_FUNC_ERROR;
                                state <= EXE_ERROR_INIT;

                            end
                            else begin
                                case(opcode)
                                    `slot: begin
                                        exec_func <= EXE_FUNC_SLOT;
                                        state <= EXE_SLOT_INIT;
                                    end

                                    `constant: begin
                                        if(mem_tag[0] == 0) begin
                                            address <= b;
                                            mem_func <= `GET_CONTENTS;
                                            mem_execute <= 1;
                                            exec_func <= EXE_FUNC_CONSTANT;
                                            state <= EXE_CONSTANT_INIT;
                                        end
                                        else begin
                                            address <= execute_address;
                                            mem_func <= `SET_CONTENTS;
                                            mem_execute <= 1;
                                            exec_func <= EXE_FUNC_CONSTANT;
                                            state <= EXE_CONSTANT_WRITE_WAIT;
                                            write_data <= {5'b00011, b, 0};
                                        end

                                    end
                                    
                                    `evaluate: begin
                                        exec_func <= EXE_FUNC_EVAL;
                                        state <= EXE_EVAL_INIT;
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
                            if(execute_start == 0) begin // If still high don't do anything
                                exec_func <= EXE_FUNC_INIT;
                                state <= EXE_INIT_INIT;
                                is_finished_reg <=0;
                                execute_return_sys_func <=  0;
                                execute_return_state <= 0;
                            end
                        end

                    endcase
                end
            

                EXE_FUNC_SLOT: begin
                    //case(state)
                    $stop;
                    //endcase
                end

                EXE_FUNC_CONSTANT: begin
                    case(state)
                        EXE_CONSTANT_INIT: begin
                            if(mem_ready) begin
                                address <= execute_address;
                                mem_func <= `SET_CONTENTS;
                                mem_execute <= 1;
                                state <= EXE_CONSTANT_WRITE_WAIT;
                                write_data <= read_data_reg;
                            end
                            else begin
                                mem_func <= 0;
                                mem_execute <= 0;
                                read_data_reg <= read_data;
                            end
                        end

                        EXE_CONSTANT_WRITE_WAIT: begin
                            if(mem_ready) begin
                                exec_func = EXE_FUNC_INIT;
                                state = EXE_INIT_FINISHED;
                                execute_return_sys_func <=  `SYS_FUNC_READ;
                                execute_return_state <= `SYS_READ_INIT;
                                is_finished_reg <=1;
                            end
                            else begin
                                mem_func <= 0;
                                mem_execute <= 0;
                            end
                        end

                    endcase
                end

                EXE_FUNC_EVAL: begin
                    //case(state)
                    $stop;
                    //endcase
                end

                EXE_FUNC_CELL: begin
                    //case(state)
                    $stop;
                    //endcase
                end

                EXE_FUNC_INCR: begin
                    //case(state)
                    $stop;
                    //endcase
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

                
                EXE_FUNC_ERROR: begin
                    execute_return_sys_func <=  `SYS_FUNC_EXECUTE;
                    execute_return_state <= `SYS_EXECUTE_ERROR;
                    is_finished_reg <=1;
                end
            endcase
        end
    end
endmodule