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
 reg [2:0] CPU_state;
 
 
 //Noun Type Parameters
 parameter cell_noun   = 3'b111;
 parameter op_noun     = 3'b101;
 parameter atom_noun   = 3'b0??;
 
 
 //CPU State Parameters
 parameter dive   = 2'b10;
 parameter decode  = 2'b01;
 parameter pop = 2'b11;
 
 parameter nil = 32'hFFFFFFFF;
 
 assign LEDR[9:7] = CPU_state;
 
 reg [31:0] P; // Current Pointer Register
 reg [31:0] B; // Back Pointer Register
 reg [31:0] P_val; // Current Pointer Value
 reg [31:0] tmp; // Current Pointer Value

 
 reg marker;
 reg dive_dir;
 reg pop_dir;
 reg B_mem;
 reg [31:0] hed [0:7]; // Program memory
 reg [31:0] tel [0:7]; // Program memory

 //Display P register 
 assign HEX0 = digit(B[3:0]);
 assign HEX1 = digit(P[3:0]);
 
 //Display P_tel register contents
 assign HEX3 = digit(tel[P][31:28]);
 assign HEX2 = digit(tel[P][3:0]);
 
 //Display P_hed register contents
 assign HEX5 = digit(hed[P][31:28]);
 assign HEX4 = digit(hed[P][3:0]);

 assign LEDR[0] = dive_dir;
 assign LEDR[1] = pop_dir;

 assign LEDR[2] = marker;
 
 reg run; // Flag indicating CPU is running
 always @ (posedge(clk), posedge(reset))
  begin
   if (reset)
    begin
     hed [0] <= 32'hE0000001; //Pointer to 0x01
  	  hed [1] <= 32'hE0000002; //Pointer to 0x02
	  hed [2] <= 32'h00000004; //Atom - 4
  	  hed [3] <= 32'h00000006; //Atom - 6
	  hed [4] <= 32'h0000000E; //Atom - 14

	  tel [0] <= 32'hFFFFFFFF; //NULL
  	  tel [1] <= 32'hE0000003; //Pointer to 0x03
	  tel [2] <= 32'h00000005; //Atom - 5
  	  tel [3] <= 32'hE0000004; //Pointer to 0x04
	  tel [4] <= 32'h0000000F; //Atom - 15
	  
	  
     dive_dir <= 0;
	  pop_dir <= 0;
	  P <= 32'h00000000;
	  B <= nil;
	  B_mem <= 0;
	  P_val <= hed[P];
	  marker <= 0;
	  
     CPU_state <= decode;
    end
   else
    case (CPU_state)
	 
	  decode:  // Disassemble the instruction 
      begin
		 if (dive_dir==0)
			P_val = hed[P];
		 else
		   P_val = tel[P];

		
		 casex (P_val[31:29])
		  cell_noun:
		   begin
		    CPU_state <= dive;
		   end
		  op_noun:
		   begin
		    //TODO what happens when a noun is an opcode
		   end
		  atom_noun:
		   begin
			 if(dive_dir == 0)
			  begin
			   dive_dir = 1;
				CPU_state <= decode;
			  end
			  else
			   CPU_state <= pop;
			end
		 endcase
      end
		
     dive:
      begin
		 if(dive_dir == 0)
		  begin //BUG: For some reason hed/tel doesn't get set to B
		   hed[P] <= B;
		   P <= hed[P];
		   B <= P;
		  end
		 else
		  begin
		   tel[P] <= B;
		   P <= tel[P];
		   B <= P;
		  end
       dive_dir <= 0;
       CPU_state <= decode;
      end
		
	  pop:
	   begin
	    B <= hed[B];
		 P <= B;
		 hed[B] <= P;
		 //BUG: I need to figure out how and when the pop state -> pop state rather than decode
		 dive_dir <= 1;
		 CPU_state <= decode;
		end
    endcase
  end
endmodule