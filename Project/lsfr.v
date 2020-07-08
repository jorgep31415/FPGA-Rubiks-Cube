//-----------------------------------------------------
// Design Name : lfsr
// File Name   : lfsr.v
// Function    : Linear feedback shift register
// Coder       : Deepak Kumar Tala
//-----------------------------------------------------
module lfsr    (
	input clk,
	output reg [3:0] out
	);

	wire linear_feedback;
	reg [3:0] out_assign;

	assign linear_feedback = ~(out_assign[3] ^ out_assign[2]);

	always @(posedge clk) begin
		if ({out_assign[2:0], linear_feedback} < 12)
			out <= {out_assign[2:0], linear_feedback};
		out_assign <= {out_assign[2:0], linear_feedback};
	end
	
endmodule