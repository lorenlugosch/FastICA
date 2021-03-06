-- Loren Lugosch
-- ECSE 682 Project
-- 
-- processing_element.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.parameters.all;

ENTITY processing_element IS
	PORT(
		clock : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		start_token : IN STD_LOGIC;
		end_token : IN STD_LOGIC;
		ws : IN Q6_10_array_N;
		w_Q6_10 : IN Q6_10_array_N;
		sum_1_in : IN SIGNED(Q11_21.data_width-1 DOWNTO 0);
		sum_1_out : OUT SIGNED(Q11_21.data_width-1 DOWNTO 0);
		p2_in : IN Q11_21_array_N;
		p2_out : OUT Q11_21_array_N
	);
END ENTITY;

ARCHITECTURE arch OF processing_element IS

	-- signals + pipeline registers
	SIGNAL ws_reg_1 : Q6_10_array_N;
	SIGNAL ws_reg_2 : Q6_10_array_N;
	SIGNAL p1 : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL p1_reg : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL tp : SIGNED(Q6_10.data_width-1 DOWNTO 0);
	SIGNAL tp_reg : SIGNED(Q6_10.data_width-1 DOWNTO 0);
	SIGNAL sp : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL sp_reg : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL tpws : Q11_21_array_N;
	SIGNAL tpws_reg : Q11_21_array_N;
	SIGNAL start_token_reg_1 : STD_LOGIC;
	SIGNAL start_token_reg_2 : STD_LOGIC;
	SIGNAL start_token_reg_3 : STD_LOGIC;
	SIGNAL end_token_reg_1 : STD_LOGIC;
	SIGNAL end_token_reg_2 : STD_LOGIC;
	SIGNAL end_token_reg_3 : STD_LOGIC;

BEGIN

	-- multiply input whitened signals by current unmixing vector
	PROCESS(ws,w_Q6_10)
	BEGIN
		p1 <= ((ws(0)*w_Q6_10(0)) + (ws(1)*w_Q6_10(1))) sll 1;
	END PROCESS;

	tanh_t: tanh
	PORT MAP(
		p1 => p1_reg,
		tp => tp
	);

	sech2_t: sech2
	PORT MAP(
		p1 => p1_reg,
		sp => sp
	);

	PROCESS(tp_reg,ws_reg_2)
	BEGIN
		tpws(0) <= (tp_reg * ws_reg_2(0)) sll 1;
		tpws(1) <= (tp_reg * ws_reg_2(1)) sll 1;
	END PROCESS;

	PROCESS(sum_1_in, sp_reg, start_token_reg_3, end_token_reg_3, p2_in, tpws)
	BEGIN
		-- if circuit enabled 3 clock cycles ago, allow output
		IF (start_token_reg_3 = '0') AND (end_token_reg_3 = '0') THEN
			sum_1_out <= sp_reg + sum_1_in;
			p2_out(0) <= tpws(0) + p2_in(0);
			p2_out(1) <= tpws(1) + p2_in(1);
		ELSIF (start_token_reg_3 = '0') AND (end_token_reg_3 = '1') THEN
			sum_1_out <= sum_1_in;
			p2_out <= p2_in;
		ELSIF (start_token_reg_3 = '1') AND (end_token_reg_3 = '0') THEN
			sum_1_out <= sp_reg;
			p2_out <= tpws;
		ELSE -- shouldn't happen
			sum_1_out <= (OTHERS => '0');
			p2_out(0) <= (OTHERS => '0');
			p2_out(1) <= (OTHERS => '0');
		END IF;
	END PROCESS;

	PROCESS(clock, reset)
	BEGIN
		IF (reset = '1') THEN
			ws_reg_1(0) <= (OTHERS => '0');
			ws_reg_1(1) <= (OTHERS => '0');
			ws_reg_2(0) <= (OTHERS => '0');
			ws_reg_2(1) <= (OTHERS => '0');
			p1_reg <= (OTHERS => '0');
			tp_reg <= (OTHERS => '0');
			sp_reg <= (OTHERS => '0');
			start_token_reg_1 <= '0';
			start_token_reg_2 <= '0';
			start_token_reg_3 <= '0';
			end_token_reg_1 <= '0';
			end_token_reg_2 <= '0';
			end_token_reg_3 <= '0';
		ELSIF (RISING_EDGE(clock)) THEN
			ws_reg_1 <= ws;
			ws_reg_2 <= ws_reg_1;
			p1_reg <= p1;
			tp_reg <= tp;
			sp_reg <= sp;
			start_token_reg_1 <= start_token;
			start_token_reg_2 <= start_token_reg_1;
			start_token_reg_3 <= start_token_reg_2;
			end_token_reg_1 <= end_token;
			end_token_reg_2 <= end_token_reg_1;
			end_token_reg_3 <= end_token_reg_2;
		END IF;
	END PROCESS;


END arch;