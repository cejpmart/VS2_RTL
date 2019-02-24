#!/bin/sh
set -ex

git clone http://git.veripool.org/git/verilator
cd verilator
git checkout 8a43f41ed60e11106e464f90d2be371f724019cd
autoconf
./configure --prefix=`pwd`/../verilator_bin
make
make install
