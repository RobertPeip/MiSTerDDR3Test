library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     
library STD;    
use STD.textio.all;

library tb;
library ddr3test;

library procbus;
use procbus.pProc_bus.all;
use procbus.pRegmap.all;

library reg_map;
use reg_map.pReg_tb.all;

entity etb  is
end entity;

architecture arch of etb is

   constant clk_speed : integer := 100000000;
   constant baud      : integer := 25000000;
 
   signal clk33       : std_logic := '1';
   signal clk100      : std_logic := '1';
   signal clkvid      : std_logic := '1';
   
   signal reset       : std_logic := '1';
   signal pause       : std_logic := '0';
   
   signal command_in  : std_logic;
   signal command_out : std_logic;
   signal command_out_filter : std_logic;
   
   signal proc_bus_in : proc_bus_type;
   
   -- ddrram
   signal DDRAM_CLK           : std_logic;
   signal DDRAM_BUSY          : std_logic;
   signal DDRAM_BURSTCNT      : std_logic_vector(7 downto 0);
   signal DDRAM_ADDR          : std_logic_vector(28 downto 0);
   signal DDRAM_DOUT          : std_logic_vector(63 downto 0);
   signal DDRAM_DOUT_READY    : std_logic;
   signal DDRAM_RD            : std_logic;
   signal DDRAM_DIN           : std_logic_vector(63 downto 0);
   signal DDRAM_BE            : std_logic_vector(7 downto 0);
   signal DDRAM_WE            : std_logic;
   
   -- video
   signal hblank              : std_logic;
   signal vblank              : std_logic;
   signal video_ce            : std_logic;
   signal video_r             : std_logic_vector(7 downto 0);
   signal video_g             : std_logic_vector(7 downto 0);
   signal video_b             : std_logic_vector(7 downto 0);
   
begin

   clk33  <= not clk33  after 15 ns;
   clk100 <= not clk100 after 5 ns;
   
   reset  <= '0' after 1 us;
   
   -- NTSC 53.693175 mhz => 30 ns * 33.8688 / 53.693175 / 2 = 9.4617612014 ns
   clkvid <= not clkvid after 9462 ps;     
   
   pause <= '0';
   --pause <= not pause after 1 ms;

   iddr3_mister : entity ddr3test.ddr3_mister
   port map
   (
      clk                   => clk33,          
      clkvid                => clkvid,
      reset                 => reset,
      pause                 => '0',
      
      ADDRMODE              => "01",
      BURSTCNT              => "010",
      WRITEMODE             => '0',
                            
      ddr3_BUSY             => DDRAM_BUSY,
      ddr3_DOUT             => DDRAM_DOUT,
      ddr3_DOUT_READY       => DDRAM_DOUT_READY,
      ddr3_BURSTCNT         => DDRAM_BURSTCNT,
      ddr3_ADDR             => DDRAM_ADDR,
      ddr3_DIN              => DDRAM_DIN,
      ddr3_BE               => DDRAM_BE,
      ddr3_WE               => DDRAM_WE,
      ddr3_RD               => DDRAM_RD,
                            
      video_hsync           => open,
      video_vsync           => open,
      video_hblank          => hblank,
      video_vblank          => vblank,
      video_ce              => video_ce,
      video_r               => video_r, 
      video_g               => video_g,    
      video_b               => video_b
   );
   
   iddrram_model : entity tb.ddrram_model
   generic map
   (
      SLOWTIMING   => 40,
      RANDOMTIMING => '1' 
   )
   port map
   (
      DDRAM_CLK        => clk33,      
      DDRAM_BUSY       => DDRAM_BUSY,      
      DDRAM_BURSTCNT   => DDRAM_BURSTCNT,  
      DDRAM_ADDR       => DDRAM_ADDR,      
      DDRAM_DOUT       => DDRAM_DOUT,      
      DDRAM_DOUT_READY => DDRAM_DOUT_READY,
      DDRAM_RD         => DDRAM_RD,        
      DDRAM_DIN        => DDRAM_DIN,       
      DDRAM_BE         => DDRAM_BE,        
      DDRAM_WE         => DDRAM_WE        
   );
   
   iframebuffer : entity work.framebuffer
   port map
   (
      clk               => clkvid,     
      hblank            => hblank,  
      vblank            => vblank,  
      video_ce          => video_ce,
      video_r           => video_r, 
      video_g           => video_g,    
      video_b           => video_b  
   );
   
end architecture;


