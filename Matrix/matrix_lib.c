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
    float *pM1, *pM2, *pR, *plR, *pcR;

    pR = r->values;
    for (int i = 0; i < r->cols * r->rows; i++)
    {
        *pR = 0;
        pR++;
    }
    
    pM1 = m1->values;
    plR = r->values;
    for (int i = 0; i < m1->rows; i++)
    {
        pM2 = m2->values;
        
        for (int j = 0; j < m1->cols; j++)
        {
            pcR = plR;
            for (int k = 0; k < m2->cols; k++)
            {
                *pcR += (*pM1) * (*pM2);
                    
                pcR++;
                pM2++;
            }
            
            pM1++;
        }
        plR += r->cols;
    }

    return 0;
}