-- Loren Lugosch
-- ECSE 682 project
-- 
-- matrix_RAM.vhd
--
-- This module implements a memory for matrix data.
-- I took most of this code from example code in the 
-- Altera "Recommended HDL Coding Styles" guide.
-- (https://www.altera.com/content/dam/altera-www/global/en_US/pdfs/literature/hb/qts/qts_qii5v1.pdf)

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.parameters.all;

ENTITY RAM IS
	GENERIC (
		params : fixed_point := Q6_10;
		size : INTEGER := T
	);
	PORT (
		clock : IN STD_LOGIC;
		address : IN INTEGER RANGE 0 TO size - 1;
		datain : IN SIGNED((N*params.data_width)-1 DOWNTO 0);
		we : IN STD_LOGIC;
		dataout : OUT SIGNED((N*params.data_width)-1 DOWNTO 0)
	);
END ENTITY;

ARCHITECTURE arch OF RAM IS
	-- Build a 2-D array type for the RAM
	TYPE memory_t is ARRAY((size - 1) DOWNTO 0) OF SIGNED((N*params.data_width)-1 DOWNTO 0);
	-- Declare the RAM signal.
	SHARED VARIABLE ram : memory_t;
 
BEGIN
	PROCESS(clock)
	BEGIN
		IF(rising_edge(clock)) THEN -- Port 0
			IF(we = '1') THEN
				ram(address) := datain;
				dataout <= datain;
			ELSE
				dataout <= ram(address);
			END IF;
		END IF;
	END PROCESS;
END arch;
