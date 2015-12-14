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
		RAM_address : OUT INTEGER RANGE 0 TO T - 1;
		valid_w : OUT STD_LOGIC;
		valid_p1 : OUT STD_LOGIC;
		RAM_we : OUT STD_LOGIC;
		first_iteration : OUT STD_LOGIC;
		rotation_start_token : OUT STD_LOGIC;
		rotation_end_token : OUT STD_LOGIC;
		normalization_start_token : OUT STD_LOGIC;
		normalization_end_token : OUT STD_LOGIC
	);
END ENTITY;

ARCHITECTURE arch OF controller IS
	CONSTANT rotation_pipeline_offset : INTEGER := -1;
	CONSTANT rotation_latency : INTEGER := T + rotation_pipeline_offset;
	CONSTANT normalization_pipeline_offset : INTEGER := 5;
	CONSTANT normalization_latency : INTEGER := rotation_latency + normalization_pipeline_offset;

	SIGNAL counter : INTEGER RANGE 0 TO 100;--normalization_latency;
	SIGNAL address: INTEGER RANGE 0 TO T - 1;

	TYPE state_type IS (
		ready, 
		rotating_start,
		rotating, 
		rotating_done, 
		normalizing_start,
		normalizing, 
		normalizing_done, 
		done
	);
	SIGNAL state : state_type;

BEGIN

	RAM_address <= address;

	-- outputs
	PROCESS(state)
	BEGIN
		CASE state IS
			WHEN ready => 
				valid_w <= '0';
				valid_p1 <= '0';
				RAM_we <= '0';
				rotation_start_token <= '0';
				rotation_end_token <= '0';
				normalization_start_token <= '0';
				normalization_end_token <= '0';

			WHEN rotating_start => 
				valid_w <= '0';
				valid_p1 <= '0';
				RAM_we <= '1';
				rotation_start_token <= '1';
				rotation_end_token <= '0';
				normalization_start_token <= '0';
				normalization_end_token <= '0';
			
			WHEN rotating =>
				valid_w <= '0';
				valid_p1 <= '0';
				RAM_we <= '0';
				rotation_start_token <= '0';
				rotation_end_token <= '0';
				normalization_start_token <= '0';
				normalization_end_token <= '0';

			WHEN rotating_done => 
				valid_w <= '0';
				valid_p1 <= '0';
				RAM_we <= '0';
				rotation_start_token <= '0';
				rotation_end_token <= '1';
				normalization_start_token <= '0';
				normalization_end_token <= '0';

			WHEN normalizing_start =>
				valid_w <= '0';
				valid_p1 <= '0';
				RAM_we <= '0';
				rotation_start_token <= '0';
				rotation_end_token <= '1';
				normalization_start_token <= '1';
				normalization_end_token <= '0';
			
			WHEN normalizing =>
				valid_w <= '0';
				valid_p1 <= '0';
				RAM_we <= '0';
				rotation_start_token <= '0';
				rotation_end_token <= '1';
				normalization_start_token <= '0';
				IF (counter = normalization_latency-2) THEN
					normalization_end_token <= '1';
				ELSE 
					normalization_end_token <= '0';
				END IF;

			WHEN normalizing_done => 
				valid_w <= '1';
				valid_p1 <= '1';
				RAM_we <= '0';
				rotation_start_token <= '0';
				rotation_end_token <= '1';
				normalization_start_token <= '0';
				normalization_end_token <= '0';

			when done => 
				valid_w <= '0';
				valid_p1 <= '0';
				RAM_we <= '0';
				rotation_start_token <= '0';
				rotation_end_token <= '1';
				normalization_start_token <= '0';
				normalization_end_token <= '0';
			  
		END CASE;
	END PROCESS;

	-- state transitions
	PROCESS(clock, reset)
	BEGIN
		IF (reset = '1') THEN
			counter <= 0;
			state <= ready;
			address <= 0;
			first_iteration <= '1';
		ELSIF (rising_edge(clock)) THEN
			CASE state IS
				WHEN ready => 
					IF (start = '1') THEN
						state <= rotating_start;
					END IF;
				WHEN rotating_start =>
					counter <= counter + 1;
					state <= rotating;
					address <= address + 1;
				
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
						state <= normalizing_start;
						address <= address;
					END IF;
				
				WHEN normalizing_start =>
					IF (converged = '1') THEN
						state <= done;
						counter <= 0;
						address <= 0;
					ELSIF (counter = normalization_latency) THEN
						counter <= counter + 1;
						state <= normalizing_done;
						address <= address;
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
						counter <= counter + 1;
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
						state <= rotating_start;
						address <= 0;
						first_iteration <= '0';
					END IF;

				when done => 
					state <= done;
					counter <= 0;
					address <= address;
				  
			END CASE;
		END IF;
	END PROCESS;

END arch;