`include "memory_unit.vh"


module mem_traversal(power, clk, rst, start_addr,  execute, mem_ready, read_addr, read_data, mem_execute, mem_func, write_addr, write_data);
   input power, clk, rst;
   input [`memory_addr_width - 1:0] start_addr; //Address to start traversal at
   input execute; // wire to begin traversal
   
   //Interface with memory unit
   input mem_ready;
   input [`memory_data_width - 1:0] read_data;
   
   output reg mem_execute;
   output reg [`memory_addr_width - 1:0] read_addr;
   output reg [1:0] mem_func;
   output reg [`memory_addr_width - 1:0] write_addr; // Not sure if needed
   output reg [`memory_data_width - 1:0] write_data; // Not sure if needed
   
   // Internal registers needed
   reg [3:0] sys_func;
   reg [3:0] state;
   reg [3:0] mem_tag;
   reg [(`memory_data_width-4)/2 - 1:0] hed, tel;
   reg [`memory_addr_width - 1:0] mem_addr;
   reg [`memory_data_width - 1:0] mem_data;
   
   // Traversal Registers needed
   reg [(`memory_data_width-4)/2 - 1:0] trav_P;
   reg [(`memory_data_width-4)/2 - 1:0] trav_B;

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
             SYS_READ_DECODE = 4'h3;
   
   // Write States
   parameter SYS_WRITE_INIT = 4'h0,
             SYS_WRITE_WAIT = 4'h1;
   
   // Traverse States
   parameter SYS_TRAVERSE_INIT   = 4'h0,
             SYS_TRAVERSE_PUSH   = 4'h1,
             SYS_TRAVERSE_POP    = 4'h2,
             SYS_TRAVERSE_TEL    = 4'h3;
   
   // Execute States
   parameter SYS_EXECUTE_INIT = 4'h0;
   
   always@(posedge clk or negedge rst) begin
      if(!rst) begin
         
         sys_func <= SYS_FUNC_READ;
         state <= SYS_READ_INIT;
         mem_addr <= start_addr;
         trav_B <= `NIL;
         
      end
      else if (power) begin
         case (sys_func)
            SYS_FUNC_READ: begin
               case(state)
                  SYS_READ_INIT: begin
                     read_addr <= mem_addr;
                     mem_func <= `GET_CONTENTS;
                     mem_execute <= 1;
                  
                     state <= SYS_READ_WAIT;
                  end
                  
                  SYS_READ_WAIT: begin
                     
                     if(mem_ready) begin
                        mem_data <= read_data;
                        mem_tag <= read_data[`tag_start:`tag_end]; // read first 4 bits and store into tag for easier access
                        
                        hed <= read_data[`hed_start:`hed_end];
                        tel <= read_data[`tel_start:`tel_end];
                        state <= SYS_READ_DECODE;
                     end
                     else begin
                        read_addr <= 0;
                        mem_func <= 0;
                        mem_execute <= 0;
                     end
                  
                  end
                  
                  SYS_READ_DECODE: begin
                     // If cell is marked for execution
                     if(mem_tag[2] == 1) begin
                        sys_func <= SYS_FUNC_EXECUTE;
                        state <= SYS_EXECUTE_INIT;
                     end
                     else begin
                        sys_func <= SYS_FUNC_TRAVERSE;
                        state <= SYS_TRAVERSE_INIT;
                     end
                     
                  end
               endcase
               
               
            end
            
            SYS_FUNC_WRITE: begin
               case(state)
                  SYS_WRITE_INIT: begin
                     write_addr <= mem_addr;
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
                        write_addr <= 0;
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
                              if(mem_tag[3] == 0) begin // if the hed cell hasn't been visited we push into it
                              
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
                                 write_return_sys_func <= SYS_FUNC_TRAVERSE;
                                 write_return_state <= SYS_TRAVERSE_POP;
                                 
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
                              if(mem_tag[2] == 0) begin // if both were visited
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
                                 // Set the command after write to pop
                                 write_return_sys_func <= SYS_FUNC_TRAVERSE;
                                 write_return_state <= SYS_TRAVERSE_POP;
                                 
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
                              if(mem_tag[3] == 0) begin // if the hed cell hasn't been visited we push into it
                              
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
                                 write_return_sys_func <= SYS_FUNC_TRAVERSE;
                                 write_return_state <= SYS_TRAVERSE_POP;
                                 
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
                     
                  end
                  
                  SYS_TRAVERSE_POP: begin
                     mem_addr <= trav_P;
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
            
            SYS_FUNC_EXECUTE: begin
               sys_func <= SYS_FUNC_READ;
               state <= SYS_READ_INIT;
            end
         endcase
      end
   end
   
endmodule