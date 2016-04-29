// vasp-check.cc
//
// It checks current directory and reports:
//  - if electronic relaxation is converged
//  - if ionic relaxation is converged
//  - if entropy term T*S is below 1 meV/atom
//  - if ENCUT is good enough
//  - if CPU time is much shorter than total
//
//  Created by Changning Niu on 3/19/2016.

#include <iostream>
#include <fstream>
#include <sstream>
#include <string>

using namespace std;

// Check OSZICAR
void check_oszicar () {
    ifstream oszicar;								// file OSZICAR
    string line;									// to read a line
    istringstream iss;								// line processing
    int num;										// to read an integer
    int count = 0;									// to count lines
    double x;										// to read a float
    string str1, str2, str3, str4;					// to read a string

    oszicar.open("OSZICAR");
    if (!oszicar) {                                 // does OSZICAR exist?
        cout << "Can't find OSZICAR.\n";
        return null;
    }
    while (getline(oszicar, line)) count++;         // count lines
    iss.str(line);									// read last line
	if (! iss >> num) {								// if not starts w/ number
		cout << "OSZICAR is not complete. Last line:\n";
		cout << line << "\n";
		return null;								// end w/ error
	}

	oszicar.clear();								// clear flags
	oszicar.seekg(0);								// rewind OSZICAR file
	for (int i=0; i < count-1; i++)					// skip N-2 lines
		getline(oszicar, line);						// and read No.N-1 line
	iss.clear();
	iss.str(line);
	if (! iss >> str1 >> num >> str2 >> x) {
		cout << "Failed reading second last line of OSZICAR.\n";
		return null;
	}
