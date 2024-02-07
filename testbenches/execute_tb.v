`timescale 1ns/1ns
`include "../verilog/memory_unit.vh"


module execute_tb();

//Test Parameters
//parameter MEM_INIT_FILE = "./memory/slot_tb.hex";
//parameter MEM_INIT_FILE = "./memory/inc_slot.hex";
parameter MEM_INIT_FILE = "./memory/evaluate.hex";
//parameter MEM_INIT_FILE = "./memory/evaluate2.hex";
//parameter MEM_INIT_FILE = "./memory/evaluate3.hex";
//parameter MEM_INIT_FILE = "./memory/cell_tb.hex";
//parameter MEM_INIT_FILE = "./memory/constant_tb.hex";
//parameter MEM_INIT_FILE = "./memory/nested_increment.hex";
//parameter MEM_INIT_FILE = "./memory/increment.hex";

//Signal Declarations
reg MAX10_CLK1_50;

wire clk;
assign clk = MAX10_CLK1_50;

reg reset;


wire power;
assign power = 1'b1;

wire [1:0] mem_func;
wire mem_execute;
wire [`memory_addr_width - 1:0] address1;
wire [`memory_addr_width - 1:0] address2;
wire [`memory_data_width - 1:0] write_data;
wire [`memory_addr_width - 1:0] free_addr;
wire [`memory_data_width - 1:0] read_data1;
wire [`memory_data_width - 1:0] read_data2;
wire [`memory_data_width - 1:0] mem_data_out1;
wire [`memory_data_width - 1:0] mem_data_out2;


wire mem_ready;

wire [3:0] state;

reg traversal_execute;
wire traversal_finished;

reg [`memory_addr_width - 1:0] start_addr;

// Signal from MTU to memory Mux
wire [1:0] mem_func_mtu;
wire mem_execute_mtu;
wire [`memory_addr_width - 1:0] address1_mtu;
wire [`memory_addr_width - 1:0] address2_mtu;
wire [`memory_data_width - 1:0] write_data_mtu;
wire select;

//Signal from NEM (Nock Execution Module) to memory Mux
wire [1:0] mem_func_nem;
wire mem_execute_nem;
wire [`memory_addr_width - 1:0] address1_nem;
wire [`memory_addr_width - 1:0] address2_nem;
wire [`memory_data_width - 1:0] write_data_nem;

//Signal from MTU to NEM
wire [`memory_addr_width - 1:0] execute_address;
wire [`tag_width - 1:0] execute_tag;
wire [`memory_data_width - 1:0] execute_data;
wire execute_finished;
wire [`tag_width - 1:0] error;
wire [3:0] execute_return_sys_func;
wire [3:0] execute_return_state;

// Instantiate Memory Unit
memory_unit mem(.func (mem_func),
                .execute (mem_execute),
                .address1 (address1),
                .address2 (address2),
                .write_data (write_data),
                .free_addr (free_addr),
                .read_data1 (read_data1),
                .read_data2 (read_data2),
                .is_ready (mem_ready),
                .power (power),
                .clk (clk),
                .state (state),
                .mem_data_out1 (mem_data_out1),
                .mem_data_out2 (mem_data_out2),
                .rst (reset));

// Instantiate Memory Mux
memory_mux memory_mux(.mem_func_a (mem_func_mtu),
                      .mem_func_b (mem_func_nem),
                      .execute_a (mem_execute_mtu),
                      .execute_b (mem_execute_nem),
                      .address1_a (address1_mtu),
                      .address2_a (address2_mtu),
                      .address1_b (address1_nem),
                      .address2_b (address2_nem),
                      .write_data_a (write_data_mtu),
                      .write_data_b (write_data_nem),
                      .sel (select),
                      .mem_func (mem_func),
                      .execute (mem_execute),
                      .address1 (address1),
                      .address2 (address2),
                      .write_data (write_data));

// Instantiate MTU
mem_traversal traversal(.power (power),
                        .clk (clk),
                        .rst (reset),
                        .start_addr (start_addr),
                        .execute (traversal_execute),
                        .mem_ready (mem_ready),
                        .address1 (address1_mtu),
                        .address2 (address2_mtu),
                        .read_data1 (read_data1),
                        .read_data2 (read_data2),
                        .mem_execute (mem_execute_mtu),
                        .mem_func (mem_func_mtu),
                        .free_addr (free_addr),
                        .write_data (write_data_mtu),
                        .finished(traversal_finished),
                        .error(error),
                        .mux_controller(select),
                        .execute_address(execute_address),
                        .execute_tag(execute_tag),
                        .execute_data(execute_data),
                        .execute_finished(execute_finished),
                        .execute_return_sys_func(execute_return_sys_func),
                        .execute_return_state(execute_return_state));

//Instantiate Nock Execute Module
execute execute(.clk(clk),
                .rst(reset),
                .error(error),
                .execute_start(select),
                .execute_address(execute_address),
                .execute_tag(execute_tag),
                .execute_data(execute_data),
                .mem_ready(mem_ready),
                .mem_execute(mem_execute_nem),
                .mem_func(mem_func_nem),
                .address1(address1_nem),
                .address2(address2_nem),
                .free_addr(free_addr),
                .read_data1(read_data1),
                .read_data2(read_data2),
                .write_data(write_data_nem),
                .finished(execute_finished),
                .execute_return_sys_func(execute_return_sys_func),
                .execute_return_state(execute_return_state));

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
  $dumpfile("waveform.vcd");
  $dumpvars(0, execute_tb);

  for (idx = 0; idx < 1023; idx = idx+1) begin
    $dumpvars(0,mem.ram.ram[idx]);
  end

  start_addr = 1;
  // Reset
  reset = 1'b0;
  repeat (2) @(posedge clk);
  reset = 1'b1;
  wait (mem_ready == 1'b1);

  traversal_execute = 1;

  wait (traversal_finished == 1'b1);
  repeat (2) @(posedge clk);

  $stop;
end

endmodule
