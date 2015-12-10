-- Loren Lugosch
-- ECSE 682 Project
-- 
-- reduction_sum_Q11_21.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.parameters.all;

ENTITY reduction_sum_Q11_21 IS
	PORT(
		summands : IN Q11_21_array_T;
		sum : OUT SIGNED(Q11_21.data_width-1 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE arch OF reduction_sum_Q11_21 IS

	SIGNAL sum_internal : SIGNED(Q11_21.data_width-1 DOWNTO 0);

BEGIN

	sum <= (((((summands(0) + summands(1)) + (summands(2) + summands(3))) + ((summands(4) + summands(5)) + (summands(6) + summands(7)))) + (((summands(8) + summands(9)) + (summands(10) + summands(11))) + ((summands(12) + summands(13)) + (summands(14) + summands(15))))) + ( (((summands(16) + summands(17)) + (summands(18) + summands(19))) + ((summands(20) + summands(21)) + (summands(22) + summands(23)))) + (((summands(24) + summands(25)) + (summands(26) + summands(27))) + ((summands(28) + summands(29)) + (summands(30) + summands(31)))))) + ( ((((summands(32) + summands(33)) + (summands(34) + summands(35))) + ((summands(36) + summands(37)) + (summands(38) + summands(39)))) + (((summands(40) + summands(41)) + (summands(42) + summands(43))) + ((summands(44) + summands(45)) + (summands(46) + summands(47))))) + ( (((summands(48) + summands(49)) + (summands(50) + summands(51))) + ((summands(52) + summands(53)) + (summands(54) + summands(55)))) + (((summands(56) + summands(57)) + (summands(58) + summands(59))) + ((summands(60) + summands(61)) + (summands(62) + summands(63))))) );

END arch;