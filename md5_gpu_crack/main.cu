#include <python2.7/Python.h>
#include "md5.cu"

#define LOOP 100

__device__ const int DEVICE_LOOP = LOOP;
__device__ int global_success = 0;
__device__ char *haha;

__device__ void copyWord(unsigned char* bruteWord, unsigned char* answer, int wordSize) {
	int i;
	for (i = 0; i < wordSize; i++) {
		answer[i] = bruteWord[i];
	}
	answer[wordSize] = '\0';
}

__device__ void fillZero(unsigned char* word, int wordSize) {
	int i;
	for (i = 0; i < wordSize; i++) {
		word[i] = 0;
	}
	word[wordSize] = '\0';
}

__device__ int strsize(char *string) {
	int i = 0;
	while (string[i] != '\0') {
		i++;
	}
	return i;
}

__device__ void makeBruteWord(unsigned char* indexWord, unsigned char* bruteWord, char* string, int digit) {
	int i;
	for (i = 0; i < digit; i++) {
		bruteWord[i] = string[indexWord[i]];
	}
}

__device__ void fowardWord(unsigned char* indexWord, int digit, char* string, int stringSize,
		unsigned long long int increment) {

	int i = digit - 1;
	while (increment > 0 && i >= 0) {
		unsigned long long int add = increment + indexWord[i];
//		printf("[%d] indexWord[i]:%d fowardWord increment:%-15llu  wordMax:%d  stringSize:%d  add:%-10llu  addstringSize:%u\n", i,  indexWord[i], increment, wordMax, stringSize, add, add % stringSize);
		indexWord[i] = add % stringSize;
		increment = add / stringSize;
		i -= 1;
	}
}

__global__ void crack(char* string, int *digit, uint *h1, uint *h2, uint *h3, uint *h4,
		unsigned long long int* increments, int *hasFound, unsigned char* answer, unsigned char* checkWord) {
	// Get Thread Index
	unsigned int idx = threadIdx.x + blockIdx.x * blockDim.x;
	unsigned int offset = blockDim.x * gridDim.x;
	unsigned long long int increment;

	// Declare
	unsigned char* indexWord = new unsigned char[*digit + 1];
	unsigned char* bruteWord = new unsigned char[*digit + 1];
	uint v1, v2, v3, v4;
	int loop = 0;
	int deviceLoopMax = DEVICE_LOOP;

	// Initialization
	increment = increments[idx];
	increments[idx] += DEVICE_LOOP;

	fillZero(indexWord, *digit);
	fillZero(bruteWord, *digit);

	fowardWord(indexWord, *digit, string, strsize(string), increment + idx);
//	makeBruteWord(indexWord, bruteWord, string, *digit);
//	copyWord(bruteWord, checkWord, *digit);

	while (global_success == 0 && loop <= deviceLoopMax) {

		makeBruteWord(indexWord, bruteWord, string, *digit);
//		if(idx == 0){
//			printf("[%u]DEVICE bruteWord:%s increment:%llu offset:%u\n", idx, bruteWord, increment, offset);
//		}
//		if (idx == 0 && increment % 5000000 == 0 && loop == deviceLoopMax - 1) {
//			printf("[%u]DEVICE bruteWord:%s increment:%llu\n", idx, bruteWord, increment);
//		}

		if (idx == 0 && increment % 5000 == 0 && loop == deviceLoopMax - 1) {
			copyWord(bruteWord, checkWord, *digit);
		}

//		bruteWord[0] = 'a';
//		bruteWord[1] = 'b';
//		bruteWord[2] = '1';
//		bruteWord[3] = '4';
//		bruteWord[4] = '%';
//		bruteWord[5] = 'P';
//		bruteWord[6] = '\0';

		md5_vfy(bruteWord, *digit, &v1, &v2, &v3, &v4);
		if (*h1 == v1 && *h2 == v2 && *h3 == v3 && *h4 == v4 && global_success == 0) {
			*hasFound = 1;
			global_success = 1;
			copyWord(bruteWord, answer, *digit);

//			printf("DEVICE Found:%s bruteWord:%s\n", answer, bruteWord);
//			printf("DEVICE %p %p %p %p\n", h1, h2, h3, h4);
//			printf("DEVICE h%u %u %u %u\n", *h1, *h2, *h3, *h4);
//			printf("DEVICE v%u %u %u %u\n", v1, v2, v3, v4);
			break;
		}

		fowardWord(indexWord, *digit, string, strsize(string), offset);
		loop += 1;
	}

	// Finish
	increments[idx] += offset;

	// Destory
	free(indexWord);
	free(bruteWord);
}

unsigned char* anderson_main(char* hash, int digit, const char* string, int N_BLOCK = 256, int N_THREAD = 1024,
		int display = 0) {
	int N_TOTAL = N_BLOCK * N_THREAD;

	// Declare Variables
	const unsigned long long int HOST_LOOP = pow(strlen(string), digit);
	uint h1, h2, h3, h4;
	unsigned long long int increments[N_TOTAL];
	unsigned char check[digit + 1];
	unsigned char* answer = (unsigned char*) malloc(digit + 1);
	int hasFound = 0;
	int loop = 0;
	int i;

	// Declare CUDA Variables
	unsigned char *dev_answer;
	unsigned char *dev_check;
	char *dev_string;
	int *dev_digit;
	int *dev_hasFound;
	uint *dev_h1;
	uint *dev_h2;
	uint *dev_h3;
	uint *dev_h4;
	unsigned long long int *dev_increments;

	// Hash Initialization
	md5_to_ints((unsigned char*) hash, &h1, &h2, &h3, &h4);

	// Init Increments
	for (i = 0; i < N_TOTAL; i++) {
		increments[i] = 0;
	}

	for (i = 0; i < digit; i++) {
		check[i] = 0;
	}
	check[digit] = '\0';

	// CUDA Memory Allocation
	cudaMalloc((void**) &dev_string, sizeof(char) * (strlen(string) + 1));
	cudaMalloc((void**) &dev_digit, sizeof(int));
	cudaMalloc((void**) &dev_h1, sizeof(uint));
	cudaMalloc((void**) &dev_h2, sizeof(uint));
	cudaMalloc((void**) &dev_h3, sizeof(uint));
	cudaMalloc((void**) &dev_h4, sizeof(uint));
	cudaMalloc((void**) &dev_increments, sizeof(unsigned long long int) * N_TOTAL);
	cudaMalloc((void**) &dev_hasFound, sizeof(int));
	cudaMalloc((void**) &dev_answer, sizeof(unsigned char) * digit + 1);
	cudaMalloc((void**) &dev_check, sizeof(unsigned char) * digit + 1);

	// CUDA Memory Copy
	cudaMemcpy(dev_string, string, sizeof(char) * (strlen(string) + 1), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_digit, &digit, sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_h1, &h1, sizeof(uint), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_h2, &h2, sizeof(uint), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_h3, &h3, sizeof(uint), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_h4, &h4, sizeof(uint), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_increments, &increments, sizeof(unsigned long long int) * N_TOTAL, cudaMemcpyHostToDevice);
	cudaMemcpy(dev_hasFound, &hasFound, sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_answer, &answer, sizeof(unsigned char) * (digit + 1), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_check, &check, sizeof(unsigned char) * (digit + 1), cudaMemcpyHostToDevice);

	// Crack!
	while (loop < HOST_LOOP && hasFound == 0) {
		crack<<<N_BLOCK, N_THREAD>>>(dev_string, dev_digit, dev_h1, dev_h2, dev_h3, dev_h4, dev_increments,
				dev_hasFound, dev_answer, dev_check);

		cudaMemcpy(&hasFound, dev_hasFound, sizeof(int), cudaMemcpyDeviceToHost);
		if (hasFound == 1) {
			cudaMemcpy(answer, dev_answer, sizeof(unsigned char) * (digit + 1), cudaMemcpyDeviceToHost);
			if(display == 1){
				printf("ANSWER: %s\n", answer);
			}
			break;
		}

		if (display == 1 && loop % 100 == 0) {
			cudaMemcpy(&check, dev_check, sizeof(unsigned char) * (digit + 1), cudaMemcpyDeviceToHost);
			printf("Progress: %s\n", check);
		}

		loop += 1;
	}

	// Destroy..
	cudaFree(dev_increments);
	cudaFree(dev_string);
	cudaFree(dev_digit);
	cudaFree(dev_h1);
	cudaFree(dev_h2);
	cudaFree(dev_h3);
	cudaFree(dev_h4);
	cudaFree(dev_hasFound);
	cudaFree(dev_answer);
	cudaFree(dev_check);

	free(dev_string);
	free(dev_digit);
	free(dev_h1);
	free(dev_h2);
	free(dev_h3);
	free(dev_h4);
	free(dev_hasFound);
	free(dev_answer);
	free(dev_check);
	return answer;
}

int main(int argc, char **argv) {
	if (argc < 3) {
		printf(" hash digit [num of blocks] [num of threads] [possible string]\n");
		return 1;
	}

	char* hash = argv[1];
	int digit = atoi(argv[2]);
	const char *string =
			"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!\"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~\0";
	int blocks = 512;
	int threads = 1024;
        printf("argc: %d %s \n", argc, argv[4]);
	if (argc >= 4) {
		blocks = atoi(argv[3]);
	}
	if (argc >= 5) {
		threads = atoi(argv[4]);
	}

	if (argc >= 6) {
		string = argv[5];
	}
	
	printf("hash:%s digit:%d string:%s blocks:%d threads:%d\n", hash, digit, string, blocks, threads);

	anderson_main(hash, digit, string, blocks, threads, 1);
	free(hash);
	return 1;
}

