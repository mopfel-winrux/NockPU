/*
 Will have 3 main functions used by external modules.
  - Given an address of a cell, return its value
  - Given an address of a cell, the cell's value, and a type tag, write to memory
  - Request the next empty cell available in the memory, return address of empty cell
 Memory is word addressable. When all the correct values are set, 
 pull execute to high and wait for is_ready to go high. This will mark that your command is finished 
*/

`include "memory_unit.vh"

module memory_unit(power, clk, rst, func, execute, address, write_data, free_addr, read_data, is_ready, state, mem_data_out);

   input power, clk, rst;

   // Control wires for this module
   input [1:0] func;
   input execute;
   input [`memory_addr_width - 1:0] address;
   input [`memory_data_width - 1:0] write_data;

   // Signal wires for this module
   reg is_ready_reg;
   output wire is_ready;
   assign is_ready = !execute && is_ready_reg;
   output reg [`memory_addr_width - 1:0] free_addr;
   output reg [`memory_data_width - 1:0] read_data;
   
   // Interface with the ram module
   reg [`memory_addr_width - 1:0] mem_addr;
   reg mem_write;
   reg [`memory_data_width - 1:0] mem_data_in;
   output wire [`memory_data_width - 1:0] mem_data_out;
   
   // Internal regs and wires
   reg [`memory_addr_width - 1:0] free_mem;
   output reg [3:0] state;
   
   // States
   parameter STATE_INIT_SETUP          = 4'h0,
             STATE_INIT_WAIT_0         = 4'h1,
             STATE_INIT_STORE_FREE_MEM = 4'h2,
             STATE_INIT_CLEAR_NIL      = 4'h3,
             STATE_INIT_WAIT_1         = 4'h4,
             STATE_WAIT                = 4'h5,
             STATE_READ_WAIT_0         = 4'h6,
             STATE_READ_FINISH         = 4'h7,
             STATE_WRITE_WAIT_0        = 4'h8,
             STATE_WRITE_FINISH        = 4'h9,
             STATE_FREE_WAIT           = 4'hA,
             STATE_GARBAGE_COLLECT     = 4'hB;
             
   ram ram(.address (mem_addr),
           .clock (clk),
           .data (mem_data_in),
           .wren (mem_write),
           .q (mem_data_out));
   
   always@(posedge clk or negedge rst) begin
      if(!rst) begin
         state <= STATE_INIT_SETUP;
         
         free_mem <= 0;
         
         mem_addr <= 0;
         mem_data_in <= 0;
         
         is_ready_reg <= 0;
      end
      else if (power) begin
         case (state)
            // Initialize the free memory register
            STATE_INIT_SETUP: begin
               state <= STATE_INIT_WAIT_0;
               mem_addr <= 0;
            end
            STATE_INIT_WAIT_0: begin
               state <= STATE_INIT_STORE_FREE_MEM;
            end
            // Record the start of the free memory store
            STATE_INIT_STORE_FREE_MEM: begin
               state <= STATE_INIT_CLEAR_NIL;
               free_mem <= mem_data_out[9:0];
            end
            // Clear the nil pointer
            STATE_INIT_CLEAR_NIL: begin
               state <= STATE_INIT_WAIT_1;
               
               mem_addr <= 0;
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
                        mem_addr <= address;
                        state <= STATE_READ_WAIT_0;
                     end
                     `SET_CONTENTS: begin
                        mem_addr <= address;
                        mem_data_in <= write_data;
                        mem_write<=1;
                        state <= STATE_WRITE_WAIT_0;

                     end
                     `GET_FREE: begin
                        if(free_addr + write_data <= 1023) begin // if you have enough free memory
                           free_addr <= free_mem;
                           free_mem <= free_mem + write_data;
                           state <= STATE_FREE_WAIT;
                        end
                        else begin
                           state <= STATE_GARBAGE_COLLECT;
                        end
                     end
                  endcase
               end
               // Keep waiting
               else begin
                  state <= STATE_WAIT;
                  is_ready_reg <= 1;
                  //mem_addr <= 0;
               end
            end
            // Various wait states used when reading from memory
            STATE_READ_WAIT_0: begin
               state <= STATE_READ_FINISH;
            end
            STATE_READ_FINISH: begin
               state <= STATE_WAIT;
               is_ready_reg <= 1;
               
               read_data <= mem_data_out;
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
            // Return a new cell
            STATE_GARBAGE_COLLECT: begin             
               state <= STATE_GARBAGE_COLLECT;
            end
            default:;
         endcase
      end
   end

endmodule
