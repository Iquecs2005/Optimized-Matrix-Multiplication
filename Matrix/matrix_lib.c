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

    __m256 values_a, values_b, results, zero;

    p_r = r->values;
    n_numbers = r->cols * r->rows;

    zero = _mm256_setzero_ps();

    for (int i = 0; i < n_numbers; i += 8)
    {
        _mm256_store_ps(p_r, zero);
        p_r += 8;
    }
    
    p_m1 = m1->values;
    p_l_r = r->values;
    for (int i = 0; i < m1->rows; i++)
    {
        p_m2 = m2->values;
        
        for (int j = 0; j < m1->cols; j++)
        {
            //Para cada elemento de A passando pelas linhas
            p_c_r = p_l_r;
            values_a = _mm256_set1_ps(*p_m1);
            for (int k = 0; k < m2->cols; k += 8)
            {
                values_b = _mm256_load_ps(p_m2);
                results = _mm256_load_ps(p_c_r);
                results = _mm256_fmadd_ps(values_a, values_b, results);
                _mm256_store_ps(p_c_r, results);
                    
                p_c_r += 8;
                p_m2 += 8;
            }
            
            p_m1++;
        }
        p_l_r += r->cols;
    }

    return 0;
}