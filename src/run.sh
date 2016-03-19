#!/bin/bash
rm -f POSCAR_Cart
make
./dir2car POSCAR
make clean
