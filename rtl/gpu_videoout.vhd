library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all; 

library mem;

entity gpu_videoout is
   port 
   (
      clkvid               : in  std_logic;
      reset_1x             : in  std_logic;
      
      clockCount           : in  unsigned(31 downto 0) := (others => '0');
      runcount             : in  unsigned(31 downto 0) := (others => '0');
      delay_cnt_min        : in  unsigned(15 downto 0) := (others => '0');
      delay_cnt_max        : in  unsigned(15 downto 0) := (others => '0');
      delay_cnt_avg        : in  unsigned(31 downto 0) := (others => '0');
      bandwidth            : in  unsigned(31 downto 0) := (others => '0');
      burstwait            : in  unsigned(31 downto 0) := (others => '0');
        
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

architecture arch of gpu_videoout is

   function to_unsigned(a : string) return unsigned is
      variable ret : unsigned(a'length*8-1 downto 0);
   begin
      for i in 1 to a'length loop
         ret((a'length - i)*8+7 downto (a'length - i)*8) := to_unsigned(character'pos(a(i)), 8);
      end loop;
      return ret;
   end function to_unsigned;
   
   function conv_number(a : unsigned) return unsigned is
      variable ret : unsigned((a'length * 2) -1 downto 0);
   begin
      for i in 0 to (a'length / 4)-1 loop
         if (a(((i * 4) + 3) downto (i * 4)) < 10) then
            ret(((i * 8) + 7) downto (i * 8)) := resize(a(((i * 4) + 3) downto (i * 4)), 8) + 16#30#;
         else
            ret(((i * 8) + 7) downto (i * 8)) := resize(a(((i * 4) + 3) downto (i * 4)), 8) + 16#37#;
         end if;
      end loop;
      return ret;
   end function conv_number;

   signal reset_1             : std_logic := '0';
   signal reset_2             : std_logic := '0';
   signal reset               : std_logic := '0';

   -- overlay
   signal overlay_data        : std_logic_vector(23 downto 0);
   
   signal clockCountBCD       : unsigned(39 downto 0);
   signal runcountBCD         : unsigned(39 downto 0);
   signal delay_cnt_minBCD    : unsigned(39 downto 0);
   signal delay_cnt_maxBCD    : unsigned(39 downto 0);
   signal delay_cnt_avgBCD    : unsigned(39 downto 0);
   signal bandwidthBCD        : unsigned(39 downto 0);
   signal burstwaitBCD        : unsigned(39 downto 0);
   
   constant OVERLAY_COUNT : integer := 15;
   type t_overlay_array is array(0 to OVERLAY_COUNT-1) of std_logic_vector(23 downto 0);
   signal overlay_array : t_overlay_array;
   signal overlay_ena   : std_logic_vector(0 to OVERLAY_COUNT-1);
   
   -- timing
   signal nextHCount                   : integer range 0 to 4095;
            
   signal vpos                         : integer range 0 to 511;
   signal vdisp                        : integer range 0 to 511;
   signal lineIn                       : integer range 0 to 511;
   signal inVsync                      : std_logic := '0';

   signal htotal                       : integer range 3406 to 3413;
   signal vtotal                       : integer range 262 to 314;
   signal vDisplayStart                : integer range 0 to 314;
   signal vDisplayEnd                  : integer range 0 to 314;
   signal vDisplayCnt                  : integer range 0 to 314 := 0;
   signal vDisplayMax                  : integer range 0 to 314 := 239;
              
   signal newLineTrigger               : std_logic := '0';  
   
   -- output   
   type tState is
   (
      WAITNEWLINE,
      WAITHBLANKEND,
      WAITHBLANKENDVSYNC,
      WAITINVSYNC,
      DRAW
   );
   signal state : tState := WAITNEWLINE;
   
   signal vid_ce              : std_logic := '0';
   
   signal clkDiv              : integer range 4 to 10 := 4; 
   signal clkCnt              : integer range 0 to 10 := 0;
   signal xCount              : integer range 0 to 1023 := 256;
   
   signal xpos                : integer range 0 to 1023;
   signal ypos                : integer range 0 to 1023;
         
   signal hsync_start         : integer range 0 to 4095;
   signal hsync_end           : integer range 0 to 4095;
      
   signal hCropCount          : unsigned(11 downto 0) := (others => '0');
   signal hCropPixels         : unsigned(1 downto 0) := (others => '0');
   
begin 
  
   -- texts
   ioverlayTextclockrate : entity work.gpu_overlay generic map (10, 10, 60, x"000000")
   port map ( clkvid, vid_ce, '1', xpos, ypos, overlay_array(0), overlay_ena(0), to_unsigned("Clockrate:")); 
   
   ioverlayTextruncount : entity work.gpu_overlay generic map (10, 10, 80, x"000000")
   port map ( clkvid, vid_ce, '1', xpos, ypos, overlay_array(1), overlay_ena(1), to_unsigned("Transfers:"));    
   
   ioverlayTextMinDelay : entity work.gpu_overlay generic map ( 10, 10, 100, x"000000")
   port map ( clkvid, vid_ce, '1', xpos, ypos, overlay_array(2), overlay_ena(2), to_unsigned("Delay Min:"));    
   
   ioverlayTextMaxDelay : entity work.gpu_overlay generic map ( 10, 10, 120, x"000000")
   port map ( clkvid, vid_ce, '1', xpos, ypos, overlay_array(3), overlay_ena(3), to_unsigned("Delay Max:"));    
   
   ioverlayTextAvgDelay : entity work.gpu_overlay generic map ( 10, 10, 140, x"000000")
   port map ( clkvid, vid_ce, '1', xpos, ypos, overlay_array(4), overlay_ena(4), to_unsigned("Delay Avg:"));    
   
   ioverlayTextBandwidth : entity work.gpu_overlay generic map ( 10, 10, 160, x"000000")
   port map ( clkvid, vid_ce, '1', xpos, ypos, overlay_array(5), overlay_ena(5), to_unsigned("Bytes / s:")); 
   
   ioverlayTextBurstwait : entity work.gpu_overlay generic map ( 10, 10, 180, x"000000")
   port map ( clkvid, vid_ce, '1', xpos, ypos, overlay_array(6), overlay_ena(6), to_unsigned("Burstwait:")); 

   -- values
   ioverlayclockrateBCD : entity work.ToBCD port map ( clkvid, clockCount, clockCountBCD);
   ioverlayclockrate: entity work.gpu_overlay generic map (10, 120, 60, x"0000FF")
   port map ( clkvid, vid_ce, '1', xpos, ypos, overlay_array(7), overlay_ena(7), conv_number(clockCountBCD)); 
   
   ioverlayruncountBCD : entity work.ToBCD port map ( clkvid, runcount, runcountBCD);
   ioverlayruncount: entity work.gpu_overlay generic map (10, 120, 80, x"0000FF")
   port map ( clkvid, vid_ce, '1', xpos, ypos, overlay_array(8), overlay_ena(8), conv_number(runcountBCD));    
   
   ioverlayMinDelayBCD : entity work.ToBCD port map ( clkvid, X"0000" & delay_cnt_min, delay_cnt_minBCD);
   ioverlayMinDelay : entity work.gpu_overlay generic map (10, 120, 100, x"0000FF")
   port map ( clkvid, vid_ce, '1', xpos, ypos, overlay_array(9), overlay_ena(9), conv_number(delay_cnt_minBCD)); 
   
   ioverlayMaxDelayBCD : entity work.ToBCD port map ( clkvid, X"0000" & delay_cnt_max, delay_cnt_maxBCD);
   ioverlayMaxDelay : entity work.gpu_overlay generic map (10, 120, 120, x"0000FF")
   port map ( clkvid, vid_ce, '1', xpos, ypos, overlay_array(10), overlay_ena(10), conv_number(delay_cnt_maxBCD)); 
   
   ioverlayAvgDelayBCD : entity work.ToBCD port map ( clkvid, X"0000" & delay_cnt_avg(31 downto 16), delay_cnt_avgBCD);
   ioverlayAvgDelay : entity work.gpu_overlay generic map (10, 120, 140, x"0000FF")
   port map ( clkvid, vid_ce, '1', xpos, ypos, overlay_array(11), overlay_ena(11), conv_number(delay_cnt_avgBCD)); 
   
   ioverlayAvgDelayHex : entity work.gpu_overlay generic map (8, 240, 140, x"0000FF")
   port map ( clkvid, vid_ce, '1', xpos, ypos, overlay_array(12), overlay_ena(12), conv_number(delay_cnt_avg)); 

   ioverlayBandwidthBCD : entity work.ToBCD port map ( clkvid, bandwidth, bandwidthBCD);
   ioverlayBandwidth : entity work.gpu_overlay generic map (10, 120, 160, x"0000FF")
   port map ( clkvid, vid_ce, '1', xpos, ypos, overlay_array(13), overlay_ena(13), conv_number(bandwidthBCD));    
   
   ioverlayBurstwaitBCD : entity work.ToBCD port map ( clkvid, burstwait, burstwaitBCD);
   ioverlayBBurstwait : entity work.gpu_overlay generic map (10, 120, 180, x"0000FF")
   port map ( clkvid, vid_ce, '1', xpos, ypos, overlay_array(14), overlay_ena(14), conv_number(burstwaitBCD)); 
   

   video_ce <= vid_ce;

   process (overlay_array, overlay_ena)
   begin
      overlay_data <= (others => '0');
      for i in 0 to OVERLAY_COUNT-1 loop
         if (overlay_ena(i) = '1') then
            overlay_data <= overlay_array(i);
         end if;
      end loop;
   end process;
   
   process (clkvid)
      variable isVsync        : std_logic;
      variable vdispNew       : integer range 0 to 511;
   begin
      if rising_edge(clkvid) then
         
         reset_1 <= reset_1x;
         reset_2 <= reset_1;
         reset   <= reset_2;
         
         vDisplayMax   <= 240;
         vDisplayStart <= 0;
         vDisplayEnd   <= 239;
         
         newLineTrigger <= '0';
                
         if (reset = '1') then
               
            nextHCount                 <= htotal;
            vpos                       <= 0;
            inVsync                    <= '0';
            vdisp                      <= 0;

         else
            
            htotal <= 3413;
            vtotal <= 263;
              
            vdispNew := vdisp + 1;

            -- gpu timing count
            if (nextHCount > 1) then
               nextHCount <= nextHCount - 1;
            else
               
               nextHCount <= htotal;
               
               vpos <= vpos + 1;
               if (vpos + 1 = vtotal) then
                  vpos <= 0;
               end if;               
               
               if (video_vsync = '1') then
                  vdispNew := 0;
               end if;
               
               -- synthesis translate_off
               if (vdispNew >= vtotal) then
                  vdispNew := 0; -- fix simulation issues with rollover
               end if;
               -- synthesis translate_on
            
               vdisp <= vdispNew;

               if (vDisplayCnt < vDisplayMax) then
                  vDisplayCnt <= vDisplayCnt + 1;
               end if;

               isVsync := inVsync;
               if (vdispNew = vDisplayStart) then
                  isVsync     := '0';
                  vDisplayCnt <= 0;
               elsif (vdispNew = vDisplayEnd or vdispNew = 0) then
                  isVsync := '1';
               end if;

               if (isVsync = '0') then
                  lineIn <= vdispNew - vDisplayStart;
               end if;

               if (isVsync /= inVsync) then
                  inVsync <= isVsync;
               end if;
               
               newLineTrigger <= '1';
               vdispNew := vdispNew + 1;

            end if;
            
         end if;
      end if;
   end process;
   
   video_vblank  <= inVsync when vDisplayCnt < 240 else '1';
   
   process (clkvid)
      variable vsync_hstart  : integer range 0 to 4095;
      variable vsync_vstart  : integer range 0 to 511;
   begin
      if rising_edge(clkvid) then
         
         vid_ce <= '0';
           
         clkDiv <= 8;

         if (reset = '1') then
         
            state                       <= WAITNEWLINE;                          
            clkCnt                      <= 0;
            video_hblank                <= '1';
            video_vsync                 <= '0';
            ypos                        <= 0;
         
         else
            
            if (clkCnt < (clkDiv - 1)) then
               clkCnt <= clkCnt + 1;
            else
               clkCnt    <= 0;
               vid_ce  <= '1';
            end if;
            
            if (newLineTrigger = '1') then --clock divider reset at end of line
               clkCnt           <= 0;
            end if;

            hCropCount <= hCropCount + 1;
            
            case (state) is
            
               when WAITNEWLINE =>
                  video_hblank <= '1';
                  
                  if (lineIn /= ypos) then
                     state <= WAITHBLANKEND;
                     xpos <= 0;
                     ypos <= lineIn;
                     
                     xCount                <= 0;
                     hCropCount            <= (others => '0');
                     hCropPixels           <= (others => '0');
                     
                  elsif (newLineTrigger = '1') then
                     
                     state                 <= WAITHBLANKENDVSYNC;
                     hCropCount            <= (others => '0');
                     hCropPixels           <= (others => '0');
                     
                  end if;
            
               when WAITHBLANKEND | WAITHBLANKENDVSYNC =>
                  if (clkCnt >= (clkDiv - 1)) then
                     if (hCropCount >= 16#260#) then
                        if (state = WAITHBLANKENDVSYNC) then
                           state <= WAITINVSYNC;
                        else 
                           state <= DRAW;
                        end if;
                     end if;
                  end if;
                  
               when WAITINVSYNC =>
                  if (clkCnt >= (clkDiv - 1)) then
                     hCropPixels <= hCropPixels + 1;
                     if ((hCropCount + 1) >= 16#C70#) then
                        if ((hCropPixels + 1) = 0) then
                           state <= WAITNEWLINE;
                        end if;
                     end if;
                  end if;
                  if ((nextHCount = 32 + 3413/2) and vpos = vsync_vstart and vtotal = 262) then
                     state        <= WAITHBLANKENDVSYNC;
                  end if;
                  
               when DRAW =>
                  if (clkCnt >= (clkDiv - 1)) then
                     video_hblank  <= '0';
                     video_r       <= overlay_data( 7 downto  0);
                     video_g       <= overlay_data(15 downto  8);
                     video_b       <= overlay_data(23 downto 16);
                     
                     if (xCount < 1023) then
                        xCount <= xCount + 1;
                     end if;
                    
                     xpos <= xpos + 1;
                     
                     hCropPixels <= hCropPixels + 1;
                     if ((hCropCount + 1) >= 16#C70#) then
                        if ((hCropPixels + 1) = 0) then
                           state           <= WAITNEWLINE;
                        end if;
                     end if;
                     
                  end if;
               
            end case;
            
            hsync_start <= 32;
            
            if (nextHCount = hsync_start) then 
               hsync_end <= 252;
               video_hsync <= '1'; 
            end if;
               
            if (hsync_end > 0) then
               hsync_end <= hsync_end - 1;
               if (hsync_end = 1) then 
                  video_hsync <= '0';
               end if;
            end if;

            vsync_hstart := hsync_start;
            vsync_vstart := 242;

            if (nextHCount = vsync_hstart) then
               if (vpos = vsync_vstart    ) then video_vsync <= '1'; end if;
               if (vpos = vsync_vstart + 3) then 
                  video_vsync <= '0'; 
               end if;
            end if;
         
         end if;
         
      end if;
   end process; 
   
   
end architecture;





