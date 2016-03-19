# Makefile
#
# Created by Changning Niu on 3/18/2016.

CC		= g++
CFLAGS	= -Wall -g

TARGET	= bin/dir2car bin/supercell

############# DO NOT CHANGE:
all: $(TARGET)

bin/dir2car: src/dir2car.o src/poscar.o
	$(CC) -o $@ $^ $(CFLAGS)

bin/supercell: src/supercell.o src/poscar.o
	$(CC) -o $@ $^ $(CFLAGS)

src/dir2car.o: src/dir2car.cc src/poscar.h
	$(CC) -c -o $@ $< $(CFLAGS)

src/supercell.o: src/supercell.cc src/poscar.h
	$(CC) -c -o $@ $< $(CFLAGS)

src/poscar.o: src/poscar.cc src/poscar.h src/matrix.h
	$(CC) -c -o $@ $< $(CFLAGS)

clean:
	rm -f src/*.o $(TARGET)
