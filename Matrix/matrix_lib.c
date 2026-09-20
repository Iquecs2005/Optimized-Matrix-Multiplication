/**
 * Modulo com funcoes para multiplicar uma matriz por um escalar e uma matrix por outra
 * utilizando instrucoes vetoriais da biblioteca Intel Intrinsics como forma de otimizacao
 */
#include "matrix_lib.h"

/**
 * scalar_matrix_mult
 * 
 * Recebe um valor escalar e duas matrizes e armazena em uma das matrizes
 * o resultado da multiplicacao entre a outra matriz e o valor escalar
 * 
 * @param scalar_value valor escalar em float
 * @param m ponteiro para estrutura que representa a matriz a ser multiplicada
 * @param r ponteiro para estrutura que representa a matriz de resposta da multiplicacao
 * @return 0
 */
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

/**
 * matrix_matrix_mult
 * 
 * Recebe três matrizes e armazena em uma delas 
 * o resultado da multiplicacao das outras duas
 * 
 * @param m1 ponteiro para estrutura que representa a primeira matriz a ser multiplicada
 * @param m2 ponteiro para estrutura que representa a segunda matriz a ser multiplicada
 * @param r ponteiro para estrutura que representa a matriz de resposta da multiplicacao
 * @return 0
 */
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