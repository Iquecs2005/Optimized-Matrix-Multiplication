//#define DEBUG
/**
 * @file matrix_lib_test.cu
 * @brief Test program for matrix operations using CUDA.
 * @author Alexandre Meslin
 * @date 2026-10-19
 */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <errno.h>
#include <getopt.h>

#include "matrix_lib.h"

int store_matrix(matrix *matrix, char *filename);
int check_linear_errors(matrix *source, matrix *destination, float scalar_value);
int check_mult_errors(matrix *matA, matrix *matB, matrix *matC);
int print_matrix(const char *header, matrix *matrix);
int load_matrix(matrix *matrix, char *filename);
void usage(char *program_name);

int threadsPerBlock;  // número de threads por bloco
int blocksPerGrid;    // número de blocos por grid

/**
 * Main function of the program
 * @param argc number of arguments
 * @param argv array of arguments
 * @return 0 if success, 1 if error
 */
int main(int argc, char *argv[]) {
  float scalar_value = 0.0f; // Valor escalar para multiplicação
  // Dados das matrizes
  unsigned long int dim1_rows = 0;
  unsigned long int dim1_cols = 0;
  unsigned long int dim2_rows = 0;
  unsigned long int dim2_cols = 0;
  char *matrix1_filename = NULL;
  char *matrix2_filename = NULL;
  char *result1_filename = NULL;
  char *result2_filename = NULL;

  // As matrizes
  matrix matrix1;
  matrix matrix2;
  matrix result1;
  matrix result2;

  // Timers
  struct timespec start;
  struct timespec stop;
  
  // opções
  char short_options[] = "s:r:c:C:m:M:o:O:t:b:";
  struct option long_options[] = {
    {"scalar", 1, NULL, 's'},
    {"rows1", 1, NULL, 'r'},
    {"cols1", 1, NULL, 'c'},
    {"cols2", 1, NULL, 'C'},
    {"threadsperblock", 1, NULL, 't'},
    {"blockspergrid", 1, NULL, 'b'},
    {"matrix1", 1, NULL, 'm'},
    {"matrix2", 1, NULL, 'M'},
    {"output1", 1, NULL, 'o'},
    {"output2", 1, NULL, 'O'},
    {NULL, 0, NULL, 0}
  };
  char ch;

  // Check arguments
  if(argc != 21) {
    fprintf(stderr, "[ERROR %d] %s: invalid number of arguments: %d\n", __LINE__, argv[0], argc);
    usage(argv[0]);
    return 1;
  }

  // Parse command line arguments
  while((ch = getopt_long(argc, argv, short_options, long_options, NULL)) != -1) {
    switch(ch) {
      case 's':
        scalar_value = strtof(optarg, NULL);
        break;
      case 'r':
        dim1_rows = strtol(optarg, NULL, 10);
        break;
      case 'c':
        dim1_cols = strtol(optarg, NULL, 10);
        dim2_rows = dim1_cols; // The number of rows in the second matrix must match the number of columns in the first matrix
        break;
      case 'C':
        dim2_cols = strtol(optarg, NULL, 10);
        break;
      case 't':
        threadsPerBlock = strtol(optarg, NULL, 10);
        break;
      case 'b':
        blocksPerGrid = strtol(optarg, NULL, 10);
        break;
      case 'm':
        matrix1_filename = (char *)malloc(strlen(optarg) + 1);
        strcpy(matrix1_filename, optarg);
        break;
      case 'M':
        matrix2_filename = (char *)malloc(strlen(optarg) + 1);
        strcpy(matrix2_filename, optarg);
        break;
      case 'o':
        result1_filename = (char *)malloc(strlen(optarg) + 1);
        strcpy(result1_filename, optarg);
        break;
      case 'O':
        result2_filename = (char *)malloc(strlen(optarg) + 1);
        strcpy(result2_filename, optarg);
        break;
      default:
        fprintf(stderr, "[ERROR %d] %s: invalid option: %c\n", __LINE__, argv[0], ch);
        usage(argv[0]);
        return 2;
    }
  }
  if(!matrix1_filename || !matrix2_filename || !result1_filename || !result2_filename) {
    fprintf(stderr, "[ERROR %d] %s: missing required arguments\n", __LINE__, argv[0]);
    usage(argv[0]);
    return 3;
  }
  if(!scalar_value || !dim1_rows || !dim1_cols || !dim2_cols) {
    fprintf(stderr, "[ERROR %d] %s: invalid argument values: %d\n", __LINE__, argv[0], errno);

    // Display a conversion error message if a conversion error occurred
    if(errno == EINVAL) {
      fprintf(stderr, "Conversion error occurred: %d\n", errno);
    } else if(errno == ERANGE) {
      fprintf(stderr, "The value provided was out of range: %d\n", errno);
    }
    usage(argv[0]);
    return 4;
  }
  if(dim1_cols%8 || dim1_rows%8 || dim2_cols%8 || dim2_rows%8) {
    fprintf(stderr, "[ERROR %d] %s: matrix dimensions must be multiples of 8\n", __LINE__, argv[0]);
    usage(argv[0]);
    return 5;
  }
  if(threadsPerBlock == 0 || blocksPerGrid == 0) {
    fprintf(stderr, "[ERROR %d] %s: threads per block and blocks per grid must be greater than 0\n", __LINE__, argv[0]);
    usage(argv[0]);
    return 6;
  }
  printf("[INFO %d] Starting...\n", __LINE__);

  /* Allocate the arrays of the 4 matrixes */
  float *m1 = (float*)aligned_alloc(32, dim1_rows*dim1_cols*sizeof(float));
  float *m2 = (float*)aligned_alloc(32, dim2_rows*dim2_cols*sizeof(float));
  float *r1 = (float*)aligned_alloc(32, dim1_rows*dim1_cols*sizeof(float));
  float *r2 = (float*)aligned_alloc(32, dim1_rows*dim2_cols*sizeof(float));

  // check matrix allocations
  if(!m1 || !m2 || !r1 || !r2) {
  	fprintf(stderr, "[ERROR %d] %s: array allocation problem.", __LINE__, argv[0]);
	  return 7;
  }
  // check for filename allocations
  if(!matrix1_filename || !matrix2_filename || !result1_filename || !result2_filename) {
  	fprintf(stderr, "[ERROR %d] %s: filename allocation problem.", __LINE__, argv[0]);
    return 7;
  }

  /* Initialize the 4 matrixes */
  // 1st matrix
  printf("[INFO %d] Initializing matrix A...\n", __LINE__);
  matrix1.rows = dim1_rows;
  matrix1.cols = dim1_cols;
  matrix1.values = m1;
  if(load_matrix(&matrix1, matrix1_filename)) {
  	fprintf(stderr, "[ERROR %d] %s: matrix1 initialization problem.", __LINE__, argv[0]);
	  return 8;
  }

  /* Print matrix */
  print_matrix("---------- Matrix A ----------\n", &matrix1);

  matrix2.rows = dim2_rows;
  matrix2.cols = dim2_cols;
  matrix2.values = m2;
  if(load_matrix(&matrix2, matrix2_filename)) {
  	fprintf(stderr, "[ERROR %d] %s: matrixB initialization problem.", __LINE__, argv[0]);
	  return 1;
  }

  /* Print matrix */
  print_matrix("---------- Matrix B ----------\n", &matrix2);

  result1.rows = dim1_rows;
  result1.cols = dim1_cols;
  result1.values = r1;
  result2.rows = dim1_rows;
  result2.cols = dim2_cols;
  result2.values = r2;

  /* Scalar product of matrix A */
  printf("[INFO %d] Executing scalar_matrix_mult(%5.1f, matrixA)...\n", __LINE__, scalar_value);
  clock_gettime(CLOCK_MONOTONIC, &start);
  if(scalar_matrix_mult(scalar_value, &matrix1, &result1)) {
  	fprintf(stderr, "[ERROR %d] %s: scalar_matrix_mult problem.", __LINE__, argv[0]);
	  return 1;
  }
  clock_gettime(CLOCK_MONOTONIC, &stop);
  printf("[OUTPUT %d] Time for scalar_matrix_mult: %lf ms\n", __LINE__, timedifference_msec(start, stop));

  /* Print matrix */
  print_matrix("---------- Matrix A ----------\n", &result1);

  /* Write first result */
  printf("Writing first result: %s...\n", result1_filename);
  if(store_matrix(&result1, result1_filename)) {
	  fprintf(stderr, "[ERROR %d] %s: failed to write first result to file.", __LINE__, argv[0]);
	  return 1;
  }

  /* Check for errors */
  printf("[INFO %d] Checking matrix result for errors...\n", __LINE__);
  check_linear_errors(&matrix1, &result1, scalar_value);  // it's not necessary to check the return value, because the function already prints the error message

  /* Calculate the product between matrix A and matrix B */
  printf("[INFO %d] Executing matrix_matrix_mult(matrixA, mattrixB, matrixC)...\n", __LINE__);
  clock_gettime(CLOCK_MONOTONIC, &start);
  if(matrix_matrix_mult(&matrix1, &matrix2, &result2)) {
  	fprintf(stderr, "[ERROR %d] %s: matrix_matrix_mult problem.", __LINE__, argv[0]);
	  return 1;
  }
  clock_gettime(CLOCK_MONOTONIC, &stop);
  printf("[OUTPUT %d] Time for matrix_matrix_mult: %lf ms\n", __LINE__, timedifference_msec(start, stop));

  /* Print matrix */
  print_matrix("---------- Matrix C ----------\n", &result2);

  /* Write second result */
  printf("Writing second result: %s...\n", result2_filename);
  if(store_matrix(&result2, result2_filename)) {
  	fprintf(stderr, "[ERROR %d] %s: failed to write second result to file.", __LINE__, argv[0]);
	  return 1;
  }

  /* Check for errors */
  printf("[INFO %d] Checking matrix result for errors...\n", __LINE__);
  check_mult_errors(&matrix1, &matrix2, &result2);

  // Free all allocated memory
  if(m1) free(m1);
  if(m2) free(m2);
  if(r1) free(r1);
  if(r2) free(r2);
  if(matrix1_filename) free(matrix1_filename);
  if(matrix2_filename) free(matrix2_filename);
  if(result1_filename) free(result1_filename);
  if(result2_filename) free(result2_filename);
  
  return 0;
}

/**
 * Store matrix to secondary memory
 * 
 * @param matrix pointer to the matrix structure
 * @param filename filename string
 * @return 0 in case of success or the error code
 */
int store_matrix(matrix *matrix, char *filename) {
  unsigned long int i = 0;
  unsigned long int n = 0;
  FILE *fd = NULL;

  /* Check the numbers of the elements of the matrix */
  n = matrix->rows * matrix->cols;

  /* Check the integrity of the matrix */
  if(n == 0 || matrix->values == NULL) return 21;

  /* Try to open file of floats */
  if((fd = fopen(filename, "wb")) == NULL) {
    fprintf(stderr, "Unable to open file %s\n", filename);
    return 20;
  }

  float *nxt_a = matrix->values; 

  for(i=0; i<n; i+=8, nxt_a+=8) {
  	if(fwrite(nxt_a, sizeof(float), 8, fd) != 8) {
      fprintf(stderr, "Error writing to file %s: short write (less than 8 floats)\n", filename);
      fclose(fd);
      return 21;
  	}
  }

  if(fd != NULL) fclose(fd);

  return 0;
}

/**
 * Read matrix from secondary memory
 * 
 * @param matrix pointer to the matrix structure
 * @param filename filename string
 * @return 0 in case of success or the error code
 */
int load_matrix(matrix *matrix, char *filename) {
  unsigned long int i = 0;
  unsigned long int n = 0;
  FILE *fd = NULL;

  /* Check the numbers of the elements of the matrix */
  n = matrix->rows * matrix->cols;

  /* Check the integrity of the matrix */
  if(n == 0 || matrix->values == NULL) return 21;

  /* Try to open file of floats */
  if((fd = fopen(filename, "rb")) == NULL) {
    fprintf(stderr, "Unable to open file %s\n", filename);
    return 9;
  }

  float *nxt_a = matrix->values; 

  for(i=0; i<n; i+=8, nxt_a+=8) {
  	if(fread(nxt_a, sizeof(float), 8, fd) != 8) {
      fprintf(stderr, "[ERROR %d] Error reading from file %s: short read (less than 8 floats)\n", __LINE__, filename);
      fclose(fd);
      return 10;
	  }
  }

  if(fd != NULL) fclose(fd);

  return 0;
}

int print_matrix(const char *header, matrix *matrix) {
  #ifdef DEBUG
  puts(header);
  unsigned long int i;
  unsigned long int n;
  unsigned long int nxt_newLine;

  /* Check the numbers of the elements of the matrix */
  n = matrix->rows * matrix->cols;

  /* Check the integrity of the matrix */
  if(n==0 || matrix->values==NULL) return 21;

  /* Initialize new line controol */
  nxt_newLine = matrix->cols - 1;

  /* Print matrix elements */
  for(i=0; i<n; i++) {
    printf("%5.1f ", matrix->values[i]);
    if(i == nxt_newLine) {
	    printf("\n");
	    nxt_newLine += matrix->cols;
    }
    if(i == 255) {
      printf("Ooops...256 printing limit found...skipping printing...\n");
      break;
    }
  }
  #endif
  return 0;
}

int check_linear_errors(matrix *source, matrix *destination, float scalar_value) {
  for(int line=0; line<source->rows; line++) {
    for(int row=0; row<source->cols; row++) {
      int pos = line*source->cols+row;
      float expected = scalar_value * source->values[pos];
      if(fabs((expected-destination->values[pos])/destination->values[pos]) > 0.0001) {
        fprintf(stderr, "[ERROR %d] Linear error at [%d, %d] - %f x %f\n", __LINE__, line, row, expected, destination->values[pos]);
        return 1;
      }
    }
  }

  return 0;
}

int check_mult_errors(matrix *matA, matrix *matB, matrix *matC) {
  // Loop para calcular cada elemento da matriz resultante
  for (int i = 0; i < matC->rows; i++) {
    for (int j = 0; j < matC->cols; j++) {
      float sum = 0.0;
      for (int k = 0; k < matA->cols; k++) {
        sum += matA->values[i * matA->cols + k] * matB->values[k * matB->cols + j];
      }
      if(fabs((matC->values[i * matC->cols + j]-sum)/sum) > 0.0001) {
        fprintf(stderr, "[ERROR %d] Multiplication error at [%d, %d] - %f x %f\n", __LINE__, i, j, matC->values[i * matC->cols + j], sum);
        return 1;
      }
    }
  }
  return 0;
}

void usage(char *program_name) {
  fprintf(stderr, "Usage: %s [OPTION]...\n", program_name);
  fprintf(stderr, "Multiply matrix by scalar and by matrix\n");
  fprintf(stderr, "-s --scalar          scalar value that will multiply the first matrix\n");
  fprintf(stderr, "-r --rows            number of rows in the first matrix\n");
  fprintf(stderr, "-c --cols1           number of columns in the first matrix or the number of rows in the second matrix\n");
  fprintf(stderr, "-C --cols2           number of columns in the second matrix\n");
  fprintf(stderr, "-t --threadsperblock number of threads per block\n");
  fprintf(stderr, "-b --blockspergrid   number of blocks per grid\n");
  fprintf(stderr, "-m --matrix1         float file that will be used to load the first matrix\n");
  fprintf(stderr, "-M --matrix2         float file that will be used to load the second matrix\n");
  fprintf(stderr, "-o --output1         float file where the first result will be stored\n");
  fprintf(stderr, "-O --output2         float file where the second result will be stored\n");
}
