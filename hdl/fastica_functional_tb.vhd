-- Loren Lugosch
-- ECSE 682 Project
-- 
-- fastica_functional_tb.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.parameters.all;

ENTITY fastica_functional_tb IS
END ENTITY;

ARCHITECTURE arch OF fastica_functional_tb IS

	SIGNAL clock : STD_LOGIC := '0';
	SIGNAL reset : STD_LOGIC := '0';
	CONSTANT clk_period : TIME := 1 ns;
	SIGNAL w : Q6_10_array_N;
	SIGNAL done : STD_LOGIC;


BEGIN	

	-- complete design under test
	DUT: fastica
		PORT MAP(
			clock => clock,
			reset => reset,
			ws0 => test_signal_0,
			ws1 => test_signal_1,
			w => w,
			done => done
		);

	clock_process: 
	PROCESS
	BEGIN
		clock <= '1';
		WAIT FOR clk_period/2;
		clock <= '0';
		WAIT FOR clk_period/2;
	END PROCESS;

	test_process: 
	PROCESS
	BEGIN
		-- flash reset 
		reset <= '1';
		WAIT FOR clk_period / 2;
		reset <= '0';
		WAIT FOR clk_period / 2;

		-- wait forever
		WAIT;
	END PROCESS;

END arch;