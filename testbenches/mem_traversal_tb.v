`timescale 1ns/1ns
`include "../verilog/memory_unit.vh"


module mem_traversal_tb();

//Test Parameters
parameter MEM_FUNC = 2'b00; // GET_CONTENTS
parameter MAX_ADDR = 6;
parameter MEM_INIT_FILE = "../memory/memory.hex";
parameter MEM_WRITE_DATA = 68'hDEADBEEF;

//Signal Declarations
reg MAX10_CLK1_50;

wire clk;
assign clk = MAX10_CLK1_50;

reg reset;


wire power;
assign power = 1'b1;

wire [1:0] mem_func;
wire mem_execute;
wire [`memory_addr_width - 1:0] addr;
wire [`memory_data_width - 1:0] write_data;
wire [`memory_addr_width - 1:0] addr_out;
wire [`memory_data_width - 1:0] read_data;
wire [`memory_data_width - 1:0] mem_data_out;

wire mem_ready;

wire [3:0] state;

reg traversal_execute;

reg [`memory_addr_width - 1:0] start_addr;

                 

// Instantiate UUT 
memory_unit mem(.func (mem_func),
                .execute (mem_execute),
                .addr_in (addr),
                .data_in (write_data),
                .addr_out (addr_out),
                .data_out (read_data),
                .is_ready (mem_ready),
                .power (power),
                .clk (clk),
                .state (state),
                .mem_data_out(mem_data_out),
                .rst (reset));

 mem_traversal traversal(.power (power),
                 .clk (clk),
                 .rst (reset),
                 .start_addr (start_addr),
                 .execute (traversal_execute),
                 .mem_ready (mem_ready),
                 .read_addr (addr),
                 .read_data (read_data),
                 .mem_execute (mem_execute),
                 .mem_func (mem_func),
                 .write_addr (addr_out),
                 .write_data (write_data));

// Setup Clock
initial begin
    MAX10_CLK1_50 =0;
    forever MAX10_CLK1_50 = #10 ~MAX10_CLK1_50;
end


// Perform Test
initial begin 
    if (MEM_INIT_FILE != "") begin
        $readmemh(MEM_INIT_FILE, mem.ram.ram);
    end

    start_addr = 1;
    // Reset
    reset = 1'b0;
    repeat (2) @(posedge clk);
    reset = 1'b1;
    wait (mem_ready == 1'b1);

    traversal_execute = 1;
    repeat (50) @(posedge clk);


    $stop;
end

endmodule