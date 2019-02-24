module rom32(
	address,
	clock,
	q);

parameter ADDR_WIDTH;
parameter DEPTH;
parameter WIDTH;

input[ADDR_WIDTH-1:0] address;
input clock;
output reg[WIDTH-1:0] q;

reg[WIDTH-1:0] memory[0:DEPTH-1] /*verilator public*/;

always @ (posedge clock) begin
	q <= memory[address];
end

endmodule
