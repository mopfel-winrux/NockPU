module single_port_ram
(
	input [68:0] data,
	input [9:0] address,
	input wren, clock,
	output [68:0] q
);

	// Declare the RAM variable
	reg [68:0] ram[68:0];
	
	// Variable to hold the registered read address
	reg [9:0] addr_reg;
	
	always @ (posedge clock)
	begin
	// Write
		if (wren)
			ram[address] <= data;
		
		addr_reg <= address;
		
	end
		
	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	assign q = ram[addr_reg];
	
endmodule
