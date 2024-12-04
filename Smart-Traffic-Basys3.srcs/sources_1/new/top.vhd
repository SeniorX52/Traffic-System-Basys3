----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/04/2024 04:49:23 PM
-- Design Name: 
-- Module Name: top - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity top is
port(
clk: in std_logic;
reset: in std_logic;
lcd_en: out std_logic ;
lcd_rs: out std_logic ;
lcd_rw: out std_logic ;
lcd_data:out std_logic_vector(3 downto 0);  --D7,D6,D5,D4
echo        : in  STD_LOGIC;                  -- Echo signal from sensor
trigger     : out STD_LOGIC                 -- Trigger signal to sensor
);
end top;

architecture Structural of top is
    signal common_bus: std_logic_vector (63 downto 0);
    component lcd is
        port(
            clk: in std_logic;
            reset: in std_logic;
            en: out std_logic ;
            rs: out std_logic ;
            rw: out std_logic ;
            common_bus: inout std_logic_vector (63 downto 0);
            data:out std_logic_vector(3 downto 0)  --D7,D6,D5,D4
);
    end component ;

    
begin
    lcd_inst: lcd
        port map(
            clk         => clk,               -- Connect top-level clock to LCD clock
            reset       => reset,             -- Connect top-level reset to LCD reset
            en          => lcd_en,            -- Enable signal to top-level port
            rs          => lcd_rs,            -- Register select signal to top-level port
            rw          => lcd_rw,            -- Read/write control to top-level port
            common_bus  => common_bus,        -- Shared common bus signal
            data        => lcd_data           -- Data lines connected to top-level port
        );



end Structural;
