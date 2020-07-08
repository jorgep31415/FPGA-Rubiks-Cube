`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:15:01 05/22/2019 
// Design Name: 
// Module Name:    clk_divider 
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
module clk_divider(
	input wire clk,		//master clock: 100MHz
	output wire dclk,		//pixel clock: 25MHz
	output wire segclk,	//7-segment clock: 381.47 Hz
	output wire randclk	//scrambling clock: 5.96 Hz
	);

	// 25-bit counter variable
	reg [24:0] q;
	
	reg randclk_temp;

	// Clock divider --
	// Each bit in q is a clock signal that is
	// only a fraction of the master clock.
	always @(posedge clk)
	begin
		q <= q + 1;
		
		if (q == 0)
			randclk_temp = 1;
		else
			randclk_temp = 0;
	end

	// 100Mhz % 2^25 = 2.98Hz
	assign randclk = randclk_temp;

	// 100Mhz % 2^18 = 381.47Hz
	assign segclk = q[17];

	// 100Mhz % 2^2 = 25MHz
	assign dclk = q[1];

endmodule
