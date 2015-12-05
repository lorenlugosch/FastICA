//#include <omp.h>
#include <stdio.h>
#include <math.h>
#include <stdint.h>
#include "fixed_fastica.h"

float Q6_10_to_float(Q6_10 input) {
	return ((float)input) / 1024;
}

float Q11_21_to_float(Q11_21 input) {
	return ((float)input) / 2097152;
}

float Q21_43_to_float(Q21_43 input) {
	return ((float)input) / 8796093022208;
}

Q6_10 float_to_Q6_10(float input) {
	return (Q6_10)(input*1024);
}

Q11_21 float_to_Q11_21(float input) {
	return (Q11_21)(input*2097152);
}

Q21_43 float_to_Q21_43(float input) {
	return (Q11_21)(input*8796093022208);
}

Q11_21 multiply_Q6_10_by_Q6_10(Q6_10 a, Q6_10 b) {
	//if ((a == b) && (a == -65536)) { return 65535; }
	Q11_21 cc = (Q11_21)a * (Q11_21)b * 2;

	return cc;
}

Q21_43 multiply_Q11_21_by_Q11_21(Q11_21 a, Q11_21 b) {
	//if ((a == b) && (a == -65536)) { return 65535; }
	Q21_43 cc = (Q21_43)a * (Q21_43)b * 2;

	return cc;
}

/* reciprocal square root (newton-raphson method) */
Q11_21 rsqrt(Q21_43 input) {
	// int i;
	//Q21_43 output = 4398046511104; // initial guess = 0.5
	/*//(newton-raphson method)
	// Q21_43 a;
	// Q21_43 b;
	// Q21_43 c;
	// Q21_43 d;

	// for (i = 0; i < 5; i++) {
	// 	a = multiply_Q11_21_by_Q11_21(input >> 22,output >> 22);
	// 	b = multiply_Q11_21_by_Q11_21(a >> 22,output >> 22);
	// 	c = b >> 1;
	// 	d = 13194139533312 - c;
	// 	output = multiply_Q11_21_by_Q11_21(output >> 22,d >> 22);
	// }*/


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
	// else if (input >= 1759218604441600) 								{input = input >> 3; a = -53; b = 247170213924;}

	//printf("reciprocal square root of %f is %f\n", ((float)input)/8796093022208, ((float)((Q11_21)((multiply_Q11_21_by_Q11_21((Q11_21)(input >> 22),a) + b) >> 22)))/2097152 );
	return (Q11_21)((multiply_Q11_21_by_Q11_21((Q11_21)(input >> 22),a) + b) >> 22);
	// float x = sqrtf(((float)input)/8796093022208);
	// output = (Q11_21)((1/x)*2097152);
	// printf("reciprocal square root of %f is %f\n", ((float)input)/8796093022208, 1/x);
	//return output;
}

void update_w() {
	int i;
	for (i = 0; i < N; i++) {
		w_Q6_10[i] = w_next_Q6_10[i];
	}
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
Outputs the magnitude of the
unmixing vector (reciprocal). 
*/
Q11_21 rnorm() {
	Q21_43 sum = 0;
	int i;

	for (i = 0; i < N; i++) {
		sum += ((Q21_43)(multiply_Q6_10_by_Q6_10(w_next_Q6_10[i], w_next_Q6_10[i])))<<22;
	}
	return rsqrt(sum);
}


/* 
Returns 1 if the unmixing vector has converged. 
*/
int converged() {
	Q11_21 dot_product = 0;
	int i;
	for (i = 0; i < N; i++) {
		dot_product += multiply_Q6_10_by_Q6_10(w_Q6_10[i], w_next_Q6_10[i]);
	}
	//printf("dot_product: %f\n",((float)dot_product)/2097152);

	if (fabs(fabs(dot_product)-2097152) < EPSILON) { return 1; }
	else { return 0; }
}

/*
Update step in optimization loop.
*/
void rotate() {
	iteration++;
	int n,t;
	for (t = 0; t < T; t++) {
		product_1[t] = 0;
		for (n = 0; n < N; n++) {
			product_1[t] += multiply_Q6_10_by_Q6_10(w_Q6_10[n],whitened_signals[n][t]);
		}

	}

	for (n = 0; n < N; n++) {
		product_2[n] = 0; 
		for (t = 0; t < T; t++) {
			product_2[n] += multiply_Q6_10_by_Q6_10(whitened_signals[n][t], linear_tanh(product_1[t]));
		}
	} 

	sum_1 = 0;
	for (t = 0; t < T; t++) {
		sum_1 += linear_sech2(product_1[t]);
	}

	for (n = 0; n < N; n++) {
		// divide sum_1 by 2 (shift by 12 instead of 11), multiply w by 2
		product_3[n] = multiply_Q6_10_by_Q6_10(w_Q6_10[n] << 1, (Q6_10)(sum_1 >> 12));
	}

	for (n = 0; n < N; n++) {
		w_next_Q11_21[n] = (product_2[n] - product_3[n]) / N;
		w_next_Q6_10[n] = (Q6_10)(w_next_Q11_21[n] >> 11);
	}
}

/*
Makes rotation vector into unit vector.
*/
void normalize() {
	int i;
	Q11_21 w_rnorm = rnorm();
	//printf("w_rnorm: %f\n", ((float)w_rnorm)/2097152);
	for (i = 0; i < N; i++) {
		w_next_Q21_43[i] = multiply_Q11_21_by_Q11_21(w_rnorm, w_next_Q11_21[i]);
		w_next_Q6_10[i] = (Q6_10)(w_next_Q21_43[i] >> 33);
		printf("w_next: %f\n",((float)w_next_Q6_10[i]) / 1024);
	}
}

/*
Main computation.
Finds one of the vectors of the unmixing matrix.
*/
void fastica() {
	// w_Q6_10[0] = float_to_Q6_10(0.5);
	// w_Q6_10[1] = float_to_Q6_10(0.5);
	// w_next_Q6_10[0] = float_to_Q6_10(0.6);
	// w_next_Q6_10[1] = float_to_Q6_10(0.7);
	// rotate();
	// normalize();
	// while(1);

	/* rotate, normalize, and repeat */
	while(!converged()) {
		//printf("iteration %d : w = [%f %f], w_next = [%f %f]\n",iteration,((float)w_Q6_10[0])/1024,((float)w_Q6_10[1])/1024,((float)w_next_Q6_10[0])/1024,((float)w_next_Q6_10[1])/1024);
		printf("iteration %d :\n",iteration);
		update_w();
		rotate();
		normalize();
	}
}

int main() {
	/* mix signals */
	//mix_signals();

	/* find unmixing vector */ 
	fastica();
	printf("The unmixing vector is : [%f %f]\n",((float)w_Q6_10[0])/1024,((float)w_Q6_10[1])/1024);
}
