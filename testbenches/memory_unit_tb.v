`timescale 1ns/1ns
`include "../verilog/memory_unit.vh"


module memory_unit_tb();

//Test Parameters
parameter MEM_INIT_FILE = "../memory/memory.hex";
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


reg [`memory_data_width - 1:0] data_in;
wire [`memory_addr_width - 1:0] addr_out;
wire [`memory_data_width - 1:0] data_out;
wire [`memory_data_width - 1:0] mem_data_out;

reg [`memory_data_width - 1:0] free_addr;

wire mem_ready;
wire [3:0] state;


// Instantiate UUT 
memory_unit mem(.func (mem_func),
                .execute (mem_execute),
                .addr_in (addr),
                .data_in (data_in),
                .addr_out (addr_out),
                .data_out (data_out),
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


// Perform Test
initial begin 
    if (MEM_INIT_FILE != "") begin
        $readmemh(MEM_INIT_FILE, mem.ram.ram);
    end

    mem_execute = 0;
    // Reset
    reset = 1'b0;
    repeat (2) @(posedge clk);
    reset = 1'b1;
    wait (mem_ready == 1'b1);


    // Get Next Free Memory Location
    mem_func = `GET_FREE;
    mem_execute = 1;
    repeat (2) @(posedge clk);
    mem_execute = 0;
    free_addr = addr_out;
    wait (mem_ready == 1'b1);

    repeat (1) @(posedge clk);


    // Write to Free Addr
    data_in = MEM_WRITE_DATA;
    addr = free_addr;
    mem_func = `SET_CONTENTS;
    mem_execute = 1;
    repeat (2) @(posedge clk);
    mem_execute = 0;
    wait (mem_ready == 1'b1);
    
    repeat (1) @(posedge clk);

    // Get Next Free Memory Location
    mem_func = `GET_FREE;
    mem_execute = 1;
    repeat (2) @(posedge clk);
    mem_execute = 0;
    free_addr = addr_out;
    wait (mem_ready == 1'b1);
    
    repeat (1) @(posedge clk);

    // Begin Read
    mem_func = `GET_CONTENTS;

    addr = 0;

    while(addr < free_addr)
        begin
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