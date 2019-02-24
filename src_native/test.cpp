#include "Vvs2.h"
#include "Vvs2_framebuffer.h"
#include "Vvs2_ram32__A13_D20000.h"
#include "Vvs2_rom32__A11_D20000_W20.h"
#include "Vvs2_vs2.h"
#include "verilated.h"
#include <fstream>
#include <memory>

enum { MAX_TIME = 50*1000*1000 };
//enum { MAX_TIME = 1500000 };

static void load_binary(const char* filename, void* memory, size_t size) {
	std::ifstream file(filename, std::ios::in | std::ios::binary);
	assert(file);
	file.read((char*) memory, size);
}

static void save_binary(const char* filename, const void* memory, size_t size) {
	std::ofstream file(filename, std::ios::out | std::ios::binary);
	assert(file);
	file.write((const char*) memory, size);
}

static void save_ppm_rgb332(const char* filename, unsigned int width,
		unsigned int height, const uint8_t* pixels) {
	std::ofstream file(filename, std::ios::out | std::ios::binary);
	file << "P6 " << width << " " << height << " 255" << std::endl;
	file.flush();

	for (int i = 0; i < width * height; i++) {
		char rgb[3];
		//printf("%04X ", pixels[i]);
		rgb[0] = (((pixels[i] & 0xE0) >> 5) * 0b001001001) >> 1;
		rgb[1] = (((pixels[i] & 0x1C) >> 2) * 0b001001001) >> 1;
		rgb[2] = (pixels[i] & 0x03) * 0b01010101;
		file.write(rgb, 3);
	}
}

int main(int argc, char const *argv[]) {
	Verilated::commandArgs(argc, argv);

	Vvs2 vs2;

	load_binary("firmware/ROM.img", vs2.vs2->rom->memory, sizeof(vs2.vs2->rom->memory));

	for (vluint64_t t = 0; t < MAX_TIME && !Verilated::gotFinish(); t++) {
		vs2.vs2->reset = (t < 5);
		vs2.vs2->clk = !vs2.vs2->clk;
		vs2.eval();
	}

	// TODO: detect current mode
	save_ppm_rgb332("framebuffer.ppm", 640, 480,
		(const uint8_t*) vs2.vs2->framebuf->memory);

	save_binary("RAM.bin", vs2.vs2->ram->memory, sizeof(vs2.vs2->ram->memory));

	return 0;
}
