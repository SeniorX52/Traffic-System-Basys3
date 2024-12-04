library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity multi_ultrasonic is
    Port (
        clk         : in  STD_LOGIC;                        -- 100 MHz clock
        rst         : in  STD_LOGIC;                        -- Reset signal
        echo_A1     : in  STD_LOGIC;                        -- Echo signal from sensor A1
        echo_A2     : in  STD_LOGIC;                        -- Echo signal from sensor A2
        echo_B1     : in  STD_LOGIC;                        -- Echo signal from sensor B1
        echo_B2     : in  STD_LOGIC;                        -- Echo signal from sensor B2
        trigger     : out STD_LOGIC;                        -- Trigger signal to sensor A1
        buzzer: out std_logic ;
        common_bus: inout std_logic_vector (63 downto 0)
    );
end multi_ultrasonic;

architecture Behavioral of multi_ultrasonic is
    
        signal distance_A1 :  STD_LOGIC_VECTOR(23 downto 0);    -- Distance from sensor A1
        signal distance_A2 :  STD_LOGIC_VECTOR(23 downto 0);    -- Distance from sensor A2
        signal distance_B1 :  STD_LOGIC_VECTOR(23 downto 0);    -- Distance from sensor B1
        signal distance_B2 :  STD_LOGIC_VECTOR(23 downto 0);     -- Distance from sensor B2
        signal traffic: std_logic_vector (7 downto 0);
    -- Component Declaration
    component ultrasonic is
        Port (
            clk         : in  STD_LOGIC;                  -- 100 MHz clock
            rst         : in  STD_LOGIC;                  -- Reset signal
            echo        : in  STD_LOGIC;                  -- Echo signal from sensor
            trigger     : out STD_LOGIC;                  -- Trigger signal to sensor
            distance    : out STD_LOGIC_VECTOR(23 downto 0) -- Distance output
        );
    end component;

begin

    -- Instantiate Ultrasonic Component for A1
    ultrasonic_A1: ultrasonic
        port map (
            clk       => clk,
            rst       => rst,
            echo      => echo_A1,
            trigger   => trigger,
            distance  => distance_A1
        );

    -- Instantiate Ultrasonic Component for A2
    ultrasonic_A2: ultrasonic
        port map (
            clk       => clk,
            rst       => rst,
            echo      => echo_A2,
            trigger   => trigger,
            distance  => distance_A2
        );

    -- Instantiate Ultrasonic Component for B1
    ultrasonic_B1: ultrasonic
        port map (
            clk       => clk,
            rst       => rst,
            echo      => echo_B1,
            trigger   => trigger,
            distance  => distance_B1
        );

    -- Instantiate Ultrasonic Component for B2
    ultrasonic_B2: ultrasonic
        port map (
            clk       => clk,
            rst       => rst,
            echo      => echo_B2,
            trigger   => trigger,
            distance  => distance_B2
        );
    process(clk,rst) is 
    variable distanceA1: integer;
    variable distanceB1: integer;
    variable distanceA2: integer;
    variable distanceB2: integer;
    begin
    distanceA1:=to_integer(unsigned(distance_A1));
    distanceA2:=to_integer(unsigned(distance_A2));
    distanceB1:=to_integer(unsigned(distance_B1));
    distanceB2:=to_integer(unsigned(distance_B2));
    if traffic(7)= '1' and (distanceA1<20 or distanceA2<20) then   --lane a is red
        traffic(5)<='1';
    elsif traffic(6)= '1' and (distanceB1<20 or distanceB2<20) then
        traffic(5)<='1';
    else
        traffic(5)<='0';
    end if;
    end process;
    traffic<=common_bus(47 downto 40);
    buzzer<=traffic(5);
end Behavioral;
