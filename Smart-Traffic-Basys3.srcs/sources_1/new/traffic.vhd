----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/04/2024 04:49:23 PM
-- Design Name: 
-- Module Name: traffic - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: A traffic control FSM that manages traffic signals for two lanes
--              and their respective left turn indicators.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity traffic is
Port(
        clk      : in std_logic;                           -- Clock input
        rst      : in std_logic;                           -- Reset signal
        Lane_A_Left_LEDs: out std_logic_vector (1 downto 0); -- Left turn LEDs for Lane A (RED, GREEN)
        Lane_B_Left_LEDs: out std_logic_vector (1 downto 0); -- Left turn LEDs for Lane B (RED, GREEN)
        Lane_A_LEDs: out std_logic_vector (2 downto 0);    -- Traffic LEDs for Lane A (RED, YELLOW, GREEN)
        Lane_B_LEDs: out std_logic_vector (2 downto 0);    -- Traffic LEDs for Lane B (RED, YELLOW, GREEN)
        common_bus: inout std_logic_vector (63 downto 0)   -- Shared communication bus
    );
end traffic;

architecture Behavioral of traffic is
    -- State declaration for the FSM
    type t_state is (LANE_A, LANE_B, LEFT_A, LEFT_B, A_TO_B, B_TO_A);
    signal currentState, nextState : t_state := LANE_A; -- Current and next state signals

    -- Counter for timing delays
    signal counter : integer := 0;
    
    -- Timing constants
    constant CLOCK_FREQUENCY : integer := 100_000_000; -- 100 MHz system clock frequency
    constant GREEN_TIME      : integer := CLOCK_FREQUENCY * 15; -- Duration for green light (15 seconds)
    constant LEFT_TIME       : integer := CLOCK_FREQUENCY * 7;  -- Duration for left turn light (7 seconds)
    constant YELLOW_TIME     : integer := CLOCK_FREQUENCY * 3;  -- Duration for yellow light (3 seconds)
begin
    -- Process for state transitions and counter updates
    process(clk, rst)
    begin
        if rst = '1' then
            -- Reset the FSM to the initial state and counter to zero
            currentState <= LANE_A;
            counter <= 0;
        elsif rising_edge(clk) then
            -- Update current state to next state on clock edge
            currentState <= nextState;

            -- Timing logic for each state
            if (currentState = LANE_A) or (currentState = LANE_B) then
                -- Increment counter during green light
                if counter < GREEN_TIME - 1 then
                    counter <= counter + 1;
                else
                    counter <= 0;
                end if;
            elsif (currentState = A_TO_B) or (currentState = B_TO_A) then
                -- Increment counter during yellow light
                if counter < YELLOW_TIME - 1 then
                    counter <= counter + 1;
                else
                    counter <= 0;
                end if;
            elsif (currentState = LEFT_A) or (currentState = LEFT_B) then
                -- Increment counter during left turn light
                if counter < LEFT_TIME - 1 then
                    counter <= counter + 1;
                else
                    counter <= 0;
                end if;
            else
                -- Reset counter for other states
                counter <= 0;
            end if;
        end if;
    end process;

    -- Process for determining next state and output signals
    process(currentState, counter)
    begin
        -- Default output values
        nextState <= currentState;
        Lane_A_Left_LEDs <= "10"; -- Default: Lane A left turn RED
        Lane_B_Left_LEDs <= "10"; -- Default: Lane B left turn RED

        case currentState is
            when LANE_A =>
                -- Lane A has a green light, Lane B is red
                Lane_A_LEDs <= "001"; -- GREEN
                common_bus(47 downto 46) <= "01"; -- Indicate Lane A active
                Lane_B_LEDs <= "100"; -- RED
                if counter = GREEN_TIME - 1 then
                    nextState <= LEFT_A; -- Move to left turn for Lane A
                end if;

            when LEFT_A =>
                -- Lane A left turn green, Lane B is red
                Lane_A_LEDs <= "100"; -- RED
                Lane_B_LEDs <= "100"; -- RED
                common_bus(47 downto 46) <= "11"; -- Indicate both lanes inactive
                Lane_A_Left_LEDs <= "01"; -- GREEN for left turn
                Lane_B_Left_LEDs <= "10"; -- RED for left turn
                if counter = LEFT_TIME - 1 then
                    nextState <= A_TO_B; -- Move to yellow light transition
                end if;

            when A_TO_B =>
                -- Yellow light transition from Lane A to Lane B
                Lane_A_LEDs <= "010"; -- YELLOW
                Lane_B_LEDs <= "010"; -- YELLOW
                common_bus(47 downto 46) <= "00"; -- Indicate no active lane
                if counter = YELLOW_TIME - 1 then
                    nextState <= LANE_B; -- Move to green light for Lane B
                end if;

            when LANE_B =>
                -- Lane B has a green light, Lane A is red
                Lane_B_LEDs <= "001"; -- GREEN
                Lane_A_LEDs <= "100"; -- RED
                common_bus(47 downto 46) <= "10"; -- Indicate Lane B active
                if counter = GREEN_TIME - 1 then
                    nextState <= LEFT_B; -- Move to left turn for Lane B
                end if;

            when LEFT_B =>
                -- Lane B left turn green, Lane A is red
                Lane_A_LEDs <= "100"; -- RED
                Lane_B_LEDs <= "100"; -- RED
                Lane_A_Left_LEDs <= "10"; -- RED for left turn
                Lane_B_Left_LEDs <= "01"; -- GREEN for left turn
                common_bus(47 downto 46) <= "11"; -- Indicate both lanes inactive
                if counter = LEFT_TIME - 1 then
                    nextState <= B_TO_A; -- Move to yellow light transition
                end if;

            when B_TO_A =>
                -- Yellow light transition from Lane B to Lane A
                Lane_A_LEDs <= "010"; -- YELLOW
                Lane_B_LEDs <= "010"; -- YELLOW
                common_bus(47 downto 46) <= "00"; -- Indicate no active lane
                if counter = YELLOW_TIME - 1 then
                    nextState <= LANE_A; -- Move to green light for Lane A
                end if;
        end case;
    end process;
end Behavioral;
