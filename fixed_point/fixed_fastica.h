#define T 64 /* number of samples */
#define N 2   /* number of source signals */
#define EPSILON 41943 // 0.02

#define DBL2HEX(a) (*(unsigned *)&a) /* (taken from LegUp examples) */
#define fabs(a) ((a) > 0.0 ? (a) : -(a)) /* floating absolute value (taken from LegUp examples) */

#define Q6_10 int16_t
#define Q11_21 int32_t
#define Q21_43 int64_t

/* "randomly initialized" unmixing vector */
Q6_10 w_next_Q6_10[N] = 
{
	-1654,
	15
};
Q11_21 w_next_Q11_21[N] = 
{
	-3389207,
	30828
};
Q21_43 w_next_Q21_43[N] = 
{
	-14215365933190,
	129302567426
};
Q6_10 w_Q6_10[N] = 
{
	-38,
	413
};

/* intermediate variables */
Q11_21 product_1[T];
Q11_21 product_2[N];
Q11_21 product_3[N];
Q11_21 sum_1;

Q6_10 whitened_signals[N][T] = {
	{49,1148,1224,194,-1004,-1276,-374,870,1311,544,-727,-1333,-717,554,1313,860,-387,-1285,-1008,184,1190,1075,-69,-1075,-1175,-160,1021,1273,358,-885,-1317,-541,729,1325,699,-573,-1322,-859,389,1276,984,-220,-1233,-1129,-13,1074,1248,193,-1006,-1261,-347,889,1309,522,-746,-1333,-697,576,1316,842,-409,-1289,-987,216},
	{34,456,481,78,-389,-496,-145,337,509,211,-283,-519,-279,215,510,334,-151,-501,-394,67,456,407,-43,-402,-447,-56,399,496,139,-344,-512,-211,283,515,271,-223,-515,-335,150,495,381,-88,-483,-445,-15,400,501,84,-385,-487,-133,346,508,202,-291,-519,-271,223,511,327,-159,-502,-385,82}
};

