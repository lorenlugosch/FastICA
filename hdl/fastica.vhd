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
	SIGNAL RAM_address : INTEGER RANGE 0 TO T - 1;
	SIGNAL valid_w : STD_LOGIC;
	SIGNAL valid_p1 : STD_LOGIC;
	SIGNAL RAM_we : STD_LOGIC;
	SIGNAL RAM_out : SIGNED(N*Q6_10.data_width-1 DOWNTO 0);
	SIGNAL ws_hack : SIGNED(N*Q6_10.data_width-1 DOWNTO 0);
	SIGNAL w_Q6_10 : Q6_10_array_N;
	SIGNAL w_Q6_10_out : Q6_10_array_N;
	SIGNAL w_next_Q6_10 : Q6_10_array_N;
	SIGNAL sum_1_in : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL sum_1_in_safe : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL sum_1_out : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL p2_in : Q11_21_array_N;
	SIGNAL p2_in_safe : Q11_21_array_N;
	SIGNAL p2_out : Q11_21_array_N;
	SIGNAL ws_in : Q6_10_array_N;
	SIGNAL first_iteration : STD_LOGIC;
	SIGNAL rotation_start_token : STD_LOGIC;
	SIGNAL rotation_end_token : STD_LOGIC;
	SIGNAL normalization_start_token : STD_LOGIC;
	SIGNAL normalization_end_token : STD_LOGIC;

BEGIN

	-- feedback into systolic array
	PROCESS(clock, reset)
	BEGIN
		IF (reset = '1') THEN
			sum_1_in <= (OTHERS => '0');
			p2_in(0) <= (OTHERS => '0');
			p2_in(1) <= (OTHERS => '0');
		ELSIF (RISING_EDGE(clock)) THEN
			sum_1_in <= sum_1_out;
			p2_in <= p2_out;
		END IF;
	END PROCESS;

	-- initialize w
	PROCESS(first_iteration, w_next_Q6_10)
	BEGIN
		IF (first_iteration = '1') THEN 
			w_Q6_10(0) <= "1111100110001010";--"1111111111011001"; -- ("random" vector)
			w_Q6_10(1) <= "0000000000001111";--"0000000110011101"; --  
		ELSIF (rotation_start_token = '1') THEN
			w_Q6_10 <= w_next_Q6_10;
		END IF;
	END PROCESS;

	PE: processing_element
	PORT MAP(
		clock => clock,
		reset => reset,
		ws => ws_in,
		w_Q6_10 => w_Q6_10,
		sum_1_in => sum_1_in,
		sum_1_out => sum_1_out,
		p2_in => p2_in,
		p2_out => p2_out,
		start_token => rotation_start_token,
		end_token => rotation_end_token
	);

	NU: normalization_unit
	PORT MAP(
		clock => clock,
		reset => reset,
		w_Q6_10 => w_Q6_10,
		sum_1 => sum_1_out,
		p2 => p2_out,
		w_next_Q6_10 => w_next_Q6_10,
		w_Q6_10_out => w_Q6_10_out,
		start_token => normalization_start_token,
		end_token => normalization_end_token
	);

	CC: convergence_check
	PORT MAP(
		clock => clock,
		reset => reset,
		w_Q6_10 => w_Q6_10_out,
		valid_w => valid_w,
		w_next_Q6_10_in => w_next_Q6_10,
		converged => converged
	);

	C: controller
	PORT MAP(
		clock => clock,
		reset => reset,
		start => start,
		converged => converged,
		RAM_address => RAM_address,
		valid_w => valid_w,
		valid_p1 => valid_p1,
		RAM_we => RAM_we,
		first_iteration => first_iteration,
		rotation_start_token => rotation_start_token,
		rotation_end_token => rotation_end_token,
		normalization_start_token => normalization_start_token,
		normalization_end_token =>normalization_end_token
	);

	ws_hack <= ws(1) & ws(0); -- needed for Modelsim
	ws_ram: RAM
	PORT MAP(
		clock => clock,
		address => RAM_address,
		datain => ws_hack,
		we => first_iteration,
		dataout => RAM_out
	);

	ws_in(1) <= RAM_out(2*Q6_10.data_width-1 DOWNTO Q6_10.data_width);
	ws_in(0) <= RAM_out(Q6_10.data_width-1 DOWNTO 0);

	w <= w_next_Q6_10;
	done <= converged;
END arch;