// Cracking MD5 with Nvidia GPU
// @Developer : Anderson Jo
// @email: a141890@gmail.com
// @website: http://andersonjo.github.io
// @copyrights: Use this library as you wish provided that
//              it is identified as "Made By Anderson Jo".
//              Do not remove developer name, email, website, and copyright.

#include <stdio.h>
#include <stdlib.h>
#include "md5.cu"
#define N (1024*33)

#define MAX_BRUTE_STRING_LENGTH 14
#define MD5_HASH_LENGTH 32

//Performance:
#define BLOCKS 65535
#define THREADS_PER_BLOCK 1024

__device__ void initWord(unsigned char* word, int wordMax, char* string, int stringSize, int tid) {
	int t = tid;
	int i;
	printf("initWord - wordMax:%d, \n", wordMax);
	for (i = 0; i < wordMax; i++) {
		word[i] = 0;
	}

	for (i = 0; i < wordMax; i++) {
		word[i]

	}

}

__global__ void searchHashWord(char* string, int* stringLength, int* wordMax, uint* h1, uint* h2, uint* h3, uint* h4) {
	uint v1, v2, v3, v4;

	printf("searchHashWord - stringLength:%d \n", stringLength);
	int tid = threadIdx.x + blockIdx.x * blockDim.x;

	unsigned char* word = new unsigned char[*wordMax];

	initWord(word, *wordMax, string, *stringLength, tid);

	if (tid >= (1024 - 1)) {
		printf("thread ID: %u\n", tid);
		printf("string %s %d\n", string);
	}

//	unsigned char* x = (unsigned char*) "ab14%P";
//	unsigned char* word[6];
//	md5_vfy(x, 6, &v1, &v2, &v3, &v4);

//	printf("%p %p %p %p\n", h1, h2, h3, h4);
//	printf("h%u %u %u %u\n", *h1, *h2, *h3, *h4);
//	printf("v%u %u %u %u\n", v1, v2, v3, v4);
}

int main(int argc, char **argv) {
	const char* string =
			"!\"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~";
	const int stringLength = strlen(string);
	const int wordMax = 30;

	unsigned char hash[MD5_HASH_LENGTH];
	memcpy(hash, "fe5f329d483283b7d03b03fc1e48e90c", MD5_HASH_LENGTH);

	// Get Unsigned Integers of Hash Key
	uint h1, h2, h3, h4;
	uint* dev_h1;
	uint* dev_h2;
	uint* dev_h3;
	uint* dev_h4;

	char* dev_string;
	int* dev_stringLength;
	int* dev_wordMax;

	md5_to_ints(hash, &h1, &h2, &h3, &h4);
	printf("%u %u %u %u\n", h1, h2, h3, h4);

	cudaMalloc((void**) &dev_h1, sizeof(uint));
	cudaMalloc((void**) &dev_h2, sizeof(uint));
	cudaMalloc((void**) &dev_h3, sizeof(uint));
	cudaMalloc((void**) &dev_h4, sizeof(uint));
	cudaMalloc((void**) &dev_string, strlen(string));
	cudaMalloc((void**) &dev_stringLength, sizeof(int));
	cudaMalloc((void**) &dev_wordMax, sizeof(int));

	cudaMemcpy(dev_h1, &h1, 1 * sizeof(uint), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_h2, &h2, 1 * sizeof(uint), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_h3, &h3, 1 * sizeof(uint), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_h4, &h4, 1 * sizeof(uint), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_string, string, strlen(string), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_stringLength, &stringLength, sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dev_wordMax, &wordMax, sizeof(int), cudaMemcpyHostToDevice);

	printf("%p %p %p %p\n", dev_h1, dev_h2, dev_h3, dev_h4);
	searchHashWord<<<1, 1>>>(dev_string, dev_stringLength, dev_wordMax, dev_h1, dev_h2, dev_h3, dev_h4);

	cudaFree(dev_h1);
	cudaFree(dev_h2);
	cudaFree(dev_h3);
	cudaFree(dev_h4);
	cudaFree(dev_string);
	cudaFree(dev_stringLength);
	cudaFree(dev_wordMax);
}

