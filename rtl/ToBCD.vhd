library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all; 

entity ToBCD is
   port 
   (
      clk            : in  std_logic;
      
      dataIn         : in  unsigned(31 downto 0) := (others => '0');
      dataOut        : out unsigned(39 downto 0) := (others => '0')
   );
end entity;

architecture arch of ToBCD is
  
   type tState is
   (
      IDLE,
      CALC,
      OUTPUT
   );
   signal state : tState := IDLE;

   signal data       : unsigned(35 downto 0) := (others => '0');
   signal result     : unsigned(39 downto 0) := (others => '0');
   signal position   : integer range 0 to 9;
   
begin 
  
   process (clk)
      variable newData : unsigned(35 downto 0);
   begin
      if rising_edge(clk) then
         
         case (state) is
         
            when IDLE =>
               state    <= CALC;
               data     <= x"0" & dataIn;
               result   <= (others => '0');
               position <= 9;
            
            when CALC =>
               newData := data;
               if    (data >= x"218711A00") then newData := data - x"218711A00"; result(position*4+3 downto position*4) <= x"9";
               elsif (data >= x"1DCD65000") then newData := data - x"1DCD65000"; result(position*4+3 downto position*4) <= x"8";
               elsif (data >= x"1A13B8600") then newData := data - x"1A13B8600"; result(position*4+3 downto position*4) <= x"7";
               elsif (data >= x"165A0BC00") then newData := data - x"165A0BC00"; result(position*4+3 downto position*4) <= x"6";
               elsif (data >= x"12A05F200") then newData := data - x"12A05F200"; result(position*4+3 downto position*4) <= x"5";
               elsif (data >= x"0EE6B2800") then newData := data - x"0EE6B2800"; result(position*4+3 downto position*4) <= x"4";
               elsif (data >= x"0B2D05E00") then newData := data - x"0B2D05E00"; result(position*4+3 downto position*4) <= x"3";
               elsif (data >= x"077359400") then newData := data - x"077359400"; result(position*4+3 downto position*4) <= x"2";
               elsif (data >= x"03B9ACA00") then newData := data - x"03B9ACA00"; result(position*4+3 downto position*4) <= x"1";
               else                                                       result(position*4+3 downto position*4) <= x"0";
               end if;
               
               data <= resize(newData * 10, 36);
                    
               if (position = 0) then
                  state <= OUTPUT;
               else
                  position <= position - 1;
               end if;
               
            when OUTPUT =>
               state <= IDLE;
               dataOut <= result;
         
         end case;
         
      end if;
   end process; 
   
   
end architecture;





