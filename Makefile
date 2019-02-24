include verilator_common.mk

RTL=\
		rtl/vs2.v\
		rtl/generic/framebuffer.v\
		rtl/generic/ram32.v\
		rtl/generic/rom32.v\
		rtl/ip/picorv32.v

CFLAGS=$(VERILATOR_CFLAGS)

SRC=src_native/test.cpp
OUTPUT=test_tb
TESTBENCH_LIB=build_verilator/Vvs2__ALL.a

all: $(OUTPUT)

clean:
	rm -f $(OUTPUT)
	rm -rf build_verilator

test:
	./$(OUTPUT)
	if ! cmp -s stdout.log stdout.expected.log; then \
		echo "Output not equal to expectation"; \
		exit 1; \
	fi
	if ! cmp -s framebuffer.ppm framebuffer_expected.ppm; then \
		echo "Output not equal to expectation"; \
		exit 1; \
	fi

$(OUTPUT): $(SRC) $(TESTBENCH_LIB)
	g++ -o $@ $(SRC) $(VERILATOR_LIB) -I build_verilator $(TESTBENCH_LIB) $(CFLAGS)

$(TESTBENCH_LIB): $(RTL)
	$(VERILATOR) --top-module vs2 -cc $(RTL) $(VERILATOR_FLAGS) \
			-Mdir build_verilator --stats -Wno-fatal

	make -j -C build_verilator -f Vvs2.mk
