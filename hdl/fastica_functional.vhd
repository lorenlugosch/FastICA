-- Loren Lugosch
-- ECSE 682 Project
-- 
-- fastica_functional.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.parameters.all;

ENTITY fastica_functional IS
	PORT(
		clock : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		ws0 : IN Q6_10_array_T;
		ws1 : IN Q6_10_array_T;
		w : OUT Q6_10_array_N;
		done : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE arch OF fastica_functional IS

	SIGNAL w_Q6_10 : Q6_10_array_N;
	SIGNAL w_Q21_43 : Q21_43_array_N;

	SIGNAL w_next_Q6_10 : Q6_10_array_N;
	SIGNAL w_next : Q21_43_array_N;
	SIGNAL w_next_Q21_43 : Q21_43_array_N;

	SIGNAL p1 : Q11_21_array_T;
	SIGNAL sp : Q11_21_array_T;
	SIGNAL tp : Q6_10_array_T;
	SIGNAL tpws0 : Q11_21_array_T;
	SIGNAL tpws1 : Q11_21_array_T;
	SIGNAL sum_1 : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL sum_1_6 : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL p2 : Q11_21_array_N;
	SIGNAL p3 : Q11_21_array_N;
	SIGNAL diff : Q11_21_array_N;
	SIGNAL sum_2 : SIGNED(Q21_43.data_width-1 DOWNTO 0);
	SIGNAL w_rnorm : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL dot : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL abs_dot : SIGNED(Q11_21.data_width-1 DOWNTO 0);
	SIGNAL abs_dot_2 : SIGNED(Q11_21.data_width-1 DOWNTO 0);

	CONSTANT EPSILON : SIGNED(Q11_21.data_width-1 DOWNTO 0) := "00000000000000001010001111010111";

BEGIN

	PROCESS(ws0,ws1,w_Q6_10)
	BEGIN
		FOR t IN 0 TO T-1 LOOP
			p1(t) <= ((ws0(t)*w_Q6_10(0)) + (ws1(t)*w_Q6_10(1))) sll 1;
		END LOOP; 
	END PROCESS;

	tanh_gen: FOR t IN 0 TO T-1 GENERATE
		tanh_t: tanh
		PORT MAP(
			--clock => clock,
			--reset => reset,
			p1 => p1(t),
			tp => tp(t)
		);
	END GENERATE;

	sech2_gen: FOR t IN 0 TO T-1 GENERATE
		sech2_t: sech2
		PORT MAP(
			--clock => clock,
			--reset => reset,
			p1 => p1(t),
			sp => sp(t)
		);
	END GENERATE;

	reduce_1: reduction_sum_Q11_21
	PORT MAP(
		summands => sp,
		sum => sum_1
	);

	PROCESS(tp,ws0,ws1)
	BEGIN
		FOR t IN 0 TO T-1 LOOP
			tpws0(t) <= (tp(t) * ws0(t)) sll 1;
			tpws1(t) <= (tp(t) * ws1(t)) sll 1;
		END LOOP; 
	END PROCESS;

	reduce_2: reduction_sum_Q11_21
	PORT MAP(
		summands => tpws0,
		sum => p2(0)
	);

	reduce_3: reduction_sum_Q11_21
	PORT MAP(
		summands => tpws1,
		sum => p2(1)
	);

	sum_1_6 <= (sum_1 srl 12);
	p3(0) <= (sum_1_6(Q6_10.data_width-1 DOWNTO 0) * (w_Q6_10(0) sll 1)) sll 1;
	p3(1) <= (sum_1_6(Q6_10.data_width-1 DOWNTO 0) * (w_Q6_10(1) sll 1)) sll 1;

	diff(0) <= shift_right((p2(0) - p3(0)) , 1);
	diff(1) <= shift_right((p2(1) - p3(1)) , 1);

	sum_2 <= (diff(0)*diff(0) + diff(1)*diff(1)) sll 1; -- "0000000000000011100101000101010010010001000000000000000000000000"; -- for debugging purposes --

	reciprocal_square_root: rsqrt
	PORT MAP(
		sum_2 => sum_2,
		w_rnorm => w_rnorm
	);

	w_next_Q21_43(0) <= (diff(0) * w_rnorm) sll 1;
	w_next_Q21_43(1) <= (diff(1) * w_rnorm) sll 1;

	w_next(0) <= w_next_Q21_43(0) srl 33;
	w_next(1) <= w_next_Q21_43(1) srl 33; 

	w_next_Q6_10(0) <= w_next(0)(Q6_10.data_width-1 DOWNTO 0);
	w_next_Q6_10(1) <= w_next(1)(Q6_10.data_width-1 DOWNTO 0);

	-- convergence check
	PROCESS(w_next_Q6_10, w_Q6_10)
	BEGIN
		dot <= (w_Q6_10(0)*w_next_Q6_10(0) + w_Q6_10(1)*w_next_Q6_10(1)) sll 1; 
		IF (dot < 0) THEN
			abs_dot <= (NOT dot) + 1;
		ELSE
			abs_dot <= dot;
		END IF;

		IF ((abs_dot - "00000000001000000000000000000000") < "00000000000000000000000000000000") THEN
			abs_dot_2 <= "00000000001000000000000000000000" - abs_dot;
		ELSE
			abs_dot_2 <= abs_dot - "00000000001000000000000000000000";
		END IF;

		IF (abs_dot_2 < EPSILON) THEN
			done <= '1';
		ELSE 
			done <= '0';
		END IF;

	END PROCESS;

	PROCESS(clock, reset)
	BEGIN
		IF (reset = '1') THEN
			w_Q6_10(0) <= "1111100110001010";--"1111111111011001"; -- -0.0378 ("random" vector)
			w_Q6_10(1) <= "0000000000001111";--"0000000110011101"; --  0.4038]
			w_Q21_43(0) <= "1111111111111111111111111011001010010101110000000000000000000000";
			w_Q21_43(1) <= "0000000000000000000000110011101011111011010000000000000000000000";
		ELSIF (RISING_EDGE(clock)) THEN
			w_Q6_10 <= w_next_Q6_10;
			w_Q21_43 <= w_next_Q21_43;
		END IF;
	END PROCESS;

	w <= w_Q6_10;

END arch;