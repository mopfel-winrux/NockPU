/*
 Will have 3 main functions used by external modules.
  - Given an address of a cell, return its value
  - Given an address of a cell, the cell's value, and a type tag, write to memory
  - Request the a batch of emprt cells that have a length of write_data.
    These are garrenteed to be open and this will cause a GC to run if not.
 Memory is word addressable. When all the correct values are set,
 pull execute to high and wait for is_ready to go high. This will mark that your command is finished
*/

`include "memory_unit.vh"

module memory_unit(
  input power,
  input clk,
  input rst,
  input [1:0] func, 
  input execute,
  input [`memory_addr_width - 1:0] address1,
  input [`memory_addr_width - 1:0] address2,
  input [`memory_data_width - 1:0] write_data,
  output reg [`memory_addr_width - 1:0] free_addr,
  output reg [`memory_data_width - 1:0] read_data1,
  output reg [`memory_data_width - 1:0] read_data2,
  output wire is_ready,
  output wire [`memory_data_width - 1:0] mem_data_out1,
  output wire [`memory_data_width - 1:0] mem_data_out2
);
  // Signal wires for this module
  reg is_ready_reg;
  assign is_ready = !execute && is_ready_reg;

  // Interface with the ram module
  reg [`memory_addr_width - 1:0] mem_addr1;
  reg [`memory_addr_width - 1:0] mem_addr2;
  reg mem_write;
  reg [`memory_data_width - 1:0] mem_data_in;

  //Garbage Collection Registers
  reg [`memory_addr_width - 1:0] gc_x;
  reg [`memory_addr_width - 1:0] gc_h;
  reg [`memory_addr_width - 1:0] gc_k;
  reg [`memory_addr_width - 1:0] gc_n;
  reg [`memory_data_width - 1:0] gc_a;
  reg [`memory_data_width - 1:0] gc_d;


  // Internal regs and wires
  reg [`memory_addr_width - 1:0] free_mem;

  reg [4:0] state;
  // States
  parameter STATE_INIT_SETUP          = 5'h0,
            STATE_INIT_WAIT_0         = 5'h1,
            STATE_INIT_STORE_FREE_MEM = 5'h2,
            STATE_INIT_CLEAR_NIL      = 5'h3,
            STATE_INIT_WAIT_1         = 5'h4,
            STATE_WAIT                = 5'h5,
            STATE_READ_WAIT_0         = 5'h6,
            STATE_READ_FINISH         = 5'h7,
            STATE_WRITE_WAIT_0        = 5'h8,
            STATE_WRITE_FINISH        = 5'h9,
            STATE_FREE_WAIT           = 5'hA,
            STATE_GC_A1               = 5'hB,
            STATE_GC_A2               = 5'hC,
            STATE_GC_A3               = 5'hD,
            STATE_GC_A4               = 5'hE,
            STATE_GC_A5               = 5'hF,
            STATE_GC_A6               = 5'h10,
            STATE_GC_B1               = 5'h11,
            STATE_GC_B2               = 5'h12,
            STATE_GC_B3               = 5'h13;

  ram ram(.address1 (mem_addr1),
          .address2 (mem_addr2),
          .clock (clk),
          .data (mem_data_in),
          .wren (mem_write),
          .q1 (mem_data_out1),
          .q2 (mem_data_out2));

  always@(posedge clk or negedge rst) begin
  if(!rst) begin
    state <= STATE_INIT_SETUP;
    free_mem <= 0;

    mem_addr1 <= 0;
    mem_addr2 <= 0;
    mem_data_in <= 0;

    is_ready_reg <= 0;
  end
  else if (power) begin
    case (state)
    // Initialize the free memory register
    STATE_INIT_SETUP: begin
      state <= STATE_INIT_WAIT_0;
      mem_addr1 <= 0;
      mem_addr2 <= 0;
    end
    STATE_INIT_WAIT_0: begin
      state <= STATE_INIT_STORE_FREE_MEM;
    end
    // Record the start of the free memory store
    STATE_INIT_STORE_FREE_MEM: begin
      state <= STATE_INIT_CLEAR_NIL;
      free_mem <= mem_data_out1[9:0];
    end
    // Clear the nil pointer
    STATE_INIT_CLEAR_NIL: begin
      state <= STATE_INIT_WAIT_1;
      mem_addr1 <= 0;
      mem_addr2 <= 0;
      mem_data_in <= 0;
    end
    STATE_INIT_WAIT_1: begin
      state <= STATE_WAIT;
      free_addr <= free_mem;

      mem_write <= 0;
    end

    // Wait for a command dispatch
    STATE_WAIT: begin
      if(execute) begin
        is_ready_reg <= 0;
        // Dispatch according to the function
        case (func)
        `GET_CONTENTS: begin
          mem_addr1 <= address1;
          mem_addr2 <= address2;
          state <= STATE_READ_WAIT_0;
        end

        `SET_CONTENTS: begin
          mem_addr1 <= address1;
          mem_data_in <= write_data;
          mem_write<=1;
          state <= STATE_WRITE_WAIT_0;
        end

        `GET_FREE: begin
          if(free_addr + write_data <= 2047) begin // if you have enough free memory
            free_addr <= free_mem;
            free_mem <= free_mem + write_data;
            state <= STATE_FREE_WAIT;
          end
          else begin
            state <= STATE_GC_A1;
          end
        end
        endcase
      end else begin
        state <= STATE_WAIT;
        is_ready_reg <= 1;
      end
    end

    // Various wait states used when reading from memory
    STATE_READ_WAIT_0: begin
      state <= STATE_READ_FINISH;
    end

    STATE_READ_FINISH: begin
      state <= STATE_WAIT;
      is_ready_reg <= 1;
      read_data1 <= mem_data_out1;
      read_data2 <= mem_data_out2;
    end
    
    // Various wait states used when writing to memory
    STATE_WRITE_WAIT_0: begin
      state <= STATE_WRITE_FINISH;
      mem_write<=0;
    end

    STATE_WRITE_FINISH: begin
      state <= STATE_WAIT;
      is_ready_reg <= 1;
    end

    // Return a new cell
    STATE_FREE_WAIT: begin
      is_ready_reg <= 1;
      state <= STATE_WAIT;
    end
    
    // Garbage Collect
    STATE_GC_A1: begin
      //  [Initialize.] x+--h, h*-n, and k*--NIL.
      state <= STATE_GC_A2;
    end

    STATE_GC_A2: begin
      state <= STATE_GC_A3;
    end
    STATE_GC_A3: begin
      state <= STATE_GC_A4;
    end
    STATE_GC_A4: begin
      state <= STATE_GC_A5;
    end
    STATE_GC_A5: begin
      state <= STATE_GC_A6;
    end
    STATE_GC_A6: begin
      state <= STATE_GC_B1;
    end
    STATE_GC_B1: begin
      state <= STATE_GC_B2;
    end
    STATE_GC_B2: begin
      state <= STATE_GC_B3;
    end
    STATE_GC_B3: begin
      $stop;
      state <= STATE_GC_B1;
    end

    default:;
    endcase
  end
end

endmodule
