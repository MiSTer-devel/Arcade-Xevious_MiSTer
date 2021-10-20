//============================================================================
//  Arcade: Xevious
//
//  Port to MiSTer
//  Copyright (C) 2017 Sorgelig
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
	inout  [45:0] HPS_BUS,

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

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
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

assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign USER_OUT  = '1;
assign LED_USER  = rom_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;
assign AUDIO_MIX = 0;

assign FB_FORCE_BLANK = '0;
assign HDMI_FREEZE = 0;

wire [1:0] ar = status[20:19];

assign VIDEO_ARX = (!ar) ? ((status[2] ) ? 8'd4 : 8'd3) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? ((status[2] ) ? 8'd3 : 8'd4) : 12'd0;


`include "build_id.v"
localparam CONF_STR = {
	"Xevious;;",
	"OOR,CRT H-sync adjust,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
	"OSV,CRT V-sync adjust,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
	"O8,Flip Screen,Off,On;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
	"H0OJK,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H0O2,Orientation,Vert,Horz;",
	"-;",
	"DIP;",
	"-;",
	"H1OR,Autosave Hiscores,Off,On;",
	"P1,Pause options;",
	"P1OP,Pause when OSD is open,On,Off;",
	"P1OQ,Dim video after 10s,On,Off;",
	"-;",
	"O6,Service Mode,Off,On;",
	"R0,Reset;",
	"J1,Fire,Bomb,Start 1P,Start 2P,Coin,Pause;",
	"jn,A,B,Start,Select,R,L;",

	"V,v",`BUILD_DATE
};

reg [7:0] dsw[2];
always @(posedge clk_sys)
	if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:1])
		dsw[ioctl_addr[0]] <= ~ioctl_dout;

////////////////////   CLOCKS   ///////////////////

wire clk_sys,clk_12,clk_24,clk_36,clk_48;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_sys),
	.outclk_1(clk_48),
	.outclk_2(clk_12),
	.outclk_3(clk_24),
	.outclk_4(clk_36),
	.locked(pll_locked)
);

///////////////////////////////////////////////////

wire [31:0] status;
wire  [1:0] buttons;
wire [10:0] ps2_key;

wire        forced_scandoubler;
wire        direct_video;

wire        ioctl_download;
wire        ioctl_upload;
wire        ioctl_upload_req;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;
wire  [7:0] ioctl_index;

wire [15:0] joystick_0, joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;

wire [21:0] gamma_bus;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.buttons(buttons),
	.status(status),
	.status_menumask({~hs_configured,direct_video}),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),

	.ps2_key(ps2_key),
	.joystick_0(joystick_0),
	.joystick_1(joystick_1)
);

wire key_start1, key_start2;
wire key_coin1, key_coin2, key_coin3, key_coin4;
wire key_reset, key_service;

wire key_p1_up, key_p1_left, key_p1_down, key_p1_right, key_p1_fire, key_p1_bomb;
wire key_p2_up, key_p2_left, key_p2_down, key_p2_right, key_p2_fire, key_p2_bomb;

wire pressed = ps2_key[9];
always @(posedge clk_sys) begin
	reg old_state;

	old_state <= ps2_key[10];
	if(old_state ^ ps2_key[10]) begin
		casex(ps2_key[8:0])
			'h016: key_start1   <= pressed; // 1
			'h01e: key_start2   <= pressed; // 2
			'h02E: key_coin1    <= pressed; // 5
			'h036: key_coin2    <= pressed; // 6
			'h004: key_reset    <= pressed; // F3
			'h046: key_service  <= pressed; // 9

			'hX75: key_p1_up    <= pressed; // up
			'hX6b: key_p1_left  <= pressed; // left
			'hX72: key_p1_down  <= pressed; // down
			'hX74: key_p1_right <= pressed; // right
			'h014: key_p1_fire  <= pressed; // lctrl
			'h011: key_p1_bomb  <= pressed; // lalt

			'h02d: key_p2_up    <= pressed; // r
			'h023: key_p2_left  <= pressed; // d
			'h02b: key_p2_down  <= pressed; // f
			'h034: key_p2_right <= pressed; // g
			'h01c: key_p2_fire  <= pressed; // a
			'h01b: key_p2_bomb  <= pressed; // s
		endcase
	end
end


wire m_start1 = joystick_0[6] | joystick_1[7] | key_start1;
wire m_coin1  = joystick_0[8] | key_coin1;
wire m_up1    = joystick_0[3] | key_p1_up;
wire m_down1  = joystick_0[2] | key_p1_down;
wire m_left1  = joystick_0[1] | key_p1_left;
wire m_right1 = joystick_0[0] | key_p1_right;
wire m_fire1  = joystick_0[4] | key_p1_fire;
wire m_bomb1  = joystick_0[5] | key_p1_bomb;

wire m_start2 = joystick_1[6] | joystick_0[7] | key_start2;
wire m_coin2  = joystick_1[8] | key_coin2;
wire m_up2    = joystick_1[3] | key_p2_up;
wire m_down2  = joystick_1[2] | key_p2_down;
wire m_left2  = joystick_1[1] | key_p2_left;
wire m_right2 = joystick_1[0] | key_p2_right;
wire m_fire2  = joystick_1[4] | key_p2_fire;
wire m_bomb2  = joystick_1[5] | key_p2_bomb;

wire m_pause  = joy[9];


// PAUSE SYSTEM
wire				pause_cpu;
pause #(4,4,4,12) pause (
	.*,
	.user_button(m_pause),
	.pause_request(hs_pause),
	.options(~status[26:25])
);

wire hblank, vblank;
wire ce_vid;
wire hs, vs;
wire rde, rhs, rvs;
wire [3:0] r,g,b;
wire [11:0] rgb_out;

reg ce_pix;
always @(posedge clk_48) begin
	reg [2:0] div;
	div <= div + 1'd1;
	ce_pix <= !div;
end

wire rotate_ccw = 0;
wire no_rotate = status[2] | direct_video  ;
screen_rotate screen_rotate (.*);


arcade_video #(288,12) arcade_video
(
	.*,

	.clk_video(clk_48),
	.RGB_in(rgb_out),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(hs),
	.VSync(vs),

	.fx(status[5:3])
);

wire [15:0] audio;
assign AUDIO_L = audio;
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;

wire service, service_r, service_trigger;
always @(posedge clk_48) begin
	service <= status[6];
	service_r <= service;
	service_trigger <= service & !service_r;
end

wire rom_download = ioctl_download & !ioctl_index;
wire reset = RESET | status[0] | buttons[1] | rom_download | service_trigger | key_reset;

xevious xevious
(
	.clock_18(clk_sys),
	.reset(reset),

	.dn_addr(ioctl_addr[16:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr & rom_download),

	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_en(ce_vid),
	.video_hs(hs),
	.video_vs(vs),
	.blank_h(hblank),
	.blank_v(vblank),

	.flip(status[8]),
	.h_offset(status[27:24]),
	.v_offset(status[31:28]),

	.audio(audio),

	.self_test(status[6]),

	.service(key_service),
	.coin1(m_coin1),
	.coin2(m_coin2),
	.start1(m_start1),
	.start2(m_start2),
	.up1(m_up1),
	.down1(m_down1),
	.left1(m_left1),
	.right1(m_right1),
	.fire1(m_fire1),
	.up2(m_up2),
	.down2(m_down2),
	.left2(m_left2),
	.right2(m_right2),
	.fire2(m_fire2),

	.dip_switch_a(dsw[0]),
	.dip_switch_b({dsw[1][7:5], ~m_bomb2, dsw[1][3:1], ~m_bomb1}),

	.pause(pause_cpu),

	.hs_address(hs_address),
	.hs_data_out(hs_data_out),
	.hs_data_in(hs_data_in),
	.hs_write(hs_write_enable)
);


// HISCORE SYSTEM
// --------------

wire [11:0]hs_address;
wire [7:0] hs_data_in;
wire [7:0] hs_data_out;
wire hs_write_enable;
wire hs_pause;
wire hs_configured;

hiscore #(
	.HS_ADDRESSWIDTH(11),
	.CFG_ADDRESSWIDTH(2),		// 2 entries max (zaxxon/szaxxon)
	.CFG_LENGTHWIDTH(2)
) hi (
	.*,
	.clk(clk_sys),
	.paused(pause_cpu),
	.autosave(status[27]),
	.ram_address(hs_address),
	.data_from_ram(hs_data_out),
	.data_to_ram(hs_data_in),
	.data_from_hps(ioctl_dout),
	.data_to_hps(ioctl_din),
	.ram_write(hs_write_enable),
	.ram_intent_read(),
	.ram_intent_write(),
	.pause_cpu(hs_pause),
	.configured(hs_configured)
);

endmodule
