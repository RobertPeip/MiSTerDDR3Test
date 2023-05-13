//============================================================================
//  DDR3Test
//  Copyright (C) 2019 Robert Peip
//
//  Port to MiSTer
//  Copyright (C) 2019 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
   output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign HDMI_FREEZE = 1'b0;

assign AUDIO_S = 0;
assign AUDIO_L = 0;
assign AUDIO_R = 0;
assign AUDIO_MIX = 0;

assign LED_USER  = 0;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign VGA_SCALER= 0;

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;

assign VIDEO_ARX = 12'd4;
assign VIDEO_ARY = 12'd3;

///////////////////////  CLOCK/RESET  ///////////////////////////////////

wire clk_variable;
wire clk_vid;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_variable),
   .reconfig_to_pll(reconfig_to_pll),
	.reconfig_from_pll(reconfig_from_pll)
);

pll2 pll2
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_vid)
);

wire [63:0] reconfig_to_pll;
wire [63:0] reconfig_from_pll;
wire        cfg_waitrequest;
reg         cfg_write = 0;
reg   [5:0] cfg_address;
reg  [31:0] cfg_data;

pll_cfg pll_cfg
(
	.mgmt_clk(CLK_50M),
	.mgmt_reset(0),
	.mgmt_waitrequest(cfg_waitrequest),
	.mgmt_read(0),
	.mgmt_readdata(),
	.mgmt_write(cfg_write),
	.mgmt_address(cfg_address),
	.mgmt_writedata(cfg_data),
	.reconfig_to_pll(reconfig_to_pll),
	.reconfig_from_pll(reconfig_from_pll)
);

always @(posedge CLK_50M) begin : cfg_block
	reg  [4:0] state = 0;
   
   reg [1:0] setting_1;
   reg [1:0] setting_2;
   reg [1:0] setting_3;
   
   setting_1 <= status[11:10];
   setting_2 <= setting_1;
   setting_3 <= setting_2;

   if (setting_3 != setting_2) state <= 1;

	cfg_write <= 0;
   
	if(!cfg_waitrequest) begin
		if(state) state<=state+1'd1;
		case(state)
			1: begin
					cfg_address <= 0;
					cfg_data <= 0;
					cfg_write <= 1;
				end
         3: begin
					cfg_address <= 4;
               case (setting_3)
                  0 : cfg_data <= 'h00505;
                  1 : cfg_data <= 'h00404;
                  2 : cfg_data <= 'h00404;
                  3 : cfg_data <= 'h00404;
               endcase
					cfg_write <= 1;
				end
         5: begin
					cfg_address <= 5;
               case (setting_3)
                  0 : cfg_data <= 'h00202;
                  1 : cfg_data <= 'h20302;
                  2 : cfg_data <= 'h20304;
                  3 : cfg_data <= 'h00202;
               endcase
					cfg_write <= 1;
				end
			7: begin
					cfg_address <= 7;
               case (setting_3)
                  0 : cfg_data <= 'h00000001;
                  1 : cfg_data <= 'h80000000;
                  2 : cfg_data <= 'hC0000000;
                  3 : cfg_data <= 'h00000001;
               endcase
					cfg_write <= 1;
				end
			9: begin
					cfg_address <= 2;
					cfg_data <= 0;
					cfg_write <= 1;
				end
		endcase
	end
end

wire reset_or = RESET | buttons[1] | status[0];

////////////////////////////  HPS I/O  //////////////////////////////////

// Status Bit Map: (0..31 => "O", 32..63 => "o")
// 0         1         2         3          4         5         6          7         8         9
// 01234567890123456789012345678901 23456789012345678901234567890123 45678901234567890123456789012345
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV 
// 

`include "build_id.v"
parameter CONF_STR = {
	"DDR3TEST;;",
   "O[5],Direction,Read,Write;",
   "O[2:1],Address Mode,Static,Count up,Count down,Random;",
   "O[11:10],Clock Mhz,125,85,62.5,100;",
   "O[22:20],Burst,1,2,4,8,16,32,64,128;",
	"R0,Reset;",
	"V,v",`BUILD_DATE
};

wire  [1:0] buttons;
wire [127:0] status;
wire        forced_scandoubler;

wire [19:0] joy;

wire [10:0] ps2_key;

wire [127:0] status_in = status;

wire bk_pending;
wire DIRECT_VIDEO;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(CLK_50M),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),

	.buttons(buttons),
	.forced_scandoubler(forced_scandoubler),

	.joystick_0(joy),
	.ps2_key(ps2_key),

	.status(status),
	.status_in(status_in),
	.status_set(0),
	.status_menumask(0),
	.info_req(0),
	.info(0),
   
   .direct_video(DIRECT_VIDEO)
);

////////////////////////////  SYSTEM  ///////////////////////////////////

wire HBlank;
wire VBlank;

assign DDRAM_CLK = clk_variable;

ddr3_mister
ddr3test
(
   .clk(DDRAM_CLK),          
   .clkvid(clk_vid),
   .reset(reset_or),
   .pause(OSD_STATUS),
   
   .ADDRMODE       (status[2:1]),
   .BURSTCNT       (status[22:20]),
   .WRITEMODE      (status[5]),
   
   // ddr3
   .ddr3_BUSY      (DDRAM_BUSY      ),
   .ddr3_BURSTCNT  (DDRAM_BURSTCNT  ),
   .ddr3_ADDR      (DDRAM_ADDR      ),
   .ddr3_DOUT      (DDRAM_DOUT      ),
   .ddr3_DOUT_READY(DDRAM_DOUT_READY),
   .ddr3_RD        (DDRAM_RD        ),
   .ddr3_DIN       (DDRAM_DIN       ),
   .ddr3_BE        (DDRAM_BE        ),
   .ddr3_WE        (DDRAM_WE        ),
   // Video
   .video_hsync    (VGA_HS),
   .video_vsync    (VGA_VS),
   .video_hblank   (HBlank),
   .video_vblank   (VBlank),
   .video_ce       (CE_PIXEL),
   .video_r        (VGA_R),
   .video_g        (VGA_G),
   .video_b        (VGA_B)
);

assign CLK_VIDEO = clk_vid;
assign VGA_DE = ~(HBlank | VBlank);
assign VGA_F1 = 0;
assign VGA_SL = 0;
assign VGA_DISABLE = 0;

endmodule

      
      

  
      
       
        
        
        