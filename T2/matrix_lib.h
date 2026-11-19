#ifndef MATRIX_LIB_H
#define MATRIX_LIB_H

#include <time.h>

typedef struct {
	unsigned long int rows;
	unsigned long int cols;
	float *values;
	float *d_values;
} matrix;

typedef struct
{
    int nLines, nCollumns;
    double *matrixData;
} Matrix;

int scalar_matrix_mult(float scalar_value, Matrix *m, Matrix *r);
int matrix_matrix_mult(Matrix *m1, Matrix *m2, Matrix *r);
int load_matrix(matrix *matrix, char *filename);
int store_matrix(matrix *matrix, char *filename);
void usage(const char *name);
int check_linear_errors(matrix *source, matrix *destination, float scalar_value);
int check_mult_errors(matrix *matA, matrix *matB, matrix *matC);

/** número de threads por bloco */
extern int threadsPerBlock;  // número de threads por bloco
/** número de blocos por grid */
extern int blocksPerGrid;  // número de blocos por grid

/**
 * Retorna a diferença entre dois instantes, em milissegundos.
 * start e stop devem ter sido obtidos com clock_gettime().
 */
#define timedifference_msec(start, stop) \
    (((double)((stop).tv_sec - (start).tv_sec) * 1000.0) + \
     ((double)((stop).tv_nsec - (start).tv_nsec) / 1000000.0))

#endif