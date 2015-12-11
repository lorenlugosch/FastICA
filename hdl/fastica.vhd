-- Loren Lugosch
-- ECSE 682 Project
-- 
-- fastica_functional.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.parameters.all;

ENTITY fastica IS
	PORT(
		clock : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		ws0 : IN SIGNED(Q6_10.data_width-1 DOWNTO 0);
		ws1 : IN SIGNED(Q6_10.data_width-1 DOWNTO 0);
		w : OUT Q6_10_array_N;
		done : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE arch OF fastica IS

BEGIN

END arch;