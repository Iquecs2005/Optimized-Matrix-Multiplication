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

void *matrix_worker(void *args);
void *scalar_worker(void *args);

int matrix_matrix_mult(matrix *m1, matrix *m2, matrix *r)
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

    matrix* a = thread_args->m1;
    matrix* b = thread_args->m2;
    matrix* c = thread_args->r;

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

int scalar_matrix_mult(float scalar_value, matrix *m, matrix *r)
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