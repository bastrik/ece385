/************************************************************************
Lab 9 Nios Software

Dong Kai Wang, Fall 2017
Christine Chen, Fall 2013

For use with ECE 385 Experiment 9
University of Illinois ECE Department
************************************************************************/

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <string.h>
#include "aes.h"

// Pointer to base address of AES module, make sure it matches Qsys
volatile unsigned int * AES_PTR = (unsigned int *) 0x00000100;

// Execution mode: 0 for testing, 1 for benchmarking
int run_mode = 0;

/** charToHex
 *  Convert a single character to the 4-bit value it represents.
 *  
 *  Input: a character c (e.g. 'A')
 *  Output: converted 4-bit value (e.g. 0xA)
 */
char charToHex(char c)
{
	char hex = c;

	if (hex >= '0' && hex <= '9')
		hex -= '0';
	else if (hex >= 'A' && hex <= 'F')
	{
		hex -= 'A';
		hex += 10;
	}
	else if (hex >= 'a' && hex <= 'f')
	{
		hex -= 'a';
		hex += 10;
	}
	return hex;
}

/** charsToHex
 *  Convert two characters to byte value it represents.
 *  Inputs must be 0-9, A-F, or a-f.
 *  
 *  Input: two characters c1 and c2 (e.g. 'A' and '7')
 *  Output: converted byte value (e.g. 0xA7)
 */
char charsToHex(char c1, char c2)
{
	char hex1 = charToHex(c1);
	char hex2 = charToHex(c2);
	return (hex1 << 4) + hex2;
}

/** encrypt
 *  Top level AES encryption wrapper.
 *
 *  Input: msg_ascii - Pointer to 32x 8-bit char array that contains the input message in ASCII format
 *         key_ascii - Pointer to 32x 8-bit char array that contains the input key in ASCII format
 *  Output:  msg_enc - Pointer to 4x 32-bit int array that contains the encrypted message
 *               key - Pointer to 4x 32-bit int array that contains the input key
 */
void encrypt(unsigned char * msg_ascii, unsigned char * key_ascii, unsigned int * msg_enc, unsigned int * key)
{
	int i, row, col;
	uchar input[4*4];		// 1*  4*4 8-bit
	uint state[4];			// 1*  4*1 32-bit
	uchar cipherKey[4*4];	// 1*  4*4 8-bit
	uint roundKeyArr[4*11];	// 11* 4*  32-bit keys
	uint word[4];			// 4*  32-bit
	// column major population
	for (col = 0; col < 4; col++)
	{
		for (row = 0; row < 4; row++)
		{
			i = 4*col + row;
			input[ 4*row + col ] = charsToHex( msg_ascii[i], msg_ascii[i+1] );
			cipherKey [4*row + col] = charsToHex( key_ascii[i], key_ascii[i+1] );
		}
	}

	KeyExpansion( &cipherKey, &roundKeyArr );
	AddRoundKey( &input, &roundKeyArr, 0 );

	for (i = 0; i < 9; i++)
	{
		SubBytes(&input);
		ShiftRows(&input);
		MixColumns(&input);
		AddRoundKey( &input, &roundKeyArr, i+1 );
	}
	SubBytes(&input);
	ShiftRows(&input);
	AddRoundKey( &input, &roundKeyArr, 10 );

	for (i = 0; i < 4; ++i)
		state[i] = (input[4*i] << 24) | (input[4*i +1] << 16) | 
		(input[4*i +2] << 8) | (input[4*i +3]);

	*msg_enc = state;
}

/**  
 *   Helpers
 */
void KeyExpansion(uchar* cipherKey, uint* roundKeyArr)
{
	uint temp;
	int i = 0;
	for (i = 0; i < 4; ++i)
	{
		roundKeyArr[i] = (cipherKey[4*i] << 24) | (cipherKey[4*i +1] << 16) | 
		(cipherKey[4*i +2] << 8) | (cipherKey[4*i +3]);
	}
	for (i = 4; i < 44; ++i)
	{
		temp = roundKeyArr[i-1];
		if (i % 4 == 0)
		{
			temp = SubWord(rotWord(temp)) ^ Rcon[i/4 - 1];
		}
		roundKeyArr[i] = roundKeyArr[i-4] ^ temp;
	}
}
uint rotWord(uint word)
{
	return word;	// TODO
}
void SubBytes(uchar* input)
{
	int i;
	for (i = 0; i < strlen(input); i++)
	{
		uint index1 = (input[i] >> 4) & 0xf;
		uint index2 = input[i] & 0xf;
		input[i] = aes_sbox[index1*16 + index2];
	}
}
uint SubWord(uint* word)
{
	uchar temp[4] = {
		*word >> 24 & 0xf,
		*word >> 16 & 0xf,
		*word >> 8  & 0xf,
		*word       & 0xf
	};
	SubBytes(&temp);
	return (temp[0] << 24) | (temp[1] << 16) | (temp[2] << 8) | temp[3];
}
void ShiftRows(uchar* input)
{
	uchar temp;

	temp = input[4];
	input[4] = input[5];
	input[5] = input[6];
	input[6] = input[7];
	input[7] = temp;

	temp = input[8];
	input[8] = input[10];
	input[10] = temp;
	temp = input[9];
	input[9] = input[11];
	input[11] = temp;

	temp = input[15];
	input[15] = input[14];
	input[14] = input[13];
	input[13] = input[12];
	input[12] = temp;
}
void MixColumns(uchar* input)
{
	int i;
	uchar b;
	uchar temp[16];

	for (i = 0; i < 4; i++)
	{
		// TODO
	}

	memcpy(input, temp, sizeof(temp));
}
void AddRoundKey( uchar* input, uint* roundKeyArr, int round )
{
	int i;
	for (i = 0; i < 4; ++i)
	{
		input[i]    = input[i]    ^ (roundKeyArr[4*round + i] >> 24);
		input[i+4]  = input[i+4]  ^ (roundKeyArr[4*round + i] >> 16);
		input[i+8]  = input[i+7]  ^ (roundKeyArr[4*round + i] >> 8);
		input[i+12] = input[i+11] ^ (roundKeyArr[4*round + i]);
	}
}
/** decrypt
 *  Perform AES decryption in hardware.
 *
 *  Input:  msg_enc - Pointer to 4x 32-bit int array that contains the encrypted message
 *              key - Pointer to 4x 32-bit int array that contains the input key
 *  Output: msg_dec - Pointer to 4x 32-bit int array that contains the decrypted message
 */
void decrypt(unsigned int * msg_enc, unsigned int * msg_dec, unsigned int * key)
{
	// Implement this function
}

/** main
 *  Allows the user to enter the message, key, and select execution mode
 *
 */
int main()
{
	// Input Message and Key as 32x 8-bit ASCII Characters ([33] is for NULL terminator)
	unsigned char msg_ascii[33];
	unsigned char key_ascii[33];
	// Key, Encrypted Message, and Decrypted Message in 4x 32-bit Format to facilitate Read/Write to Hardware
	unsigned int key[4];
	unsigned int msg_enc[4];
	unsigned int msg_dec[4];

	printf("Select execution mode: 0 for testing, 1 for benchmarking: ");
	scanf("%d", &run_mode);

	if (run_mode == 0) {
		// Continuously Perform Encryption and Decryption
		while (1) {
			int i = 0;
			printf("\nEnter Message:\n");
			scanf("%s", msg_ascii);
			printf("\n");
			printf("\nEnter Key:\n");
			scanf("%s", key_ascii);
			printf("\n");
			encrypt(msg_ascii, key_ascii, msg_enc, key);
			printf("\nEncrpted message is: \n");
			for(i = 0; i < 4; i++){
				printf("%08x", msg_enc[i]);
			}
			printf("\n");
			decrypt(msg_enc, msg_dec, key);
			printf("\nDecrypted message is: \n");
			for(i = 0; i < 4; i++){
				printf("%08x", msg_dec[i]);
			}
			printf("\n");
		}
	}
	else {
		// Run the Benchmark
		int i = 0;
		int size_KB = 2;
		// Choose a random Plaintext and Key
		for (i = 0; i < 32; i++) {
			msg_ascii[i] = 'a';
			key_ascii[i] = 'b';
		}
		// Run Encryption
		clock_t begin = clock();
		for (i = 0; i < size_KB * 64; i++)
			encrypt(msg_ascii, key_ascii, msg_enc, key);
		clock_t end = clock();
		double time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
		double speed = size_KB / time_spent;
		printf("Software Encryption Speed: %f KB/s \n", speed);
		// Run Decryption
		begin = clock();
		for (i = 0; i < size_KB * 64; i++)
			decrypt(msg_enc, msg_dec, key);
		end = clock();
		time_spent = (double)(end - begin) / CLOCKS_PER_SEC;
		speed = size_KB / time_spent;
		printf("Hardware Encryption Speed: %f KB/s \n", speed);
	}
	return 0;
}
