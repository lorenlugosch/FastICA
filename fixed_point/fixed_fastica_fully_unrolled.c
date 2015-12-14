#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include "fixed_fastica.h"

#define MAX_NEGATIVE_Q6_10 -32768
#define MAX_NEGATIVE_Q11_21 -2147483648
#define MAX_POSITIVE_Q11_21 2147483647
#define MAX_POSITIVE_Q21_43 9223372036854775807

Q11_21 multiply_Q6_10_by_Q6_10(Q6_10 a, Q6_10 b) {
	if ((a == b) && (a == MAX_NEGATIVE_Q6_10)) { return MAX_POSITIVE_Q11_21; }
	Q11_21 cc = (Q11_21)a * (Q11_21)b * 2;

	return cc;
}

Q21_43 multiply_Q11_21_by_Q11_21(Q11_21 a, Q11_21 b) {
	if ((a == b) && (a == MAX_NEGATIVE_Q11_21)) { return MAX_POSITIVE_Q21_43; }
	Q21_43 cc = (Q21_43)a * (Q21_43)b * 2;

	return cc;
}

// #define multiply_Q6_10_by_Q6_10(a, b) ( (a == b) && (a == MAX_NEGATIVE_Q6_10) ? MAX_POSITIVE_Q11_21 : (Q11_21)a * (Q11_21)b * 2 )
// #define multiply_Q11_21_by_Q11_21(a, b) ( (a == b) && (a == MAX_NEGATIVE_Q11_21) ? MAX_POSITIVE_Q21_43 : (Q21_43)a * (Q21_43)b * 2 )

Q21_43 sum_2;
Q11_21 w_rnorm;
Q11_21 dot_product;

/* reciprocal square root (piecewise linear approximation) */
Q11_21 rsqrt(Q21_43 input) {
	Q11_21 a;
	Q21_43 b;

	if ((input > 0) && (input < 175921860444160)) 						{a = -57030; b = 5852040687674;}
	else if ((input >= 175921860444160) && (input < 351843720888320)) 		{a = -6694; b = 2474340967147;}
	else if ((input >= 351843720888320) && (input < 659706976665600)) 		{a = -2498; b = 1777690399788;}
	
	else if ((input >= 659706976665600) && (input < 1319413953331200)) 		{a = -918; b = 1275433488220;}
	else if ((input >= 1319413953331200) && (input < 2199023255552000)) 		{a = -379; b = 945579999887;}
	else if ((input >= 2199023255552000) && (input < 4398046511104000)) 	{a = -150; b = 698409785963;}
	
	// input won't fit into Q11.21- scale input and make "a" bigger to compensate
	else if ((input >= 4398046511104000) && (input < 8796093022208000))		{input = input >> 3; a = -426; b = 493460818545;}
	else if ((input >= 8796093022208000)) 	{input = input >> 3; a = -150; b = 349204892981;}

	return (Q11_21)((multiply_Q11_21_by_Q11_21((Q11_21)(input >> 22),a) + b) >> 22);
}

/* Piecewise linear approximation of 
hyperbolic tangent. */
Q6_10 linear_tanh(Q11_21 input) {
	Q11_21 a;
	Q21_43 b;

	if (input < -6291456) 							{a = 1536; b = -8796093022208;}
	else if ((input >= -6291456) && (input < -4194304)) 	{a = 61440; b = -7971899106027;}
	else if ((input >= -4194304) && (input < -3145728)) 	{a = 243199; b = -6597069766656;}
	else if ((input >= -3145728) && (input < -2097152)) 	{a = 596479; b = -4398046511104;}
	else if ((input >= -2097152) && (input < -1048576)) 	{a = 1243647; b = -1649267441664;}
	else if ((input >= -1048576) && (input < 0)) 	{a = 1998335; b = 0;}
	else if ((input >= 0) && (input < 1048576)) 	{a = 1998335; b = 0;}
	else if ((input >= 1048576) && (input < 2097152))		{a = 1243647; b = 1649267441664;}
	else if ((input >= 2097152) && (input < 3145728)) 	{a = 596479; b = 4398046511104;}
	else if ((input >= 3145728) && (input < 4194304)) 	{a = 243199; b = 6597069766656;}
	else if ((input >= 4194304) && (input < 6291456)) 		{a = 61440; b = 7971899106027;}
	else if (input > 6291456) 						{a = 1536; b = 8796093022208;}

	return (multiply_Q11_21_by_Q11_21(a, input) + b) >> 33;
}

/* Piecewise linear approximation of 
hyperbolic secant squared (derivative of tanh). */
Q11_21 linear_sech2(Q11_21 input) {
	Q11_21 a;
	Q21_43 b;

	if (input < -6291456) 									{a = 8115; b = 157450065097;}
	else if ((input >= -6291456) && (input < -4194304)) 	{a = 118313; b = 1513807609121;}
	else if ((input >= -4194304) && (input < -3145728)) 	{a = 449105; b = 4332955422739;}
	else if ((input >= -3145728) && (input < -2097152)) 	{a = 988194 ; b = 7708016315360;}
	else if ((input >= -2097152) && (input < -1048576)) 	{a = 1552234; b = 10152450566232;}
	else if ((input >= -1048576) && (input < -419430))		{a = 1255513; b = 9603574361646;}
	else if ((input >= -419430) && (input < 0)) 			{a = 450119; b = 8867341375687;}
	else if ((input >= 0) && (input < 419430)) 				{a = -450119; b = 8867341375687;}
	else if ((input >= 419430) && (input < 1048576)) 		{a = -1255513; b = 9603574361646;}
	else if ((input >= 1048576) && (input < 2097152))		{a = -1552234; b = 10152450566232;}
	else if ((input >= 2097152) && (input < 3145728)) 		{a = -988194; b = 7708016315360;}
	else if ((input >= 3145728) && (input < 4194304)) 		{a = -449105; b = 4332955422739;}
	else if ((input >= 4194304) && (input < 6291456)) 		{a = -118313; b = 1513807609121;}
	else if (input > 6291456) 								{a = -8115; b = 157450065097;}

	return (multiply_Q11_21_by_Q11_21(a, input) + b) >> 22;
}

/*
Main computation.
Finds one of the vectors of the unmixing matrix.
*/
void fastica() {
	int n,t;
	dot_product = 0; // not converged

	/* rotate, normalize, and repeat */
	while(fabs(fabs(dot_product)-2097152) > EPSILON) {
		/* update w */
		w_Q6_10[0] = w_next_Q6_10[0];
		w_Q6_10[1] = w_next_Q6_10[1];
		
		/* rotate */
		product_1[0] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][0]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][0]);
		product_1[1] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][1]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][1]);
		product_1[2] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][2]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][2]);
		product_1[3] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][3]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][3]);
		product_1[4] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][4]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][4]);
		product_1[5] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][5]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][5]);
		product_1[6] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][6]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][6]);
		product_1[7] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][7]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][7]);
		product_1[8] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][8]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][8]);
		product_1[9] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][9]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][9]);
		
		product_1[10] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][10]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][10]);
		product_1[11] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][11]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][11]);
		product_1[12] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][12]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][12]);
		product_1[13] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][13]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][13]);
		product_1[14] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][14]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][14]);
		product_1[15] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][15]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][15]);
		product_1[16] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][16]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][16]);
		product_1[17] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][17]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][17]);
		product_1[18] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][18]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][18]);
		product_1[19] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][19]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][19]);
		
		product_1[20] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][20]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][20]);
		product_1[21] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][21]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][21]);
		product_1[22] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][22]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][22]);
		product_1[23] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][23]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][23]);
		product_1[24] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][24]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][24]);
		product_1[25] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][25]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][25]);
		product_1[26] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][26]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][26]);
		product_1[27] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][27]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][27]);
		product_1[28] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][28]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][28]);
		product_1[29] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][29]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][29]);
		
		product_1[30] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][30]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][30]);
		product_1[31] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][31]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][31]);
		product_1[32] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][32]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][32]);
		product_1[33] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][33]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][33]);
		product_1[34] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][34]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][34]);
		product_1[35] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][35]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][35]);
		product_1[36] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][36]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][36]);
		product_1[37] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][37]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][37]);
		product_1[38] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][38]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][38]);
		product_1[39] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][39]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][39]);
		
		product_1[40] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][40]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][40]);
		product_1[41] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][41]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][41]);
		product_1[42] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][42]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][42]);
		product_1[43] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][43]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][43]);
		product_1[44] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][44]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][44]);
		product_1[45] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][45]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][45]);
		product_1[46] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][46]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][46]);
		product_1[47] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][47]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][47]);
		product_1[48] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][48]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][48]);
		product_1[49] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][49]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][49]);
		
		product_1[50] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][50]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][50]);
		product_1[51] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][51]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][51]);
		product_1[52] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][52]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][52]);
		product_1[53] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][53]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][53]);
		product_1[54] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][54]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][54]);
		product_1[55] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][55]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][55]);
		product_1[56] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][56]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][56]);
		product_1[57] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][57]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][57]);
		product_1[58] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][58]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][58]);
		product_1[59] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][59]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][59]);

		product_1[60] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][60]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][60]);
		product_1[61] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][61]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][61]);
		product_1[62] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][62]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][62]);
		product_1[63] = multiply_Q6_10_by_Q6_10(w_Q6_10[0],whitened_signals[0][63]) + multiply_Q6_10_by_Q6_10(w_Q6_10[1],whitened_signals[1][63]);
		
		product_2[0] = 0; 
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][0], linear_tanh(product_1[0]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][1], linear_tanh(product_1[1]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][2], linear_tanh(product_1[2]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][3], linear_tanh(product_1[3]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][4], linear_tanh(product_1[4]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][5], linear_tanh(product_1[5]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][6], linear_tanh(product_1[6]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][7], linear_tanh(product_1[7]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][8], linear_tanh(product_1[8]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][9], linear_tanh(product_1[9]));

		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][10], linear_tanh(product_1[10]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][11], linear_tanh(product_1[11]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][12], linear_tanh(product_1[12]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][13], linear_tanh(product_1[13]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][14], linear_tanh(product_1[14]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][15], linear_tanh(product_1[15]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][16], linear_tanh(product_1[16]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][17], linear_tanh(product_1[17]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][18], linear_tanh(product_1[18]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][19], linear_tanh(product_1[19]));

		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][20], linear_tanh(product_1[20]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][21], linear_tanh(product_1[21]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][22], linear_tanh(product_1[22]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][23], linear_tanh(product_1[23]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][24], linear_tanh(product_1[24]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][25], linear_tanh(product_1[25]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][26], linear_tanh(product_1[26]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][27], linear_tanh(product_1[27]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][28], linear_tanh(product_1[28]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][29], linear_tanh(product_1[29]));

		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][30], linear_tanh(product_1[30]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][31], linear_tanh(product_1[31]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][32], linear_tanh(product_1[32]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][33], linear_tanh(product_1[33]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][34], linear_tanh(product_1[34]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][35], linear_tanh(product_1[35]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][36], linear_tanh(product_1[36]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][37], linear_tanh(product_1[37]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][38], linear_tanh(product_1[38]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][39], linear_tanh(product_1[39]));

		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][40], linear_tanh(product_1[40]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][41], linear_tanh(product_1[41]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][42], linear_tanh(product_1[42]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][43], linear_tanh(product_1[43]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][44], linear_tanh(product_1[44]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][45], linear_tanh(product_1[45]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][46], linear_tanh(product_1[46]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][47], linear_tanh(product_1[47]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][48], linear_tanh(product_1[48]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][49], linear_tanh(product_1[49]));

		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][50], linear_tanh(product_1[50]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][51], linear_tanh(product_1[51]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][52], linear_tanh(product_1[52]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][53], linear_tanh(product_1[53]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][54], linear_tanh(product_1[54]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][55], linear_tanh(product_1[55]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][56], linear_tanh(product_1[56]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][57], linear_tanh(product_1[57]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][58], linear_tanh(product_1[58]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][59], linear_tanh(product_1[59]));

		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][60], linear_tanh(product_1[60]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][61], linear_tanh(product_1[61]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][62], linear_tanh(product_1[62]));
		product_2[0] += multiply_Q6_10_by_Q6_10(whitened_signals[0][63], linear_tanh(product_1[63]));

		product_2[1] = 0; 
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][0], linear_tanh(product_1[0]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][1], linear_tanh(product_1[1]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][2], linear_tanh(product_1[2]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][3], linear_tanh(product_1[3]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][4], linear_tanh(product_1[4]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][5], linear_tanh(product_1[5]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][6], linear_tanh(product_1[6]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][7], linear_tanh(product_1[7]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][8], linear_tanh(product_1[8]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][9], linear_tanh(product_1[9]));

		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][10], linear_tanh(product_1[10]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][11], linear_tanh(product_1[11]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][12], linear_tanh(product_1[12]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][13], linear_tanh(product_1[13]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][14], linear_tanh(product_1[14]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][15], linear_tanh(product_1[15]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][16], linear_tanh(product_1[16]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][17], linear_tanh(product_1[17]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][18], linear_tanh(product_1[18]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][19], linear_tanh(product_1[19]));

		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][20], linear_tanh(product_1[20]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][21], linear_tanh(product_1[21]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][22], linear_tanh(product_1[22]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][23], linear_tanh(product_1[23]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][24], linear_tanh(product_1[24]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][25], linear_tanh(product_1[25]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][26], linear_tanh(product_1[26]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][27], linear_tanh(product_1[27]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][28], linear_tanh(product_1[28]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][29], linear_tanh(product_1[29]));

		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][30], linear_tanh(product_1[30]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][31], linear_tanh(product_1[31]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][32], linear_tanh(product_1[32]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][33], linear_tanh(product_1[33]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][34], linear_tanh(product_1[34]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][35], linear_tanh(product_1[35]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][36], linear_tanh(product_1[36]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][37], linear_tanh(product_1[37]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][38], linear_tanh(product_1[38]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][39], linear_tanh(product_1[39]));

		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][40], linear_tanh(product_1[40]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][41], linear_tanh(product_1[41]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][42], linear_tanh(product_1[42]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][43], linear_tanh(product_1[43]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][44], linear_tanh(product_1[44]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][45], linear_tanh(product_1[45]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][46], linear_tanh(product_1[46]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][47], linear_tanh(product_1[47]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][48], linear_tanh(product_1[48]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][49], linear_tanh(product_1[49]));

		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][50], linear_tanh(product_1[50]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][51], linear_tanh(product_1[51]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][52], linear_tanh(product_1[52]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][53], linear_tanh(product_1[53]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][54], linear_tanh(product_1[54]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][55], linear_tanh(product_1[55]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][56], linear_tanh(product_1[56]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][57], linear_tanh(product_1[57]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][58], linear_tanh(product_1[58]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][59], linear_tanh(product_1[59]));

		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][60], linear_tanh(product_1[60]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][61], linear_tanh(product_1[61]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][62], linear_tanh(product_1[62]));
		product_2[1] += multiply_Q6_10_by_Q6_10(whitened_signals[1][63], linear_tanh(product_1[63]));

		sum_1 = 0;
		sum_1 += linear_sech2(product_1[0]);
		sum_1 += linear_sech2(product_1[1]);
		sum_1 += linear_sech2(product_1[2]);
		sum_1 += linear_sech2(product_1[3]);
		sum_1 += linear_sech2(product_1[4]);
		sum_1 += linear_sech2(product_1[5]);
		sum_1 += linear_sech2(product_1[6]);
		sum_1 += linear_sech2(product_1[7]);
		sum_1 += linear_sech2(product_1[8]);
		sum_1 += linear_sech2(product_1[9]);
		sum_1 += linear_sech2(product_1[10]);
		sum_1 += linear_sech2(product_1[11]);
		sum_1 += linear_sech2(product_1[12]);
		sum_1 += linear_sech2(product_1[13]);
		sum_1 += linear_sech2(product_1[14]);
		sum_1 += linear_sech2(product_1[15]);
		sum_1 += linear_sech2(product_1[16]);
		sum_1 += linear_sech2(product_1[17]);
		sum_1 += linear_sech2(product_1[18]);
		sum_1 += linear_sech2(product_1[19]);
		sum_1 += linear_sech2(product_1[20]);
		sum_1 += linear_sech2(product_1[21]);
		sum_1 += linear_sech2(product_1[22]);
		sum_1 += linear_sech2(product_1[23]);
		sum_1 += linear_sech2(product_1[24]);
		sum_1 += linear_sech2(product_1[25]);
		sum_1 += linear_sech2(product_1[26]);
		sum_1 += linear_sech2(product_1[27]);
		sum_1 += linear_sech2(product_1[28]);
		sum_1 += linear_sech2(product_1[29]);
		sum_1 += linear_sech2(product_1[30]);
		sum_1 += linear_sech2(product_1[31]);
		sum_1 += linear_sech2(product_1[32]);
		sum_1 += linear_sech2(product_1[33]);
		sum_1 += linear_sech2(product_1[34]);
		sum_1 += linear_sech2(product_1[35]);
		sum_1 += linear_sech2(product_1[36]);
		sum_1 += linear_sech2(product_1[37]);
		sum_1 += linear_sech2(product_1[38]);
		sum_1 += linear_sech2(product_1[39]);
		sum_1 += linear_sech2(product_1[40]);
		sum_1 += linear_sech2(product_1[41]);
		sum_1 += linear_sech2(product_1[42]);
		sum_1 += linear_sech2(product_1[43]);
		sum_1 += linear_sech2(product_1[44]);
		sum_1 += linear_sech2(product_1[45]);
		sum_1 += linear_sech2(product_1[46]);
		sum_1 += linear_sech2(product_1[47]);
		sum_1 += linear_sech2(product_1[48]);
		sum_1 += linear_sech2(product_1[49]);
		sum_1 += linear_sech2(product_1[50]);
		sum_1 += linear_sech2(product_1[51]);
		sum_1 += linear_sech2(product_1[52]);
		sum_1 += linear_sech2(product_1[53]);
		sum_1 += linear_sech2(product_1[54]);
		sum_1 += linear_sech2(product_1[55]);
		sum_1 += linear_sech2(product_1[56]);
		sum_1 += linear_sech2(product_1[57]);
		sum_1 += linear_sech2(product_1[58]);
		sum_1 += linear_sech2(product_1[59]);
		sum_1 += linear_sech2(product_1[60]);
		sum_1 += linear_sech2(product_1[61]);
		sum_1 += linear_sech2(product_1[62]);
		sum_1 += linear_sech2(product_1[63]);

		// divide sum_1 by 2 (shift by 12 instead of 11), multiply w by 2 (shift by 1)
		product_3[0] = multiply_Q6_10_by_Q6_10(w_Q6_10[0] << 1, (Q6_10)(sum_1 >> 12));
		product_3[1] = multiply_Q6_10_by_Q6_10(w_Q6_10[1] << 1, (Q6_10)(sum_1 >> 12));

		w_next_Q11_21[0] = (product_2[0] - product_3[0]) >> 1;
		w_next_Q6_10[0] = (Q6_10)(w_next_Q11_21[0] >> 11);
		w_next_Q11_21[1] = (product_2[1] - product_3[1]) >> 1;
		w_next_Q6_10[1] = (Q6_10)(w_next_Q11_21[1] >> 11);

		/* normalize */
		sum_2 = 0;
		sum_2 += ((Q21_43)(multiply_Q6_10_by_Q6_10(w_next_Q6_10[0], w_next_Q6_10[0])))<<22;
		sum_2 += ((Q21_43)(multiply_Q6_10_by_Q6_10(w_next_Q6_10[1], w_next_Q6_10[1])))<<22;

		w_rnorm = rsqrt(sum_2);
		w_next_Q21_43[0] = multiply_Q11_21_by_Q11_21(w_rnorm, w_next_Q11_21[0]);
		w_next_Q6_10[0] = (Q6_10)(w_next_Q21_43[0] >> 33);
		w_next_Q21_43[1] = multiply_Q11_21_by_Q11_21(w_rnorm, w_next_Q11_21[1]);
		w_next_Q6_10[1] = (Q6_10)(w_next_Q21_43[1] >> 33);

		/* calculate convergence */ 
		dot_product = 0;
		dot_product += multiply_Q6_10_by_Q6_10(w_Q6_10[0], w_next_Q6_10[0]);
		dot_product += multiply_Q6_10_by_Q6_10(w_Q6_10[1], w_next_Q6_10[1]);
	}
}

int main() {
	/* find unmixing vector */ 
	fastica();
	printf("The unmixing vector is : [%d %d]\n",w_next_Q6_10[0],w_next_Q6_10[1]);
}
