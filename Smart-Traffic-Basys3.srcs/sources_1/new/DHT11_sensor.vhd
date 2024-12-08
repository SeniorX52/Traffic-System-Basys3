library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Entity declaration for the DHT11 sensor interface
entity DHT11_sensor is
Port (
    clk: in std_logic;                   -- Input clock signal
    dht_data: inout std_logic;           -- Bidirectional data line for DHT11 communication
    common_bus: inout std_logic_vector(63 downto 0)
);
end DHT11_sensor;

-- Architecture definition
architecture Behavioral of DHT11_sensor is

-- State enumeration for the FSM (Finite State Machine)
type t_state is (zero_state,start_delay, start_down_state,start_up_state, waitResponse_state, readData_state, process_state,assign_output_state);
signal currentState, nextState: t_state := zero_state; -- Current and next states

-- Internal signals
signal tick: integer := 0;               -- Counter for timing delays
signal data: std_logic_vector(39 downto 0) := (others => '0'); -- Stores 40-bit received data
signal dht_data_out: std_logic := '0';  -- Output signal to drive the DHT11 data line
signal dht_data_dir: std_logic := '0';  -- Direction control: 0=input (DHT controls), 1=output (MCU sends)
signal index: integer := 0;             -- Index for storing bits during data reception
signal checksum_received: std_logic_vector(7 downto 0); -- Checksum from DHT11
signal checksum_calculated: std_logic_vector(7 downto 0); -- Checksum calculated from data
signal temp_sum: unsigned(9 downto 0);  -- Temporary sum for checksum calculation
signal flag: boolean := false;
signal s_TEMPERATURE: unsigned(7 downto 0); -- Output: Temperature integer part
signal s_HUMIDITY: std_logic_vector(7 downto 0);    -- Output: Humidity integer part
signal s_readyFlag:  std_logic;            -- Output: Indicates valid data is ready
signal s_TEMPERATURE_DEC: std_logic_vector(7 downto 0); -- Output: Temperature decimal part
begin

-- Tri-state buffer for DHT data line
-- Drives dht_data_out when direction is output (dht_data_dir = '1')
-- Sets line to high-impedance ('Z') otherwise
dht_data <= dht_data_out when dht_data_dir = '1' else 'Z';

-- Main process for the FSM
process(clk, currentState) is
variable temperature_ten : unsigned(7 downto 0);
variable temperature_unit : unsigned(7 downto 0);
begin 

    if (clk = '1' and clk'event) then -- Rising edge of the clock
        case (currentState) is

            -- Initial state: Reset outputs and prepare to start communication
            when zero_state =>
                s_readyFlag <= '0';        -- Data not ready
                tick <= 0;               -- Reset counter
                s_temperature<="00000000";
                s_temperature_dec<="00000000";
                s_humidity<="00000000";
                currentState <= start_down_state;

            -- Start state: Hold data line low for 18ms to initiate DHT11 communication
            when start_delay =>
                if(tick < 100000000) then
                    tick <= tick + 1;
                else
                    dht_data_dir <= '1';
                    currentState <= start_down_state;
                end if;                
            when start_down_state =>
                
                if (tick < 1800000) then  -- 18ms delay (assuming 100MHz clock)
                    tick <= tick + 1;
                else 
                    dht_data_out <= '1'; -- Release data line
                    tick <= 0;
                    currentState <= start_up_state;
                 end if;
             when start_up_state =>   
                if tick < 2000 then
                    tick <= tick + 1;
                else
                     tick <= 0;
                     dht_data_dir <= '0';  
                     currentState <= waitResponse_state;
                end if;

            -- Wait for DHT11's response
            when waitResponse_state =>
                if (tick < 8000) then -- Wait for low phase of 80탎
                    if (dht_data = '0') then
                        tick <= tick + 1;
                    else
                        tick <= tick;
                    end if;
                elsif (tick>= 8000) and (tick < 16000) then -- Check high phase
                    if dht_data = '1' then
                        tick <= tick + 1;
                    else 
                        tick <= tick;
                    end if;
                elsif tick = 16000 then -- High phase completed (160탎 total)
                        tick <= 0;
                        currentState <= readData_state;
                end if;

            -- Read 40 bits of data from the DHT11
            when readData_state =>
                if (tick < 5000) and (dht_data = '0') then -- Wait for low pulse (50탎)
                    tick <= tick + 1;
                elsif (tick >= 5000) and  (dht_data = '1') then -- High pulse detection
                    tick <= tick + 1;
                    --if tick > 5000 and tick < 7800 then -- 50-78탎 indicates a '0'
                 elsif (tick > 5000) and (dht_data = '0') then
                    flag <= true;
                 end if;
                 if (dht_data='0') and (tick<=7800) and (flag) then
                        data(index) <= '0'; -- Store bit '0'
                        index <= index + 1; 
                        tick <= 0; 
                        flag <= false;
                 elsif (dht_data = '0') and (tick>7800) and (tick<=12000) and (flag) then
                        data(index) <= '1' ;
                        index<=index + 1;
                        tick <= 0; 
                        flag <= false;
                 end if;
                       -- tick <= 0;           -- Reset counter
                   -- elsif tick >= 7000 then -- >70탎 indicates a '1'
                     --   data(index) <= '1'; -- Store bit '1'
                       -- index <= index + 1;
                        --tick <= 0;           -- Reset counter
                    if index = 40 then -- All 40 bits received
                        tick <= 0;
                        index <= 0;         -- Reset index for next cycle
                        currentState <= process_state;
                    end if;


            -- Process received data
            when process_state =>
                checksum_received <= data(39 downto 32); -- Extract humidity integer part
                s_temperature_dec <= data(31 downto 24); -- Extract temperature integer part
                s_temperature <= unsigned(data(23 downto 16)); -- Extract temperature decimal part
                s_humidity <= data(7 downto 0); -- Extract checksum

                -- Calculate checksum (not used in this simplified version)
                temp_sum <="0000000000" + unsigned(data(39 downto 32)) + 
                            unsigned(data(31 downto 24)) + 
                            unsigned(data(23 downto 16)) + 
                            unsigned(data(15 downto 8));
                checksum_calculated <= std_logic_vector(temp_sum(7 downto 0));
                if (checksum_calculated = checksum_received) then
                                       s_readyFlag <= '1';  -- Set ready flag (assume data is valid for now)
                                   else
                                       s_readyFlag <= '0'; -- Data is invalid
                                   end if;
                                  
                                   currentState <= assign_output_state; -- Return to initial state for next cycle
            when assign_output_state =>
                temperature_ten := s_temperature / 10 mod 10;
                temperature_unit := s_temperature mod 10;
                
                --common_bus(63 downto 56) <= std_logic_vector(temperature_ten + 48);
                --common_bus(55 downto 48) <= std_logic_vector(temperature_unit + 48); 
                currentState <= zero_state;
                
            -- Default case: Return to initial state
            when others =>
                currentState <= zero_state;
        end case;
    end if;
end process;

--process(currentState)
--begin
--   case (currentState) is 
--      when zero_state =>
--         if dht_data_dir = '1' then
--            dht_data <= dht_data_out;
--          else 
--            dht_data <= 'Z';
--          end if;
--      when start_down_state =>
--          if dht_data_dir = '1' then
--              dht_data <= dht_data_out;
--          else 
--              dht_data <= 'Z';
--          end if;
--       when others =>
--           temperature<="00000000";
--           temperature_dec<="00000000";
--           humidity<="00000000";
--      end case;
-- end process;      
end Behavioral;