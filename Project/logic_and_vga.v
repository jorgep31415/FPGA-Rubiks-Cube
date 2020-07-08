`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:32:17 05/26/2019 
// Design Name: 
// Module Name:    logic_and_vga 
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
module logic_and_vga(
	input clk,
	input dclk,
	input randclk,
	input [7:0] sw,
	input btn_reset,
	input is_cw_posedge,
	input is_ccw_posedge,
	input is_hrot_posedge,
	input is_vrot_posedge,
	input [3:0] rand_num,
	output [1:0] state,
	output [12:0] move_count,
	output hsync,
	output vsync,
	output [2:0] red,
	output [2:0] green,
	output [1:0] blue
    );

	reg [161:0] stickers;	//3 bits for each sticker's color (162 colors for 162/3 = 54 stickers)
	reg [17:0] legend;		//3 bits for each legend's color (18 colors for 18/3 = 6 legends)
	
	parameter hpixels = 800;// horizontal pixels per line
	parameter vlines = 521; // vertical lines per frame
	parameter hpulse = 96; 	// hsync pulse length
	parameter vpulse = 2; 	// vsync pulse length
	parameter hbp = 144; 	// end of horizontal back porch
	parameter hfp = 784; 	// beginning of horizontal front porch
	parameter vbp = 31; 		// end of vertical back porch
	parameter vfp = 511; 	// beginning of vertical front porch
	
	reg [9:0] hc;				// horizontal counter
	reg [9:0] vc;				// vertical counter
	
	reg cw_pressed = 0;		// btn_cw is being pressed
	reg ccw_pressed = 0;		// btn_ccw is being pressed
	reg cw_turn = 0;			// clockwise (cw) turn
	reg ccw_turn = 0;			// counterclockwise (ccw) turn
	reg hrot_pressed = 0;	// btn_hrot (horizontal rotation) is being pressed
	reg vrot_pressed = 0;	// btn_vrot (vertical rotation) is being pressed
		
	reg [2:0] curr_color;	// color of current sticker
	reg [2:0] temp;			// temp register for rotating sticker placements
	reg [3:0] prev_rand_move = 1;	//previous random move while scrambling
	reg in_range;			//set to 1, if random move is in range
	integer i = 0;				// iterator
	
	reg [2:0] red_temp;
	reg [2:0] green_temp;
	reg [1:0] blue_temp;
	reg [1:0] state_temp;
	reg [12:0] move_count_temp = 0;	//up to 8192 moves
	
	// traverse/count pixel display position
	always @(posedge dclk)
	begin
		if (hc < hpixels - 1)
			hc <= hc + 1;
		else
			begin
				hc <= 0;
				if (vc < vlines - 1)
					vc <= vc + 1;
				else
					vc <= 0;
			end
	end

	assign hsync = (hc < hpulse) ? 0:1;
	assign vsync = (vc < vpulse) ? 0:1;
	
	

	// functions for sticker logic
   function [26:0] face_cw;
		input [26:0] old;
        reg [26:0] new;
        begin
			new[8:6] 	= old[2:0];		//0->2
            new[17:15] 	= old[5:3];		//1->5
            new[26:24] 	= old[8:6];		//2->8
            new[5:3] 	= old[11:9];	//3->1
            new[14:12] 	= old[14:12];	//4->4
            new[23:21] 	= old[17:15];	//5->7
            new[2:0] 	= old[20:18];	//6->0
            new[11:9] 	= old[23:21];	//7->3
            new[20:18] 	= old[26:24];	//8->6
            face_cw = new;
        end
	endfunction
    
   function [26:0] face_ccw;
		input [26:0] old;
        reg [26:0] new;
        begin
            new[20:18] 	= old[2:0];		//0->6
            new[11:9] 	= old[5:3];		//1->3
            new[2:0] 	= old[8:6];    //2->0
            new[23:21] 	= old[11:9];	//3->7
            new[14:12] 	= old[14:12];	//4->4
            new[5:3] 	= old[17:15];	//5->1
            new[26:24] 	= old[20:18];	//6->8
            new[17:15]	= old[23:21];	//7->5
            new[8:6] 	= old[26:24];	//8->2
            face_ccw = new;
        end
	endfunction

	//cube logic
	always @(posedge clk) begin
			// "one turn per button press" logic
			if(is_cw_posedge) begin
				if(~cw_pressed)
					cw_turn = 1;
				else
					cw_turn = 0;
				cw_pressed = 1;
			end
			else begin
				cw_pressed = 0;
				cw_turn = 0;
			end
			
			if(is_ccw_posedge) begin
				if(~ccw_pressed)
					ccw_turn = 1;
				else
					ccw_turn = 0;
				ccw_pressed = 1;
			end
			else begin
				ccw_pressed = 0;
				ccw_turn = 0;
			end
			
			//rotate horizontally right logic - "whole cube does UP turn - formally, Y move"
			if(is_hrot_posedge) begin
				if(~hrot_pressed) begin
					stickers[134:27] = {stickers[53:27], stickers[134:54]};
					legend[14:3] = {legend[5:3], legend[14:6]};
					stickers[26:0] = face_cw(stickers[26:0]);
					stickers[161:135] = face_ccw(stickers[161:135]);
				end
				hrot_pressed = 1;
			end
			else begin
				hrot_pressed = 0;
			end
			
			//rotate vertically up logic - "whole cube does RIGHT turn - formally, X move"
			if(is_vrot_posedge) begin
				if(~vrot_pressed) begin
					stickers[161:0] = {stickers[134:108], stickers[26:0], stickers[107:81], stickers[161:135], stickers[53:27], stickers[80:54]};
					legend[17:0] = {legend[14:12], legend[2:0], legend[11:9], legend[17:15], legend[5:3], legend[8:6]};
					stickers[107:81] = face_cw(stickers[107:81]);
					stickers[53:27] = face_ccw(stickers[53:27]);
				end
				vrot_pressed = 1;
			end
			else begin
				vrot_pressed = 0;
			end
			
			// solved/default cube
			if (stickers == 0 || btn_reset)
            begin
					legend[17:0] = 18'b101100011010001000;
					state_temp = 0;	// set/reset
					move_count_temp = 0;
               for (i = 0; i < 27; i=i+3) begin
                   stickers[i+2] = 0; stickers[i+1] = 0; stickers[i] = 0;
               end
               for (i = 27; i < 54; i=i+3) begin
                   stickers[i+2] = 0; stickers[i+1] = 0; stickers[i] = 1;
               end
               for (i = 54; i < 81; i=i+3) begin
                   stickers[i+2] = 0; stickers[i+1] = 1; stickers[i] = 0;
               end
               for (i = 81; i < 108; i=i+3) begin
                   stickers[i+2] = 0; stickers[i+1] = 1; stickers[i] = 1;
               end
               for (i = 108; i < 135; i=i+3) begin
                   stickers[i+2] = 1; stickers[i+1] = 0; stickers[i] = 0;
               end
               for (i = 135; i < 162; i=i+3) begin
                   stickers[i+2] = 1; stickers[i+1] = 0; stickers[i] = 1;
               end
            end
				
		  //scramble logic
		  else if (sw[0] && randclk)
				begin
					state_temp = 1;	// scrambling
					move_count_temp = 0;
					case (rand_num + 1)
					  1: begin //UP cw
							stickers[26:0] 	= face_cw(stickers[26:0]);			//[0]

							temp[2:0] 			= stickers[29:27];			   	//save [1][0]
							stickers[29:27] 	= stickers[56:54];		    		//[2][0]->[1][0]
							stickers[56:54] 	= stickers[83:81];		    		//[3][0]->[2][0]
							stickers[83:81] 	= stickers[110:108];					//[4][0]->[3][0]
							stickers[110:108] = temp[2:0];			    			//[1][0]->[4][0]

							temp[2:0] 			= stickers[32:30];			   	//save [1][1]
							stickers[32:30] 	= stickers[59:57];		    		//[2][1]->[1][1]
							stickers[59:57] 	= stickers[86:84];		    		//[3][1]->[2][1]
							stickers[86:84] 	= stickers[113:111];					//[4][1]->[3][1]
							stickers[113:111] = temp[2:0];			    			//[1][1]->[4][1]

							temp[2:0] 			= stickers[35:33];			   	//save [1][2]
							stickers[35:33]	= stickers[62:60];		    		//[2][2]->[1][2]
							stickers[62:60] 	= stickers[89:87];		    		//[3][2]->[2][2]
							stickers[89:87] 	= stickers[116:114];					//[4][2]->[3][2]
							stickers[116:114] = temp[2:0];			    			//[1][2]->[4][2]
					  end
					  2: begin //LEFT cw
							stickers[53:27] 	= face_cw(stickers[53:27]);		//[1]

							temp[2:0] 			= stickers[134:132];			   	//save [4][8]
							stickers[134:132] = stickers[137:135];					//[5][0]->[4][8]
							stickers[137:135] = stickers[56:54];					//[2][0]->[5][0]
							stickers[56:54] 	= stickers[2:0];		    			//[0][0]->[2][0]
							stickers[2:0] 		= temp[2:0];			        		//[4][8]->[0][0]

							temp[2:0] 			= stickers[125:123];			   	//save [4][5]
							stickers[125:123] = stickers[146:144];					//[5][3]->[4][5]
							stickers[146:144] = stickers[65:63];					//[2][3]->[5][3]
							stickers[65:63] 	= stickers[11:9];		    			//[0][3]->[2][3]
							stickers[11:9] 	= temp[2:0];			        		//[4][5]->[0][3]

							temp[2:0] 			= stickers[116:114];			   	//save [4][2]
							stickers[116:114] = stickers[155:153];					//[5][6]->[4][2]
							stickers[155:153] = stickers[74:72];					//[2][6]->[5][6]
							stickers[75:72] 	= stickers[20:18];		    		//[0][6]->[2][6]
							stickers[20:18] 	= temp[2:0];			    			//[4][2]->[0][6]
					  end
					  3: begin //FRONT cw
							stickers[80:54] 	= face_cw(stickers[80:54]);		//[2]

							temp[2:0] 			= stickers[20:18];			   	//save [0][6]
							stickers[20:18] 	= stickers[53:51];		    		//[1][8]->[0][6]
							stickers[53:51] 	= stickers[143:141];					//[5][2]->[1][8]
							stickers[143:141] = stickers[83:81];					//[3][0]->[5][2]
							stickers[83:81] 	= temp[2:0];			    			//[0][6]->[3][0]

							temp[2:0] 			= stickers[23:21];			   	//save [0][7]
							stickers[23:21] 	= stickers[44:42];		    		//[1][5]->[0][7]
							stickers[44:42] 	= stickers[140:138];					//[5][1]->[1][5]
							stickers[140:138] = stickers[92:90];					//[3][3]->[5][1]
							stickers[92:90] 	= temp[2:0];			    			//[0][7]->[3][3]

							temp[2:0] 			= stickers[26:24];			   	//save [0][8]
							stickers[26:24] 	= stickers[35:33];		    		//[1][2]->[0][8]
							stickers[35:33] 	= stickers[137:135];					//[5][0]->[1][2]
							stickers[137:135] = stickers[101:99];					//[3][6]->[5][0]
							stickers[101:99] 	= temp[2:0];			    			//[0][8]->[3][6]
					  end
					  4: begin //RIGHT cw
							stickers[107:81] 	= face_cw(stickers[107:81]);		//[3]

							temp[2:0] 			= stickers[128:126];			 		//save [4][6]
							stickers[128:126] = stickers[8:6];		    			//[0][2]->[4][6]
							stickers[8:6] 		= stickers[62:60];		    		//[2][2]->[0][2]
							stickers[62:60] 	= stickers[143:141];					//[5][2]->[2][2]
							stickers[143:141] = temp[2:0];			    			//[4][6]->[5][2]

							temp[2:0] 			= stickers[119:117];			   	//save [4][3]
							stickers[119:117] = stickers[17:15];					//[0][5]->[4][3]
							stickers[17:15] 	= stickers[71:69];		    		//[2][5]->[0][5]
							stickers[71:69] 	= stickers[152:150];					//[5][5]->[2][5]
							stickers[152:150] = temp[2:0];			    			//[4][3]->[5][5]

							temp[2:0] 			= stickers[110:108];			   	//save [4][0]
							stickers[110:108] = stickers[26:24];					//[0][8]->[4][0]
							stickers[26:24] 	= stickers[80:78];		    		//[2][8]->[0][8]
							stickers[80:78] 	= stickers[161:159];					//[5][8]->[2][8]
							stickers[161:159] = temp[2:0];			    			//[4][0]->[5][8]
					  end
					  5: begin //BACK cw
							stickers[134:108] = face_cw(stickers[134:108]);		//[4]

							temp[2:0] 			= stickers[2:0];			      	//save [0][0]
							stickers[2:0] 		= stickers[89:87];		    		//[3][2]->[0][0]
							stickers[89:87] 	= stickers[161:159];					//[5][8]->[3][2]
							stickers[161:159] = stickers[47:45];					//[1][6]->[5][8]
							stickers[47:45] 	= temp[2:0];			    			//[0][0]->[1][6]

							temp[2:0] 			= stickers[5:3];			      	//save [0][1]
							stickers[5:3] 		= stickers[98:96];		    		//[3][5]->[0][1]
							stickers[98:96] 	= stickers[158:156];					//[5][7]->[3][5]
							stickers[158:156] = stickers[38:36];					//[1][3]->[5][7]
							stickers[38:36] 	= temp[2:0];			    			//[0][1]->[1][3]

							temp[2:0] 			= stickers[8:6];			      	//save [0][2]
							stickers[8:6] 		= stickers[107:105];		    		//[3][8]->[0][2]
							stickers[107:105] = stickers[155:153];					//[5][6]->[3][8]
							stickers[155:153] = stickers[29:27];					//[1][0]->[5][6]
							stickers[29:27] 	= temp[2:0];			    			//[0][2]->[1][0]
					  end
					  6: begin //DOWN cw
							stickers[161:135] = face_cw(stickers[161:135]);		//[5]

							temp[2:0] 			= stickers[47:45];			   	//save [1][6]
							stickers[47:45] 	= stickers[128:126];					//[4][6]->[1][6]
							stickers[128:126] = stickers[101:99];					//[3][6]->[4][6]
							stickers[101:99] 	= stickers[74:72];		    		//[2][6]->[3][6]
							stickers[74:72] 	= temp[2:0];			    			//[1][6]->[2][6]

							temp[2:0] 			= stickers[50:48];			   	//save [1][7]
							stickers[50:48] 	= stickers[131:129];					//[4][7]->[1][7]
							stickers[131:129] = stickers[104:102];					//[3][7]->[4][7]
							stickers[104:102] = stickers[77:75];					//[2][7]->[3][7]
							stickers[77:75] 	= temp[2:0];			    			//[1][7]->[2][7]

							temp[2:0] 			= stickers[53:51];			   	//save [1][8]
							stickers[53:51] 	= stickers[134:132];					//[4][8]->[1][8]
							stickers[134:132] = stickers[107:105];					//[3][8]->[4][8]
							stickers[107:105] = stickers[80:78];					//[2][8]->[3][8]
							stickers[80:78] 	= temp[2:0];			    			//[1][8]->[2][8]
						end
						7: begin //UP ccw
							stickers[26:0] 	= face_ccw(stickers[26:0]);		//[0]

							temp[2:0] 			= stickers[29:27];			   	//save [1][0]
							stickers[29:27] 	= stickers[110:108];					//[4][0]->[1][0]
							stickers[110:108] = stickers[83:81];					//[3][0]->[4][0]
							stickers[83:81] 	= stickers[56:54];		    		//[2][0]->[3][0]
							stickers[56:54] 	= temp[2:0];			    			//[1][0]->[2][0]

							temp[2:0] 			= stickers[32:30];			   	//save [1][1]
							stickers[32:30] 	= stickers[113:111];					//[4][1]->[1][1]
							stickers[113:111] = stickers[86:84];					//[3][1]->[4][1]
							stickers[86:84] 	= stickers[59:57];		    		//[2][1]->[3][1]
							stickers[59:57] 	= temp[2:0];			    			//[1][1]->[2][1]

							temp[2:0] 			= stickers[35:33];			   	//save [1][2]
							stickers[35:33] 	= stickers[116:114];					//[4][2]->[1][2]
							stickers[116:114] = stickers[89:87];					//[3][2]->[4][2]
							stickers[89:87] 	= stickers[62:60];		    		//[2][2]->[3][2]
							stickers[62:60] 	= temp[2:0];			    			//[1][2]->[2][2]
						end
						8: begin //LEFT ccw
							stickers[53:27] 	= face_ccw(stickers[53:27]);		//[1]

							temp[2:0] 			= stickers[134:132];			    	//save [4][8]
							stickers[134:132] = stickers[2:0];		    			//[0][0]->[4][8]
							stickers[2:0] 		= stickers[56:54];		    		//[2][0]->[0][0]
							stickers[56:54] 	= stickers[137:135];					//[5][0]->[2][0]
							stickers[137:135] = temp[2:0];			    			//[4][8]->[5][0]

							temp[2:0] 			= stickers[125:123];			    	//save [4][5]
							stickers[125:123] = stickers[11:9];		    			//[0][3]->[4][5]
							stickers[11:9] 	= stickers[65:63];		    		//[2][3]->[0][3]
							stickers[65:63] 	= stickers[146:144];					//[5][3]->[2][3]
							stickers[146:144] = temp[2:0];			    			//[4][5]->[5][3]

							temp[2:0] 			= stickers[116:114];			    	//save [4][2]
							stickers[116:114] = stickers[20:18];					//[0][6]->[4][2]
							stickers[20:18] 	= stickers[74:72];		    		//[2][6]->[0][6]
							stickers[75:72] 	= stickers[155:153];					//[5][6]->[2][6]
							stickers[155:153] = temp[2:0];			    			//[4][2]->[5][6]
						end
						9: begin //FRONT ccw
							stickers[80:54] 	= face_ccw(stickers[80:54]);		//[2]

							temp[2:0] 			= stickers[20:18];			    	//save [0][6]
							stickers[20:18] 	= stickers[83:81];		    		//[3][0]->[0][6]
							stickers[83:81] 	= stickers[143:141];					//[5][2]->[3][0]
							stickers[143:141] = stickers[53:51];					//[1][8]->[5][2]
							stickers[53:51] 	= temp[2:0];			    			//[0][6]->[1][8]

							temp[2:0] 			= stickers[23:21];			    	//save [0][7]
							stickers[23:21] 	= stickers[92:90];		    		//[3][3]->[0][7]
							stickers[92:90] 	= stickers[140:138];					//[5][1]->[3][3]
							stickers[140:138] = stickers[44:42];					//[1][5]->[5][1]
							stickers[44:42] 	= temp[2:0];			    			//[0][7]->[1][5]

							temp[2:0] 			= stickers[26:24];			    	//save [0][8]
							stickers[26:24] 	= stickers[101:99];		    		//[3][6]->[0][8]
							stickers[101:99] 	= stickers[137:135];					//[5][0]->[3][6]
							stickers[137:135] = stickers[35:33];					//[1][2]->[5][0]
							stickers[35:33] 	= temp[2:0];			    			//[0][8]->[1][2]
						end
						10: begin //RIGHT ccw
							stickers[107:81] 	= face_ccw(stickers[107:81]);		//[3]

							temp[2:0] 			= stickers[128:126];		        	//save [4][6]
							stickers[128:126] = stickers[143:141];					//[5][2]->[4][6]
							stickers[143:141] = stickers[62:60];					//[2][2]->[5][2]
							stickers[62:60] 	= stickers[8:6];		    			//[0][2]->[2][2]
							stickers[8:6] 		= temp[2:0];			        		//[4][6]->[0][2]

							temp[2:0] 			= stickers[119:117];			    	//save [4][3]
							stickers[119:117] = stickers[152:150];					//[5][5]->[4][3]
							stickers[152:150] = stickers[71:69];					//[2][5]->[5][5]
							stickers[71:69] 	= stickers[17:15];		    		//[0][5]->[2][5]
							stickers[17:15] 	= temp[2:0];			    			//[4][3]->[0][5]

							temp[2:0] 			= stickers[110:108];			    	//save [4][0]
							stickers[110:108] = stickers[161:159];					//[5][8]->[4][0]
							stickers[161:159] = stickers[80:78];					//[2][8]->[5][8]
							stickers[80:78] 	= stickers[26:24];		    		//[0][8]->[2][8]
							stickers[26:24] 	= temp[2:0];			    			//[4][0]->[0][8]
						end
						11: begin //BACK ccw
							stickers[134:108] = face_ccw(stickers[134:108]);	//[4]

							temp[2:0] 			= stickers[2:0];			        	//save [0][0]
							stickers[2:0] 		= stickers[47:45];		    		//[1][6]->[0][0]
							stickers[47:45] 	= stickers[161:159];					//[5][8]->[1][6]
							stickers[161:159] = stickers[89:87];					//[3][2]->[5][8]
							stickers[89:87] 	= temp[2:0];			    			//[0][0]->[3][2]

							temp[2:0] 			= stickers[5:3];			        	//save [0][1]
							stickers[5:3] 		= stickers[38:36];		    		//[1][3]->[0][1]
							stickers[38:36] 	= stickers[158:156];					//[5][7]->[1][3]
							stickers[158:156] = stickers[98:96];					//[3][5]->[5][7]
							stickers[98:96] 	= temp[2:0];			    			//[0][1]->[3][5]

							temp[2:0] 			= stickers[8:6];			        	//save [0][2]
							stickers[8:6] 		= stickers[29:27];		    		//[1][0]->[0][2]
							stickers[29:27] 	= stickers[155:153];					//[5][6]->[1][0]
							stickers[155:153] = stickers[107:105];					//[3][8]->[5][6]
							stickers[107:105] = temp[2:0];			    			//[0][2]->[3][8]
						end
						12: begin //DOWN ccw
							stickers[161:135] = face_ccw(stickers[161:135]);	//[5]

							temp[2:0] 			= stickers[47:45];			    	//save [1][6]
							stickers[47:45] 	= stickers[74:72];		    		//[2][6]->[1][6]
							stickers[74:72] 	= stickers[101:99];		    		//[3][6]->[2][6]
							stickers[101:99] 	= stickers[128:126];					//[4][6]->[3][6]
							stickers[128:126] = temp[2:0];			    			//[1][6]->[4][6]

							temp[2:0] 			= stickers[50:48];			    	//save [1][7]
							stickers[50:48] 	= stickers[77:75];		    		//[2][7]->[1][7]
							stickers[77:75] 	= stickers[104:102];					//[3][7]->[2][7]
							stickers[104:102] = stickers[131:129];					//[4][7]->[3][7]
							stickers[131:129] = temp[2:0];			    			//[1][7]->[4][7]

							temp[2:0] 			= stickers[53:51];			    	//save [1][8]
							stickers[53:51] 	= stickers[80:78];		    		//[2][8]->[1][8]
							stickers[80:78] 	= stickers[107:105];					//[3][8]->[2][8]
							stickers[107:105] = stickers[134:132];					//[4][8]->[3][8]
							stickers[134:132] = temp[2:0];			    			//[1][8]->[4][8]
						end
					endcase
				end
		  
		  // clockwise turn logic		  
        else if (cw_turn) 
			begin
				if (state_temp == 1)
					state_temp = 2;
				move_count_temp = move_count_temp + 1;
                case (sw[7:2])
                    'b100000: begin //UP
                        stickers[26:0] 	= face_cw(stickers[26:0]);			//[0]

                        temp[2:0] 			= stickers[29:27];			   	//save [1][0]
                        stickers[29:27] 	= stickers[56:54];		    		//[2][0]->[1][0]
                        stickers[56:54] 	= stickers[83:81];		    		//[3][0]->[2][0]
                        stickers[83:81] 	= stickers[110:108];					//[4][0]->[3][0]
                        stickers[110:108] = temp[2:0];			    			//[1][0]->[4][0]

                        temp[2:0] 			= stickers[32:30];			   	//save [1][1]
                        stickers[32:30] 	= stickers[59:57];		    		//[2][1]->[1][1]
                        stickers[59:57] 	= stickers[86:84];		    		//[3][1]->[2][1]
                        stickers[86:84] 	= stickers[113:111];					//[4][1]->[3][1]
                        stickers[113:111] = temp[2:0];			    			//[1][1]->[4][1]

                        temp[2:0] 			= stickers[35:33];			   	//save [1][2]
                        stickers[35:33]	= stickers[62:60];		    		//[2][2]->[1][2]
                        stickers[62:60] 	= stickers[89:87];		    		//[3][2]->[2][2]
                        stickers[89:87] 	= stickers[116:114];					//[4][2]->[3][2]
                        stickers[116:114] = temp[2:0];			    			//[1][2]->[4][2]
                    end
                    'b010000: begin //LEFT
                        stickers[53:27] 	= face_cw(stickers[53:27]);		//[1]

                        temp[2:0] 			= stickers[134:132];			   	//save [4][8]
                        stickers[134:132] = stickers[137:135];					//[5][0]->[4][8]
                        stickers[137:135] = stickers[56:54];					//[2][0]->[5][0]
                        stickers[56:54] 	= stickers[2:0];		    			//[0][0]->[2][0]
                        stickers[2:0] 		= temp[2:0];			        		//[4][8]->[0][0]

                        temp[2:0] 			= stickers[125:123];			   	//save [4][5]
                        stickers[125:123] = stickers[146:144];					//[5][3]->[4][5]
                        stickers[146:144] = stickers[65:63];					//[2][3]->[5][3]
                        stickers[65:63] 	= stickers[11:9];		    			//[0][3]->[2][3]
                        stickers[11:9] 	= temp[2:0];			        		//[4][5]->[0][3]

                        temp[2:0] 			= stickers[116:114];			   	//save [4][2]
                        stickers[116:114] = stickers[155:153];					//[5][6]->[4][2]
                        stickers[155:153] = stickers[74:72];					//[2][6]->[5][6]
                        stickers[75:72] 	= stickers[20:18];		    		//[0][6]->[2][6]
                        stickers[20:18] 	= temp[2:0];			    			//[4][2]->[0][6]
                    end
                    'b001000: begin //FRONT
                        stickers[80:54] 	= face_cw(stickers[80:54]);		//[2]

                        temp[2:0] 			= stickers[20:18];			   	//save [0][6]
                        stickers[20:18] 	= stickers[53:51];		    		//[1][8]->[0][6]
                        stickers[53:51] 	= stickers[143:141];					//[5][2]->[1][8]
                        stickers[143:141] = stickers[83:81];					//[3][0]->[5][2]
                        stickers[83:81] 	= temp[2:0];			    			//[0][6]->[3][0]

                        temp[2:0] 			= stickers[23:21];			   	//save [0][7]
                        stickers[23:21] 	= stickers[44:42];		    		//[1][5]->[0][7]
                        stickers[44:42] 	= stickers[140:138];					//[5][1]->[1][5]
                        stickers[140:138] = stickers[92:90];					//[3][3]->[5][1]
                        stickers[92:90] 	= temp[2:0];			    			//[0][7]->[3][3]

                        temp[2:0] 			= stickers[26:24];			   	//save [0][8]
                        stickers[26:24] 	= stickers[35:33];		    		//[1][2]->[0][8]
                        stickers[35:33] 	= stickers[137:135];					//[5][0]->[1][2]
                        stickers[137:135] = stickers[101:99];					//[3][6]->[5][0]
                        stickers[101:99] 	= temp[2:0];			    			//[0][8]->[3][6]
                    end
                    'b000100: begin //RIGHT
                        stickers[107:81] 	= face_cw(stickers[107:81]);		//[3]

                        temp[2:0] 			= stickers[128:126];			 		//save [4][6]
                        stickers[128:126] = stickers[8:6];		    			//[0][2]->[4][6]
                        stickers[8:6] 		= stickers[62:60];		    		//[2][2]->[0][2]
                        stickers[62:60] 	= stickers[143:141];					//[5][2]->[2][2]
                        stickers[143:141] = temp[2:0];			    			//[4][6]->[5][2]

                        temp[2:0] 			= stickers[119:117];			   	//save [4][3]
                        stickers[119:117] = stickers[17:15];					//[0][5]->[4][3]
                        stickers[17:15] 	= stickers[71:69];		    		//[2][5]->[0][5]
                        stickers[71:69] 	= stickers[152:150];					//[5][5]->[2][5]
                        stickers[152:150] = temp[2:0];			    			//[4][3]->[5][5]

                        temp[2:0] 			= stickers[110:108];			   	//save [4][0]
                        stickers[110:108] = stickers[26:24];					//[0][8]->[4][0]
                        stickers[26:24] 	= stickers[80:78];		    		//[2][8]->[0][8]
                        stickers[80:78] 	= stickers[161:159];					//[5][8]->[2][8]
                        stickers[161:159] = temp[2:0];			    			//[4][0]->[5][8]
                    end
                    'b000010: begin //BACK
                        stickers[134:108] = face_cw(stickers[134:108]);		//[4]

                        temp[2:0] 			= stickers[2:0];			      	//save [0][0]
                        stickers[2:0] 		= stickers[89:87];		    		//[3][2]->[0][0]
                        stickers[89:87] 	= stickers[161:159];					//[5][8]->[3][2]
                        stickers[161:159] = stickers[47:45];					//[1][6]->[5][8]
                        stickers[47:45] 	= temp[2:0];			    			//[0][0]->[1][6]

                        temp[2:0] 			= stickers[5:3];			      	//save [0][1]
                        stickers[5:3] 		= stickers[98:96];		    		//[3][5]->[0][1]
                        stickers[98:96] 	= stickers[158:156];					//[5][7]->[3][5]
                        stickers[158:156] = stickers[38:36];					//[1][3]->[5][7]
                        stickers[38:36] 	= temp[2:0];			    			//[0][1]->[1][3]

                        temp[2:0] 			= stickers[8:6];			      	//save [0][2]
                        stickers[8:6] 		= stickers[107:105];		    		//[3][8]->[0][2]
                        stickers[107:105] = stickers[155:153];					//[5][6]->[3][8]
                        stickers[155:153] = stickers[29:27];					//[1][0]->[5][6]
                        stickers[29:27] 	= temp[2:0];			    			//[0][2]->[1][0]
                    end
                    'b000001: begin //DOWN
                        stickers[161:135] = face_cw(stickers[161:135]);		//[5]

                        temp[2:0] 			= stickers[47:45];			   	//save [1][6]
                        stickers[47:45] 	= stickers[128:126];					//[4][6]->[1][6]
                        stickers[128:126] = stickers[101:99];					//[3][6]->[4][6]
                        stickers[101:99] 	= stickers[74:72];		    		//[2][6]->[3][6]
                        stickers[74:72] 	= temp[2:0];			    			//[1][6]->[2][6]

                        temp[2:0] 			= stickers[50:48];			   	//save [1][7]
                        stickers[50:48] 	= stickers[131:129];					//[4][7]->[1][7]
                        stickers[131:129] = stickers[104:102];					//[3][7]->[4][7]
                        stickers[104:102] = stickers[77:75];					//[2][7]->[3][7]
                        stickers[77:75] 	= temp[2:0];			    			//[1][7]->[2][7]

                        temp[2:0] 			= stickers[53:51];			   	//save [1][8]
                        stickers[53:51] 	= stickers[134:132];					//[4][8]->[1][8]
                        stickers[134:132] = stickers[107:105];					//[3][8]->[4][8]
                        stickers[107:105] = stickers[80:78];					//[2][8]->[3][8]
                        stickers[80:78] 	= temp[2:0];			    			//[1][8]->[2][8]
                     end
					 default: begin
						move_count_temp = move_count_temp - 1;
					 end
                endcase
            end
		  // counter-clockwise turn logic
        else if (ccw_turn) 
			begin
				if (state_temp == 1)
					state_temp = 2;
				move_count_temp = move_count_temp + 1;
                case (sw[7:2])
                    'b100000: begin //UP
                        stickers[26:0] 	= face_ccw(stickers[26:0]);		//[0]

                        temp[2:0] 			= stickers[29:27];			   	//save [1][0]
                        stickers[29:27] 	= stickers[110:108];					//[4][0]->[1][0]
                        stickers[110:108] = stickers[83:81];					//[3][0]->[4][0]
                        stickers[83:81] 	= stickers[56:54];		    		//[2][0]->[3][0]
                        stickers[56:54] 	= temp[2:0];			    			//[1][0]->[2][0]

                        temp[2:0] 			= stickers[32:30];			   	//save [1][1]
                        stickers[32:30] 	= stickers[113:111];					//[4][1]->[1][1]
                        stickers[113:111] = stickers[86:84];					//[3][1]->[4][1]
                        stickers[86:84] 	= stickers[59:57];		    		//[2][1]->[3][1]
                        stickers[59:57] 	= temp[2:0];			    			//[1][1]->[2][1]

                        temp[2:0] 			= stickers[35:33];			   	//save [1][2]
                        stickers[35:33] 	= stickers[116:114];					//[4][2]->[1][2]
                        stickers[116:114] = stickers[89:87];					//[3][2]->[4][2]
                        stickers[89:87] 	= stickers[62:60];		    		//[2][2]->[3][2]
                        stickers[62:60] 	= temp[2:0];			    			//[1][2]->[2][2]
                    end
                    'b010000: begin //LEFT
                        stickers[53:27] 	= face_ccw(stickers[53:27]);		//[1]

                        temp[2:0] 			= stickers[134:132];			    	//save [4][8]
                        stickers[134:132] = stickers[2:0];		    			//[0][0]->[4][8]
                        stickers[2:0] 		= stickers[56:54];		    		//[2][0]->[0][0]
                        stickers[56:54] 	= stickers[137:135];					//[5][0]->[2][0]
                        stickers[137:135] = temp[2:0];			    			//[4][8]->[5][0]

                        temp[2:0] 			= stickers[125:123];			    	//save [4][5]
                        stickers[125:123] = stickers[11:9];		    			//[0][3]->[4][5]
                        stickers[11:9] 	= stickers[65:63];		    		//[2][3]->[0][3]
                        stickers[65:63] 	= stickers[146:144];					//[5][3]->[2][3]
                        stickers[146:144] = temp[2:0];			    			//[4][5]->[5][3]

                        temp[2:0] 			= stickers[116:114];			    	//save [4][2]
                        stickers[116:114] = stickers[20:18];					//[0][6]->[4][2]
                        stickers[20:18] 	= stickers[74:72];		    		//[2][6]->[0][6]
                        stickers[75:72] 	= stickers[155:153];					//[5][6]->[2][6]
                        stickers[155:153] = temp[2:0];			    			//[4][2]->[5][6]
                    end
                    'b001000: begin //FRONT
                        stickers[80:54] 	= face_ccw(stickers[80:54]);		//[2]

                        temp[2:0] 			= stickers[20:18];			    	//save [0][6]
                        stickers[20:18] 	= stickers[83:81];		    		//[3][0]->[0][6]
                        stickers[83:81] 	= stickers[143:141];					//[5][2]->[3][0]
                        stickers[143:141] = stickers[53:51];					//[1][8]->[5][2]
                        stickers[53:51] 	= temp[2:0];			    			//[0][6]->[1][8]

                        temp[2:0] 			= stickers[23:21];			    	//save [0][7]
                        stickers[23:21] 	= stickers[92:90];		    		//[3][3]->[0][7]
                        stickers[92:90] 	= stickers[140:138];					//[5][1]->[3][3]
                        stickers[140:138] = stickers[44:42];					//[1][5]->[5][1]
                        stickers[44:42] 	= temp[2:0];			    			//[0][7]->[1][5]

                        temp[2:0] 			= stickers[26:24];			    	//save [0][8]
                        stickers[26:24] 	= stickers[101:99];		    		//[3][6]->[0][8]
                        stickers[101:99] 	= stickers[137:135];					//[5][0]->[3][6]
                        stickers[137:135] = stickers[35:33];					//[1][2]->[5][0]
                        stickers[35:33] 	= temp[2:0];			    			//[0][8]->[1][2]
                    end
                    'b000100: begin //RIGHT
                        stickers[107:81] 	= face_ccw(stickers[107:81]);		//[3]

                        temp[2:0] 			= stickers[128:126];		        	//save [4][6]
                        stickers[128:126] = stickers[143:141];					//[5][2]->[4][6]
                        stickers[143:141] = stickers[62:60];					//[2][2]->[5][2]
                        stickers[62:60] 	= stickers[8:6];		    			//[0][2]->[2][2]
                        stickers[8:6] 		= temp[2:0];			        		//[4][6]->[0][2]

                        temp[2:0] 			= stickers[119:117];			    	//save [4][3]
                        stickers[119:117] = stickers[152:150];					//[5][5]->[4][3]
                        stickers[152:150] = stickers[71:69];					//[2][5]->[5][5]
                        stickers[71:69] 	= stickers[17:15];		    		//[0][5]->[2][5]
                        stickers[17:15] 	= temp[2:0];			    			//[4][3]->[0][5]

                        temp[2:0] 			= stickers[110:108];			    	//save [4][0]
                        stickers[110:108] = stickers[161:159];					//[5][8]->[4][0]
                        stickers[161:159] = stickers[80:78];					//[2][8]->[5][8]
                        stickers[80:78] 	= stickers[26:24];		    		//[0][8]->[2][8]
                        stickers[26:24] 	= temp[2:0];			    			//[4][0]->[0][8]
                    end
                    'b000010: begin //BACK
                        stickers[134:108] = face_ccw(stickers[134:108]);	//[4]

                        temp[2:0] 			= stickers[2:0];			        	//save [0][0]
                        stickers[2:0] 		= stickers[47:45];		    		//[1][6]->[0][0]
                        stickers[47:45] 	= stickers[161:159];					//[5][8]->[1][6]
                        stickers[161:159] = stickers[89:87];					//[3][2]->[5][8]
                        stickers[89:87] 	= temp[2:0];			    			//[0][0]->[3][2]

                        temp[2:0] 			= stickers[5:3];			        	//save [0][1]
                        stickers[5:3] 		= stickers[38:36];		    		//[1][3]->[0][1]
                        stickers[38:36] 	= stickers[158:156];					//[5][7]->[1][3]
                        stickers[158:156] = stickers[98:96];					//[3][5]->[5][7]
                        stickers[98:96] 	= temp[2:0];			    			//[0][1]->[3][5]

                        temp[2:0] 			= stickers[8:6];			        	//save [0][2]
                        stickers[8:6] 		= stickers[29:27];		    		//[1][0]->[0][2]
                        stickers[29:27] 	= stickers[155:153];					//[5][6]->[1][0]
                        stickers[155:153] = stickers[107:105];					//[3][8]->[5][6]
                        stickers[107:105] = temp[2:0];			    			//[0][2]->[3][8]
                    end
                    'b000001: begin //DOWN
                        stickers[161:135] = face_ccw(stickers[161:135]);	//[5]

                        temp[2:0] 			= stickers[47:45];			    	//save [1][6]
                        stickers[47:45] 	= stickers[74:72];		    		//[2][6]->[1][6]
                        stickers[74:72] 	= stickers[101:99];		    		//[3][6]->[2][6]
                        stickers[101:99] 	= stickers[128:126];					//[4][6]->[3][6]
                        stickers[128:126] = temp[2:0];			    			//[1][6]->[4][6]

                        temp[2:0] 			= stickers[50:48];			    	//save [1][7]
                        stickers[50:48] 	= stickers[77:75];		    		//[2][7]->[1][7]
                        stickers[77:75] 	= stickers[104:102];					//[3][7]->[2][7]
                        stickers[104:102] = stickers[131:129];					//[4][7]->[3][7]
                        stickers[131:129] = temp[2:0];			    			//[1][7]->[4][7]

                        temp[2:0] 			= stickers[53:51];			    	//save [1][8]
                        stickers[53:51] 	= stickers[80:78];		    		//[2][8]->[1][8]
                        stickers[80:78] 	= stickers[107:105];					//[3][8]->[2][8]
                        stickers[107:105] = stickers[134:132];					//[4][8]->[3][8]
                        stickers[134:132] = temp[2:0];			    			//[1][8]->[4][8]
                    end
					default: begin
						move_count_temp = move_count_temp - 1;
					end
                endcase
            end
			
			// if cube underwent scrambling, change to special state if solved! 
			if (state_temp == 2 &&
				 stickers[26:0]    == {stickers[2:0], stickers[2:0], stickers[2:0], 
											  stickers[2:0], stickers[2:0], stickers[2:0], 
										     stickers[2:0], stickers[2:0], stickers[2:0]} &&
				 stickers[53:27]   == {stickers[29:27], stickers[29:27], stickers[29:27], 
											  stickers[29:27], stickers[29:27], stickers[29:27], 
											  stickers[29:27], stickers[29:27], stickers[29:27]} &&
				 stickers[80:54]   == {stickers[56:54], stickers[56:54], stickers[56:54], 
											  stickers[56:54], stickers[56:54], stickers[56:54], 
											  stickers[56:54], stickers[56:54], stickers[56:54]} &&						
				 stickers[107:81]  == {stickers[83:81], stickers[83:81], stickers[83:81], 
											  stickers[83:81], stickers[83:81], stickers[83:81], 
											  stickers[83:81], stickers[83:81], stickers[83:81]} &&							
				 stickers[134:108] == {stickers[110:108], stickers[110:108], stickers[110:108], 
											  stickers[110:108], stickers[110:108], stickers[110:108], 
											  stickers[110:108], stickers[110:108], stickers[110:108]} &&
				 stickers[161:135] == {stickers[137:135], stickers[137:135], stickers[137:135], 
											  stickers[137:135], stickers[137:135], stickers[137:135], 
											  stickers[137:135], stickers[137:135], stickers[137:135]})
				begin
					state_temp = 3;
				end
	end
	
	//assign correct permutation to cube (proper sticker colors)
	always @(posedge clk)
	begin
        // TOP face
        if(hc >= hbp+160 && hc < hbp+190 && vc >= vbp+40 && vc < vbp+70)
            curr_color = stickers[2:0];
        else if(hc >= hbp+195 && hc < hbp+225 && vc >= vbp+40 && vc < vbp+70)
            curr_color = stickers[5:3];
        else if(hc >= hbp+230 && hc < hbp+260 && vc >= vbp+40 && vc < vbp+70)
            curr_color = stickers[8:6];
        else if(hc >= hbp+160 && hc < hbp+190 && vc >= vbp+75 && vc < vbp+105)
            curr_color = stickers[11:9];
        else if(hc >= hbp+195 && hc < hbp+225 && vc >= vbp+75 && vc < vbp+105)
            curr_color = stickers[14:12];
        else if(hc >= hbp+230 && hc < hbp+260 && vc >= vbp+75 && vc < vbp+105)
            curr_color = stickers[17:15];
        else if(hc >= hbp+160 && hc < hbp+190 && vc >= vbp+110 && vc < vbp+140)
            curr_color = stickers[20:18];
        else if(hc >= hbp+195 && hc < hbp+225 && vc >= vbp+110 && vc < vbp+140)
            curr_color = stickers[23:21];
        else if(hc >= hbp+230 && hc < hbp+260 && vc >= vbp+110 && vc < vbp+140)
            curr_color = stickers[26:24];
        
        // LEFT face
        else if(hc >= hbp+40 && hc < hbp+70 && vc >= vbp+160 && vc < vbp+190)
            curr_color = stickers[29:27];
        else if(hc >= hbp+75 && hc < hbp+105 && vc >= vbp+160 && vc < vbp+190)
            curr_color = stickers[32:30];
        else if(hc >= hbp+110 && hc < hbp+140 && vc >= vbp+160 && vc < vbp+190)
            curr_color = stickers[35:33];
        else if(hc >= hbp+40 && hc < hbp+70 && vc >= vbp+195 && vc < vbp+225)
            curr_color = stickers[38:36];
        else if(hc >= hbp+75 && hc < hbp+105 && vc >= vbp+195 && vc < vbp+225)
            curr_color = stickers[41:39];
        else if(hc >= hbp+110 && hc < hbp+140 && vc >= vbp+195 && vc < vbp+225)
            curr_color = stickers[44:42];
        else if(hc >= hbp+40 && hc < hbp+70 && vc >= vbp+230 && vc < vbp+260)
            curr_color = stickers[47:45];
        else if(hc >= hbp+75 && hc < hbp+105 && vc >= vbp+230 && vc < vbp+260)
            curr_color = stickers[50:48];
        else if(hc >= hbp+110 && hc < hbp+140 && vc >= vbp+230 && vc < vbp+260)
            curr_color = stickers[53:51];
        
        // FRONT face
        else if(hc >= hbp+160 && hc < hbp+190 && vc >= vbp+160 && vc < vbp+190)
            curr_color = stickers[56:54];
        else if(hc >= hbp+195 && hc < hbp+225 && vc >= vbp+160 && vc < vbp+190)
            curr_color = stickers[59:57];
        else if(hc >= hbp+230 && hc < hbp+260 && vc >= vbp+160 && vc < vbp+190)
            curr_color = stickers[62:60];
        else if(hc >= hbp+160 && hc < hbp+190 && vc >= vbp+195 && vc < vbp+225)
            curr_color = stickers[65:63];
        else if(hc >= hbp+195 && hc < hbp+225 && vc >= vbp+195 && vc < vbp+225)
            curr_color = stickers[68:66];
        else if(hc >= hbp+230 && hc < hbp+260 && vc >= vbp+195 && vc < vbp+225)
            curr_color = stickers[71:69];
        else if(hc >= hbp+160 && hc < hbp+190 && vc >= vbp+230 && vc < vbp+260)
            curr_color = stickers[74:72];
        else if(hc >= hbp+195 && hc < hbp+225 && vc >= vbp+230 && vc < vbp+260)
            curr_color = stickers[77:75];
        else if(hc >= hbp+230 && hc < hbp+260 && vc >= vbp+230 && vc < vbp+260)
            curr_color = stickers[80:78];
        
        // RIGHT face
        else if(hc >= hbp+280 && hc < hbp+310 && vc >= vbp+160 && vc < vbp+190)
            curr_color = stickers[83:81];
        else if(hc >= hbp+315 && hc < hbp+345 && vc >= vbp+160 && vc < vbp+190)
            curr_color = stickers[86:84];
        else if(hc >= hbp+350 && hc < hbp+380 && vc >= vbp+160 && vc < vbp+190)
            curr_color = stickers[89:87];
        else if(hc >= hbp+280 && hc < hbp+310 && vc >= vbp+195 && vc < vbp+225)
            curr_color = stickers[92:90];
        else if(hc >= hbp+315 && hc < hbp+345 && vc >= vbp+195 && vc < vbp+225)
            curr_color = stickers[95:93];
        else if(hc >= hbp+350 && hc < hbp+380 && vc >= vbp+195 && vc < vbp+225)
            curr_color = stickers[98:96];
        else if(hc >= hbp+280 && hc < hbp+310 && vc >= vbp+230 && vc < vbp+260)
            curr_color = stickers[101:99];
        else if(hc >= hbp+315 && hc < hbp+345 && vc >= vbp+230 && vc < vbp+260)
            curr_color = stickers[104:102];
        else if(hc >= hbp+350 && hc < hbp+380 && vc >= vbp+230 && vc < vbp+260)
            curr_color = stickers[107:105];
        
        // BACK face
        else if(hc >= hbp+400 && hc < hbp+430 && vc >= vbp+160 && vc < vbp+190)
            curr_color = stickers[110:108];
        else if(hc >= hbp+435 && hc < hbp+465 && vc >= vbp+160 && vc < vbp+190)
            curr_color = stickers[113:111];
        else if(hc >= hbp+470 && hc < hbp+500 && vc >= vbp+160 && vc < vbp+190)
            curr_color = stickers[116:114];
        else if(hc >= hbp+400 && hc < hbp+430 && vc >= vbp+195 && vc < vbp+225)
            curr_color = stickers[119:117];
        else if(hc >= hbp+435 && hc < hbp+465 && vc >= vbp+195 && vc < vbp+225)
            curr_color = stickers[122:120];
        else if(hc >= hbp+470 && hc < hbp+500 && vc >= vbp+195 && vc < vbp+225)
            curr_color = stickers[125:123];
        else if(hc >= hbp+400 && hc < hbp+430 && vc >= vbp+230 && vc < vbp+260)
            curr_color = stickers[128:126];
        else if(hc >= hbp+435 && hc < hbp+465 && vc >= vbp+230 && vc < vbp+260)
            curr_color = stickers[131:129];
        else if(hc >= hbp+470 && hc < hbp+500 && vc >= vbp+230 && vc < vbp+260)
            curr_color = stickers[134:132];
        
        // DOWN face
        else if(hc >= hbp+160 && hc < hbp+190 && vc >= vbp+280 && vc < vbp+310)
            curr_color = stickers[137:135];
        else if(hc >= hbp+195 && hc < hbp+225 && vc >= vbp+280 && vc < vbp+310)
            curr_color = stickers[140:138];
        else if(hc >= hbp+230 && hc < hbp+260 && vc >= vbp+280 && vc < vbp+310)
            curr_color = stickers[143:141];
        else if(hc >= hbp+160 && hc < hbp+190 && vc >= vbp+315 && vc < vbp+345)
            curr_color = stickers[146:144];
        else if(hc >= hbp+195 && hc < hbp+225 && vc >= vbp+315 && vc < vbp+345)
            curr_color = stickers[149:147];
        else if(hc >= hbp+230 && hc < hbp+260 && vc >= vbp+315 && vc < vbp+345)
            curr_color = stickers[152:150];
        else if(hc >= hbp+160 && hc < hbp+190 && vc >= vbp+350 && vc < vbp+380)
            curr_color = stickers[155:153];
        else if(hc >= hbp+195 && hc < hbp+225 && vc >= vbp+350 && vc < vbp+380)
            curr_color = stickers[158:156];
        else if(hc >= hbp+230 && hc < hbp+260 && vc >= vbp+350 && vc < vbp+380)
            curr_color = stickers[161:159];
        
        // legend - on bottom right of display
        else if(hc >= hbp+460 && hc < hbp+470 && vc >= vbp+420 && vc < vbp+430)
            curr_color = legend[2:0];
        else if(hc >= hbp+480 && hc < hbp+490 && vc >= vbp+420 && vc < vbp+430)
            curr_color = legend[5:3];
        else if(hc >= hbp+500 && hc < hbp+510 && vc >= vbp+420 && vc < vbp+430)
            curr_color = legend[8:6];
        else if(hc >= hbp+520 && hc < hbp+530 && vc >= vbp+420 && vc < vbp+430)
            curr_color = legend[11:9];
        else if(hc >= hbp+540 && hc < hbp+550 && vc >= vbp+420 && vc < vbp+430)
            curr_color = legend[14:12];
        else if(hc >= hbp+560 && hc < hbp+570 && vc >= vbp+420 && vc < vbp+430)
            curr_color = legend[17:15];
              
        // default color - black
        else 
            curr_color = 'b110;
        
		  //decode sticker 3-bit code to sticker color
        case (curr_color[2:0])
            'b000: //white
                begin
                    red_temp = 3'b111;
                    green_temp = 3'b111;
                    blue_temp = 2'b11;
                end
            'b001: //orange
                begin
                    red_temp = 3'b111;
                    green_temp = 3'b100;
                    blue_temp = 2'b00;
                end
            'b010: //green
                begin
                    red_temp = 3'b000;
                    green_temp = 3'b111;
                    blue_temp = 2'b00;
                end
            'b011: //red
                begin
                    red_temp = 3'b111;
                    green_temp = 3'b000;
                    blue_temp = 2'b00;
                end
            'b100: //blue
                begin
                    red_temp = 3'b001;
                    green_temp = 3'b001;
                    blue_temp = 2'b11;
                end
            'b101: //yellow 
                begin
                    red_temp = 3'b111;
                    green_temp = 3'b111;
                    blue_temp = 2'b00;
                end
            'b110: //black
                begin
                    red_temp = 3'b000;
                    green_temp = 3'b000;
                    blue_temp = 2'b00;
                end
        endcase
    end
    
    assign red = red_temp;
    assign green = green_temp;
    assign blue = blue_temp;
	assign state = state_temp;
	assign move_count = move_count_temp;
    
endmodule
