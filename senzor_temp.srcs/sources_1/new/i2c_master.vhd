----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/25/2020 08:02:36 PM
-- Design Name: 
-- Module Name: i2c_master - Behavioral
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

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

entity I2C_Master is
    generic(
        input_clk: integer := 100_000_000;
        bus_clk: integer := 400_000); -- < clk maxim al senzor tmp
    port(
    
        Clk: in std_logic;
        Rst: in std_logic;
        Start: in std_logic;
        
        RW: in std_logic;
        Data: in std_logic_vector(7 downto 0);
        Address: in std_logic_vector(6 downto 0);
             
        Finish: out std_logic;
        Request: out std_logic;
        Rdy: out std_logic;
        Ack_Error: out std_logic;
        Data_out: out std_logic_vector(7 downto 0);
        
        SDA: inout std_logic;
        SCL: inout std_logic);
end I2C_Master;

architecture Behavioral of I2C_Master is

    constant divider  :  INTEGER := (input_clk/bus_clk)/4; --number of clocks in 1/4 cycle of scl
    signal data_clk_prev : STD_LOGIC;                      --data clock during previous system clock
    signal data_clk      : STD_LOGIC;                      --data clock for sda
    signal scl_clk       : STD_LOGIC;                      --constantly running internal scl   
    signal stretch       : STD_LOGIC := '0';               --identifies if slave is stretching scl
    
    signal ReadWriteAdr, Read_Write: std_logic := '0';
    signal I2C_Ack_Error: std_logic := '0';
    signal Data_reg: std_logic_vector(7 downto 0):= (others => '0');
    signal ReadWrite_Address: std_logic_vector(7 downto 0):= (others => '0');
    signal Shift_Register: std_logic_vector(7 downto 0):= (others => '0');
    
    signal SelSDA: integer:= 1;
    signal SelSCL: integer := 1;    
    signal cnt_bit: integer;
      
    type states is (ready, start_bit, command, slv_ack1, read, write, slv_ack2, master_ack,stop);
    signal state: states;
begin

PROCESS(clk, rst)
    VARIABLE count  :  INTEGER RANGE 0 TO divider*4;  --timing for clock generation
  BEGIN
    IF(rst = '0') THEN                --reset asserted
      stretch <= '0';
      count := 0;
    ELSIF rising_edge(clk) THEN
      data_clk_prev <= data_clk;          --store previous value of data clock
      IF(count = divider*4-1) THEN        --end of timing cycle
        count := 0;                       --reset timer
      ELSIF(stretch = '0') THEN           --clock stretching from slave not detected
        count := count + 1;               --continue clock generation timing
      END IF;
      CASE count IS
        WHEN 0 TO divider-1 =>            --first 1/4 cycle of clocking
          scl_clk <= '0';
          data_clk <= '0';
        WHEN divider TO divider*2-1 =>    --second 1/4 cycle of clocking
          scl_clk <= '0';
          data_clk <= '1';
        WHEN divider*2 TO divider*3-1 =>  --thiread 1/4 cycle of clocking
          scl_clk <= '1';                 --release scl
          IF(scl = '0') THEN              --detect if slave is stretching clock
            stretch <= '1';
          ELSE
            stretch <= '0';
          END IF;
          data_clk <= '1';
        WHEN OTHERS =>                    --last 1/4 cycle of clocking
          scl_clk <= '1';
          data_clk <= '0';
      END CASE;
    END IF;
  END PROCESS;

--set scl and sda outputs
  scl <= '0' WHEN (SelSCL = 1 AND scl_clk = '0') ELSE 'Z';
  sda <= '0' WHEN SelSDA = 0 ELSE 'Z';


ReadWriteAdr <= ReadWrite_Address(0);

--FSM I2C
process(Clk, Rst)
begin
    if (Rst = '1') then
        state <= ready;
        I2C_Ack_Error <= '0';
    elsif (rising_edge(Clk)) then
        case state is
            when ready =>
                if (data_clk = '1') then
                    if (Start = '1') then
                        state <= start_bit;                       
                        ReadWrite_Address <= Address & RW;
                        Data_reg <=Data;
                    end if;
                end if;
            when start_bit =>
                if (data_clk = '1') then
                    I2C_Ack_Error <= '0';
                    state <= command;
                    cnt_bit <= 7;
                    Shift_Register <= ReadWrite_Address;
                end if;
            when command =>
                if (data_clk = '1') then
                    if (cnt_bit = 0) then
                        state <= slv_ack1;
                    end if;
                    cnt_bit <= cnt_bit - 1;
                    Shift_Register(7 downto 1) <= Shift_Register(6 downto 0);
                    Shift_Register(0) <= SDA;
                end if;
            when slv_ack1 =>
                if (data_clk = '1') then
                    if (SDA /= '0') then
                        I2C_Ack_Error <= '1';
                        state <= stop;
                    else
                        if (ReadWriteAdr = '0') then
                            state <= write;
                            Shift_Register <= Data_reg;
                        else
                            state <= read;
                        end if;
                        cnt_bit <= 7;
                    end if;
                end if;
            when read =>
                if (data_clk = '1') then
                    if (cnt_bit = 0 and Start = '1') then
                        state <= master_ack;
                    else
                        state <= read;
                        cnt_bit <= cnt_bit - 1;
                        Shift_Register(7 downto 1) <= Shift_Register(6 downto 0);
                        Shift_Register(0) <= SDA;
                    end if;
                end if;
            when write =>
                if (data_clk = '1') then
                    if (cnt_bit = 0) then
                        state <= slv_ack2;
                    else
                        state <= write;
                        cnt_bit <= cnt_bit - 1;
                        Shift_Register(7 downto 1) <= Shift_Register(6 downto 0);
                        Shift_Register(0) <= SDA;
                    end if;
                end if;
            when slv_ack2 =>
                if (data_clk = '1') then
                    if (SDA /= '0') then
                        I2C_Ack_Error <= '1';
                        state <= stop;
                    else
                        if (Start = '1') then
                            if (RW = '0' and Address = ReadWrite_Address(7 downto 1)) then
                                state <= write;
                                cnt_bit <= 7;
                                Data_reg <=Data;
                                Shift_Register <=Data;
                            else
                                state <= start_bit;
                                ReadWrite_Address <= Address & RW;
                                Data_reg <= Data;
                            end if;
                        else
                            state <= stop;
                        end if;
                    end if;
                end if;
            when master_ack =>
            if (data_clk = '1') then
                if (Start = '1') then
                    if (RW = '1' and Address = ReadWrite_Address(7 downto 1)) then
                        state <= read;
                        cnt_bit <= 7;
                    else
                        state <= start_bit;
                        ReadWrite_Address <= Address & RW;
                        Data_reg <= Data;
                    end if;
                else
                    state <= stop;
                end if;
            end if;
            when stop =>
                if (data_clk = '1') then
                    state <= ready;
                end if;
            when others =>
                state <= ready;
        end case;
    end if;
end process;

Data_out(7 downto 0) <= Shift_Register(7 downto 0);
Finish <= '1' when (state = slv_ack2) else '0';
Request <= '1' when ((state = read and cnt_bit = 0) or state = slv_ack2) else '0';
Rdy <= '1' when (state = ready) else '0';
Ack_Error <= I2C_Ack_Error;
Read_Write <= '1' when (state = slv_ack1 or state = read or state = slv_ack2) else '0';

SelSCL <= 0 when (state = stop) else
           1 when (state = ready or state = start_bit or state = stop) else 2;
SelSDA <= 0 when (state = start_bit or state = master_ack or state = stop) else 
           1 when (state = ready) else 2;           

end Behavioral;