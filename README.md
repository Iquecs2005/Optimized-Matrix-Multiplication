# Optimized Matrix Multiplication

Error Codes:

3 - Device Matrix allocation error
4 - Transfer error between host and device

Build Instructions:

-   Main Program: "gcc -Wall -std=c11 -mfma -o matrix_lib_test matrix_lib_test.c matrix_lib.c"
-   Matrix Generator: "gcc -o matrix_generator matrix_generator.c"
