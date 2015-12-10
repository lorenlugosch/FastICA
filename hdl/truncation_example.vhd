-- truncation example

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.parameters.all;

ENTITY multiply_Q6_10_by_Q6_10 IS
	PORT(
		clock : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		s1 : IN SIGNED(Q6_10.data_width-1 DOWNTO 0);
		s2 : IN SIGNED(Q6_10.data_width-1 DOWNTO 0);
		
		done : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE arch OF multiply_Q6_10_by_Q6_10 IS

	SIGNAL temp : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL s3 : SIGNED(Q6_10.data_width-1 DOWNTO 0);

BEGIN

	temp <= s1 * s2;
	PROCESS(temp,s1,s2)
	BEGIN
		-- check for corner case
		IF (s1 = MAX_NEGATIVE_Q6_10) AND (s2 = MAX_NEGATIVE_Q6_10) THEN
			s3 <= MAX_POSITIVE_Q11_21;
		-- otherwise, truncate and floor
		ELSE
			s3 <= temp( (Q6_10.integer_width + Q11_21.fractional_width - 2) DOWNTO (Q11_21.fractional_width - Q6_10.fractional_width - 1) ); 
		END IF;
	END PROCESS;

END arch;