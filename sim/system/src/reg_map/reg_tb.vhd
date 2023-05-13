library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

library procbus;
use procbus.pProc_bus.all;
use procbus.pRegmap.all;

package pReg_tb is

   -- range 1048576 .. 2097151
   --                                                adr      upper    lower    size  default   accesstype)
   constant Reg_ddr3_on            : regmap_type := (1056768,   0,      0,        1,       0,   readwrite); -- on = 1
   
end package;
