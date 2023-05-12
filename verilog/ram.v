module ram(
    input wire clock,
    input wire [9:0] address,
    input wire [68:0] data,
    input wire wren,
    output reg [68:0] q
);

    // Define a 256 byte (2^68) RAM.
    reg [68:0] ram [255:0];

    always @(posedge clock) begin
        if (wren) begin
            // On a write cycle, store the input data at the specified address.
            ram[address] <= data;
        end else begin
            // On a read cycle, output the data at the specified address.
            q <= ram[address];
        end
    end
endmodule

