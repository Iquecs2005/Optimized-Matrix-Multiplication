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