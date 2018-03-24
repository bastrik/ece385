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
volatile unsigned int * AES_PTR = (unsigned int *) 0x00000040;

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
	printf("The given message is %s \n", msg_ascii);
 	printf("The given key is %s \n\n", key_ascii);
	int i, row, col;
	uchar input[4*4];		// 1*  4*4 8-bit
	uint state[4];			// 1*  4*1 32-bit
	uchar cipherKey[4*4];	// 1*  4*4 8-bit
	uint inputKey[4*4];		// 1*  4*1 32-bit
	uint roundKeyArr[4*11];	// 11* 4*  32-bit keys
	// column major population
	for (col = 0; col < 4; col++)
	{
		for (row = 0; row < 4; row++)
		{
			i = 4*col + row;
			input[ 4*row + col ] = charsToHex( msg_ascii[2*i], msg_ascii[2*i+1] );
			cipherKey [4*row + col] = charsToHex( key_ascii[2*i], key_ascii[2*i+1] );
		}
	}

//	printf("Initial state: \n", i+1);
//	printf("%x %x %x %x \n", input[0], input[1], input[2], input[3]);
//	printf("%x %x %x %x \n", input[4], input[5], input[6], input[7]);
//	printf("%x %x %x %x \n", input[8], input[9], input[10], input[11]);
//	printf("%x %x %x %x \n", input[12], input[13], input[14], input[15]);
//	printf("\n");

	KeyExpansion( cipherKey, roundKeyArr );
//	printf("Initial round key: \n", i+1);
//	printf("%x %x %x %x \n", roundKeyArr[0], roundKeyArr[1], roundKeyArr[2], roundKeyArr[3]);
//	printf("\n");
	AddRoundKey( input, roundKeyArr, 0 );

	for (i = 0; i < 9; i++)
	{
//		printf("At start of round %i: \n", i+1);
//		printf("%x %x %x %x \n", input[0], input[1], input[2], input[3]);
//		printf("%x %x %x %x \n", input[4], input[5], input[6], input[7]);
//		printf("%x %x %x %x \n", input[8], input[9], input[10], input[11]);
//		printf("%x %x %x %x \n", input[12], input[13], input[14], input[15]);
//		printf("\n");
		SubBytes(input);
//		printf("After sub_bytes \n");
//		printf("%x %x %x %x \n", input[0], input[1], input[2], input[3]);
//		printf("%x %x %x %x \n", input[4], input[5], input[6], input[7]);
//		printf("%x %x %x %x \n", input[8], input[9], input[10], input[11]);
//		printf("%x %x %x %x \n", input[12], input[13], input[14], input[15]);
//		printf("\n");
		ShiftRows(input);
//		printf("After shift_rows \n");
//		printf("%x %x %x %x \n", input[0], input[1], input[2], input[3]);
//		printf("%x %x %x %x \n", input[4], input[5], input[6], input[7]);
//		printf("%x %x %x %x \n", input[8], input[9], input[10], input[11]);
//		printf("%x %x %x %x \n", input[12], input[13], input[14], input[15]);
//		printf("\n");
		MixColumns(input);
//		printf("After mix_columns \n");
//		printf("%x %x %x %x \n", input[0], input[1], input[2], input[3]);
//		printf("%x %x %x %x \n", input[4], input[5], input[6], input[7]);
//		printf("%x %x %x %x \n", input[8], input[9], input[10], input[11]);
//		printf("%x %x %x %x \n", input[12], input[13], input[14], input[15]);
//		printf("\n");
		AddRoundKey( input, roundKeyArr, i+1 );
//		printf("Round key: \n", i+1);
//		printf("%x %x %x %x \n", roundKeyArr[4*(i+1)], roundKeyArr[4*(i+1)+1], roundKeyArr[4*(i+1)+2], roundKeyArr[4*(i+1)+3]);
//		printf("\n");
	}
//	printf("At start of final round: \n");
//	printf("%x %x %x %x \n", input[0], input[1], input[2], input[3]);
//	printf("%x %x %x %x \n", input[4], input[5], input[6], input[7]);
//	printf("%x %x %x %x \n", input[8], input[9], input[10], input[11]);
//	printf("%x %x %x %x \n", input[12], input[13], input[14], input[15]);
//	printf("\n");
	SubBytes(input);
//	printf("After sub_bytes \n");
//	printf("%x %x %x %x \n", input[0], input[1], input[2], input[3]);
//	printf("%x %x %x %x \n", input[4], input[5], input[6], input[7]);
//	printf("%x %x %x %x \n", input[8], input[9], input[10], input[11]);
//	printf("%x %x %x %x \n", input[12], input[13], input[14], input[15]);
//	printf("\n");
	ShiftRows(input);
//	printf("After shift_rows \n");
//	printf("%x %x %x %x \n", input[0], input[1], input[2], input[3]);
//	printf("%x %x %x %x \n", input[4], input[5], input[6], input[7]);
//	printf("%x %x %x %x \n", input[8], input[9], input[10], input[11]);
//	printf("%x %x %x %x \n", input[12], input[13], input[14], input[15]);
//	printf("\n");
	AddRoundKey( input, roundKeyArr, 10 );
//	printf("Round key: \n", i+1);
//	printf("%x %x %x %x \n", roundKeyArr[4*(9+1)], roundKeyArr[4*(9+1)+1], roundKeyArr[4*(9+1)+2], roundKeyArr[4*(9+1)+3]);
//	printf("\n");
//	printf("Final state \n");
//	printf("%x %x %x %x \n", input[0], input[1], input[2], input[3]);
//	printf("%x %x %x %x \n", input[4], input[5], input[6], input[7]);
//	printf("%x %x %x %x \n", input[8], input[9], input[10], input[11]);
//	printf("%x %x %x %x \n", input[12], input[13], input[14], input[15]);
//	printf("\n");

	for (i = 0; i < 4; ++i)
	{
		state[i] = (input[4*0 + i] << 24) | (input[4*1 + i] << 16) | 
		(input[4*2 + i] << 8) | (input[4*3 + i]);
		inputKey[i] = (cipherKey[4*0 + i] << 24) | (cipherKey[4*1 + i] << 16) | 
		(cipherKey[4*2 + i] << 8) | (cipherKey[4*3 + i]);
	}

//	printf("state is %x %x %x %x\n", state[0], state[1], state[2], state[3]);
	memcpy(msg_enc, state, sizeof(state));
	AES_PTR[4] = msg_enc[0];
	AES_PTR[5] = msg_enc[1];
	AES_PTR[6] = msg_enc[2];
	AES_PTR[7] = msg_enc[3];
	printf("msg_enc is %x %x %x %x\n", msg_enc[0], msg_enc[1], msg_enc[2], msg_enc[3]);
	memcpy(key, inputKey, sizeof(inputKey));
	AES_PTR[0] = key[0];
	AES_PTR[1] = key[1];
	AES_PTR[2] = key[2];
	AES_PTR[3] = key[3];
}

/**  
 *   Helpers
 */
void KeyExpansion(uchar* cipherKey, uint* roundKeyArr)
{
	uint temp;
	int i;
	for (i = 0; i < 4; ++i)
	{
		roundKeyArr[i] = (cipherKey[4*0 + i] << 24) | (cipherKey[4*1 + i] << 16) | 
		(cipherKey[4*2 + i] << 8) | (cipherKey[4*3 + i]);
	}
	for (i = 4; i < 44; ++i)
	{
//		printf("i = %i\n", i);
		temp = roundKeyArr[i-1];
//		printf("temp: roundKeyArr[%i] = %x\n", i-1, roundKeyArr[i-1]);
		if (i % 4 == 0)
		{
//			printf("RotWord(temp) = %x\n", RotWord(temp));
//			printf("SubWord(Rt) = %x\n", SubWord(RotWord(temp)));
			temp = SubWord(RotWord(temp)) ^ Rcon[i/4];
//			printf("newTemp = %x\n", temp);
		}
//		printf("roundKeyArr[%i] = %x\n", i-4, roundKeyArr[i-4]);
		roundKeyArr[i] = roundKeyArr[i-4] ^ temp;
//		printf("Result: roundKeyArr[%i] = %x\n\n", i, roundKeyArr[i]);
	}
}
uint RotWord(uint word)
{
	uchar temp[4] = {
		word >> 24,
		word >> 16,
		word >> 8,
		word
	};	
	return (temp[1] << 24) | (temp[2] << 16) | (temp[3] << 8) | temp[0];
}
void SubBytes(uchar* input)
{
	int i;
	for (i = 0; i < 16; i++)
	{
		uint index1 = (input[i] >> 4) & 0xf;
		uint index2 = input[i] & 0xf;
		input[i] = aes_sbox[index1*16 + index2];
	}
}
uint SubWord(uint word)
{
	uchar temp[4] = {
		word >> 24,
		word >> 16,
		word >> 8,
		word
	};
	int i;
	for (i = 0; i < 4; i++)
	{
		uint index1 = (temp[i] >> 4) & 0xf;
		uint index2 = temp[i] & 0xf;
		temp[i] = aes_sbox[index1*16 + index2];
	}
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
	uchar temp[16];

	for (i = 0; i < 4; i++)
	{
		temp[i] = (gf_mul[input[i]][0]) ^ (gf_mul[input[i+4]][1]) ^ input[i+8] ^ input[i+12];
		temp[i+4] = input[i] ^ (gf_mul[input[i+4]][0]) ^ (gf_mul[input[i+8]][1]) ^ input[i+12];
		temp[i+8] = input[i] ^ input[i+4] ^ (gf_mul[input[i+8]][0]) ^ (gf_mul[input[i+12]][1]);
		temp[i+12] = (gf_mul[input[i]][1]) ^ input[i+4] ^ input[i+8] ^ (gf_mul[input[i+12]][0]);
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
		input[i+8]  = input[i+8]  ^ (roundKeyArr[4*round + i] >> 8);
		input[i+12] = input[i+12] ^ (roundKeyArr[4*round + i]);
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
			msg_enc[0] = AES_PTR[4];
			msg_enc[1] = AES_PTR[5];
			msg_enc[2] = AES_PTR[6];
			msg_enc[3] = AES_PTR[7];
			printf("\nEncrypted message is: \n");
			for(i = 0; i < 4; i++){
				printf("%08x", msg_enc[i]);
			}
			printf("\n");
//			printf("The key is %08x %08x %08x %08x\n", key[0], key[1], key[2], key[3]);
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
