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
		ws : IN Q6_10_array_N;
		start : IN STD_LOGIC;
		w : OUT Q6_10_array_N;
		done : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE arch OF fastica IS

	SIGNAL converged : STD_LOGIC;
	SIGNAL ws_select : STD_LOGIC; -- 0 - external, 1 - from RAM
	SIGNAL RAM_address : INTEGER RANGE 0 TO T - 1;
	SIGNAL valid_w : STD_LOGIC;
	SIGNAL valid_p1 : STD_LOGIC;
	SIGNAL RAM_we : STD_LOGIC;
	SIGNAL RAM_out : SIGNED(N*Q6_10.data_width-1 DOWNTO 0);
	SIGNAL ws_hack : SIGNED(N*Q6_10.data_width-1 DOWNTO 0);
	SIGNAL w_Q6_10 : Q6_10_array_N;
	SIGNAL w_next_Q6_10 : Q6_10_array_N;
	SIGNAL sum_1_in : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL sum_1_out : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL p2_in : Q11_21_array_N;
	SIGNAL p2_out : Q11_21_array_N;
	SIGNAL PE_in : Q6_10_array_N;
	SIGNAL rotation_start : STD_LOGIC;

BEGIN

	-- if first iteration, use incoming signal
	-- otherwise, read from RAM
	PROCESS(ws_select)
	BEGIN
		IF (ws_select = '1') THEN
			PE_in(0) <= RAM_out(2*Q6_10.data_width-1 DOWNTO Q6_10.data_width);
			PE_in(1) <= RAM_out(Q6_10.data_width-1 DOWNTO 0);
		ELSE
			PE_in <= ws;
		END IF;
	END PROCESS;

	PROCESS(clock, reset)
	BEGIN
		IF (reset = '1') THEN
			--w_Q6_10(0) <= "1111100110001010";--"1111111111011001"; -- -0.0378 ("random" vector)
			--w_Q6_10(1) <= "0000000000001111";--"0000000110011101"; --  0.4038
			--sum_1_in <= (OTHERS => '0');
			--p2_in(0) <= (OTHERS => '0');
			--p2_in(1) <= (OTHERS => '0');
		ELSIF (RISING_EDGE(clock)) THEN
			IF (rotation_start = '1') THEN
				w_Q6_10(0) <= "1111100110001010";--"1111111111011001"; -- -0.0378 ("random" vector)
				w_Q6_10(1) <= "0000000000001111";--"0000000110011101"; --  0.4038
				sum_1_in <= (OTHERS => '0');
				p2_in(0) <= (OTHERS => '0');
				p2_in(1) <= (OTHERS => '0');
			ELSE
				w_Q6_10 <= w_next_Q6_10;
				sum_1_in <= sum_1_out;
				p2_in <= p2_out;
			END IF;
		END IF;
	END PROCESS;

	PE: processing_element
	PORT MAP(
		clock => clock,
		reset => reset,
		ws => PE_in,
		w_Q6_10 => w_Q6_10,
		sum_1_in => sum_1_in,
		sum_1_out => sum_1_out,
		p2_in => p2_in,
		p2_out => p2_out
	);

	NU: normalization_unit
	PORT MAP(
		clock => clock,
		reset => reset,
		w_Q6_10 => w_Q6_10,
		sum_1 => sum_1_out,
		p2 => p2_out,
		w_next_Q6_10 => w_next_Q6_10
	);

	CC: convergence_check
	PORT MAP(
		clock => clock,
		reset => reset,
		w_Q6_10 => w_Q6_10,
		w_next_Q6_10_in => w_next_Q6_10,
		converged => converged
	);

	C: controller
	PORT MAP(
		clock => clock,
		reset => reset,
		start => start,
		converged => converged,
		ws_select => ws_select,
		RAM_address => RAM_address,
		valid_w => valid_w,
		valid_p1 => valid_p1,
		RAM_we => RAM_we,
		rotation_start => rotation_start
	);

	ws_hack <= ws(1) & ws(0);
	ws_ram: RAM
	PORT MAP(
		clock => clock,
		address => RAM_address,
		datain => ws_hack,
		we => RAM_we,
		dataout => RAM_out
	);

	w <= w_next_Q6_10;
END arch;