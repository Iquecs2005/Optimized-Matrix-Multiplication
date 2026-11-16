#include <stdio.h>
#include <stdlib.h>
#include <cuda_runtime.h>

__global__ void add(int qtd, float* p1, float* p2, float* pres);
void allocate_matrix(float** m1H, float** m2H, float** mrH, float** m1D, float** m2D, float** mrD);
void initialize_matrix_host(float* mH);
void transfer_matrix(float* origin, float* destination, cudaMemcpyKind direction);

#define DATASET_SIZE 1024

#define timedifference_msec(start, stop) ((double)(stop - start) * 1000.0 / CLOCKS_PER_SEC)

/**
 * Funcao main
 * 
 * - alocar espaco para os 3 vetores
 * - transferir os 2 vetores de entrada para o device
 * - executar a soma no device
 * - transferir o vetor resultado para o host
 * - verificar se o resultado esta correto
*/
int main(void)
{
    float* m1H;
    float* m2H;
    float* mrH;
    float* m1D;
    float* m2D;
    float* mrD;

    clock_t start;
    clock_t stop;

    allocate_matrix(&m1H, &m2H, &mrH, &m1D, &m2D, &mrD);
    initialize_matrix_host(m1H);
    initialize_matrix_host(m2H);
    transfer_matrix(m1H, m1D, cudaMemcpyHostToDevice);
    transfer_matrix(m2H, m2D, cudaMemcpyHostToDevice);

    start = clock();
    add<<<4096,256>>>(DATASET_SIZE, m1D, m2D, mrD);
    stop = clock();

    return 0;
}

void allocate_matrix(float** m1H, float** m2H, float** mrH, float** m1D, float** m2D, float** mrD)
{
    *m1H = (float*)malloc(DATASET_SIZE * sizeof(float));
    *m2H = (float*)malloc(DATASET_SIZE * sizeof(float));
    *mrH = (float*)malloc(DATASET_SIZE * sizeof(float));

    if (!(*m1H) || !(*m2H) || !(*mrH))
    {
        fprintf(stderr, "[ERROR %d] Host Matrix allocation error\n", __LINE__);
        exit(1);
    }

    cudaError_t errorM1 = cudaMalloc(m1D, DATASET_SIZE * sizeof(float));
    cudaError_t errorM2 = cudaMalloc(m2D, DATASET_SIZE * sizeof(float));
    cudaError_t errorM3 = cudaMalloc(mrD, DATASET_SIZE * sizeof(float));

    if (errorM1 != cudaSuccess || errorM2 != cudaSuccess || errorM3 != cudaSuccess)
    {
        fprintf(stderr, "[ERROR %d] Device Matrix allocation error\n", __LINE__);
        exit(2);
    }
}

void initialize_matrix_host(float* mH)
{
    for (int i = 0; i < DATASET_SIZE; i++)
    {
        mH[i] = i;
    }
}

void transfer_matrix(float* origin, float* destination, cudaMemcpyKind direction)
{
    cudaError_t error = cudaMemcpy(destination, origin, DATASET_SIZE * sizeof(float), direction);
    if (error != cudaSuccess)
    {
        fprintf(stderr, "[ERROR %d] Matrix transfer error\n", __LINE__);
        exit(3);
    }
}

__global__ void add(int qtd, float* p1, float* p2, float* pres)
{
    long threadID = blockIdx.x * blockDim.x + threadIdx.x;

    if (threadID < qtd)
    {
        long totalThreads = gridDim.x * blockDim.x;
        int nOperations = qtd / totalThreads;
        long start = nOperations * threadID;

        for (int i = 0; i < nOperations; i++)
        {
            pres[start + i] = p1[start + i] + p2[start + i];
        }
    }

}