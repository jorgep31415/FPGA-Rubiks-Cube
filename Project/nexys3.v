`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:10:30 05/20/2019 
// Design Name: 
// Module Name:    nexys3 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module cube_top(/*AUTOARG*/
	input clk, 
	input [7:0] sw, 
	input btn_reset, 
	input btn_ccw, 
	input btn_cw,
	input btn_hrot, 
	input btn_vrot,
	output [7:0] seg, 
	output [3:0] an,
	output hsync,			//horizontal sync out
	output vsync,			//vertical sync out
	output [2:0] red,		//red vga output - 3 bits
	output [2:0] green,	//green vga output - 3 bits
	output [1:0] blue		//blue vga output - 2 bits
    );
	
	wire dclk;
	wire segclk;
	wire randclk;
	wire is_cw_posedge;
	wire is_ccw_posedge;
	wire is_hrot_posedge;
	wire is_vrot_posedge;
	
	wire [1:0] state;	// 0 - set/reset, 1 - scrambling, 2 - scrambled
	wire [12:0] move_count;	//up to 8192 moves
	wire [3:0] rand_num;		//for random moves during scramble
	
	//generate 7-segment & display (pixel) clock
	clk_divider clk_divider(
		.clk(clk),
		.dclk(dclk),
		.segclk(segclk),
		.randclk(randclk)
		);

	//7-segment display controller
	seg_display seg_display(
		.segclk(segclk),
		.state(state),
		.move_count(move_count),
		.seg(seg),
		.an(an)
		);

	//debouncing for btn_cw and btn_ccw buttons
	debouncing d1(
		.clk(clk),
		.btn(btn_cw),
		.is_posedge(is_cw_posedge)
		);

	debouncing d2(
		.clk(clk),
		.btn(btn_ccw),
		.is_posedge(is_ccw_posedge)
		);
		
	debouncing d3(
		.clk(clk),
		.btn(btn_hrot),
		.is_posedge(is_hrot_posedge)
		);
		
	debouncing d4(
		.clk(clk),
		.btn(btn_vrot),
		.is_posedge(is_vrot_posedge)
		);
	
	lfsr lfsr(
		.clk(clk),
		.out(rand_num)  // Output of the counter
		);
	
	//cube logic and vga display
	logic_and_vga logic_and_vga(
		.clk(clk),
		.dclk(dclk),
		.randclk(randclk),
		.sw(sw),
		.btn_reset(btn_reset),
		.is_cw_posedge(is_cw_posedge),
		.is_ccw_posedge(is_ccw_posedge),
		.is_hrot_posedge(is_hrot_posedge),
		.is_vrot_posedge(is_vrot_posedge),
		.rand_num(rand_num),
		.state(state),
		.move_count(move_count),
		.hsync(hsync),
		.vsync(vsync),
		.red(red),
		.green(green),
		.blue(blue)
		);

endmodule
