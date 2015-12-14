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
	SIGNAL abs_dot : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL abs_dot_2 : SIGNED(Q11_21.data_width-1 DOWNTO 0);

	CONSTANT EPSILON : SIGNED(Q11_21.data_width-1 DOWNTO 0) := "00000000000000001010001111010111";

BEGIN
	w_next_Q6_10_out <= w_next_Q6_10_in;

	-- convergence check
	PROCESS(w_next_Q6_10_in, w_Q6_10, dot, abs_dot, abs_dot_2, valid_w)
	BEGIN
		dot <= (w_Q6_10(0)*w_next_Q6_10_in(0) + w_Q6_10(1)*w_next_Q6_10_in(1)) sll 1; 
		IF (dot < 0) THEN
			abs_dot <= (NOT dot) + 1;
		ELSE
			abs_dot <= dot;
		END IF;

		IF ((abs_dot - "00000000001000000000000000000000") < "00000000000000000000000000000000") THEN
			abs_dot_2 <= "00000000001000000000000000000000" - abs_dot;
		ELSE
			abs_dot_2 <= abs_dot - "00000000001000000000000000000000";
		END IF;

		IF (abs_dot_2 < EPSILON) AND (valid_w = '1') THEN
			converged <= '1';
		ELSE 
			converged <= '0';
		END IF;

	END PROCESS;

END arch;