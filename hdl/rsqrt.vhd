-- Loren Lugosch
-- ECSE 682 Project
-- 
-- rsqrt.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.parameters.all;

ENTITY rsqrt IS
	PORT(
		--clock : IN STD_LOGIC;
		--reset : IN STD_LOGIC;
		sum_2 : IN SIGNED(Q21_43.data_width-1 DOWNTO 0);
		w_rnorm : OUT SIGNED(Q11_21.data_width-1 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE arch OF rsqrt IS

BEGIN

	--s3 <= s1 * s2;
	--PROCESS(s3,s1,s2)
	--BEGIN
	--	-- check for corner case
	--	IF (s1 = MAX_NEGATIVE_Q11_21) AND (s2 = MAX_NEGATIVE_Q11_21) THEN
	--		s4 <= MAX_POSITIVE_Q21_43;
	--	-- otherwise, truncate and floor
	--	ELSE
	--		s4 <= s3( (Q11_21.integer_width + Q21_43.fractional_width - 2) DOWNTO (Q21_43.fractional_width - Q11_21.fractional_width - 1) ); 
	--	END IF;
	--END PROCESS;

END arch;