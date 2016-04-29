#ifndef KOALA_MYSTRING_H
#define KOALA_MYSTRING_H
// mystring.h
// Created by Changning Niu on 3/20/2016.

#include <iostream>
#include <string>

using namespace std;

inline string trim(string &str)
{ 
    size_t first = str.find_first_not_of(' ');
    if (first == string::npos) return "";
    size_t last = str.find_last_not_of(' ');
    return str.substr(first, (last-first+1));
}
