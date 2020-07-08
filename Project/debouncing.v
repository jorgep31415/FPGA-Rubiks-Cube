`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    08:30:43 05/26/2019 
// Design Name: 
// Module Name:    debouncing 
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
module debouncing(
	input clk,
	input btn,
	output is_posedge
    );

	reg is_posedge_temp;
	reg [21:0] step = 0;

	always @(posedge clk) begin
		if(btn) begin
			step <= step + 1;
			if(step == 22'b1111111111111111111111) begin
				is_posedge_temp <= 1;
				step <= 0;
			end
		end
		else begin
			is_posedge_temp <= 0;
			step <= 0;
		end
	end
	
	assign is_posedge = is_posedge_temp;

endmodule
