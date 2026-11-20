/**
 * Modulo com funcoes para multiplicar uma matriz por um escalar e uma matrix por outra
 * utilizando incremento de vetores, threads e a GPU Nvidia como forma de otimizacao
 *
 * Codigos de erro:
 * - 3: erro na alocacao da matriz no device
 * - 4: erro ao transferir a matriz
 */
#include "matrix_lib.h"

#include <stdio.h>
#include <cuda_runtime.h>

int allocate_matrix_device(float** mD, unsigned long size);
int transfer_matrix(float* origin, float* destination, unsigned long size, cudaMemcpyKind dir);
__global__ void scalar_mult_worker(unsigned long size,
                                   float scalar_value,
                                   float* inputMatrix,
                                   float* resultMatrix);
__global__ void matrix_mult_worker(float* m1,
                                   float* m2,
                                   float* r,
                                   unsigned long dim_1,
                                   unsigned long dim_2,
                                   unsigned long dim_3);

/**
 * scalar_matrix_mult
 * 
 * Recebe um valor escalar e duas matrizes, 1 de entrada e uma de saída. 
 * Armazena na matriz 'r' o resultado da multiplicacao entre a outra matriz
 * e o valor escalar. A funcao e executada no host
 * e chama a funcao scalar_mult_worker no device
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
    float* dm, *dr;
    unsigned long size = r->rows * r->cols;
    int error = 0;
    
    error = allocate_matrix_device(&dm, size);
    if (error) return error;
    error = allocate_matrix_device(&dr, size);
    if (error) return error;

    error = transfer_matrix(m->values, dm, size, cudaMemcpyHostToDevice);
    if (error) return error;

    scalar_mult_worker<<<blocksPerGrid,threadsPerBlock>>>(size, scalar_value, dm, dr);

    error = transfer_matrix(dr, r->values, size, cudaMemcpyDeviceToHost);
    if (error) return error;

    cudaFree(dm);
    cudaFree(dr);

    return 0;
}

/**
 * matrix_matrix_mult
 * 
 * Recebe três matrizes inicializadas, 2 de entrada e uma de saída. 
 * Retorna na matriz 'r' o resultado da multiplicacao entre das outras duas.
 * A funcao e executada no host e chama a funcao matrix_mult_worker no device
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
    float* dm1, *dm2, *dr;
    unsigned long m1Size = m1->rows * m1->cols;
    unsigned long m2Size = m2->rows * m2->cols;
    unsigned long rSize = r->rows * r->cols;
    int error = 0;
    
    error = allocate_matrix_device(&dm1, m1Size);
    if (error) return error;
    error = allocate_matrix_device(&dm2, m2Size);
    if (error) return error;
    error = allocate_matrix_device(&dr, rSize);
    if (error) return error;

    error = transfer_matrix(m1->values, dm1, m1Size, cudaMemcpyHostToDevice);
    //error = transfer_matrix_to_device(m1, dm1);
    if (error) return error;
    error = transfer_matrix(m2->values, dm2, m2Size, cudaMemcpyHostToDevice);
    //error = transfer_matrix_to_device(m2, dm2);
    if (error) return error;

    matrix_mult_worker<<<blocksPerGrid,threadsPerBlock>>>(dm1, dm2, dr, m1->rows, m1->cols, m2->cols);

    error = transfer_matrix(dr, r->values, rSize, cudaMemcpyDeviceToHost);
    if (error) return error;

    cudaFree(dm1);
    cudaFree(dm2);
    cudaFree(dr);

    return 0;
}

/**
 * allocate_matrix_device
 * 
 * Recebe o endereco para um vetor de floats que representa a matriz no device 
 * e o tamanho da matriz. A funcao aloca o espaco de memoria para esse vetor
 * 
 * @param mD ponteiro para vetor de floats que representa a matriz no device
 * @param size tamanho da matriz que sera usado para alocar a memoria necessaria
 * @return 0 quando não encontra nenhum erro e 3 quando ocorre erro na alocacao
 */
int allocate_matrix_device(float** mD, unsigned long size)
{
    cudaError_t error = cudaMalloc(mD, size * sizeof(float));

    if (error != cudaSuccess)
    {
        fprintf(stderr, "[ERROR %d] Device Matrix allocation error\n", __LINE__);
        return 3;
    }
    return 0;
}

/**
 * transfer_matrix
 * 
 * Recebe dois ponteiros para floats que representam as matrizes e o tamanho da matriz
 * recebe tambem a direcao da operacao (host / device). 
 * A funcao copia os dados da primeira matriz para a segunda
 * 
 * @param origin vetor de floats que representa a matriz de origem
 * @param destination vetor de floats que representa a matriz de destino
 * @param size tamanho das matrizes que estao sendo transferidas
 * @param dir direcao da operação (device para host ou host para device)
 * @return 0 quando não encontra nenhum erro e 4 quando ocorre erro na transferencia
 */
int transfer_matrix(float* origin, float* destination, unsigned long size, cudaMemcpyKind dir)
{
    cudaError_t error = cudaMemcpy(destination, origin, size * sizeof(float), dir);
    if (error != cudaSuccess)
    {
        fprintf(stderr, "[ERROR %d] Matrix transfer error\n", __LINE__);
        return 4;
    }
    return 0;
}

/**
 * scalar_mult_worker
 * 
 * Funcao de auxilio executada no device nas threads da funcao scalar_matrix_mult.
 * A funcao realiza a multiplicacao da matriz por escalar por threads,
 * com cada thread cuidando dos elementos referentes ao seu ID (com offset baseado no ID)
 * 
 * @param size tamanho da matriz a ser multiplicada
 * @param scalar_value valor escalar em float
 * @param inputMatrix ponteiro para vetor de floats
 * que representa a matriz a ser multiplicada
 * @param resultMatrix ponteiro para vetor de floats
 * que representa a matriz de resposta da multiplicacao
 */
__global__ void scalar_mult_worker(unsigned long size,
                                   float scalar_value,
                                   float* inputMatrix,
                                   float* resultMatrix)
{
    unsigned long threadID = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned long totalThreads = gridDim.x * blockDim.x;

    float* endAddress = resultMatrix + size;

    inputMatrix += threadID;
    resultMatrix += threadID;

    while (resultMatrix < endAddress)
    {
        /* code */
        *resultMatrix = scalar_value * (*inputMatrix);

        inputMatrix += totalThreads;
        resultMatrix += totalThreads;
    }
}

/**
 * matrix_mult_worker
 * 
 * Funcao de auxilio executada no device nas threads da funcao matrix_matrix_mult.
 * A funcao realiza a multiplicacao entre matrizes por threads,
 * com cada thread cuidando dos elementos referentes ao seu ID (com offset baseado no ID)
 * 
 * @param m1 ponteiro para vetor de floats
 * que representa a primeira matriz a ser multiplicada
 * @param m2 ponteiro para vetor de floats
 * que representa a segunda matriz a ser multiplicada
 * @param r ponteiro para vetor de floats
 * que representa a matriz de resposta da multiplicacao
 * @param dim_1 tamanho da primeira matriz a ser multiplicada
 * @param dim_2 tamanho da segunda matriz a ser multiplicada
 * @param dim_1 tamanho da matriz de resposta
 */
__global__ void matrix_mult_worker(float* m1,
                                   float* m2,
                                   float* r,
                                   unsigned long dim_1,
                                   unsigned long dim_2,
                                   unsigned long dim_3)
{
    unsigned long threadID = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned long totalThreads = gridDim.x * blockDim.x;

    unsigned long index = threadID;
    float* p_m2;
    float* p_l_r = r;

    m1 += threadID * dim_2;
    p_l_r += threadID * dim_3;
    
    while (index < dim_1)
    {
        r = p_l_r;
        
        for (int i = 0; i < dim_3; i++)
        {
            *r = 0;
            r++;
        }
        
        p_m2 = m2;
        for (int i = 0; i < dim_2; i++)
        {
            r = p_l_r;

            for (int j = 0; j < dim_3; j++)
            {
                *r += (*m1) * (*p_m2);
                p_m2++;
                r++;
            }

            m1++;
        }

        index += totalThreads;
        p_l_r += dim_3 * totalThreads;
    }
}