`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:16:05 05/26/2019 
// Design Name: 
// Module Name:    seg_display 
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
module seg_display(
	input segclk,
	input [1:0] state,
	input [12:0] move_count,
	output reg [7:0] seg,
	output reg [3:0] an
    );

	parameter C = 8'b11000110;
	parameter U = 8'b11000001;
	parameter B = 8'b10000000;
	parameter E = 8'b10000110;
	parameter O = 8'b11000000;
	parameter D = 8'b10100001;
	parameter N = 8'b11001000;
	parameter dot = 8'b01111111;
	
	parameter left 	 = 2'b00;
	parameter midleft  = 2'b01;
	parameter midright = 2'b10;
	parameter right 	 = 2'b11;

	reg [1:0] digit = left;
	reg [31:0] seg_values;
	
	function [7:0] seg_val;
		input [3:0] num;
			begin
				case (num)
					0: seg_val = 8'b11000000;
					1: seg_val = 8'b11111001;
					2: seg_val = 8'b10100100;
					3: seg_val = 8'b10110000;
					4: seg_val = 8'b10011001;
					5: seg_val = 8'b10010010;
					6: seg_val = 8'b10000010;
					7: seg_val = 8'b11111000;
					8: seg_val = 8'b10000000;
					9: seg_val = 8'b10010000;
				endcase
			end
	endfunction
	
	always @(posedge segclk) begin
		case (state)
			0: seg_values = {C, U, B, E};
			1: seg_values = {dot, dot, dot, dot};
			2: seg_values = {seg_val(move_count/1000), seg_val((move_count%1000)/100), seg_val((move_count%100)/10), seg_val(move_count%10)};
			3: seg_values = {D, O, N, E};
		endcase
		
		case(digit)
			left: begin
				seg <= seg_values[31:24];
				an <= 'b0111;
				digit <= midleft;
			end
			midleft: begin
				seg <= seg_values[23:16];
				an <= 'b1011;
				digit <= midright;
			end
			midright: begin
				seg <= seg_values[15:8];
				an <= 'b1101;
				digit <= right;
			end
			right: begin
				seg <= seg_values[7:0];
				an <= 'b1110;
				digit <= left;
			end
		endcase
	end
endmodule
