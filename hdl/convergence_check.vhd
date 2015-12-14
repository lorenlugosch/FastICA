-- Loren Lugosch
-- ECSE 682 Project
-- 
-- convergence_check.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.parameters.all;

ENTITY convergence_check IS
	PORT(
		clock : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		w_Q6_10 : IN Q6_10_array_N;
		w_next_Q6_10_in : IN Q6_10_array_N;
		w_next_Q6_10_out : OUT Q6_10_array_N;
		valid_w : IN STD_LOGIC;
		converged : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE arch OF convergence_check IS

	SIGNAL dot : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL dot_reg : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL abs_dot : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL abs_dot_reg : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL abs_dot_2 : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL abs_dot_2_reg : SIGNED(Q11_21.data_width-1 DOWNTO 0);

	SIGNAL valid_w_reg_1 : STD_LOGIC;
	SIGNAL valid_w_reg_2 : STD_LOGIC;
	SIGNAL valid_w_reg_3 : STD_LOGIC;
	SIGNAL valid_w_reg_4 : STD_LOGIC;
	SIGNAL valid_w_reg_5 : STD_LOGIC;
	SIGNAL valid_w_reg_6 : STD_LOGIC;
	SIGNAL w_Q6_10_reg : Q6_10_array_N;

	CONSTANT EPSILON : SIGNED(Q11_21.data_width-1 DOWNTO 0) := "00000000000000001010001111010111";

BEGIN
	w_next_Q6_10_out <= w_next_Q6_10_in; -- register this!

	PROCESS(w_next_Q6_10_in, w_Q6_10_reg, dot, dot_reg, abs_dot, abs_dot_reg, abs_dot_2, abs_dot_2_reg, valid_w_reg_5)
	BEGIN
		dot <= (w_Q6_10_reg(0)*w_next_Q6_10_in(0) + w_Q6_10_reg(1)*w_next_Q6_10_in(1)) sll 1; 
		IF (dot < 0) THEN
			abs_dot <= (NOT dot_reg) + 1; -- multiply by -1 in two's complement
		ELSE
			abs_dot <= dot_reg;
		END IF;

		IF ((abs_dot - "00000000001000000000000000000000") < "00000000000000000000000000000000") THEN
			abs_dot_2 <= "00000000001000000000000000000000" - abs_dot_reg;
		ELSE
			abs_dot_2 <= abs_dot_reg - "00000000001000000000000000000000";
		END IF;

		IF (abs_dot_2_reg < EPSILON) AND (valid_w_reg_5 = '1') THEN
			converged <= '1';
		ELSE 
			converged <= '0';
		END IF;
	END PROCESS;


	PROCESS(clock, reset)
	BEGIN
		IF (reset = '1') THEN
			dot_reg <= (OTHERS => '0');
			abs_dot_reg <= (OTHERS => '0');
			abs_dot_2_reg <= (OTHERS => '0');
			valid_w_reg_1 <= '0';
			valid_w_reg_2 <= '0';
			valid_w_reg_3 <= '0';
			valid_w_reg_4 <= '0';
			valid_w_reg_5 <= '0';
			valid_w_reg_6 <= '0';
			w_Q6_10_reg <= ((OTHERS => '0'), (OTHERS => '0'));
		ELSIF (RISING_EDGE(clock)) THEN
			dot_reg <= dot;
			abs_dot_reg <= abs_dot;
			abs_dot_2_reg <= abs_dot_2;
			valid_w_reg_1 <= valid_w;
			valid_w_reg_2 <= valid_w_reg_1;
			valid_w_reg_3 <= valid_w_reg_2;
			valid_w_reg_4 <= valid_w_reg_3;
			valid_w_reg_5 <= valid_w_reg_4;
			valid_w_reg_6 <= valid_w_reg_5;
			w_Q6_10_reg <= w_Q6_10;
		END IF;
	END PROCESS;


END arch;