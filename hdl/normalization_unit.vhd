-- Loren Lugosch
-- ECSE 682 Project
-- 
-- normalization_unit.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.parameters.all;

ENTITY normalization_unit IS
	PORT(
		clock : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		enable : IN STD_LOGIC;
		w_Q6_10 : IN Q6_10_array_N;
		sum_1 : IN SIGNED(Q11_21.data_width-1 DOWNTO 0);
		p2 : IN Q11_21_array_N;
		w_next_Q6_10 : OUT Q6_10_array_N
	);
END ENTITY;

ARCHITECTURE arch OF normalization_unit IS

	SIGNAL w_next : Q21_43_array_N;
	SIGNAL w_next_Q21_43 : Q21_43_array_N;

	SIGNAL sum_1_6 : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL p3 : Q11_21_array_N;
	SIGNAL diff : Q11_21_array_N;
	SIGNAL sum_2 : SIGNED(Q21_43.data_width-1 DOWNTO 0);
	SIGNAL w_rnorm : SIGNED(Q11_21.data_width-1 DOWNTO 0);

	SIGNAL p2_reg : Q11_21_array_N;
	SIGNAL p3_reg : Q11_21_array_N;
	SIGNAL diff_reg : Q11_21_array_N;
	SIGNAL sum_2_reg : SIGNED(Q21_43.data_width-1 DOWNTO 0);
	SIGNAL w_rnorm_reg : SIGNED(Q11_21.data_width-1 DOWNTO 0);

BEGIN

	sum_1_6 <= (sum_1 srl 12);
	p3(0) <= (sum_1_6(Q6_10.data_width-1 DOWNTO 0) * (w_Q6_10(0) sll 1)) sll 1;
	p3(1) <= (sum_1_6(Q6_10.data_width-1 DOWNTO 0) * (w_Q6_10(1) sll 1)) sll 1;

	diff(0) <= shift_right((p2_reg(0) - p3_reg(0)) , 1);
	diff(1) <= shift_right((p2_reg(1) - p3_reg(1)) , 1);

	sum_2 <= (diff_reg(0)*diff_reg(0) + diff_reg(1)*diff_reg(1)) sll 1;

	reciprocal_square_root: rsqrt
	PORT MAP(
		sum_2 => sum_2_reg,
		w_rnorm => w_rnorm
	);

	w_next_Q21_43(0) <= (diff_reg(0) * w_rnorm_reg) sll 1;
	w_next_Q21_43(1) <= (diff_reg(1) * w_rnorm_reg) sll 1;

	w_next(0) <= w_next_Q21_43(0) srl 33;
	w_next(1) <= w_next_Q21_43(1) srl 33; 

	w_next_Q6_10(0) <= w_next(0)(Q6_10.data_width-1 DOWNTO 0);
	w_next_Q6_10(1) <= w_next(1)(Q6_10.data_width-1 DOWNTO 0);

	PROCESS(clock, reset)
	BEGIN
		IF (reset = '1') THEN
			p2_reg <= ((OTHERS => '0'),(OTHERS => '0'));
			p3_reg <= ((OTHERS => '0'),(OTHERS => '0'));
			diff_reg <= ((OTHERS => '0'),(OTHERS => '0'));
			sum_2_reg <= (OTHERS => '0');
			w_rnorm_reg <= (OTHERS => '0');

		ELSIF (RISING_EDGE(clock) AND enable = '1') THEN
			p2_reg <= p2;
			p3_reg <= p3;
			diff_reg <= diff;
			sum_2_reg <= sum_2;
			w_rnorm_reg <= w_rnorm;
		END IF;
	END PROCESS;

END arch;