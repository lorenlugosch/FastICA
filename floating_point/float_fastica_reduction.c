//#include <omp.h>
#include <stdio.h>
#include <math.h>
#include "float_fastica.h"

float dot_product = 0;

void update_w() {
	int i;
	for (i = 0; i < N; i++) {
		w[i] = w_next[i];
	}
}

/* Piecewise linear approximation of 
hyperbolic tangent. */
float linear_tanh(float input) {
	float a, b;
	if (input < -3) 							{a = 0.000732422; b = -1;}
	else if ((input >= -3) && (input < -2)) 	{a = 0.029296875; b = -0.9063;}
	else if ((input >= -2) && (input < -1.5)) 	{a = 0.115966796; b = -0.75;}
	else if ((input >= -1.5) && (input < -1)) 	{a = 0.284423828; b = -0.5;}
	else if ((input >= -1) && (input < -0.5)) 	{a = 0.593017578; b = -0.1875;}
	else if ((input >= -0.5) && (input < 0)) 	{a = 0.952880859; b = 0;}
	else if ((input >= 0) && (input < 0.5)) 	{a = 0.952880859; b = 0;}
	else if ((input >= 0.5) && (input < 1))		{a = 0.593017578; b = 0.1875;}
	else if ((input >= 1) && (input < 1.5)) 	{a = 0.284423828; b = 0.5;}
	else if ((input >= 1.5) && (input < 2)) 	{a = 0.115966796; b = 0.75;}
	else if ((input >= 2) && (input < 3)) 		{a = 0.029296875; b = 0.9063;}
	else if (input > 3) 						{a = 0.000732422; b = 1;}

	return a*input + b;
//	return tanh(input);
}

/* Piecewise linear approximation of 
hyperbolic secant squared (derivative of tanh). */
float linear_sech2(float input) {
//	return 1/(cosh(input) * cosh(input)); // prohibitively slow to simulate!
	float a, b;
	if (input < -3) 							{a = 0.003869790; b = 0.0179;}
	else if ((input >= -3) && (input < -2)) 	{a = 0.056416286; b = 0.1721;}
	else if ((input >= -2) && (input < -1.5)) 	{a = 0.214149958; b = 0.4926;}
	else if ((input >= -1.5) && (input < -1)) 	{a = 0.471207672; b = 0.8763;}
	else if ((input >= -1) && (input < -0.5)) 	{a = 0.740162976; b = 1.1542;}
	else if ((input >= -0.5) && (input < -0.2)) {a = 0.598675668; b = 1.0918;}
	else if ((input >= -0.2) && (input < 0)) 	{a = 0.214633761; b = 1.0081;}
	else if ((input >= 0) && (input < 0.2)) 	{a = -0.214633761; b = 1.0081;}
	else if ((input >= 0.2) && (input < 0.5)) 	{a = -0.598675668; b = 1.0918;}
	else if ((input >= 0.5) && (input < 1))		{a = -0.740162976; b = 1.1542;}
	else if ((input >= 1) && (input < 1.5)) 	{a = -0.471207672; b = 0.8763;}
	else if ((input >= 1.5) && (input < 2)) 	{a = -0.214149958; b = 0.4926;}
	else if ((input >= 2) && (input < 3)) 		{a = -0.056416286; b = 0.1721;}
	else if (input > 3) 						{a = -0.003869790; b = 0.0179;}

	return a*input + b;
}

float rsqrt(float input) {
	float a, b;

	if ((input > 0) && (input < 20)) 			{a = -0.02719429; b = 0.6653;}
	else if ((input >= 20) && (input < 40)) 	{a = -0.00319228; b = 0.2813;}
	else if ((input >= 40) && (input < 75)) 	{a = -0.00119129; b = 0.2021;}
	
	else if ((input >= 75) && (input < 150)) 	{a = -0.00043819; b = 0.1450;}
	else if ((input >= 150) && (input < 250)) 	{a = -0.00018116; b = 0.1075;}
	else if ((input >= 250) && (input < 500)) 	{a = -0.00007194; b = 0.0794;}
	
	else if ((input >= 500) && (input < 1000)) 	{a = -0.00002543; b = 0.0561;}
	else if ((input >= 1000))  {a = -0.00000899; b = 0.0397;}

	return a*input + b;
	// return 1/sqrtf(input);
}

/* 
Takes a vector as input; outputs the 
magnitude of that vector. 
*/
float rnorm() {
	float sum = 0;
	int n;

	//#pragma omp parallel for num_threads(2) private(n)
	for (n = 0; n < N; n++) {
		sum += w_next[n] * w_next[n];
	}

	printf("sum: %f\n", sum);
	return rsqrt(sum);
	//return 1/sqrt(sum);
}


/* 
Returns 1 if the unmixing vector has converged. 
*/
int converged() {
	dot_product = 0;
	int i;
	for (i = 0; i < N; i++) {
		dot_product += w[i] * w_next[i];
	}

	if (fabs(fabs(dot_product)-1) < EPSILON) { return 1; }
	else { return 0; }
}

/*
Update step in optimization loop.
*/
void rotate() {
	int n,t;
	for (t = 0; t < T; t++) {
		product_1[t] = 0;
		for (n = 0; n < N; n++) {
			product_1[t] += w[n]*whitened_signals[n][t];
			printf("p1 = %f * %f: %f\n",w[n],whitened_signals[n][t],product_1[t]);
		}
		printf("\n");
	}
	while(1);

	//#pragma omp parallel for num_threads(2) private(n,t)
	for (n = 0; n < N; n++) {
		product_2[n] = 0; 
		for (t = 0; t < T; t++) {
			product_2[n] += whitened_signals[n][t] * linear_tanh(product_1[t]);
		}
	}

	sum_1 = 0;
	#pragma omp parallel for reduction(+:sum_1)
	for (t = 0; t < T; t++) {
		sum_1 += linear_sech2(product_1[t]);
	}

	for (n = 0; n < N; n++) {
		product_3[n] = w[n] * sum_1;
	}

	for (n = 0; n < N; n++) {
		w_next[n] = (product_2[n] - product_3[n]) / N;
	}
	
}

/*
Makes rotation vector into unit vector.
*/
void normalize() {
	int i;
	float w_rnorm = rnorm();
	//#pragma omp parallel for num_threads(2) private(i)
	for (i = 0; i < N; i++) {
		w_next[i] *= w_rnorm;
	}
}

/*
Main computation.
Finds one of the vectors of the unmixing matrix.
*/
void fastica() {
	/* rotate, normalize, and repeat */
	while(!converged()) {
		//printf("w: [%f %f], w_next: [%f %f]\n",w[0],w[1],w_next[0],w_next[1]);//DBL2HEX(w[0]),DBL2HEX(w[1]));
		update_w();
		rotate();
		normalize();
	}
}

int main() {
	/* find unmixing vector */ 
	fastica();
	printf("The unmixing vector is : [%u %u]\n",DBL2HEX(w[0]),DBL2HEX(w[1]));//DBL2HEX(w[0]),DBL2HEX(w[1]));
}
