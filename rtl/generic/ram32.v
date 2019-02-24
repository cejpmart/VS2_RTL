module ram32(
	address,
	clock,
	data,
	wren,
	q);

parameter ADDR_WIDTH;
parameter DEPTH;
localparam WIDTH = 32;

input[ADDR_WIDTH-1:0] address;
input clock;
input[WIDTH-1:0] data;
input[3:0] wren;
output reg[WIDTH-1:0] q;

wire[ADDR_WIDTH-3:0] word_address = address[ADDR_WIDTH-1:2];

reg[WIDTH-1:0] memory[0:DEPTH-1] /*verilator public*/;

always @ (posedge clock) begin
	if (wren != 0) begin
		memory[word_address] <= {
				wren[3] ? data[31:24] : memory[word_address][31:24],
				wren[2] ? data[23:16] : memory[word_address][23:16],
				wren[1] ? data[15: 8] : memory[word_address][15: 8],
				wren[0] ? data[ 7: 0] : memory[word_address][ 7: 0] };
	end

	q <= memory[word_address];
end

endmodule
