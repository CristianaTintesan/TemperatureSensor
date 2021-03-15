----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/12/2020 08:17:40 PM
-- Design Name: 
-- Module Name: i2c_slave - Behavioral
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

entity temp_controller is
    generic(
        input_clk: integer := 100_000_000);
    port(
        Clk: in std_logic;
        Rst: in std_logic;
        Start: in std_logic;
        
        Slave_Address: in std_logic_vector(6 downto 0);
        Address_Register: in std_logic_vector(7 downto 0);
        
        Data: out std_logic_vector(15 downto 0);
        Busy: out std_logic;
        Error: out std_logic;
        
        SDA: inout std_logic;
        SCL: inout std_logic);
end temp_controller;

architecture Behavioral of temp_controller is
    constant i2c_bus: integer := 100_000;

    signal Slave_Register: std_logic_vector(6 downto 0) := (others => '0');
    signal Data_Register: std_logic_vector(15 downto 0):= (others => '0');
    signal FirstRegister: std_logic_vector(7 downto 0):= (others => '0');
    signal AddressRegister: std_logic_vector(7 downto 0):= (others => '0');
    signal Temp_Controller_Start: std_logic := '0';
    signal Temp_Controller_DataIn: std_logic_vector(7 downto 0):= (others => '0');
    signal Temp_Controller_Address: std_logic_vector(6 downto 0):= (others => '0');
    signal Temp_Controller_RW: std_logic := '0';
    signal Temp_Controller_DataOut: std_logic_vector(7 downto 0):= (others => '0');
    signal Temp_Controller_Finish: std_logic := '0' ;
    signal Temp_Controller_AckErr: std_logic := '0';
    signal Temp_Controller_Rdy: std_logic := '0';
    signal Temp_Controller_Request: std_logic := '0';
      
    type states is (init, ready, start1, data1, start2, data2, ack_error);
    signal state: states;
begin

I2C:entity WORK.I2C_Master generic map (
       input_clk => input_clk,
       bus_clk => i2c_bus)
    port map(
       Clk => Clk, 
       Rst => Rst,
       Start => Temp_Controller_Start,
       
       RW => Temp_Controller_RW,
       Data =>Temp_Controller_DataIn,
       Address => Temp_Controller_Address,
        
       Finish => Temp_Controller_Finish,
       Request => Temp_Controller_Request,
       Rdy => Temp_Controller_Rdy,
       Ack_Error => Temp_Controller_AckErr,
       Data_out => Temp_Controller_DataOut,
       
       SDA => SDA,
       SCL => SCL);
   


process(Clk, Rst)
begin
    if (Rst = '1') then
        state <= init;
        Data_Register <= (others => '0');
    elsif (rising_edge(Clk)) then 
        if (Temp_Controller_AckErr = '1') then
            state <= ack_error;
        else
            case state is
                when init =>
                    if (Start = '1') then
                        state <= ready;
                        Slave_Register <= Slave_Address;
                        AddressRegister <= Address_Register;
                    end if;
                when ready =>
                    if (Temp_Controller_Rdy = '1') then
                        state <= start1;
                    end if;
                when start1 =>
                    if (Temp_Controller_Request = '1') then
                        state <= data1;
                    else
                        state <= start1;
                    end if;                       
                when data1 =>
                    if (Temp_Controller_Finish = '1' and Temp_Controller_Request = '0') then
                        state <= start2;
                        FirstRegister <= Temp_Controller_DataOut;
                    end if;
                when start2 =>
                    if (Temp_Controller_Request = '1') then
                        state <= data2;
                    end if;
                when data2 =>
                    if (Temp_Controller_Finish = '1' and Temp_Controller_Request = '0') then
                        state <= init;
                        Data_Register <= FirstRegister & Temp_Controller_DataOut;
                    end if;
                when ack_error =>
                    if (Temp_Controller_Rdy = '1') then
                        state <= init;
                    end if;
                when others =>
                    state <= init;
            end case;
        end if;
    end if;    
end process;

Data(8 downto 0) <= Data_Register(15 downto 7);  -- /128 pentru conversie temperatura            
                                            -- shiftare 7 biti la dreapta
Error <= Temp_Controller_AckErr;
Busy <= '0' when (state <= init) else '1';
Data <= Data_Register;                                	                
Temp_Controller_DataIn <= AddressRegister when (state = start1) else "00000000";
Temp_Controller_Address <= Slave_Register when (state = start1 or state = data1) else "0000000";
Temp_Controller_RW <= '0' when (state = start1) else '1';
Temp_Controller_Start <= '1' when (state = start1 or state = data1) else '0';

end Behavioral;