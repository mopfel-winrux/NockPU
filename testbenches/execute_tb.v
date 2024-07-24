`timescale 1ns/1ns
`include "../verilog/memory_unit.vh"


module execute_tb();

//Test Parameters
//parameter MEM_INIT_FILE = "./memory/autocons.hex";
//parameter MEM_INIT_FILE = "./memory/autocons2.hex";
//parameter MEM_INIT_FILE = "./memory/slot_tb.hex";
//parameter MEM_INIT_FILE = "./memory/constant_tb.hex";
//parameter MEM_INIT_FILE = "./memory/evaluate.hex";
//parameter MEM_INIT_FILE = "./memory/evaluate2.hex";
//parameter MEM_INIT_FILE = "./memory/evaluate3.hex";
//parameter MEM_INIT_FILE = "./memory/evaluate4.hex";
//parameter MEM_INIT_FILE = "./memory/inc_slot.hex";
//parameter MEM_INIT_FILE = "./memory/cell_tb.hex";
//parameter MEM_INIT_FILE = "./memory/cell_auto.hex";
//parameter MEM_INIT_FILE = "./memory/nested_increment.hex";
//parameter MEM_INIT_FILE = "./memory/increment.hex";
//parameter MEM_INIT_FILE = "./memory/opcode_5/yes_atom.hex";
//parameter MEM_INIT_FILE = "./memory/opcode_5/yes_cell.hex";
//parameter MEM_INIT_FILE = "./memory/opcode_5/yes_deep_cell.hex";
//parameter MEM_INIT_FILE = "./memory/opcode_5/nested_yes.hex";
//parameter MEM_INIT_FILE = "./memory/opcode_5/no_atom.hex";
//parameter MEM_INIT_FILE = "./memory/opcode_5/no_atom_cell.hex";
//parameter MEM_INIT_FILE = "./memory/opcode_5/no_deep_cell.hex";
//parameter MEM_INIT_FILE = "./memory/add_equal.hex";
//parameter MEM_INIT_FILE = "./memory/atom_incr.hex";
//parameter MEM_INIT_FILE = "./memory/if_ans2.hex";
//parameter MEM_INIT_FILE = "./memory/opcode7.hex";
//parameter MEM_INIT_FILE = "./memory/opcode8.hex";
//parameter MEM_INIT_FILE = "./memory/opcode8_nested.hex";
//parameter MEM_INIT_FILE = "./memory/opcode8_2.hex";
//parameter MEM_INIT_FILE = "./memory/opcode9_tmp.hex";
//parameter MEM_INIT_FILE = "./memory/opcode9.hex";
//parameter MEM_INIT_FILE = "./memory/opcode9_incr.hex";
//parameter MEM_INIT_FILE = "./memory/opcode9_9201.hex";
//parameter MEM_INIT_FILE = "./memory/wtf.hex";
//parameter MEM_INIT_FILE = "./memory/decrement.hex";
parameter MEM_INIT_FILE = "./memory/ackerman_1_2.hex";
//parameter MEM_INIT_FILE = "./memory/add.hex";
//parameter MEM_INIT_FILE = "./memory/cap.hex";
//parameter MEM_INIT_FILE = "./memory/opcode10.hex";
//parameter MEM_INIT_FILE = "./memory/opcode11_static.hex";
//parameter MEM_INIT_FILE = "./memory/opcode11_dynamic.hex";

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

reg traversal_execute;
wire traversal_finished;

reg [`memory_addr_width - 1:0] start_addr;

//GC signals

wire gc; // wire from MMU to MTU signaling a GC
wire gc_ready; // wire from MTU to MMU signaling MTU is ready for GC 

//Signal from Control Mux to MTU 
wire [`memory_addr_width - 1:0] module_address;
wire [`memory_data_width - 1:0] module_data;
wire module_finished;
wire [3:0] return_sys_func;
wire [3:0] return_state;

// Signal from MTU to memory Mux
wire [1:0] mem_func_mtu;
wire mem_execute_mtu;
wire [`memory_addr_width - 1:0] address1_mtu;
wire [`memory_addr_width - 1:0] address2_mtu;
wire [`memory_data_width - 1:0] write_data_mtu;
wire [2:0] select;

//Signal from NEM (Nock Execution Module) to memory Mux
wire [1:0] mem_func_nem;
wire mem_execute_nem;
wire [`memory_addr_width - 1:0] address1_nem;
wire [`memory_addr_width - 1:0] address2_nem;
wire [`memory_data_width - 1:0] write_data_nem;
wire [`noun_width-1:0] hint;
wire hint_tag;

//Signal from MTU to NEM
wire [`memory_addr_width - 1:0] execute_address;
wire [`memory_data_width - 1:0] execute_data;
wire execute_finished;
wire [3:0] execute_return_sys_func;
wire [3:0] execute_return_state;
wire [`tag_width - 1:0] error;//do we need?

//Signal from cell module to memory Mux
wire [1:0] mem_func_cell;
wire mem_execute_cell;
wire [`memory_addr_width - 1:0] address1_cell;
wire [`memory_addr_width - 1:0] address2_cell;
wire [`memory_data_width - 1:0] write_data_cell;

//Signal from MTU to cell Module
wire [`memory_addr_width - 1:0] cell_address;
wire [`memory_data_width - 1:0] cell_data;
wire cell_finished;
wire [3:0] cell_return_sys_func;
wire [3:0] cell_return_state;
wire [`tag_width - 1:0] cell_error;

//Signal from incr module to memory Mux
wire [1:0] mem_func_incr;
wire mem_execute_incr;
wire [`memory_addr_width - 1:0] address1_incr;
wire [`memory_addr_width - 1:0] address2_incr;
wire [`memory_data_width - 1:0] write_data_incr;

//Signal from MTU to incr Module
wire [`memory_addr_width - 1:0] incr_address;
wire [`memory_data_width - 1:0] incr_data;
wire incr_finished;
wire [3:0] incr_return_sys_func;
wire [3:0] incr_return_state;
wire [`tag_width - 1:0] incr_error;

//Signal from incr module to memory Mux
wire [1:0] mem_func_equal;
wire mem_execute_equal;
wire [`memory_addr_width - 1:0] address1_equal;
wire [`memory_addr_width - 1:0] address2_equal;
wire [`memory_data_width - 1:0] write_data_equal;

//Signal from MTU to equal Module
wire [`memory_addr_width - 1:0] equal_address;
wire [`memory_data_width - 1:0] equal_data;
wire equal_finished;
wire [3:0] equal_return_sys_func;
wire [3:0] equal_return_state;
wire [`tag_width - 1:0] equal_error;

//Signal from edit module to memory Mux
wire [1:0] mem_func_edit;
wire mem_execute_edit;
wire [`memory_addr_width - 1:0] address1_edit;
wire [`memory_addr_width - 1:0] address2_edit;
wire [`memory_data_width - 1:0] write_data_edit;

//Signal from MTU to edit Module
wire [`memory_addr_width - 1:0] edit_address;
wire [`memory_data_width - 1:0] edit_data;
wire edit_finished;
wire [3:0] edit_return_sys_func;
wire [3:0] edit_return_state;
wire [`tag_width - 1:0] edit_error;



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
                .mem_data_out1 (mem_data_out1),
                .mem_data_out2 (mem_data_out2),
                .rst (reset),
                .gc (gc),
                .gc_ready (gc_ready));

// Instantiate Memory Mux
memory_mux memory_mux(.mem_func_a (mem_func_mtu),
                      .execute_a (mem_execute_mtu),
                      .address1_a (address1_mtu),
                      .address2_a (address2_mtu),
                      .write_data_a (write_data_mtu),
                      .mem_func_b (mem_func_nem),
                      .execute_b (mem_execute_nem),
                      .address1_b (address1_nem),
                      .address2_b (address2_nem),
                      .write_data_b (write_data_nem),
                      .mem_func_c (mem_func_cell),
                      .execute_c (mem_execute_cell),
                      .address1_c (address1_cell),
                      .address2_c (address2_cell),
                      .write_data_c (write_data_cell),
                      .mem_func_d (mem_func_incr),
                      .execute_d (mem_execute_incr),
                      .address1_d (address1_incr),
                      .address2_d (address2_incr),
                      .write_data_d (write_data_incr),
                      .mem_func_e (mem_func_equal),
                      .execute_e (mem_execute_equal),
                      .address1_e (address1_equal),
                      .address2_e (address2_equal),
                      .write_data_e (write_data_equal),
                      .mem_func_f (mem_func_edit),
                      .execute_f (mem_execute_edit),
                      .address1_f (address1_edit),
                      .address2_f (address2_edit),
                      .write_data_f (write_data_edit),
                      .sel (select),
                      .mem_func (mem_func),
                      .execute (mem_execute),
                      .address1 (address1),
                      .address2 (address2),
                      .write_data (write_data));

// Instantiate Control Mux
control_mux control_mux(.sel (select),
                        .finished (module_finished),
                        .return_sys_func (return_sys_func),
                        .return_state (return_state),
                        .module_address (module_address),
                        .module_data (module_data),
                        .execute_finished (execute_finished),
                        .execute_return_sys_func (execute_return_sys_func),
                        .execute_return_state (execute_return_state),
                        .execute_address (execute_address),
                        .execute_data (execute_data),
                        .cell_finished (cell_finished),
                        .cell_return_sys_func (cell_return_sys_func),
                        .cell_return_state (cell_return_state),
                        .cell_address (cell_address),
                        .cell_data (cell_data),
                        .incr_finished (incr_finished),
                        .incr_return_sys_func (incr_return_sys_func),
                        .incr_return_state (incr_return_state),
                        .incr_address (incr_address),
                        .incr_data (incr_data),
                        .equal_finished (equal_finished),
                        .equal_return_sys_func (equal_return_sys_func),
                        .equal_return_state (equal_return_state),
                        .equal_address (equal_address),
                        .equal_data (equal_data),
                        .edit_finished (edit_finished),
                        .edit_return_sys_func (edit_return_sys_func),
                        .edit_return_state (edit_return_state),
                        .edit_address (edit_address),
                        .edit_data (edit_data)
                      );
// Instantiate MTU
mem_traversal traversal(.power (power),
                        .clk (clk),
                        .rst (reset),
                        .start_addr (start_addr),
                        .execute (traversal_execute),
                        .gc (gc),
                        .gc_ready (gc_ready),
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
                        .module_address(module_address),
                        .module_data(module_data),
                        .module_finished(module_finished),
                        .execute_return_sys_func(execute_return_sys_func),
                        .execute_return_state(execute_return_state));

//Instantiate Nock Execute Module
execute execute(.clk(clk),
                .rst(reset),
                .error(error),
                .execute_start(select),
                .execute_address(execute_address),
                .execute_data(execute_data),
                .gc(gc),
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
                .hint(hint),
                .hint_tag(hint_tag),
                .execute_return_sys_func(execute_return_sys_func),
                .execute_return_state(execute_return_state));

//Instantiate Nock cell Module
cell_block cell_block(.clk(clk),
                      .rst(reset),
                      .cell_error(cell_error),
                      .cell_start(select),
                      .cell_address(cell_address),
                      .cell_data(cell_data),
                      .mem_ready(mem_ready),
                      .mem_execute(mem_execute_cell),
                      .mem_func(mem_func_cell),
                      .address1(address1_cell),
                      .address2(address2_cell),
                      .free_addr(free_addr),
                      .read_data1(read_data1),
                      .read_data2(read_data2),
                      .write_data(write_data_cell),
                      .finished(cell_finished),
                      .cell_return_sys_func(cell_return_sys_func),
                      .cell_return_state(cell_return_state));

//Instantiate Nock increment Module
incr_block incr_block(.clk(clk),
                      .rst(reset),
                      .incr_error(incr_error),
                      .incr_start(select),
                      .incr_address(incr_address),
                      .incr_data(incr_data),
                      .mem_ready(mem_ready),
                      .mem_execute(mem_execute_incr),
                      .mem_func(mem_func_incr),
                      .address1(address1_incr),
                      .address2(address2_incr),
                      .free_addr(free_addr),
                      .read_data1(read_data1),
                      .read_data2(read_data2),
                      .write_data(write_data_incr),
                      .finished(incr_finished),
                      .incr_return_sys_func(incr_return_sys_func),
                      .incr_return_state(incr_return_state));

//Instantiate Nock Equal Module
equal_block equal_block(.clk(clk),
                        .rst(reset),
                        .equal_error(equal_error),
                        .equal_start(select),
                        .equal_address(equal_address),
                        .equal_data(equal_data),
                        .mem_ready(mem_ready),
                        .mem_execute(mem_execute_equal),
                        .mem_func(mem_func_equal),
                        .address1(address1_equal),
                        .address2(address2_equal),
                        .free_addr(free_addr),
                        .read_data1(read_data1),
                        .read_data2(read_data2),
                        .write_data(write_data_equal),
                        .finished(equal_finished),
                        .equal_return_sys_func(equal_return_sys_func),
                        .equal_return_state(equal_return_state));

//Instantiate Nock edit Module
edit_block edit_block(.clk(clk),
                      .rst(reset),
                      .edit_error(edit_error),
                      .edit_start(select),
                      .edit_address(edit_address),
                      .edit_data(edit_data),
                      .mem_ready(mem_ready),
                      .mem_execute(mem_execute_edit),
                      .mem_func(mem_func_edit),
                      .address1(address1_edit),
                      .address2(address2_edit),
                      .free_addr(free_addr),
                      .read_data1(read_data1),
                      .read_data2(read_data2),
                      .write_data(write_data_edit),
                      .finished(edit_finished),
                      .edit_return_sys_func(edit_return_sys_func),
                      .edit_return_state(edit_return_state));



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

  for (idx = 0; idx < 2047; idx = idx+1) begin
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
  repeat (500) @(posedge clk);

  $finish;
end

endmodule
