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
	output [11:0] VIDEO_ARX,
	output [11:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler

	// Use framebuffer from DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of 16 bytes.
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,    // 1 - signed audio samples, 0 - unsigned

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

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT
);

assign VGA_F1    = 0;
assign VGA_SCALER= 0;
assign USER_OUT  = '1;
assign LED_USER  = ioctl_download;
assign LED_DISK  = 0;
assign LED_POWER = 0;

assign {FB_PAL_CLK, FB_FORCE_BLANK, FB_PAL_ADDR, FB_PAL_DOUT, FB_PAL_WR} = '0;

wire [1:0] ar = status[20:19];

assign VIDEO_ARX = (!ar) ? ((status[2] ) ? 8'd4 : 8'd3) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? ((status[2] ) ? 8'd3 : 8'd4) : 12'd0;


`include "build_id.v" 
localparam CONF_STR = {
	"A.XEVS;;",
	"H0OJK,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"H0O2,Orientation,Vert,Horz;",
	"O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"-;",
// LOOK AT GALAGA
	"O89,Lives,3,1,2,5;",
	"OAB,Difficulty,Normal,Easy,Hard,Hardest;",
// "OC,Cabinet,Upright,Cocktail;",
	"OG,Flags Award Bonus Life,Yes,No;",
// "ODF,ShipBonus,30k80kOnly,20k20k80k,30k12k12k,20k60k60k,20k60kOnly,20k70k70k,30k100k100k,Nothing;",
// "ODF,ShipBonus,30kOnly,30k150k150k,30k120kOnly,30k100k100k,30k150kOnly,30k120k120k,30k100kOnly,Nothing;",
// "ODF,ShipBonus,30k80kOnly/30kOnly,20k60kOnly/30k150kOnly,2k6k6k/3k10k10k,2k7k7k/3k12k12k,2k8k8k/3k15k10k,3k10k10k/3k12k12k,2k6k6k/3k10k10k,2k7k7k/3k12k12k,2k6k6k/3k10k10k,2k7k7k/3k12k12k;",
	"-;",
	"R0,Reset;",
	"J1,Fire,Bomb,Start 1P,Start 2P,Coin;",
	"jn,A,B,Start,Select,R;",

	"V,v",`BUILD_DATE
};
wire [7:0]dip_switch_a = { 1'b1,~status[9],~status[8],5'b11111};
wire [7:0]dip_switch_b = { 1'b1,~status[11:10],~m_bomb_2,2'b00,~status[16],~m_bomb};
//wire [7:0]dip_switch_a = { 8'b11111111};
//wire [7:0]dip_switch_b = { 7'b1110001,~m_bomb};
//dip_switch_a <= "11111111"; -- | cabinet(1) | lives(2)| bonus life(3) | coinage A(2) |
//dip_switch_b <= "1110001" & not bomb; -- |freeze(1)| difficulty(2)| input B(1) | coinage B (2) | Flags bonus life (1) | input A (1) |

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
wire        forced_scandoubler;
wire        direct_video;


wire        ioctl_download;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;

wire [15:0] joystick_0, joystick_1;
wire [15:0] joy = joystick_0 | joystick_1;

wire [21:0] gamma_bus;

hps_io #(.STRLEN($size(CONF_STR)>>3)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),

	.conf_str(CONF_STR),

	.buttons(buttons),
	.status(status),
	.status_menumask(direct_video),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),

	.ioctl_download(ioctl_download),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),

	.joystick_0(joystick_0),
	.joystick_1(joystick_1)
);

//wire m_up_2    = joy[3];
//wire m_down_2  = joy[2];
//wire m_left_2  = joy[1];
//wire m_right_2 = joy[0];
//wire m_fire_2  = joy[4];
wire m_bomb_2  = joy[5];
wire m_up      = joy[3];
wire m_down    = joy[2];
wire m_left    = joy[1];
wire m_right   = joy[0];
wire m_fire    = joy[4];
wire m_bomb    = joy[5];

wire m_start1 = joy[6];
wire m_start2 = joy[7];
wire m_coin   = joy[8];

wire hblank, vblank;
wire ce_vid;
wire hs, vs;
wire rde, rhs, rvs;
wire [3:0] r,g,b;

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
	.RGB_in({r,g,b}),
	.HBlank(hblank),
	.VBlank(vblank),
	.HSync(hs),
	.VSync(vs),

	.fx(status[5:3])
);

wire [10:0] audio;
assign AUDIO_L = {audio, 5'b00000};
assign AUDIO_R = AUDIO_L;
assign AUDIO_S = 0;

xevious xevious
(
	.clock_18(clk_sys),
	.reset(RESET | status[0] | buttons[1]),

	.dn_addr(ioctl_addr[16:0]),
	.dn_data(ioctl_dout),
	.dn_wr(ioctl_wr),

	.video_r(r),
	.video_g(g),
	.video_b(b),
	.video_en(ce_vid),
	.video_hs(hs),
	.video_vs(vs),
	.blank_h(hblank),
	.blank_v(vblank),

	.audio(audio),

	.b_test(1),
	.b_svce(1), 
	.coin(m_coin),
	.start1(m_start1),
	.start2(m_start2),
	.up(m_up),
	.down(m_down),
	.left(m_left),
	.right(m_right),
	.fire(m_fire),
	.bomb(m_bomb),
	.dip_switch_a(dip_switch_a),
	.dip_switch_b(dip_switch_b)
);

endmodule
