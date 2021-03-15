----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/13/2020 06:22:30 PM
-- Design Name: 
-- Module Name: display7seg - Behavioral
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
use IEEE.std_logic_arith.all;

entity displ7seg is
Port (clk: in std_logic;
      rst:in std_logic;
      data : in  std_logic_vector (31 downto 0); --datele de afisat 
      An   : out STD_LOGIC_VECTOR (7 downto 0); 
      Seg  : out STD_LOGIC_VECTOR (7 downto 0));
end displ7seg;

architecture Behavioral of displ7seg is
function HEX2SSEG (Hex : in STD_LOGIC_VECTOR (3 downto 0))
                  return STD_LOGIC_VECTOR is
   variable Sseg : STD_LOGIC_VECTOR (7 downto 0);
begin
   case Hex is
      when "0000" => Sseg := "11000000";  -- 0 gfedcba
      when "0001" => Sseg := "11111001";  -- 1
      when "0010" => Sseg := "10100100";  -- 2
      when "0011" => Sseg := "10110000";  -- 3
      when "0100" => Sseg := "10011001";  -- 4
      when "0101" => Sseg := "10010010";  -- 5
      when "0110" => Sseg := "10000010";  -- 6
      when "0111" => Sseg := "11111000";  -- 7
      when "1000" => Sseg := "10000000";  -- 8
      when "1001" => Sseg := "10010000";  -- 9
      when "1010" => Sseg := "10001000";  -- A
      when "1011" => Sseg := "10000011";  -- b
      when "1100" => Sseg := "11000110";  -- C
      when "1101" => Sseg := "10100001";  -- d
      when "1110" => Sseg := "10000110";  -- E
      when "1111" => Sseg := "10001110";  -- F
      when others => Sseg := "11111111";
   end case;
   return Sseg;
end function HEX2SSEG;

constant CLK_RATE  : INTEGER := 100_000_000;  -- frecventa semnalului Clk
constant CNT_100HZ : INTEGER := 2**20;        -- divizor pentru rata de
                                              -- reimprospatare de ~100 Hz
signal Count       : INTEGER range 0 to CNT_100HZ - 1 := 0;
--signal BlinkOn     : STD_LOGIC := '0';
signal CountVect   : STD_LOGIC_VECTOR (19 downto 0) := (others => '0');
signal LedSel      : STD_LOGIC_VECTOR (2 downto 0) := (others => '0');
signal Digit1      : STD_LOGIC_VECTOR (7 downto 0) := HEX2SSEG(data(31 downto 28));
signal Digit2      : STD_LOGIC_VECTOR (7 downto 0) := HEX2SSEG(data(27 downto 24));
signal Digit3      : STD_LOGIC_VECTOR (7 downto 0) := HEX2SSEG(data(23 downto 20));
signal Digit4      : STD_LOGIC_VECTOR (7 downto 0) := HEX2SSEG(data(19 downto 16));
signal Digit5      : STD_LOGIC_VECTOR (7 downto 0) := HEX2SSEG(data(15 downto 12));
signal Digit6      : STD_LOGIC_VECTOR (7 downto 0) := HEX2SSEG(data(11 downto 8));
signal Digit7      : STD_LOGIC_VECTOR (7 downto 0) := HEX2SSEG(data(7 downto 4));
signal Digit8      : STD_LOGIC_VECTOR (7 downto 0) := HEX2SSEG(data(3 downto 0));
begin
 div_clk: process (Clk)
   begin
      if RISING_EDGE (Clk) then
         if (Rst = '1') then
            Count <= 0;
         elsif (Count = CNT_100HZ - 1) then
            Count <= 0;
         else
            Count <= Count + 1;
         end if;
      end if;
   end process div_clk;

   CountVect <= CONV_STD_LOGIC_VECTOR (Count, 20);--3 biti semnificativi pt ledsel pentru selectarea cifrei active
   LedSel <= CountVect (19 downto 17);
 An <=  "11111110" when LedSel = "000" else
         "11111101" when LedSel = "001" else
         "11111011" when LedSel = "010" else
         "11110111" when LedSel = "011" else
         "11101111" when LedSel = "100" else
         "11011111" when LedSel = "101" else
         "10111111" when LedSel = "110" else
         "01111111" when LedSel = "111" else
         "11111111";
         
 Seg <=   Digit8 when LedSel = "000" else
          Digit7 when LedSel = "001" else
          Digit6 when LedSel = "010" else
          Digit5 when LedSel = "011" else
          Digit4 when LedSel = "100" else
          Digit3 when LedSel = "101" else
          Digit2 when LedSel = "110" else
          Digit1 when LedSel = "111" else
          x"FF";

end Behavioral;
