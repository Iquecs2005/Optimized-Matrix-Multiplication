#include "matrix_lib.h"

int scalar_matrix_mult(float scalar_value, matrix *m, matrix *r)
{
    for (int i = 0; i < r->rows; i++)
    {
        for (int j = 0; j < r->cols; j++)
        {
            int index = i * r->cols + j;
            r->values[index] = scalar_value * m->values[index];
        }
    }
}

int matrix_matrix_mult(matrix *m1, matrix *m2, matrix *r)
{
    for (int i = 0; i < r->rows; i++)
    {
        for (int j = 0; j < r->cols; j++)
        {
            int r_index = i * r->cols + j;
            r->values[r_index] = 0;
            for (int k = 0; k < m1->cols; k++)
            {
                int m1_index = i * m1->cols + k;
                int m2_index = k * m2->cols + j;

                r->values[r_index] += m1->values[m1_index] * m2->values[m2_index];
            }
        }
    }
}