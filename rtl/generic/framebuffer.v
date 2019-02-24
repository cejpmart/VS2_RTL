
module framebuffer (
	address,
	clock,
	data,
	wren,
	q);

parameter WIDTH = 640;
parameter HEIGHT = 480;

parameter ADDR_WIDTH = 20;
parameter DATA_WIDTH = 16;
parameter DEPTH = WIDTH * HEIGHT;

input[ADDR_WIDTH-1:0] address;
input clock;
input[DATA_WIDTH-1:0] data;
input[3:0] wren;
output reg[DATA_WIDTH-1:0] q;

wire[ADDR_WIDTH-2:0] word_address = address[ADDR_WIDTH-1:1];

reg[DATA_WIDTH-1:0] memory[0:DEPTH-1] /*verilator public*/;

integer fd, i;
localparam FILENAME = "dump.ppm";

initial begin
	for (i = 0; i < WIDTH * HEIGHT; i = i + 1)
		memory[i] = 0;

`ifndef verilator
	#1000000 save();
`endif
end

task save;
	begin
		fd = $fopen(FILENAME, "wb");
		$fwrite(fd, "P3 %0d %0d 255\n", WIDTH, HEIGHT);

		for (i = 0; i < WIDTH * HEIGHT; i = i + 1) begin
			$fwrite(fd, "%0d %0d %0d ", {memory[i][4:0], 3'b000},
				{memory[i][10:5], 2'b00}, {memory[i][15:11], 3'b000});
		end
		$fclose(fd);
	end
endtask

always @ (posedge clock) begin
	if (wren != 0) begin
		if (word_address[0] == 1'b0) begin
			memory[word_address] <= {
					wren[1] ? data[15: 8] : memory[word_address][15: 8],
					wren[0] ? data[ 7: 0] : memory[word_address][ 7: 0] };
		end else begin
			memory[word_address] <= {
					wren[3] ? data[31: 24] : memory[word_address][15: 8],
					wren[2] ? data[23: 16] : memory[word_address][ 7: 0] };
		end
	end

	q <= memory[word_address];
end

endmodule
