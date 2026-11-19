#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <pthread.h>

#include "matrix_lib.h"

#define N_THREADS 16

typedef struct {
    Matrix *m1;
    Matrix *m2;
    Matrix *r;
    float scalar_value;
    int thread_id;
} pthread_args;

Matrix CreateMatrix(int nLines, int nCollumns);
void MultiplyMatrix(Matrix* a, Matrix* b, Matrix* c);
void MultiplyMatrixVector(Matrix* a, Matrix* b, Matrix* c);
void MultiplyMatrixBest(Matrix* a, Matrix* b, Matrix* c);
void ReadMatrixFromFile(Matrix* matrix, char file[]);
void SaveMatrixToFile(Matrix* matrix, char file[]);
void PrintMatrix(Matrix* matrix);
void *matrix_worker(void *args);
int matrix_matrix_mult(Matrix *m1, Matrix *m2, Matrix *r);
void *scalar_worker(void *args);
int scalar_matrix_mult(float scalar_value, Matrix *m, Matrix *r);

int main(int argc, char *argv[])
{
    Matrix a = CreateMatrix(atoi(argv[2]), atoi(argv[3]));
    Matrix b = CreateMatrix(atoi(argv[5]), atoi(argv[6]));
    Matrix c = CreateMatrix(a.nLines, b.nCollumns);

    ReadMatrixFromFile(&a, argv[1]);
    ReadMatrixFromFile(&b, argv[4]);

    clock_t t;

    t = clock();
    matrix_matrix_mult(&a, &b, &c);
    t = clock() - t;
    
    // printf("\nMatrix A:\n\n");
    // PrintMatrix(&a);
    // printf("\nMatrix B:\n\n");
    // PrintMatrix(&b);
    // printf("\nMatrix C:\n\n");
    // PrintMatrix(&c);
    // printf("\n");

    double timeTaken = ((double)t)/CLOCKS_PER_SEC;

    printf("Time: %lf\n", timeTaken);

    SaveMatrixToFile(&c, argv[7]);

    return 0;
}

Matrix CreateMatrix(int nLines, int nCollumns)
{
    Matrix matrix;

    matrix.nLines = nLines;
    matrix.nCollumns = nCollumns;

    //matrix.matrixData = (double*)malloc(matrix.nLines * matrix.nCollumns * sizeof(double));
    matrix.matrixData = (double*)aligned_alloc(sizeof(double), matrix.nLines * matrix.nCollumns * sizeof(double));

    if (!matrix.matrixData)
    {
        fprintf(stderr, "[ERROR %d] Memory could not be allocated for Matrix. Aborting program.\n", __LINE__);
        exit(1);
    }

    return matrix;
}

void MultiplyMatrix(Matrix* a, Matrix* b, Matrix* c)
{
    for (int i = 0; i < c->nLines; i++)
    {
        for (int j = 0; j < c->nCollumns; j++)
        {
            int cIndex = i * c->nCollumns + j;
            c->matrixData[cIndex] = 0;
            for (int k = 0; k < a->nCollumns; k++)
            {
                int aIndex = i * a->nCollumns + k;
                int bIndex = k * b->nCollumns + j;

                c->matrixData[cIndex] += a->matrixData[aIndex] * b->matrixData[bIndex];
            }
        }
    }
}

void MultiplyMatrixVector(Matrix* a, Matrix* b, Matrix* c)
{
    for (int i = 0; i < c->nLines; i++)
    {
        for (int j = 0; j < c->nCollumns; j++)
        {
            int cIndex = i * c->nCollumns + j;
            c->matrixData[cIndex] = 0;
            for (int k = 0; k < a->nCollumns; k++)
            {
                int aIndex = i * a->nCollumns + k;
                int bIndex = k * b->nCollumns + j;

                c->matrixData[cIndex] += a->matrixData[aIndex] * b->matrixData[bIndex];
            }
        }
    }
}

void MultiplyMatrixBest(Matrix* a, Matrix* b, Matrix* c)
{
    double *pA, *pB, *plC, *pcC;
    double *pC;

    pC = c->matrixData;
    for (int i = 0; i < c->nCollumns * c->nLines; i++)
    {
        *pC = 0;
        pC++;
    }
    
    pA = a->matrixData;
    plC = c->matrixData;
    for (int i = 0; i < a->nLines; i++)
    {
        pB = b->matrixData;
        
        for (int j = 0; j < a->nCollumns; j++)
        {
            pcC = plC;
            for (int k = 0; k < b->nCollumns; k++)
            {
                *pcC += (*pA) * (*pB);
                    
                pcC++;
                pB++;
            }
            
            pA++;
        }
        plC += c->nCollumns;
    }
}

int matrix_matrix_mult(Matrix *m1, Matrix *m2, Matrix *r)
{
    pthread_attr_t attr;
    pthread_args thread_args[N_THREADS];
    pthread_t thread_id[N_THREADS];
    void *status;

    int rc;

    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);

    for (int i = 0; i < N_THREADS; i++)
    {
        thread_args[i].m1 = m1;
        thread_args[i].m2 = m2;
        thread_args[i].r = r;
        thread_args[i].thread_id = i;

        rc = pthread_create(&thread_id[i], &attr, matrix_worker, (void*)(&thread_args[i]));
        if (rc)
        {
            fprintf(stderr, "[ERROR %d] Erro #%d ao criar threads\n", __LINE__, rc);
            exit(1);
        }   
    }

    pthread_attr_destroy(&attr);

    for (int i = 0; i < N_THREADS; i++)
    {
        rc = pthread_join(thread_id[i], &status);
        if (rc) 
        {
            fprintf(stderr, "[ERROR %d] return code from pthread_join() is %d\n", __LINE__, rc);
            exit(2);
        }
    }
    
    return 0;
}

void *matrix_worker(void *args)
{
    pthread_args *thread_args = (pthread_args*)args;
    int qtd_linhas;
    int thread_id;
    int sobraram;
    int linha;

    Matrix *a = thread_args->m1;
    Matrix *b = thread_args->m2;
    Matrix *c = thread_args->r;

    thread_id = thread_args->thread_id;
    qtd_linhas = thread_args->r->nLines / N_THREADS;
    sobraram = thread_args->r->nLines % N_THREADS;

    //multiplica linhas

    if (thread_id < sobraram)
    {
        linha = qtd_linhas * thread_id + thread_id;
        qtd_linhas++;
    }
    else
    {
        linha = qtd_linhas * thread_id + sobraram;
    }

    for (int i = linha; i < linha + qtd_linhas; i++)
    {
        for (int j = 0; j < c->nCollumns; j++)
        {
            int cIndex = i * c->nCollumns + j;
            c->matrixData[cIndex] = 0;
            for (int k = 0; k < a->nCollumns; k++)
            {
                int aIndex = i * a->nCollumns + k;
                int bIndex = k * b->nCollumns + j;

                c->matrixData[cIndex] += a->matrixData[aIndex] * b->matrixData[bIndex];
            }
        }
    }
    return NULL;
}

int scalar_matrix_mult(float scalar_value, Matrix *m, Matrix *r)
{
    pthread_attr_t attr;
    pthread_args thread_args[N_THREADS];
    pthread_t thread_id[N_THREADS];
    void *status;

    int rc;

    pthread_attr_init(&attr);
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);

    for (int i = 0; i < N_THREADS; i++)
    {
        thread_args[i].m1 = m;
        thread_args[i].r = r;
        thread_args[i].scalar_value = scalar_value;
        thread_args[i].thread_id = i;

        rc = pthread_create(&thread_id[i], &attr, scalar_worker, (void*)(&thread_args[i]));
        if (rc)
        {
            fprintf(stderr, "[ERROR %d] Erro #%d ao criar threads\n", __LINE__, rc);
            exit(1);
        }   
    }

    pthread_attr_destroy(&attr);

    for (int i = 0; i < N_THREADS; i++)
    {
        rc = pthread_join(thread_id[i], &status);
        if (rc) 
        {
            fprintf(stderr, "[ERROR %d] return code from pthread_join() is %d\n", __LINE__, rc);
            exit(2);
        }
    }
    
    return 0;
}

void *scalar_worker(void *args)
{
    pthread_args *thread_args = (pthread_args*)args;
    int qtd_linhas;
    int thread_id;
    int sobraram;
    int linha;

    Matrix *m = thread_args->m1;
    Matrix *r = thread_args->r;
    float scalar_value = thread_args->scalar_value;

    thread_id = thread_args->thread_id;
    qtd_linhas = thread_args->r->nLines / N_THREADS;
    sobraram = thread_args->r->nLines % N_THREADS;


    if (thread_id < sobraram)
    {
        linha = qtd_linhas * thread_id + thread_id;
        qtd_linhas++;
    }
    else
    {
        linha = qtd_linhas * thread_id + sobraram;
    }

    for (int i = linha; i < linha + qtd_linhas; i++)
    {
        for (int j = 0; j < m->nCollumns; j++)
        {
            int index = i * m->nCollumns + j;
            r->matrixData[index] = scalar_value * m->matrixData[index];
        }
    }
    return NULL;
}

/*
    Read Matrix From File

    Fills a matrix with the content present in a file.

    @param matrix Matrix to be filled
    @param file File name
    @return Void
*/
void ReadMatrixFromFile(Matrix* matrix, char file[])
{
    FILE* arq;

    arq = fopen(file, "rb");
    if (!arq)
    {
        fprintf(stderr, "[ERROR %d] File %s could not be opened for reading. Aborting program.\n", __LINE__, file);
        exit(2);
    }

    int nElements = matrix->nLines * matrix->nCollumns;
    int itemsRead = fread(matrix->matrixData, sizeof(double), nElements, arq);
    if (itemsRead != nElements)
    {
        fprintf(stderr, "[ERROR %d] File %s does not contain enough elements (Expected = %d, Read = %d)\n",
             __LINE__, file, nElements, itemsRead);
    }

    fclose(arq);
}

/*
    Save Matrix To File

    Saves a matrix's content present in a file.

    @param matrix Matrix to be saved
    @param file File name
    @return Void
*/
void SaveMatrixToFile(Matrix* matrix, char file[])
{
    FILE* arq;

    arq = fopen(file, "wb");
    if (!arq)
    {
        fprintf(stderr, "[ERROR %d] File %s could not be opened for writing. Aborting program\n", __LINE__, file);
        exit(2);
    }

    int nElements = matrix->nLines * matrix->nCollumns;
    int itemsWritten = fwrite(matrix->matrixData, sizeof(double), nElements, arq);
    if (itemsWritten != nElements)
    {
        fprintf(stderr, "[ERROR %d] File %s could not be written completely (Expected = %d, Written = %d)\n",
             __LINE__, file, nElements, itemsWritten);
    }

    fclose(arq);
}

void PrintMatrix(Matrix* matrix)
{
    double* pMatrix = matrix->matrixData;
    for (int i = 0; i < matrix->nLines; i++)
    {
        for (int j = 0; j < matrix->nCollumns; j++)
        {
            printf("%lf   ", *pMatrix);
            pMatrix++;
        }
        printf("\n");
    }
}