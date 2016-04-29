#ifndef KOALA_INCAR_H
#define KOALA_INCAR_H
// incar.h
// Created by Changning Niu on 3/19/2016.

#include <string>
#include <iostream>
#include <fstream>
#include <sstream>

struct Incar {
	string 	system;
	int 	istart;
	int 	icharg;
	int 	nelm;
	double 	ediff;
	int 	ibrion;
	int 	nsw;
	double 	ediffg;
	int 	isif;
	double 	encut;
	int 	ismear;
	double 	sigma;
	int 	isym;
}

#endif
