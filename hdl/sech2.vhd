-- Loren Lugosch
-- ECSE 682 Project
-- 
-- sech2.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.parameters.all;

ENTITY sech2 IS
	PORT(
		--clock : IN STD_LOGIC;
		--reset : IN STD_LOGIC;
		p1 : IN SIGNED(Q11_21.data_width-1 DOWNTO 0);
		sp : OUT SIGNED(Q11_21.data_width-1 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE arch OF sech2 IS
 
	SIGNAL a : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL b : SIGNED(Q21_43.data_width-1 DOWNTO 0);
	SIGNAL c : SIGNED(Q21_43.data_width-1 DOWNTO 0);
	SIGNAL d : SIGNED(Q21_43.data_width-1 DOWNTO 0);

BEGIN

	PROCESS(p1)
	BEGIN

		IF    (p1 < "11111111101000000000000000000000") 													THEN a <= "00000000000000000001111110110011"; b <= "1111111111111111111110000000000000000000000000000000000000000000";
		ELSIF ((p1 >= "11111111101000000000000000000000") AND (p1 < "11111111110000000000000000000000")) 	THEN a <= "00000000000000011100111000101001"; b <= "";
		ELSIF ((p1 >= "11111111110000000000000000000000") AND (p1 < "11111111110100000000000000000000")) 	THEN a <= ""; b <= "";
		ELSIF ((p1 >= "11111111110100000000000000000000") AND (p1 < "11111111111000000000000000000000")) 	THEN a <= ""; b <= "";
		ELSIF ((p1 >= "11111111111000000000000000000000") AND (p1 < "11111111111100000000000000000000")) 	THEN a <= ""; b <= "";
		ELSIF ((p1 >= "11111111111100000000000000000000") AND (p1 < "00000000000000000000000000000000")) 	THEN a <= ""; b <= (OTHERS => '0');	
		ELSIF ((p1 >= "00000000000000000000000000000000") AND (p1 < "00000000000100000000000000000000")) 	THEN a <= ""; b <= (OTHERS => '0');
		ELSIF ((p1 >= "00000000000100000000000000000000") AND (p1 < "00000000001000000000000000000000"))	THEN a <= ""; b <= "";
		ELSIF ((p1 >= "00000000001000000000000000000000") AND (p1 < "00000000001100000000000000000000")) 	THEN a <= ""; b <= "";
		ELSIF ((p1 >= "00000000001100000000000000000000") AND (p1 < "00000000010000000000000000000000")) 	THEN a <= ""; b <= "";
		ELSIF ((p1 >= "00000000010000000000000000000000") AND (p1 < "00000000011000000000000000000000")) 	THEN a <= ""; b <= "";
		ELSE																									 a <= ""; b <= "0000000000000000000010000000000000000000000000000000000000000000";
		END IF;

	END PROCESS;

	c <= (a * p1) + b;
	d <= c srl 33;
	sp <= d(Q6_10.data_width-1 DOWNTO 0);

END arch;