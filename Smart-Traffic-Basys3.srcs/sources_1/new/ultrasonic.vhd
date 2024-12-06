----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/04/2024 04:49:23 PM
-- Design Name: 
-- Module Name: ultrasonic - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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
use ieee.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ultrasonic is
Port (
        clk         : in  STD_LOGIC;                  -- 100 MHz clock
        rst         : in  STD_LOGIC;                  -- Reset signal
        echo        : in  STD_LOGIC;                  -- Echo signal from sensor
        distance: out STD_LOGIC_VECTOR(23 downto 0);
        common_bus: inout std_logic_vector (63 downto 0)
    );
end ultrasonic;

architecture Behavioral of ultrasonic is
    type state_type is (WAIT_ECHO, CALC_DISTANCE);
    signal state, next_state : state_type := WAIT_ECHO;
    signal counter    : integer := 0;
    constant clk_freq:integer:=100000000;
    constant speed_of_sound : integer:= 34300;
begin
    -- FSM Process
    process (clk)
    begin 
        if rising_edge(clk) then
            case state is
                when WAIT_ECHO=>
                    if echo='1' then
                        state<=CALC_DISTANCE;
                    end if;
                when CALC_DISTANCE=>
                    if(echo='1') then
                        counter<=counter+1;
                    else
                        distance <= std_logic_vector (TO_UNSIGNED((counter * speed_of_sound) / (2 * clk_freq), 24));
--                        unit:=distance mod 10;
--                        distance:=distance/10;
--                        tenth:=(distance) mod 10;
--                        distance:=distance/10;
--                        hund:=(distance) mod 10;
--                        common_bus(63 downto 56) <= std_logic_vector(to_unsigned(hund+48, 8));
--                        common_bus(55 downto 48) <= std_logic_vector(to_unsigned(tenth+48, 8));
--                        common_bus(47 downto 40) <= std_logic_vector(to_unsigned(unit+48, 8));
                        counter<=0;
                        state<=WAIT_ECHO;
                    end if;

            end case;
        end if;
    end process;




end Behavioral;
