TOP := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

VERILATOR_ROOT:=$(TOP)/verilator_bin
VERILATOR=$(VERILATOR_ROOT)/bin/verilator

VERILATOR_FLAGS=--assert --language 1364-2005 -Wwarn-style

VERILATOR_CFLAGS=-I $(VERILATOR_ROOT)/share/verilator/include -I $(VERILATOR_ROOT)/share/verilator/include/vltstd
VERILATOR_LIB=$(VERILATOR_ROOT)/share/verilator/include/verilated.cpp
