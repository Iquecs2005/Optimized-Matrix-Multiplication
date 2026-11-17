#include <stdio.h>
#include <stdlib.h>
#include <time.h>

typedef float matrix_type;

//argv[1] = file name
//argv[2] = nNumbers

//OR

//argv[1] = file name
//argv[2] = nLines
//argv[3] = nCollumns

//OR

//argv[1] = file name
//argv[2] = nLines
//argv[3] = nCollumns
//argv[4] = Random = True(1) / False(0)

int main(int argc, char *argv[])
{
    if (argc < 3 || argc > 5)
    {
        fprintf(stderr, "[ERROR %d] Wrong argument count.\n", __LINE__);
        exit(1);
    }

    srand(time(NULL));

    char* fileName = argv[1];
    int nNumbers = atoi(argv[2]);
    matrix_type a = 5;
    char random = 1;

    if (argc >= 4)
    {
        nNumbers *= atoi(argv[3]);
    }
    if (argc == 5)
    {
        random = atoi(argv[4]);
    }

    FILE* outputFile = fopen(fileName, "wb");
    if (!outputFile)
    {
        fprintf(stderr, "[ERROR %d] File %s could not be opened for writing.\n", __LINE__, fileName);
        exit(2);
    }

    matrix_type n = 0;
    for (int i = 0; i < nNumbers; i++)
    {
        n = (matrix_type)i;
        if (random)
        {
            n = a * ((matrix_type)rand()/(matrix_type)RAND_MAX);
        }

        //printf("%lf\n", n);
        fwrite(&n, sizeof(n), 1, outputFile);
    }

    fclose(outputFile);

    return 0;
}