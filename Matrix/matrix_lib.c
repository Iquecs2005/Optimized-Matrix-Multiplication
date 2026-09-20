/**
 * Modulo com funcoes para multiplicar uma matriz por um escalar e uma matrix por outra
 * utilizando percurso por linhas e incremento de vetores como forma de otimizacao
 */
#include "matrix_lib.h"

/**
 * scalar_matrix_mult
 * 
 * Recebe um valor escalar e duas matrizes, 1 de entrada e uma de saída. 
 * Armazena na matriz 'r' o resultado da multiplicacao entre a outra matriz
 * e o valor escalar.
 * 
 * @param scalar_value valor escalar em float
 * @param m ponteiro para estrutura inicializada do tipo 'matrix'
 * que representa a matriz a ser multiplicada
 * @param r ponteiro para estrutura inicializada do tipo 'matrix'
 * que representa a matriz de resposta da multiplicacao
 * @return A matriz resultado no parametro 'r' e 0 quando não encontra nenhum erro
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
 * Recebe três matrizes inicializadas, 2 de entrada e uma de saída. 
 * Retorna na matriz 'r' o resultado da multiplicacao entre das outras duas.
 * 
 * @param m1 ponteiro para estrutura inicializada do tipo 'matrix'
 * que representa a primeira matriz a ser multiplicada
 * @param m2 ponteiro para estrutura inicializada do tipo 'matrix'
 * que representa a segunda matriz a ser multiplicada
 * @param r ponteiro para estrutura que representa a matriz de resposta da multiplicacao
 * @return A matriz resultado no parametro 'r' e 0 quando não encontra nenhum erro
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