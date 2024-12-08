----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/04/2024 04:49:23 PM
-- Design Name: 
-- Module Name: top - Structural
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

entity top is
    port(
        clk               : in std_logic;                     -- System clock
        reset             : in std_logic;                     -- Reset signal
        lcd_en            : out std_logic;                    -- LCD enable
        lcd_rs            : out std_logic;                    -- LCD register select
        lcd_rw            : out std_logic;                    -- LCD read/write control
        lcd_data          : out std_logic_vector(3 downto 0); -- LCD data lines
        echo_A1           : in std_logic;                     -- Echo signal from sensor A1
        echo_A2           : in std_logic;                     -- Echo signal from sensor A2
        echo_B1           : in std_logic;                     -- Echo signal from sensor B1
        echo_B2           : in std_logic;                     -- Echo signal from sensor B2
        dht_data    : inout std_logic;
        trigger_A1  : out std_logic;
        trigger_A2  : out std_logic;
        trigger_B1  : out std_logic;
        trigger_B2  : out std_logic;
        buzzer            : out std_logic;                    -- Buzzer output
        Lane_A_Left_LEDs  :out std_logic; 
        Lane_B_Left_LEDs  : out std_logic;
        Lane_A_LEDs       : out std_logic_vector(2 downto 0); -- Traffic LEDs for Lane A (RED, YELLOW, GREEN)
        Lane_B_LEDs       : out std_logic_vector(2 downto 0)  -- Traffic LEDs for Lane B (RED, YELLOW, GREEN)
    );
end top;

architecture Structural of top is
    signal common_bus: std_logic_vector (63 downto 0); -- Shared communication bus

    -- Component declarations
    component lcd is
        port(
            clk         : in std_logic;
            reset       : in std_logic;
            en          : out std_logic;
            rs          : out std_logic;
            rw          : out std_logic;
            common_bus  : inout std_logic_vector(63 downto 0);
            data        : out std_logic_vector(3 downto 0)
        );
    end component;

    component multi_ultrasonic is
        port(
            clk         : in std_logic;                        -- 100 MHz clock
            rst         : in std_logic;                        -- Reset signal
            echo_A1     : in std_logic;                        -- Echo signal from sensor A1
            echo_A2     : in std_logic;                        -- Echo signal from sensor A2
            echo_B1     : in std_logic;                        -- Echo signal from sensor B1
            echo_B2     : in std_logic;                        -- Echo signal from sensor B2
            trigger_A1  : out std_logic;
            trigger_A2  : out std_logic;
            trigger_B1  : out std_logic;
            trigger_B2  : out std_logic;
            buzzer      : out std_logic;                       -- Buzzer signal
            common_bus  : inout std_logic_vector(63 downto 0)
        );
    end component;
    
    component DHT11_sensor is
        port(
            clk         : in std_logic;
            dht_data: inout std_logic;
            common_bus: inout std_logic_vector(63 downto 0)
        );
     end component;


    component traffic is
        port(
            clk               : in std_logic;
            rst               : in std_logic;
            Lane_A_Left_LEDs  : out std_logic; -- Left Turn LEDs for Lane A (RED, GREEN)
            Lane_B_Left_LEDs  : out std_logic;-- Left Turn LEDs for Lane B (RED, GREEN)
            Lane_A_LEDs       : out std_logic_vector(2 downto 0); -- Traffic LEDs for Lane A (RED, YELLOW, GREEN)
            Lane_B_LEDs       : out std_logic_vector(2 downto 0); -- Traffic LEDs for Lane B (RED, YELLOW, GREEN)
            common_bus        : inout std_logic_vector(63 downto 0) -- Shared communication bus
        );
    end component;

begin
    -- Instantiate the LCD component
    lcd_inst: lcd
        port map(
            clk         => clk,
            reset       => reset,
            en          => lcd_en,
            rs          => lcd_rs,
            rw          => lcd_rw,
            common_bus  => common_bus,
            data        => lcd_data
        );

    -- Instantiate the Multi-Ultrasonic component
    ultrasonic_inst: multi_ultrasonic
        port map(
            clk         => clk,
            rst         => reset,
            echo_A1     => echo_A1,
            echo_A2     => echo_A2,
            echo_B1     => echo_B1,
            echo_B2     => echo_B2,
            trigger_A1  => trigger_A1,
            trigger_A2  => trigger_A2,
            trigger_B1  => trigger_B1,
            trigger_B2  => trigger_B2,
            buzzer      => buzzer,
            common_bus  => common_bus
        );
    Dht_inst: DHT11_sensor
        port map(
            clk         => clk,
            dht_data    => dht_data,
            common_bus  => common_bus
        );
    -- Instantiate the Traffic component
    traffic_inst: traffic
        port map(
            clk               => clk,
            rst               => reset,
            Lane_A_Left_LEDs  => Lane_A_Left_LEDs,
            Lane_B_Left_LEDs  => Lane_B_Left_LEDs,
            Lane_A_LEDs       => Lane_A_LEDs,
            Lane_B_LEDs       => Lane_B_LEDs,
            common_bus        => common_bus
        );

end Structural;
