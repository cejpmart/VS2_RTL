module vs2;

integer fd;

reg reset /*verilator public*/ = 1;
reg clk /*verilator public*/ = 0;

initial begin
    fd = $fopen("stdout.log", "w");
end

wire        cpu_en_out;
wire[3:0]   cpu_wren_out;
wire[31:0]  cpu_addr_out;
wire[31:0]  cpu_data_out;
reg         cpu_busy_in;
reg[31:0]   cpu_data_in;

wire[31:0]  rom_q;

wire[31:0]  ram_q;
wire[3:0]   ram_wren;

wire[15:0]  framebuffer_q;
wire[3:0]   framebuffer_wren;

picorv32 #(
    .ENABLE_COUNTERS(0),
    .ENABLE_REGS_16_31(1),      // something is wrong here
    .PROGADDR_RESET(32'h00000000)
)
cpu (
    .clk(clk),
    .resetn        (~reset),

    .mem_valid     (cpu_en_out),
    .mem_ready     (~cpu_busy_in),

    .mem_addr      (cpu_addr_out),
    .mem_wdata     (cpu_data_out),
    .mem_wstrb     (cpu_wren_out),
    .mem_rdata     (cpu_data_in)
);

// 128k words = 512kBytes
rom32 #(.ADDR_WIDTH(17), .DEPTH(128*1024), .WIDTH(32)) rom(
    .clock(clk),
    .address(cpu_addr_out[18:2]),
    .q(rom_q)
);

// 128k words = 512kBytes
ram32 #(.ADDR_WIDTH(19), .DEPTH(128*1024)) ram(
    .clock(clk),
    .address(cpu_addr_out[18:0]),
    .data(cpu_data_out),
    .q(ram_q),
    .wren(ram_wren)
);

framebuffer framebuf(
    .clock(clk),
    .address(cpu_addr_out[19:0]),
    .data(cpu_data_out[15:0]),
    .q(framebuffer_q),
    .wren(framebuffer_wren)
);

wire[23:0] cpu_addr24 = cpu_addr_out[23:0];

reg[1:0] rom_counter;
reg[1:0] ram_or_framebuffer_counter;

// 000000h - 0FFFFFh ROM (512k)
// 600000h - 7FFFFFh RAM (2M)
// C00000h - CFFFFFh VRAM (1M)

wire is_rom = (cpu_addr24[23:20] == 4'h0);
wire is_ram = (cpu_addr24[23:21] == 3'b011);
wire is_framebuffer = (cpu_addr24[23:20] == 4'hC);

assign ram_wren = is_ram ? cpu_wren_out : 4'h0;
assign framebuffer_wren = is_framebuffer ? cpu_wren_out : 4'h0;

always @ (*) begin
    if (is_rom)
        cpu_busy_in = (rom_counter != 2);
    else if (is_ram || is_framebuffer)
        cpu_busy_in = (ram_or_framebuffer_counter != 2);
    else
        cpu_busy_in = 1'bx;
end

always @ (*) begin
    if (is_rom) begin
        cpu_data_in = rom_q;
    end else if (is_ram) begin
        cpu_data_in = ram_q;
    end else if (is_framebuffer) begin
        cpu_data_in = {16'h0, framebuffer_q};
    end
end

always @ (posedge clk) begin
    if (reset) begin
        rom_counter <= 0;
    end else begin
        if (rom_counter == 0) begin
            if (cpu_en_out && is_rom)
                rom_counter <= 1;
        end else
            rom_counter <= rom_counter + 1'b1;
    end
end

always @ (posedge clk) begin
    if (reset) begin
        ram_or_framebuffer_counter <= 0;
    end else begin
        if (ram_or_framebuffer_counter == 0) begin
            if (cpu_en_out && (is_ram || is_framebuffer))
                ram_or_framebuffer_counter <= 1;
        end else
            ram_or_framebuffer_counter <= ram_or_framebuffer_counter + 1'b1;
    end
end

always @ (posedge clk) begin
    if (reset) begin
    end else begin
        if (cpu_en_out && cpu_wren_out[0]) begin
            if (cpu_addr24 == 24'h2000fc && rom_counter == 0) begin
                $fwrite(fd, "%c", cpu_data_out[7:0]);
                //$write("*** PUT: %c [%08X]\n", cpu_data_out[7:0], cpu_data_out);
                $write("%c", cpu_data_out[7:0]);
            end else if (cpu_addr24 == 24'h200200 || cpu_addr24 == 24'h200202) begin
                $write("FIXME: unimplemented write to %06X\n", cpu_addr24);
            end else if (is_ram || is_framebuffer) begin
            end else begin
                $write("Invalid write to %06X\n", cpu_addr24);
                $stop();
            end
        end
    end
end

`ifdef verilator
wire[7:0] cpu_addr_unused = cpu_addr_out[31:24];
`endif

endmodule
