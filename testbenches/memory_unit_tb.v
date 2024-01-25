`timescale 1ns/1ns
`include "../verilog/memory_unit.vh"


module memory_unit_tb();

//Test Parameters
parameter MEM_INIT_FILE = "./memory/memory.hex";
parameter MEM_WRITE_DATA = 68'hDEADBEEF;

//Signal Declarations
reg MAX10_CLK1_50;

wire clk;
assign clk = MAX10_CLK1_50;

reg reset;


reg [1:0] mem_func;

reg mem_execute;
wire power;
assign power = 1'b1;

reg [`memory_addr_width - 1:0] addr;


reg [`memory_data_width - 1:0] write_data;
wire [`memory_addr_width - 1:0] free_addr;
wire [`memory_data_width - 1:0] read_data;
wire [`memory_data_width - 1:0] mem_data_out;

reg [`memory_addr_width - 1:0] free_addr_reg;

wire mem_ready;
wire [3:0] state;


// Instantiate Memory Unit
memory_unit mem(.func (mem_func),
                .execute (mem_execute),
                .address (addr),
                .write_data (write_data),
                .free_addr (free_addr),
                .read_data (read_data),
                .is_ready (mem_ready),
                .power (power),
                .clk (clk),
                .state (state),
                .mem_data_out(mem_data_out),
                .rst (reset));

// Setup Clock
initial begin
  MAX10_CLK1_50 =0;
  forever MAX10_CLK1_50 = #10 ~MAX10_CLK1_50;
end

integer idx;

// Perform Test
initial begin
  if (MEM_INIT_FILE != "") begin
    $readmemh(MEM_INIT_FILE, mem.ram.ram);
  end
  $dumpfile("memory_unit_tb.vcd");
  $dumpvars(0, memory_unit_tb);

  for (idx = 0; idx < 1023; idx = idx+1) begin
    $dumpvars(0,mem.ram.ram[idx]);
  end


  mem_execute = 0;
  // Reset
  reset = 1'b0;
  repeat (2) @(posedge clk);
  reset = 1'b1;
  wait (mem_ready == 1'b1);


  // Get Next Free Memory Location
  mem_func = `GET_FREE;
  write_data <= 1;
  mem_execute = 1;
  repeat (2) @(posedge clk);
  mem_execute = 0;
  free_addr_reg = free_addr;
  wait (mem_ready == 1'b1);

  repeat (1) @(posedge clk);


  // Write to Free Addr
  write_data = MEM_WRITE_DATA;
  addr = free_addr_reg;
  mem_func = `SET_CONTENTS;
  mem_execute = 1;
  repeat (2) @(posedge clk);
  mem_execute = 0;
  wait (mem_ready == 1'b1);

  repeat (1) @(posedge clk);

  // Get Next Free Memory Location
  mem_func = `GET_FREE;
  write_data <= 4;
  mem_execute = 1;
  repeat (2) @(posedge clk);
  mem_execute = 0;
  free_addr_reg = free_addr;
  wait (mem_ready == 1'b1);

  repeat (1) @(posedge clk);

  // Begin Read
  mem_func = `GET_CONTENTS;

  addr = 0;

  while(addr < free_addr_reg +1) begin
    mem_execute = 1;
    repeat (2) @(posedge clk);

    mem_execute = 0;

    wait (mem_ready == 1'b1);

    addr = addr +1;
    repeat (2) @(posedge clk);
  end

  $stop;
end

endmodule
