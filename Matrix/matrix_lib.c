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
    for (int i = 0; i < r->cols; i++)
    {
        for (int j = 0; j < r->rows; j++)
        {
            int index = j * r->cols + i;
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

    return 0;
}