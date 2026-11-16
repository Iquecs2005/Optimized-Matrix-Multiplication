#include "matrix_lib.h"

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

void allocate_matrix_device(matrix* m, float** mD);
void transfer_matrix(float* origin, float* destination, cudaMemcpyKind direction);


int scalar_matrix_mult(float scalar_value, matrix *m, matrix *r)
{
    float* deviceInputMatrix, *deviceResultMatrix;

    allocate_matrix_device(m, &deviceInputMatrix);
    allocate_matrix_device(r, &deviceResultMatrix);

    transfer_matrix_to_device(m, deviceInputMatrix);

    transfer_matrix_to_device(m, deviceInputMatrix);
}

int matrix_matrix_mult(matrix *m1, matrix *m2, matrix *r)
{

}

void allocate_matrix_device(matrix* m, float** mD)
{
    cudaError_t error = cudaMalloc(mD, m->rows * m->cols * sizeof(float));

    if (error != cudaSuccess)
    {
        fprintf(stderr, "[ERROR %d] Device Matrix allocation error\n", __LINE__);
        exit(3);
    }
}

void transfer_matrix_to_device(matrix* origin, float* destination)
{
    unsigned long size = origin->rows * origin->cols;
    cudaError_t error = cudaMemcpy(destination, origin->values, size * sizeof(float), cudaMemcpyHostToDevice);
    if (error != cudaSuccess)
    {
        fprintf(stderr, "[ERROR %d] Matrix transfer error\n", __LINE__);
        exit(4);
    }
}

void transfer_matrix_to_host(float* origin, matrix* destination)
{
    unsigned long size = destination->rows * destination->cols;
    cudaError_t error = cudaMemcpy(destination->values, origin, size * sizeof(float), cudaMemcpyDeviceToHost);
    if (error != cudaSuccess)
    {
        fprintf(stderr, "[ERROR %d] Matrix transfer error\n", __LINE__);
        exit(4);
    }
}

__global__ void scalar_mult_worker(unsigned long size, float scalar_value, float* inputMatrix, float* resultMatrix)
{
    unsigned long threadID = blockIdx.x * blockDim.x + threadIdx.x;
    unsigned long totalThreads = gridDim.x * blockDim.x;

    unsigned long index = threadID;

    inputMatrix += threadID;
    resultMatrix += threadID;

    while (index < size)
    {
        /* code */
        *resultMatrix = scalar_value * *inputMatrix;

        index += totalThreads;
        inputMatrix += totalThreads;
        resultMatrix += totalThreads;
    }
}