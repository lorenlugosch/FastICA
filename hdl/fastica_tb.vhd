-- Loren Lugosch
-- ECSE 682 Project
-- 
-- fastica_tb.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.parameters.all;

ENTITY fastica_tb IS
END ENTITY;

ARCHITECTURE arch OF fastica_tb IS

	SIGNAL clock : STD_LOGIC := '0';
	SIGNAL reset : STD_LOGIC := '0';
	CONSTANT clk_period : TIME := 1 ns;
	SIGNAL w : Q6_10_array_N;
	SIGNAL done : STD_LOGIC;
	SIGNAL start : STD_LOGIC;
	SIGNAL ws : Q6_10_array_N := ((OTHERS => '0'),(OTHERS => '0'));
	--SIGNAL ws1 : SIGNED(Q6_10.data_width-1 DOWNTO 0);


BEGIN	

	-- complete design under test
	DUT: fastica
		PORT MAP(
			clock => clock,
			reset => reset,
			w => w,
			done => done,
			start => start,
			ws => ws
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

		WAIT FOR clk_period;
		--WAIT FOR clk_period / 2;

		start <= '1';
		FOR t IN 0 TO T-1 LOOP
			ws(0) <= test_signal_0(t);
			ws(1) <= test_signal_1(t);
			WAIT FOR clk_period;
		END LOOP;

		-- wait forever
		WAIT;
	END PROCESS;

END arch;