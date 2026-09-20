#include "matrix_lib.h"

#include <stdio.h>
#include <immintrin.h>

int scalar_matrix_mult(float scalar_value, matrix *m, matrix *r)
{
    float *p_m1, *p_r;
    int n_numbers;
    __m256 values, scalar, results;

    p_m1 = m->values;
    p_r = r->values;

    n_numbers = r->rows * r->cols;

    scalar = _mm256_set1_ps(scalar_value);

    for (int i = 0; i < n_numbers; i += 8)
    {
        //TODO Implement with intel intrinsics
        values = _mm256_load_ps(p_m1);
        results = _mm256_mul_ps(values, scalar);
        _mm256_store_ps(p_r, results);

        p_m1 += 8;
        p_r += 8;
    }

    return 0;
}

int matrix_matrix_mult(matrix *m1, matrix *m2, matrix *r)
{
    float *p_m1, *p_m2, *p_r, *p_l_r, *p_c_r;
    int n_numbers;

    p_r = r->values;
    n_numbers = r->cols * r->rows;

    for (int i = 0; i < n_numbers; i++)
    {
        *p_r = 0;
        p_r++;
    }
    
    p_m1 = m1->values;
    p_l_r = r->values;
    for (int i = 0; i < m1->rows; i++)
    {
        p_m2 = m2->values;
        
        for (int j = 0; j < m1->cols; j++)
        {
            p_c_r = p_l_r;
            for (int k = 0; k < m2->cols; k++)
            {
                //TODO Implement with intel intrinsics
                *p_c_r += (*p_m1) * (*p_m2);
                    
                p_c_r++;
                p_m2++;
            }
            
            p_m1++;
        }
        p_l_r += r->cols;
    }

    return 0;
}