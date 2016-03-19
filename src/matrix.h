#ifndef KOALA_MATRIX_H
#define KOALA_MATRIX_H
//
// matrix.h
//
// Created by Changning Niu on 3/18/2016.


// Get the product of two matrices of [n][3] and [3][3]
// fixed # of row: 9999
inline void matrix_product (int n, double a[9999][3], double b[3][3], double c[9999][3]) {
    for (int i = 0; i < n; i++) {
        c[i][0] = a[i][0] * b[0][0] + a[i][1] * b[1][0] + a[i][2] * b[2][0];
        c[i][1] = a[i][0] * b[0][1] + a[i][1] * b[1][1] + a[i][2] * b[2][1];
        c[i][2] = a[i][0] * b[0][2] + a[i][1] * b[1][2] + a[i][2] * b[2][2];
    }
}

// Get the determinant of a 3x3 matrix
inline double matrix_det (double a[3][3]) {
    return a[0][0] * a[1][1] * a[2][2] + a[0][1] * a[1][2] * a[2][0] + a[0][2] * a[1][0] * a[2][1]
         - a[2][0] * a[1][1] * a[0][2] + a[2][1] * a[1][2] * a[0][0] + a[2][2] * a[1][0] * a[0][1];
}

// Get the inverse of a 3x3 matrix
inline void matrix_inverse (double a[3][3], double b[3][3]) {
    double det = matrix_det(a);
    b[0][0] = (a[1][1] * a[2][2] - a[1][2] * a[2][1]) / det;
    b[0][1] = (a[0][2] * a[2][1] - a[0][1] * a[2][2]) / det;
    b[0][2] = (a[0][1] * a[1][2] - a[0][2] * a[1][1]) / det;
    b[1][0] = (a[1][2] * a[2][0] - a[1][0] * a[2][2]) / det;
    b[1][1] = (a[0][0] * a[2][2] - a[0][2] * a[2][0]) / det;
    b[1][2] = (a[0][2] * a[1][0] - a[0][0] * a[1][2]) / det;
    b[2][0] = (a[1][0] * a[2][1] - a[1][1] * a[2][0]) / det;
    b[2][1] = (a[0][1] * a[2][0] - a[0][0] * a[2][1]) / det;
    b[2][2] = (a[0][0] * a[1][1] - a[0][1] * a[1][0]) / det;
}

#endif // KOALA_MATRIX_H
