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

    return 0;
}

int matrix_matrix_mult(matrix *m1, matrix *m2, matrix *r)
{
    float *p_m1, *p_m2, *p_r, *p_l_r, *p_c_r;

    p_r = r->values;
    for (int i = 0; i < r->cols * r->rows; i++)
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