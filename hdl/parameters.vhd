-- Loren Lugosch
-- ECSE 682 Project
-- 
-- parameters.vhd
-- 
-- Some useful parameters.

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

PACKAGE parameters IS
	CONSTANT N : INTEGER := 2;
	CONSTANT T : INTEGER := 64;

	TYPE fixed_point IS RECORD
		data_width : INTEGER;
		integer_width : INTEGER;
		fractional_width : INTEGER;	
	END RECORD;
	
	CONSTANT Q6_10 : fixed_point := (data_width => 16,
                              integer_width => 6,
                              fractional_width => 10);
	CONSTANT MAX_NEGATIVE_Q6_10 : SIGNED(Q6_10.data_width-1 DOWNTO 0) := "0111111111111111"; -- -32
	CONSTANT MAX_POSITIVE_Q6_10 : SIGNED(Q6_10.data_width-1 DOWNTO 0) := "1000000000000000"; --  31.9990234375

	CONSTANT Q11_21 : fixed_point := (data_width => 32,
                              integer_width => 11,
                              fractional_width => 21);
	CONSTANT MAX_NEGATIVE_Q11_21 : SIGNED(Q11_21.data_width-1 DOWNTO 0) := "10000000000000000000000000000000"; -- -1024 
	CONSTANT MAX_POSITIVE_Q11_21 : SIGNED(Q11_21.data_width-1 DOWNTO 0) := "01111111111111111111111111111111"; --  1023.999999523162841796875

	CONSTANT Q21_43 : fixed_point := (data_width => 64,
                              integer_width => 21,
                              fractional_width => 43);
	CONSTANT MAX_NEGATIVE_Q21_43 : SIGNED(Q21_43.data_width-1 DOWNTO 0) := "1000000000000000000000000000000000000000000000000000000000000000";
	CONSTANT MAX_POSITIVE_Q21_43 : SIGNED(Q21_43.data_width-1 DOWNTO 0) := "0111111111111111111111111111111111111111111111111111111111111111";

	TYPE Q6_10_array_N IS ARRAY(0 TO N-1) OF SIGNED(Q6_10.data_width-1 DOWNTO 0);
	TYPE Q6_10_array_T IS ARRAY(0 TO T-1) OF SIGNED(Q6_10.data_width-1 DOWNTO 0);

	TYPE Q11_21_array_N IS ARRAY(0 TO N-1) OF SIGNED(Q11_21.data_width-1 DOWNTO 0);
	TYPE Q11_21_array_T IS ARRAY(0 TO T-1) OF SIGNED(Q11_21.data_width-1 DOWNTO 0);

	TYPE Q21_43_array_N IS ARRAY(0 TO N-1) OF SIGNED(Q21_43.data_width-1 DOWNTO 0);
	TYPE Q21_43_array_T IS ARRAY(0 TO T-1) OF SIGNED(Q21_43.data_width-1 DOWNTO 0);

	COMPONENT fastica_functional IS
		PORT(
			clock : IN STD_LOGIC;
			reset : IN STD_LOGIC;
			ws0 : IN Q6_10_array_T;
			ws1 : IN Q6_10_array_T;
			w : OUT Q6_10_array_N;
			done : OUT STD_LOGIC
		);
	END COMPONENT;

	COMPONENT tanh IS
		PORT(
			--clock : IN STD_LOGIC;
			--reset : IN STD_LOGIC;
			p1 : IN SIGNED(Q11_21.data_width-1 DOWNTO 0);
			tp : OUT SIGNED(Q6_10.data_width-1 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT sech2 IS
		PORT(
			--clock : IN STD_LOGIC;
			--reset : IN STD_LOGIC;
			p1 : IN SIGNED(Q11_21.data_width-1 DOWNTO 0);
			sp : OUT SIGNED(Q11_21.data_width-1 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT rsqrt IS
		PORT(
			--clock : IN STD_LOGIC;
			--reset : IN STD_LOGIC;
			sum_2 : IN SIGNED(Q21_43.data_width-1 DOWNTO 0);
			w_rnorm : OUT SIGNED(Q11_21.data_width-1 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT reduction_sum_Q11_21 IS
		PORT(
			summands : IN Q11_21_array_T;
			sum : OUT SIGNED(Q11_21.data_width-1 DOWNTO 0)
		);
	END COMPONENT;

	CONSTANT test_signal_0 : Q6_10_array_T := (
		"0000000000110001",
		"0000010001111100",
		"0000010011001000",
		"0000000011000010",
		"1111110000010100",
		"1111101100000100",
		"1111111010001010",
		"0000001101100110",
		"0000010100011111",
		"0000001000100000",
		"1111110100101001",
		"1111101011001011",
		"1111110100110011",
		"0000001000101010",
		"0000010100100001",
		"0000001101011100",
		"1111111001111101",
		"1111101011111011",
		"1111110000010000",
		"0000000010111000",
		"0000010010100110",
		"0000010000110011",
		"1111111110111011",
		"1111101111001101",
		"1111101101101001",
		"1111111101100000",
		"0000001111111101",
		"0000010011111001",
		"0000000101100110",
		"1111110010001011",
		"1111101011011011",
		"1111110111100011",
		"0000001011011001",
		"0000010100101101",
		"0000001010111011",
		"1111110111000011",
		"1111101011010110",
		"1111110010100101",
		"0000000110000101",
		"0000010011111100",
		"0000001111011000",
		"1111111100100100",
		"1111101100101111",
		"1111101110010111",
		"1111111111110011",
		"0000010000110010",
		"0000010011100000",
		"0000000011000001",
		"1111110000010010",
		"1111101100010011",
		"1111111010100101",
		"0000001101111001",
		"0000010100011101",
		"0000001000001010",
		"1111110100010110",
		"1111101011001011",
		"1111110101000111",
		"0000001001000000",
		"0000010100100100",
		"0000001101001010",
		"1111111001100111",
		"1111101011110111",
		"1111110000100101",
		"0000000011011000"
	);

	CONSTANT test_signal_1 : Q6_10_array_T := (
		"0000000000100010",
		"0000000111001000",
		"0000000111100001",
		"0000000001001110",
		"1111111001111011",
		"1111111000010000",
		"1111111101101111",
		"0000000101010001",
		"0000000111111101",
		"0000000011010011",
		"1111111011100101",
		"1111110111111001",
		"1111111011101001",
		"0000000011010111",
		"0000000111111110",
		"0000000101001110",
		"1111111101101001",
		"1111111000001011",
		"1111111001110110",
		"0000000001000011",
		"0000000111001000",
		"0000000110010111",
		"1111111111010101",
		"1111111001101110",
		"1111111001000001",
		"1111111111001000",
		"0000000110001111",
		"0000000111110000",
		"0000000010001011",
		"1111111010101000",
		"1111111000000000",
		"1111111100101101",
		"0000000100011011",
		"0000001000000011",
		"0000000100001111",
		"1111111100100001",
		"1111110111111101",
		"1111111010110001",
		"0000000010010110",
		"0000000111101111",
		"0000000101111101",
		"1111111110101000",
		"1111111000011101",
		"1111111001000011",
		"1111111111110001",
		"0000000110010000",
		"0000000111110101",
		"0000000001010100",
		"1111111001111111",
		"1111111000011001",
		"1111111101111011",
		"0000000101011010",
		"0000000111111100",
		"0000000011001010",
		"1111111011011101",
		"1111110111111001",
		"1111111011110001",
		"0000000011011111",
		"0000000111111111",
		"0000000101000111",
		"1111111101100001",
		"1111111000001010",
		"1111111001111111",
		"0000000001010010"
	);

END PACKAGE;