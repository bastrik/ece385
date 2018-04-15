// Game logic for ECE 385 final project
// April 13, 2018

module game_logic (input logic VGA_VS,
				   input logic [31:0] keycode,
				   input logic [31:0] PS2keycode,
				   output logic [11:0] xOne,
				   output logic [11:0] yOne,
				   output logic [11:0] xTwo,
				   output logic [11:0] yTwo,
				   output logic [1:0] p1dir,		// direction player is facing
				   output logic [1:0] p2dir);	// 0-> north, 1-> south, 2-> east, 3-> west

// Location of player on map
assign xOne = _xOne;
assign yOne = _yOne;
assign xTwo = _xTwo;
assign yTwo = _yTwo;

// always_ff player direction
logic [1:0] p1dir_ff, p2dir_ff;

// Location of players on map
logic [11:0] _xOne = 12'd700;
logic [11:0] _yOne = 12'd700;
logic [11:0] _xTwo = 12'd2500;
logic [11:0] _yTwo = 12'd1700;

always_ff @ (posedge VGA_VS)
begin
	_xOne <= ((_xOne + eastOne - westOne >= 12'd64) & (_xOne + eastOne - westOne <= 12'd3136))? _xOne + eastOne - westOne:_xOne;
	_yOne <= ((_yOne + southOne - northOne >= 12'd64) & (_yOne + southOne - northOne <= 12'd2336))? _yOne + southOne - northOne:_yOne;
	_xTwo <= ((_xTwo + eastTwo - westTwo >= 12'd64) & (_xTwo + eastTwo - westTwo <= 12'd3136))? _xTwo + eastTwo - westTwo:_xTwo;
	_yTwo <= ((_yTwo + southTwo - northTwo >= 12'd64) & (_yTwo + southTwo - northTwo <= 12'd2336))? _yTwo + southTwo - northTwo:_yTwo;
end

// Player motion
logic [11:0] northOne, southOne, eastOne, westOne;
logic [11:0] northTwo, southTwo, eastTwo, westTwo;

// Four-key rollover
logic [7:0] aOne, bOne, cOne, dOne;
logic [7:0] aTwo, bTwo, cTwo, dTwo;

// PS2 keyboard for player 1, USB keyboard for player 2
assign aOne = PS2keycode[7:0];
assign bOne = PS2keycode[15:8];
assign cOne = PS2keycode[23:16];
assign dOne = PS2keycode[31:24];
assign aTwo = keycode[7:0];
assign bTwo = keycode[15:8];
assign cTwo = keycode[23:16];
assign dTwo = keycode[31:24];

// // USB keyboard for player 1, PS2 keyboard for player 2
// assign aOne = keycode[7:0];
// assign bOne = keycode[15:8];
// assign cOne = keycode[23:16];
// assign dOne = keycode[31:24];
// assign aTwo = PS2keycode[7:0];
// assign bTwo = PS2keycode[15:8];
// assign cTwo = PS2keycode[23:16];
// assign dTwo = PS2keycode[31:24];

always_ff @(posedge VGA_VS)
begin
	p1dir_ff <= p1dir;
	p2dir_ff <= p2dir;
end

// Player 1 motion and shooting
always_comb
begin
	northOne = 12'd0;
	southOne = 12'd0;
	eastOne = 12'd0;
	westOne = 12'd0;
	p1dir = p1dir_ff;

	// W
	if (aOne == 8'h1A | bOne == 8'h1A | cOne == 8'h1A | dOne == 8'h1A)
	begin
		northOne = 12'd2;
		p1dir = 2'd0;
	end
	// A
	if (aOne == 8'h04 | bOne == 8'h04 | cOne == 8'h04 | dOne == 8'h04)
	begin
		westOne = 12'd2;
		p1dir = 2'd3;	
	end
	// S
	if (aOne == 8'h16 | bOne == 8'h16 | cOne == 8'h16 | dOne == 8'h16)
	begin
		southOne = 12'd2;
		p1dir = 2'd1;
	end
	// D
	if (aOne == 8'h07 | bOne == 8'h07 | cOne == 8'h07 | dOne == 8'h07)
	begin
		eastOne = 12'd2;
		p1dir = 2'd2;
	end
	// up arrow
	if (aOne == 8'h52 | bOne == 8'h52 | cOne == 8'h52 | dOne == 8'h52)
	begin
		p1dir = 2'd0;
	end
	// down arrow
	if (aOne == 8'h04 | bOne == 8'h04 | cOne == 8'h04 | dOne == 8'h04)
	begin
		p1dir = 2'd1;	
	end
	// left arrow
	if (aOne == 8'h50 | bOne == 8'h50 | cOne == 8'h50 | dOne == 8'h50)
	begin
		p1dir = 2'd3;
	end
	// right arrow
	if (aOne == 8'h4f | bOne == 8'h4f | cOne == 8'h4f | dOne == 8'h4f)
	begin
		p1dir = 2'd2;
	end

end

// Player 2 motion and shooting
always_comb
begin
	northTwo = 12'd0;
	southTwo = 12'd0;
	eastTwo = 12'd0;
	westTwo = 12'd0;
	p2dir = p2dir_ff;

	// W
	if (aTwo == 8'h1D | bTwo == 8'h1D | cTwo == 8'h1D | dTwo == 8'h1D)
	begin
		northTwo = 12'd2;
		p2dir = 2'd0;
	end
	// A
	if (aTwo == 8'h1C | bTwo == 8'h1C | cTwo == 8'h1C | dTwo == 8'h1C)
	begin
		northTwo = 12'd2;
		p2dir = 2'd3;
	end
	// S
	if (aTwo == 8'h1B | bTwo == 8'h1B | cTwo == 8'h1B | dTwo == 8'h1B)
	begin
		northTwo = 12'd2;
		p2dir = 2'd1;
	end
	// D
	if (aTwo == 8'h23 | bTwo == 8'h23 | cTwo == 8'h23 | dTwo == 8'h23)
	begin
		northTwo = 12'd2;
		p2dir = 2'd2;
	end
	// up arrow
	if (aOne == 8'h75 | bOne == 8'h75 | cOne == 8'h75 | dOne == 8'h75)
	begin
		p2dir = 2'd0;
	end
	// down arrow
	if (aOne == 8'h72 | bOne == 8'h72 | cOne == 8'h72 | dOne == 8'h72)
	begin
		p2dir = 2'd1;	
	end
	// left arrow
	if (aOne == 8'h6B | bOne == 8'h6B | cOne == 8'h6B | dOne == 8'h6B)
	begin
		p2dir = 2'd3;
	end
	// right arrow
	if (aOne == 8'h74 | bOne == 8'h74 | cOne == 8'h74 | dOne == 8'h74)
	begin
		p2dir = 2'd2;
	end
end
// always_comb
// begin
//     // By default, keep motion and position unchanged
//     Ball_X_Pos_in = Ball_X_Pos;
//     Ball_Y_Pos_in = Ball_Y_Pos;
//     Ball_X_Motion_in = Ball_X_Motion;
//     Ball_Y_Motion_in = Ball_Y_Motion;
    
//     // Update position and motion only at rising edge of frame clock
//     if (frame_clk_rising_edge)
//     begin
//         // Be careful when using comparators with "logic" datatype because compiler treats 
//         //   both sides of the operator as UNSIGNED numbers.
//         // e.g. Ball_Y_Pos - Ball_Size <= Ball_Y_Min 
//         // If Ball_Y_Pos is 0, then Ball_Y_Pos - Ball_Size will not be -4, but rather a large positive number.
//         case (keycode)
//             8'h1A:      // w
//             begin
//                 Ball_Y_Motion_in = (~(Ball_Y_Step) + 1'b1);
//                 Ball_X_Motion_in = 0;
//             end
//             8'h04:      // a
//             begin
//                 Ball_Y_Motion_in = 0;
//                 Ball_X_Motion_in = (~(Ball_X_Step) + 1'b1);
//             end
//             8'h16:      // s
//             begin
//                 Ball_Y_Motion_in = Ball_Y_Step;
//                 Ball_X_Motion_in = 0;
//             end
//             8'h07:      // d
//             begin
//                 Ball_Y_Motion_in = 0;
//                 Ball_X_Motion_in = Ball_X_Step;
//             end
//             default : ;
//         endcase
//         // *************** Y-DIRECTION CONDITIONS ****************** //
//         if( Ball_Y_Pos + Ball_Size >= Ball_Y_Max )  // Ball is at the bottom edge, BOUNCE!
// 			begin
//             Ball_X_Motion_in = 0;
// 				 Ball_Y_Motion_in = (~(Ball_Y_Step) + 1'b1);  // 2's complement.  
// 				 end 
//         else if ( Ball_Y_Pos <= Ball_Y_Min + Ball_Size )  // Ball is at the top edge, BOUNCE!
// 			begin
//             Ball_X_Motion_in = 0;
// 				 Ball_Y_Motion_in = Ball_Y_Step;
// 				 end

//         // *************** X-DIRECTION CONDITIONS ****************** //
//         if( Ball_X_Pos + Ball_Size >= Ball_X_Max )  // Ball is at the RIGHT edge, BOUNCE!
// 			begin
//             Ball_X_Motion_in = (~(Ball_X_Step) + 1'b1);  // 2's complement.  
// 				 Ball_Y_Motion_in = 0;
// 				 end
//         else if ( Ball_X_Pos <= Ball_X_Min + Ball_Size )  // Ball is at the LEFT edge, BOUNCE!
// 			begin
//             Ball_X_Motion_in = Ball_X_Step;
// 				 Ball_Y_Motion_in = 0;
// 				 end

//         // *************** KEY PRESS CONDITIONS ****************** //

    
//         // Update the ball's position with its motion
//         Ball_X_Pos_in = Ball_X_Pos + Ball_X_Motion;
//         Ball_Y_Pos_in = Ball_Y_Pos + Ball_Y_Motion;

endmodule