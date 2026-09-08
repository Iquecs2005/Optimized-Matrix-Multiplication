#include <stdio.h>
#include <stdlib.h>
#include <time.h>

typedef struct matrix
{
    int nLines, nCollumns;
    double *matrixData;
} Matrix;

Matrix CreateMatrix(int nLines, int nCollumns);
void MultiplyMatrix(Matrix* a, Matrix* b, Matrix* c);
void ReadMatrixFromFile(Matrix* matrix, char file[]);
void SaveMatrixToFile(Matrix* matrix, char file[]);

int main(int argc, char *argv[])
{
    Matrix a = CreateMatrix(atoi(argv[2]), atoi(argv[3]));
    Matrix b = CreateMatrix(atoi(argv[5]), atoi(argv[6]));
    Matrix c = CreateMatrix(a.nLines, b.nCollumns);

    ReadMatrixFromFile(&a, argv[1]);
    ReadMatrixFromFile(&b, argv[4]);

    clock_t t;

    t = clock();
    MultiplyMatrix(&a, &b, &c);
    t = clock() - t;

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

    matrix.matrixData = (double*)malloc(matrix.nLines * matrix.nCollumns * sizeof(double));
    //a.matrixData = (double*)_aligned_malloc(sizeof(double), a.nLines * a.nCollumns * sizeof(double));

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