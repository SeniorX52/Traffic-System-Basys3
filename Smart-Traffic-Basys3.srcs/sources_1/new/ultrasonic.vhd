library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ultrasonic is
Port (
    clk         : in  STD_LOGIC;                  -- 100 MHz clock
    rst         : in  STD_LOGIC;                  -- Reset signal
    echo        : in  STD_LOGIC;                  -- Echo signal from sensor
    distance    : out STD_LOGIC_VECTOR(23 downto 0);
    trigger     : out STD_LOGIC;
    common_bus  : inout STD_LOGIC_VECTOR(63 downto 0)
);
end ultrasonic;

architecture Behavioral of ultrasonic is
    type state_type is (WAIT_ECHO, CALC_DISTANCE, TRIGGER_PULSE,IDLE);
    signal state   : state_type := TRIGGER_PULSE;
    signal counter : unsigned(23 downto 0) := (others => '0');
    constant speed_of_sound_scaled : unsigned(23 downto 0) := to_unsigned(34300, 24);
    constant clock_frequency       : unsigned(31 downto 0) := to_unsigned(100_000_000, 32);
    constant time_out              : unsigned(23 downto 0) := to_unsigned(116_618, 24); -- 20 cm
    signal distance_value          : unsigned(23 downto 0) := (others => '0');
    constant delay_ms              : integer := 100_000;
    constant delay_us              : integer := 100;
begin
    process(clk,rst)
        variable distance_var  : unsigned(31 downto 0);
        variable distance_cm   : unsigned(23 downto 0);
        variable unit          : unsigned(7 downto 0);
        variable tenth         : unsigned(7 downto 0);
    begin
        if (rst='1') then
            counter <= (others => '0');
            state<=TRIGGER_PULSE;
        elsif rising_edge(clk) then
            case state is
                when TRIGGER_PULSE =>
                    if counter < to_unsigned(10 * delay_us, 24) then
                        counter <= counter + 1;
                        trigger <= '1';
                    else
                        trigger <= '0';
                        counter <= (others => '0');
                        state <= WAIT_ECHO;
                    end if;

                when WAIT_ECHO =>
                    if echo = '1' then
                        counter <= (others => '0');
                        state <= CALC_DISTANCE;
                    elsif counter < to_unsigned(50 * delay_ms, 24) then  
                        counter <= counter + 1;
                    else
                        state<= TRIGGER_PULSE;
                        counter <= (others => '0');
                    end if;
                when CALC_DISTANCE =>
                    if echo = '1' and counter < time_out then
                        counter <= counter + 1;
                    else
                        distance_var := resize((counter * speed_of_sound_scaled) / (2 * clock_frequency), 32);
                        distance_cm := resize(distance_var, 24);

                        distance_value <= distance_cm;
                        distance <= std_logic_vector(distance_cm);

                        unit := resize(distance_cm mod 10, 8);
                        tenth := resize((distance_cm / 10) mod 10, 8);
                        common_bus(63 downto 56) <= std_logic_vector(tenth + 48);
                        common_bus(55 downto 48) <= std_logic_vector(unit + 48);
                        counter <= (others => '0');
                        state <= IDLE;
                    end if;
             when IDLE=>
                if counter <to_unsigned(45 * delay_ms, 24) then
                    counter <= counter + 1;
                else
                    counter <= (others => '0');
                    state<=TRIGGER_PULSE;
                end if;
            end case;
        end if;
    end process;
end Behavioral;
