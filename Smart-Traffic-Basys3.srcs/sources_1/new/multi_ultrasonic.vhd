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
        trigger_A1  : out std_logic;
        trigger_A2  : out std_logic;
        trigger_B1  : out std_logic;
        trigger_B2  : out std_logic;
        common_bus  : inout STD_LOGIC_VECTOR(63 downto 0);  -- Shared data bus
        buzzer      : out std_logic                         -- Buzzer output
    );
end multi_ultrasonic;

architecture Behavioral of multi_ultrasonic is
    -- Signals for distances
    signal distance_A1 : STD_LOGIC_VECTOR(23 downto 0);
    signal distance_A2 : STD_LOGIC_VECTOR(23 downto 0);
    signal distance_B1 : STD_LOGIC_VECTOR(23 downto 0);
    signal distance_B2 : STD_LOGIC_VECTOR(23 downto 0);
    constant delay_ms:integer:=100_000;
    constant delay_us:integer:=100;
    -- Constants and internal signals
    signal counter      : integer := 0;
    signal inner_trigger : std_logic;
    signal trig_counter      : integer := 0;
    constant alert_distance : integer := 5;
    constant clk_freq       : integer := 100_000_000;
    signal common_bus2  : STD_LOGIC_VECTOR(63 downto 0);

    signal Lane_A_Red : std_logic;
    signal Lane_B_Red : std_logic;

    -- Component Declaration
    component ultrasonic is
        Port (
            clk         : in  STD_LOGIC;                  -- 100 MHz clock
            rst         : in  STD_LOGIC;                  -- Reset signal
            echo        : in  STD_LOGIC;                  -- Echo signal from sensor
            distance    : out STD_LOGIC_VECTOR(23 downto 0); -- Distance output
            trigger     : out std_logic;
            common_bus  : inout STD_LOGIC_VECTOR(63 downto 0) -- Shared data bus
        );
    end component;

begin
    -- Instantiate Ultrasonic Component for A1
    ultrasonic_A1: ultrasonic
        port map (
            clk       => clk,
            rst       => rst,
            echo      => echo_A1,
            distance  => distance_A1,
            trigger=> trigger_A1,
            common_bus => common_bus
        );

    -- Instantiate Ultrasonic Component for A2
    ultrasonic_A2: ultrasonic
        port map (
            clk       => clk,
            rst       => rst,
            echo      => echo_A2,
            distance  => distance_A2,
            trigger=> trigger_A2,
            common_bus => common_bus2
        );

    -- Instantiate Ultrasonic Component for B1
    ultrasonic_B1: ultrasonic
        port map (
            clk       => clk,
            rst       => rst,
            echo      => echo_B1,
            distance  => distance_B1,
            trigger=> trigger_B1,
            common_bus => common_bus2
        );

    -- Instantiate Ultrasonic Component for B2
    ultrasonic_B2: ultrasonic
        port map (
            clk       => clk,
            rst       => rst,
            echo      => echo_B2,
            distance  => distance_B2,
            trigger=> trigger_B2,
            common_bus => common_bus2
        );

    -- Distance checking process
    process (clk)
        variable distanceA1 : integer;
        variable distanceA2 : integer;
        variable distanceB1 : integer;
        variable distanceB2 : integer;
    begin
        if rising_edge(clk) then
            distanceA1 := to_integer(unsigned(distance_A1));
            distanceA2 := to_integer(unsigned(distance_A2));
            distanceB1 := to_integer(unsigned(distance_B1));
            distanceB2 := to_integer(unsigned(distance_B2));
            if Lane_A_Red = '1' and Lane_B_Red = '1' then
                common_bus(45) <= '0';
            elsif Lane_A_Red = '1' and (distanceA1 < alert_distance or distanceA2 < alert_distance) then
                common_bus(45) <= '1';
            elsif Lane_B_Red = '1' and (distanceB1 < alert_distance or distanceB2 < alert_distance) then
                common_bus(45) <= '1';
            else
                common_bus(45) <= '0';
            end if;
        end if;
    end process;
    
    -- Buzzer control
    process (clk)
    begin
        if rising_edge(clk) then
            if common_bus(45)='1' then   -- 2 seconds
                buzzer <= '1';
            else
                buzzer <= '0';
            end if;
        end if;
    end process;

    -- Assign traffic-related signals
    Lane_A_Red <= common_bus(47);
    Lane_B_Red <= common_bus(46);

end Behavioral;
