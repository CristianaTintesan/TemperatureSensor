----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/25/2020 08:42:03 PM
-- Design Name: 
-- Module Name: main - Behavioral
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

entity main is
   port
   (    Clk: in std_logic;
        Rst: in std_logic;
        Busy: out std_logic;
        Error: out std_logic;
        Seg: out std_logic_vector( 7 downto 0);
        An: out std_logic_vector( 7 downto 0);
        SDA: inout std_logic;
        SCL: inout std_logic
   
   );
      

end main;

architecture Behavioral of main is

signal start: std_logic := '0';
signal temperature: std_logic_vector(15 downto 0) := (others => '0');
signal dataSSD: std_logic_vector(31 downto 0);

begin


sensor_temperature: entity WORK.temp_Controller port map (
                            Clk => Clk,
                            Rst => Rst,
                            Start => start,
                            
                            Slave_Address => "1001011",
                            Address_Register => "00000000",
                            
                            Data =>temperature,
                            Busy => busy,
                            Error => error,
                            SDA => SDA,
                            SCL => SCL);
                            
ssd: entity WORK.displ7seg port map(
            Clk => clk,
            Rst => rst,
            Data => dataSSD,
            Seg => Seg,
            An => An);
                                
dataSSD<= x"0000" & temperature;

end Behavioral;
