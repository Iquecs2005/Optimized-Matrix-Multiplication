#include "matrix_lib.h"

#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

int allocate_matrix_device(matrix* m, float** mD);
int transfer_matrix_to_device(matrix* origin, float* destination);
int transfer_matrix_to_host(float* origin, matrix* destination);
__global__ void scalar_mult_worker(unsigned long size,
                                   float scalar_value,
                                   float* inputMatrix,
                                   float* resultMatrix);


int scalar_matrix_mult(float scalar_value, matrix *m, matrix *r)
{
    float* deviceInputMatrix, *deviceResultMatrix;
    unsigned long size = m->rows * m->cols;
    int error = 0;
    
    error = allocate_matrix_device(m, &deviceInputMatrix);
    if (error)
        return error;
    error = allocate_matrix_device(r, &deviceResultMatrix);
    if (error)
        return error;

    error = transfer_matrix_to_device(m, deviceInputMatrix);
    if (error)
        return error;

    scalar_mult_worker<<<blocksPerGrid,threadsPerBlock>>>(size, scalar_value, deviceInputMatrix, deviceResultMatrix);

    error = transfer_matrix_to_host(deviceResultMatrix, r);
    if (error)
        return error;

    cudaFree(deviceInputMatrix);
    cudaFree(deviceResultMatrix);

    return 0;
}

int matrix_matrix_mult(matrix *m1, matrix *m2, matrix *r)
{
    return -1;
}

int allocate_matrix_device(matrix* m, float** mD)
{
    cudaError_t error = cudaMalloc(mD, m->rows * m->cols * sizeof(float));

    if (error != cudaSuccess)
    {
        fprintf(stderr, "[ERROR %d] Device Matrix allocation error\n", __LINE__);
        return 3;
    }
    return 0;
}

int transfer_matrix_to_device(matrix* origin, float* destination)
{
    unsigned long size = origin->rows * origin->cols;
    cudaError_t error = cudaMemcpy(destination, origin->values, size * sizeof(float), cudaMemcpyHostToDevice);
    if (error != cudaSuccess)
    {
        fprintf(stderr, "[ERROR %d] Matrix transfer error\n", __LINE__);
        return 4;
    }
    return 0;
}

int transfer_matrix_to_host(float* origin, matrix* destination)
{
    unsigned long size = destination->rows * destination->cols;
    cudaError_t error = cudaMemcpy(destination->values, origin, size * sizeof(float), cudaMemcpyDeviceToHost);
    if (error != cudaSuccess)
    {
        fprintf(stderr, "[ERROR %d] Matrix transfer error\n", __LINE__);
        return 4;
    }
    return 0;
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
        *resultMatrix = scalar_value * (*inputMatrix);

        index += totalThreads;
        inputMatrix += totalThreads;
        resultMatrix += totalThreads;
    }
}