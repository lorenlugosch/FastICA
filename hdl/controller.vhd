-- Loren Lugosch
-- ECSE 682 project
-- 
-- controller.vhd

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE work.parameters.all;

ENTITY controller IS
	PORT (
		clock : IN STD_LOGIC;
		reset : IN STD_LOGIC;
		converged : IN STD_LOGIC;
		start : IN STD_LOGIC;
		ws_select : OUT STD_LOGIC; -- 0 - external, 1 - from RAM
		RAM_address : OUT INTEGER RANGE 0 TO T - 1;
		valid_w : OUT STD_LOGIC;
		valid_p1 : OUT STD_LOGIC;
		RAM_we : OUT STD_LOGIC;
		rotation_start : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE arch OF controller IS

	CONSTANT rotation_latency : INTEGER := T + 5;--rotation_pipeline_depth;
	CONSTANT normalization_latency : INTEGER := rotation_latency + 5;--normalization_pipeline_depth;

	SIGNAL counter : INTEGER RANGE 0 TO 100;--normalization_latency;
	SIGNAL address: INTEGER RANGE 0 TO T - 1;

	TYPE state_type IS (ready, rotating_start, rotating_start_first_iteration, rotating_first_iteration, rotating, rotating_done, normalizing, normalizing_done, done);
	SIGNAL state : state_type;

BEGIN

	RAM_address <= address;

	-- outputs
	PROCESS(state)
	BEGIN
		CASE state IS
			WHEN ready => 
				ws_select <= '0';
				valid_w <= '0';
				valid_p1 <= '0';
				RAM_we <= '0';
				rotation_start <= '0';

			WHEN rotating_start_first_iteration => 
				ws_select <= '0';
				valid_w <= '0';
				valid_p1 <= '0';
				RAM_we <= '1';
				rotation_start <= '1';

			WHEN rotating_start => 
				ws_select <= '1';
				valid_w <= '0';
				valid_p1 <= '0';
				RAM_we <= '1';
				rotation_start <= '1';

			WHEN rotating_first_iteration =>
				ws_select <= '0';
				valid_w <= '0';
				valid_p1 <= '0';
				RAM_we <= '1';
				rotation_start <= '0';
			
			WHEN rotating =>
				ws_select <= '1';
				valid_w <= '0';
				valid_p1 <= '0';
				RAM_we <= '0';
				rotation_start <= '0';

			WHEN rotating_done => 
				ws_select <= '1';
				valid_w <= '1';
				valid_p1 <= '0';
				RAM_we <= '0';
				rotation_start <= '0';
			
			WHEN normalizing =>
				ws_select <= '1';
				valid_w <= '0';
				valid_p1 <= '0';
				RAM_we <= '0';
				rotation_start <= '0';

			WHEN normalizing_done => 
				ws_select <= '1';
				valid_w <= '0';
				valid_p1 <= '1';
				RAM_we <= '0';
				rotation_start <= '0';

			when done => 
				ws_select <= '1';
				valid_w <= '0';
				valid_p1 <= '0';
				RAM_we <= '0';
				rotation_start <= '0';
			  
		END CASE;
	END PROCESS;

	-- state transitions
	PROCESS(clock, reset)
	BEGIN
		IF (reset = '1') THEN
			counter <= 0;
			state <= ready;
			address <= 0;
		ELSIF (rising_edge(clock)) THEN
			CASE state IS
				WHEN ready => 
					IF (start = '1') THEN
						state <= rotating_start_first_iteration;
					END IF;

				WHEN rotating_start_first_iteration =>
					state <= rotating_first_iteration;

				WHEN rotating_first_iteration =>
					IF (converged = '1') THEN
						state <= done;
						counter <= 0;
						address <= 0;
					ELSIF (counter = rotation_latency) THEN
						counter <= counter + 1;
						state <= rotating_done;
						address <= address;
					ELSIF (counter >= T-1) THEN
						counter <= counter + 1;
						state <= rotating_first_iteration;
						address <= address;
					ELSE
						counter <= counter + 1;
						state <= rotating_first_iteration;
						address <= address + 1;
					END IF;

				WHEN rotating_start =>
					state <= rotating;
				
				WHEN rotating =>
					IF (converged = '1') THEN
						state <= done;
						counter <= 0;
						address <= 0;
					ELSIF (counter = rotation_latency) THEN
						counter <= counter + 1;
						state <= rotating_done;
						address <= address;
					ELSIF (counter >= T-1) THEN
						counter <= counter + 1;
						state <= rotating;
						address <= address;
					ELSE
						counter <= counter + 1;
						state <= rotating;
						address <= address + 1;
					END IF;

				WHEN rotating_done =>
					IF (converged = '1') THEN
						state <= done;
						counter <= 0;
						address <= 0;
					ELSE
						counter <= counter + 1;
						state <= normalizing;
						address <= address;
					END IF;
					
				
				WHEN normalizing =>
					IF (converged = '1') THEN
						state <= done;
						counter <= 0;
						address <= 0;
					ELSIF (counter = normalization_latency) THEN
						counter <= counter + 1;
						state <= normalizing_done;
						address <= address;
					ELSE
						counter <= 0;
						state <= normalizing;
						address <= address;
					END IF;

				WHEN normalizing_done =>
					IF (converged = '1') THEN
						state <= done;
						counter <= 0;
						address <= 0;
					ELSE
						counter <= 0;
						state <= rotating;
						address <= 0;
					END IF;

				when done => 
					state <= done;
					counter <= 0;
					address <= address;
				  
			END CASE;
		END IF;
	END PROCESS;

END arch;