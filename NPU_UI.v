`include "memory_unit.vh"

//
//---------------- User Interface ----------------
//
module NPU_UI (KEY, LEDR, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);

//Setup UI for NPU. Hex display and key
 input  [1:0] KEY;
 //input  CLOCK_50;
 output [9:0] LEDR;
 output [7:0] HEX0, HEX1, HEX2, HEX3, HEX4,HEX5;
  function automatic [7:0] digit;
   input [3:0] num; 
   case (num)
     0:  digit = 8'b11000000;  // 0
     1:  digit = 8'b11111001;  // 1
     2:  digit = 8'b10100100;  // 2
     3:  digit = 8'b10110000;  // 3
     4:  digit = 8'b10011001;  // 4
     5:  digit = 8'b10010010;  // 5
     6:  digit = 8'b10000010;  // 6
     7:  digit = 8'b11111000;  // 7
     8:  digit = 8'b10000000;  // 8
     9:  digit = 8'b10010000;  // 9
     10: digit = 8'b10001000;  // A
     11: digit = 8'b10000011;  // b
     12: digit = 8'b11000110;  // C
     13: digit = 8'b10100001;  // d
     14: digit = 8'b10000110;  // E
     15: digit = 8'b10001110;  // F
   endcase
  endfunction
 wire clk,w1,reset;
 nand(clk,KEY[0],w1); // Set up RS FF latch
 nand(w1,KEY[1],clk); // as debounced clock.
 //assign clk = CLOCK_50;
 and(reset,~KEY[0],~KEY[1]); // Reset if both keys pushed
 
 //NPU State Registers
 reg [2:0] CPU_state;
 parameter start    = 2'b00;

 reg [`memory_addr_width - 1:0] start_addr;

  
 wire [1:0] mem_func;
 wire mem_execute;
 wire power;
 wire [`memory_addr_width - 1:0] addr;
 wire [`memory_data_width - 1:0] data_in;
 wire [`memory_addr_width - 1:0] addr_out;
 wire [`memory_data_width - 1:0] data_out;
 wire mem_ready;
 
 memory_unit mem(.func (mem_func),
                 .execute (mem_execute),
                 .addr_in (addr),
                 .data_in (data_in),
                 .addr_out (addr_out),
                 .data_out (data_out),
                 .is_ready (mem_ready),
                 .power (power),
                 .clk (clk),
                 .rst (reset));

 wire traversal_execute;
                 
 mem_traversal traversal(.power (power),
                 .clk (clk),
                 .rst (reset),
                 .start_addr (start_addr),
                 .execute (traversal_execute),
                 .mem_ready (mem_ready),
                 .read_addr (addr),
                 .read_data (data_in),
                 .mem_execute (mem_execute),
                 .mem_func (mem_func),
                 .write_addr (addr_out),
                 .write_data (data_out));
                 
 
 
 reg run; // Flag indicating CPU is running
 always @ (posedge(clk), posedge(reset))
  begin
   if (reset)
   begin

   end
   else
      case (CPU_state)
      start:
      begin
      
      end
      endcase
   end
endmodule