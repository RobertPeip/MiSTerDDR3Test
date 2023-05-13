library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all; 

entity ddr3_mister is
   port 
   (
      clk                  : in  std_logic;
      clkvid               : in  std_logic;
      reset                : in  std_logic;
      pause                : in  std_logic;
      
      ADDRMODE             : in  std_logic_vector(1 downto 0);
      BURSTCNT             : in  std_logic_vector(2 downto 0);
      WRITEMODE            : in  std_logic;
      
      ddr3_BUSY            : in  std_logic;                    
      ddr3_DOUT            : in  std_logic_vector(63 downto 0);
      ddr3_DOUT_READY      : in  std_logic;
      ddr3_BURSTCNT        : out std_logic_vector(7 downto 0) := (others => '0'); 
      ddr3_ADDR            : out std_logic_vector(28 downto 0) := (others => '0');                       
      ddr3_DIN             : out std_logic_vector(63 downto 0) := (others => '0');
      ddr3_BE              : out std_logic_vector(7 downto 0) := (others => '0'); 
      ddr3_WE              : out std_logic := '0';
      ddr3_RD              : out std_logic := '0';     
      
      video_hsync          : out std_logic := '0';
      video_vsync          : out std_logic := '0';
      video_hblank         : out std_logic := '0';
      video_vblank         : out std_logic := '0';
      video_ce             : out std_logic;
      video_r              : out std_logic_vector(7 downto 0);
      video_g              : out std_logic_vector(7 downto 0);
      video_b              : out std_logic_vector(7 downto 0)
   );
end entity;

architecture arch of ddr3_mister is
  
   -- clkvid
   signal clockCount_vid     : unsigned(31 downto 0) := (others => '0');
   signal secondwrap         : std_logic := '0';
   
   -- clk
   signal reset_1            : std_logic := '0'; 
   signal reset_2            : std_logic := '0';    
   
   signal pause_1            : std_logic := '0'; 
   signal pause_2            : std_logic := '0'; 
  
   type tddr3State is
   (
      IDLE,
      WAITREAD
   );
   signal ddr3State : tddr3State := IDLE;
   
   signal data_left         : unsigned(7 downto 0);
   
   signal secondwrap_1      : std_logic := '0';
   signal secondwrap_2      : std_logic := '0';
   signal secondwrap_3      : std_logic := '0';
   signal clockCount        : unsigned(31 downto 0) := (others => '0');
   signal clockCount_1      : unsigned(31 downto 0) := (others => '0');
   
   signal runcount          : unsigned(31 downto 0) := (others => '0');
   
   signal delay_cnt_now     : unsigned(15 downto 0) := (others => '0');
   signal delay_cnt_min     : unsigned(15 downto 0) := (others => '0');
   signal delay_cnt_max     : unsigned(15 downto 0) := (others => '0');
   signal delay_cnt_avg_cnt : unsigned(16 downto 0) := (others => '0');
   signal delay_cnt_avg_sum : unsigned(31 downto 0) := (others => '0');
   signal delay_cnt_avg     : unsigned(31 downto 0) := (others => '0');
   
   signal bandwidth         : unsigned(31 downto 0) := (others => '0');
   signal bandwidth_1       : unsigned(31 downto 0) := (others => '0');   
   
   signal burstwait         : unsigned(31 downto 0) := (others => '0');
   signal burstwait_1       : unsigned(31 downto 0) := (others => '0');
   
   signal random_lfsr       : std_logic_vector(19 downto 0) := x"12345";
   
begin 

   ddr3_ADDR(28 downto 23) <= "001100";
   ddr3_ADDR( 2 downto 0) <= "000";
   
   ddr3_DIN <= (others => '0');
   ddr3_BE  <= (others => '1');

   process (clkvid)
   begin
      if rising_edge(clkvid) then
      
         secondwrap <= '0';
         if (clockCount_vid > 53693170) then
            secondwrap <= '1';
         end if;
            
         clockCount_vid <= clockCount_vid + 1;   
         if (clockCount_vid > 53693175) then
            clockCount_vid <= (others => '0');
         end if;
         
      end if;
   end process;
   

   process (clk)
   begin
      if rising_edge(clk) then
      
         reset_1 <= reset;
         reset_2 <= reset_1;         
         
         pause_1 <= pause;
         pause_2 <= pause_1;
         
         secondwrap_1 <= secondwrap;
         secondwrap_2 <= secondwrap_1;
         secondwrap_3 <= secondwrap_2;

         random_lfsr   <= (random_lfsr(5) xor random_lfsr(3) xor random_lfsr(0)) & random_lfsr(19 downto 1);
      
         if (ddr3_BUSY = '0') then
            ddr3_WE <= '0';
            ddr3_RD <= '0';
         end if;
                  
         delay_cnt_now <= delay_cnt_now + 1; 
         
         case (ddr3State) is
            when IDLE =>
               if (reset_2 = '0' and pause_2 = '0' and (ddr3_BUSY = '0' or (ddr3_RD = '0' and ddr3_WE = '0'))) then
               
                  if (WRITEMODE = '1') then
                  
                     ddr3_WE                 <= '1';
                     ddr3_BURSTCNT           <= x"01";
                     delay_cnt_now           <= (others => '0');
                     
                     runcount  <= runcount + 1;
                     bandwidth <= bandwidth + 8;
                  
                     case (ADDRMODE) is
                        when "00" => ddr3_ADDR(22 downto 3) <= (others => '0');
                        when "01" => ddr3_ADDR(22 downto 3) <= std_logic_vector(unsigned(ddr3_ADDR(22 downto 3)) + 1);
                        when "10" => ddr3_ADDR(22 downto 3) <= std_logic_vector(unsigned(ddr3_ADDR(22 downto 3)) - 1);
                        when "11" => ddr3_ADDR(22 downto 3) <= random_lfsr;
                        when others => null;
                     end case;
                     
                     if (delay_cnt_now < delay_cnt_min) then delay_cnt_min <= delay_cnt_now; end if;
                     if (delay_cnt_now > delay_cnt_max) then delay_cnt_max <= delay_cnt_now; end if;
                        
                     if (delay_cnt_avg_cnt(16) = '1') then
                        delay_cnt_avg_cnt <= (others => '0');
                        delay_cnt_avg_sum <= (others => '0');
                        delay_cnt_avg     <= delay_cnt_avg_sum;
                     else
                        delay_cnt_avg_cnt <= delay_cnt_avg_cnt + 1;
                        delay_cnt_avg_sum <= delay_cnt_avg_sum + delay_cnt_now;
                     end if;
                  
                  else
                  
                     ddr3State               <= WAITREAD;
                     ddr3_RD                 <= '1';
                     delay_cnt_now           <= (others => '0');
                     
                     case (ADDRMODE) is
                        when "00" => ddr3_ADDR(22 downto 3) <= (others => '0');
                        when "01" => ddr3_ADDR(22 downto 3) <= std_logic_vector(unsigned(ddr3_ADDR(22 downto 3)) + 1);
                        when "10" => ddr3_ADDR(22 downto 3) <= std_logic_vector(unsigned(ddr3_ADDR(22 downto 3)) - 1);
                        when "11" => ddr3_ADDR(22 downto 3) <= random_lfsr;
                        when others => null;
                     end case;
                     
                     case (BURSTCNT) is
                        when "000" => ddr3_BURSTCNT <= x"01"; data_left <= x"01";
                        when "001" => ddr3_BURSTCNT <= x"02"; data_left <= x"02";
                        when "010" => ddr3_BURSTCNT <= x"04"; data_left <= x"04";
                        when "011" => ddr3_BURSTCNT <= x"08"; data_left <= x"08";
                        when "100" => ddr3_BURSTCNT <= x"10"; data_left <= x"10";
                        when "101" => ddr3_BURSTCNT <= x"20"; data_left <= x"20";
                        when "110" => ddr3_BURSTCNT <= x"40"; data_left <= x"40";
                        when "111" => ddr3_BURSTCNT <= x"80"; data_left <= x"80";
                        when others => null;
                     end case;
                  
                  end if;
                  
               end if;
                  
            when WAITREAD =>
               if (ddr3_DOUT_READY = '1') then
                  
                  data_left <= data_left - 1;
                  if (data_left = 1) then
                     ddr3State <= IDLE;
                     runcount  <= runcount + 1;
                  end if;
                  
                  bandwidth <= bandwidth + 8;
                  
                  if (data_left = unsigned(ddr3_BURSTCNT)) then
                     if (delay_cnt_now < delay_cnt_min) then delay_cnt_min <= delay_cnt_now; end if;
                     if (delay_cnt_now > delay_cnt_max) then delay_cnt_max <= delay_cnt_now; end if;
                     
                     if (delay_cnt_avg_cnt(16) = '1') then
                        delay_cnt_avg_cnt <= (others => '0');
                        delay_cnt_avg_sum <= (others => '0');
                        delay_cnt_avg     <= delay_cnt_avg_sum;
                     else
                        delay_cnt_avg_cnt <= delay_cnt_avg_cnt + 1;
                        delay_cnt_avg_sum <= delay_cnt_avg_sum + delay_cnt_now;
                     end if;
                  end if;
                  
               elsif (data_left /= unsigned(ddr3_BURSTCNT)) then -- first word not yet received
               
                  burstwait <= burstwait + 1;
               
               end if;
         
         end case;
         
          if (secondwrap_3 = '0' and secondwrap_2 = '1') then
            clockCount   <= (others => '0');
            clockCount_1 <= clockCount;
            bandwidth    <= (others => '0');
            bandwidth_1  <= bandwidth;            
            burstwait    <= (others => '0');
            burstwait_1  <= burstwait;
         else
            clockCount   <= clockCount + 1;
         end if;
         
         if (reset_2 = '1' or pause_2 = '1') then
            runcount          <= (others => '0');
            delay_cnt_now     <= (others => '0');
            delay_cnt_min     <= (others => '1');
            delay_cnt_max     <= (others => '0');
            delay_cnt_avg_cnt <= (others => '0');
            delay_cnt_avg_sum <= (others => '0');
         end if;

      end if;
   end process;
   
   igpu_videoout : entity work.gpu_videoout
   port map
   (
      clkvid               => clkvid,
      reset_1x             => reset, 
      
      clockCount           => clockCount_1,
      runcount             => runcount,
      delay_cnt_min        => delay_cnt_min,
      delay_cnt_max        => delay_cnt_max,
      delay_cnt_avg        => delay_cnt_avg,
      bandwidth            => bandwidth_1,
      burstwait            => burstwait,
                           
      video_hsync          => video_hsync, 
      video_vsync          => video_vsync,  
      video_hblank         => video_hblank, 
      video_vblank         => video_vblank, 
      video_ce             => video_ce,     
      video_r              => video_r,      
      video_g              => video_g,      
      video_b              => video_b     
   );

end architecture;





