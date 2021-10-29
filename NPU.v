//
//---------------- "ARM" CPU imitation ----------------
//
/*module NPU (KEY, reset, clk, LEDR, hexDisp);
 input  [1:0] KEY;
 input  reset, clk;
 output [9:0] LEDR;
 output [23:0] hexDisp;
 assign hexDisp[3:0] = R[1];
 assign hexDisp[7:4] = R[2];
 assign hexDisp[11:8] = R[11];
 assign hexDisp[15:12] = R[12];
 assign hexDisp[19:16] = R[3];
 assign hexDisp[23:20] = R[4];
 assign LEDR = R[15];

 // Clock, reset, and breakpoint
 
 reg run; // Flag indicating CPU is running

 // CPU instruction cycle
 
 reg [1:0] CPU_state;
 parameter init_memory     = 2'b01;
 parameter reduce    = 2'b10;
 parameter execute   = 2'b11;
 parameter read_results = 2'b00;

 // Instruction format
 
 wire [3:0] opCode; // Operation code value
 wire iFlag; // Immedite data flag
 wire [7:0] op2; // Second operand raw code
 wire [7:0] RdValDP; // Destination register value
 reg  [7:0] RnVal; // Source data register value
 reg  [7:0] RmVal; // 2nd op data register value
 wire [3:0] RdID; // Destination register number
 wire [3:0] RnID; // Source register number
 wire [3:0] RmID; // Second operand register number
 wire [20:0] IR; // Instruction register
 reg [7:0] op2Val; // Numeric value of second operand
 assign iFlag  = IR[20]; // Immediate data flag
 assign opCode = IR[19:16]; // Opcode is in upper 4 bits
 assign RnID   = IR[15:12]; // Source data register
 assign RdID   = IR[11:8]; // Destination register
 assign RmID   = IR[3:0]; // 2nd operand register
 assign op2    = IR[7:0]; // Operand is in lower 8 bits
 
 // General purpose registers R0 - R15

 reg [7:0] R[0:15]; // 16 registers
 parameter PC = 15; // Program Counter
 
 // Instantiate program memory and ALU processing
 
 ProgMod (R[PC], CPU_state==fetch, reset, IR);
 DataProcIns (opCode, RnVal, RmVal, op2, iFlag, CPU_state==execute, RdValDP);
 
 // Instruction cycle and reset
 
 always @ (posedge(clk), posedge(reset))
  begin
   if (reset)
    begin
     R[PC] <= 0; // Boot address is 0000
     CPU_state <= fetch;
    end
   else
    case (CPU_state)
     fetch:   // Get next instruction in program
      begin
       R[PC] <= R[PC] + 1;
       CPU_state <= decode;
      end
     decode:  // Disassemble the instruction 
      begin
       RnVal <= R[RnID]; // Source data register
       RmVal <= R[RmID]; // 2nd op data register
       if (~KEY[0]) // Instruction cycle interlock
        run <= 0;
       if (~KEY[1] && ~run)
        begin
         run <= 1;
         CPU_state <= execute;
        end
      end
     execute: // Perform desired operation
      CPU_state <= writeBack;
     writeBack: // Update specific register
      begin
       R[RdID] <= RdValDP; // Destination register
       CPU_state <= fetch;
      end
    endcase
  end
endmodule

//
//---------------- ALU for ARM data processing instructions ----------------
//
// Note: All arguments are values (i.e, not register ID numbers)
module DataProcIns (opCode, Rn, Rm, op2raw, iFlag, clk, Rd);
 input [3:0] opCode; // Data processing instruction opcode
 input [7:0] Rn; // Source register contents
 input [7:0] Rm; // Possible 2nd operand register contents
 input [7:0] op2raw; // Second operand "as is"
 input  iFlag; // Immediate value flag
 input  clk; // Pulse to produce calculation
 output reg [7:0] Rd; // Value to return
 wire  [7:0] op2; // Calculated value of second operand
 assign op2 = (iFlag) ? op2raw : Rm;
 always @ (posedge(clk))
  case (opCode)
   0:  Rd <= Rn & op2;  // AND
   1:  Rd <= Rn ^ op2;  // EOR (exclusive OR)
   2:  Rd <= Rn - op2;  // SUB
   3:  Rd <= op2 - Rn;  // RSB (reverse subtract)
   4:  Rd <= Rn + op2;  // ADD
   12: Rd <= Rn | op2;  // ORR (inclusive OR)
   13: Rd <= op2;       // MOV
   14: Rd <= Rn & ~op2; // BIC (bit clear)
   15: Rd <= ~op2;      // MVN (move NOT)
   default: Rd <= 0;    // None of above
  endcase
endmodule

//
//---------------- Macro definitions for assembly language ----------------
//
 `define AND asdp (4'd0,  // [Rd] = [Rn] AND (2nd operand)
 `define EOR asdp (4'd1,  // [Rd] = [Rn] Exclusive Or (2nd operand)
 `define SUB asdp (4'd2,  // [Rd] = [Rn] - (2nd operand)
 `define RSB asdp (4'd3,  // [Rd] = (2nd operand) - [Rn]
 `define ADD asdp (4'd4,  // [Rd] = [Rn] + (2nd operand)
 `define ORR asdp (4'd12, // [Rd] = [Rn] Inclusive OR (2nd operand)
 `define MOV asdp (4'd13, // [Rd] = [Rn]
 `define BIC asdp (4'd14, // [Rd] = [Rn] AND NOT (2nd operand)
 `define MVN asdp (4'd15, // [Rd] = NOT [Rn]
 `define _    );            // End of instruction

//
//---------------- Memory containing "ARM" program ----------------
//
module ProgMod (address, clk, reset, instr);
 input  [7:0] address;
 input clk, reset;
 output [20:0] instr;
 parameter R0  = 16'h1000; // General purpose register set names
 parameter R1  = 16'h1001;
 parameter R2  = 16'h1002;
 parameter R3  = 16'h1003;
 parameter R4  = 16'h1004;
 parameter R5  = 16'h1005;
 parameter R6  = 16'h1006;
 parameter R7  = 16'h1007;
 parameter R8  = 16'h1008;
 parameter R9  = 16'h1009;
 parameter R10 = 16'h100A;
 parameter R11 = 16'h100B;
 parameter R12 = 16'h100C;
 parameter R13 = 16'h100D; // a.k.a. "LR"
 parameter R14 = 16'h100E; // a.k.a. "SP"
 parameter R15 = 16'h100F; // a.k.a. "PC"

 integer IP;
 task asdp ();
  input [15:0] opcode,Rd,Rn,Rm;
  if (Rm < 'h1000)
   progMem[IP] = {1'b1,opcode[3:0],Rn[3:0],Rd[3:0],Rm[7:0]};
  else
   progMem[IP] = {1'b0,opcode[3:0],Rn[3:0],Rd[3:0],Rm[7:0]};
  IP = IP + 1;
 endtask
 
 reg [63:0] progMem[0:25]; // 21 bits per instruction
 reg [20:0] IR;             // Instruction Register
 assign instr = IR;
 
 always @ (posedge(clk))
  IR <= progMem[address];
 always @ (posedge(reset))
 begin
  IP = 0;
  `MOV R1,0,'b0101 `_ // Move 0b0101 into R1
  `MOV R2,0,'b0011 `_ // Move 0b0011 into R2
  `BIC R11,R1,R2   `_ // Not(R2) & (R1) => R11
  `BIC R12,R2,R1   `_ // Not(R1) & (R2) => R12
  `ORR R3,R11,R12  `_ // (R11) | (R12) => R3  
  `EOR R4,R1,R2    `_ // Exclusive OR instruction
  progMem[25] = 0;
 end
endmodule*/
