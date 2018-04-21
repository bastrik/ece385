// Game logic for ECE 385 final project
// April 13, 2018

module game_logic (input logic Clk, VGA_VS,
				   input logic [31:0] keycode,
				   input logic [31:0] PS2keycode,
				   output logic [11:0] xOne,
				   output logic [11:0] yOne,
				   output logic [11:0] xTwo,
				   output logic [11:0] yTwo,
				   output logic [1:0] p1dir, // direction player is moving
				   output logic [1:0] p2dir, // 0-> north, 1-> south, 2-> east, 3-> west
				   output logic [11:0] b1X, b1Y, b2X, b2Y, b3X, b3Y, b4X, b4Y, b5X, b5Y, b6X, b6Y, b7X, b7Y, b8X, b8Y, b9X, b9Y, b10X, b10Y, b11X, b11Y, b12X, b12Y, b13X, b13Y, b14X, b14Y, b15X, b15Y, b16X, b16Y,
				   output logic b1active, b2active, b3active, b4active, b5active, b6active, b7active, b8active, b9active, b10active, b11active, b12active, b13active, b14active, b15active, b16active);	

// Player motion
logic [11:0] northOne, southOne, eastOne, westOne;
logic [11:0] northTwo, southTwo, eastTwo, westTwo;
logic [1:0] p1dir_comb, p2dir_comb;

// Direction in which player is shooting
logic [1:0] p1fire, p2fire; // direction player is shooting
logic [1:0] p1fire_comb, p2fire_comb; // 0-> north, 1-> south, 2-> east, 3-> west

// Restrict how often each player can shoot
logic [24:0] firing_counter_1 = 25'd0;
logic [24:0] firing_counter_2 = 25'd0;
logic fire_flag_1 = 1'b1;
logic fire_flag_2 = 1'b1;

always_ff @ (posedge Clk)
begin
	// Allow player to fire again
	if (firing_counter_1 >= 25'd30000000)
	begin
		firing_counter_1 <= 25'd0;
		fire_flag_1 <= 1'b1;
	end
	// Don't allow player to fire
	else if (b1CD == 1'b1)
	begin
		firing_counter_1 <= firing_counter_1 + 25'd1;
		fire_flag_1 <= 1'b0;
	end

	// Allow player to fire again
	if (firing_counter_2 >= 25'd30000000)
	begin
		firing_counter_2 <= 25'd0;
		fire_flag_2 <= 1'b1;
	end
	// Don't allow player to fire
	else if (b2CD == 1'b1)
	begin
		firing_counter_2 <= firing_counter_2 + 25'd1;
		fire_flag_2 <= 1'b0;
	end
end

// Four-key rollover
logic [7:0] aOne, bOne, cOne, dOne;
logic [7:0] aTwo, bTwo, cTwo, dTwo;

// USB keyboard for player 1, PS2 keyboard for player 2
assign aOne = keycode[7:0];
assign bOne = keycode[15:8];
assign cOne = keycode[23:16];
assign dOne = keycode[31:24];
assign aTwo = PS2keycode[7:0];
assign bTwo = PS2keycode[15:8];
assign cTwo = PS2keycode[23:16];
assign dTwo = PS2keycode[31:24];


//// SHOOTING
logic b1CD = 1'b0;
logic b2CD = 1'b0;
logic [3:0] BULLETSPEED = 4'd6;
always_ff @ (posedge Clk)
begin
	if (b1set)
		b1set <= 1'b0;
	if (b2set)
		b2set <= 1'b0;
	if (b3set)
		b3set <= 1'b0;
	if (b4set)
		b4set <= 1'b0;
	if (b5set)
		b5set <= 1'b0;
	if (b6set)
		b6set <= 1'b0;
	if (b7set)
		b7set <= 1'b0;
	if (b8set)
		b8set <= 1'b0;
	if (b9set)
		b9set <= 1'b0;
	if (b10set)
		b10set <= 1'b0;
	if (b11set)
		b11set <= 1'b0;
	if (b12set)
		b12set <= 1'b0;
	if (b13set)
		b13set <= 1'b0;
	if (b14set)
		b14set <= 1'b0;
	if (b15set)
		b15set <= 1'b0;
	if (b16set)
		b16set <= 1'b0;
	if (set_bullet1 & ~b1CD) // no cooldown, fire
	begin
		b1CD <= 1'b1;
		if(b1active == 1'b0)
		begin
			b1set <= 1'b1;
			case (p1fire)
				2'd0:
				begin
					b1sX <= xOne;
					b1sY <= yOne - 12'd41;
					b1west <= westOne;
					b1east <= eastOne;
					b1north <= BULLETSPEED;
					b1south <= 4'd0;
				end
				2'd1:
				begin
					b1sX <= xOne;
					b1sY <= yOne + 12'd41;
					b1west <= westOne;
					b1east <= eastOne;
					b1north <= 4'd0;
					b1south <= BULLETSPEED;
				end
				2'd2:
				begin
					b1sX <= xOne + 12'd41;
					b1sY <= yOne;
					b1west <= 4'd0;
					b1east <= BULLETSPEED;
					b1north <= northOne;
					b1south <= southOne;
				end
				2'd3:
				begin
					b1sX <= xOne - 12'd41;
					b1sY <= yOne;
					b1west <= BULLETSPEED;
					b1east <= 4'd0;
					b1north <= northOne;
					b1south <= southOne;
				end
			endcase
		end
		else if(b2active == 1'b0)
		begin
			b2set <= 1'b1;
			case (p1fire)
				2'd0:
				begin
					b2sX <= xOne;
					b2sY <= yOne - 12'd41;
					b2west <= westOne;
					b2east <= eastOne;
					b2north <= BULLETSPEED;
					b2south <= 4'd0;
				end
				2'd1:
				begin
					b2sX <= xOne;
					b2sY <= yOne + 12'd41;
					b2west <= westOne;
					b2east <= eastOne;
					b2north <= 4'd0;
					b2south <= BULLETSPEED;
				end
				2'd2:
				begin
					b2sX <= xOne + 12'd41;
					b2sY <= yOne;
					b2west <= 4'd0;
					b2east <= BULLETSPEED;
					b2north <= northOne;
					b2south <= southOne;
				end
				2'd3:
				begin
					b2sX <= xOne - 12'd41;
					b2sY <= yOne;
					b2west <= BULLETSPEED;
					b2east <= 4'd0;
					b2north <= northOne;
					b2south <= southOne;
				end
			endcase
		end
		else if(b3active == 1'b0)
		begin
			b3set <= 1'b1;
			case (p1fire)
				2'd0:
				begin
					b3sX <= xOne;
					b3sY <= yOne - 12'd41;
					b3west <= westOne;
					b3east <= eastOne;
					b3north <= BULLETSPEED;
					b3south <= 4'd0;
				end
				2'd1:
				begin
					b3sX <= xOne;
					b3sY <= yOne + 12'd41;
					b3west <= westOne;
					b3east <= eastOne;
					b3north <= 4'd0;
					b3south <= BULLETSPEED;
				end
				2'd2:
				begin
					b3sX <= xOne + 12'd41;
					b3sY <= yOne;
					b3west <= 4'd0;
					b3east <= BULLETSPEED;
					b3north <= northOne;
					b3south <= southOne;
				end
				2'd3:
				begin
					b3sX <= xOne - 12'd41;
					b3sY <= yOne;
					b3west <= BULLETSPEED;
					b3east <= 4'd0;
					b3north <= northOne;
					b3south <= southOne;
				end
			endcase
		end
		else if(b4active == 1'b0)
		begin
			b4set <= 1'b1;
			case (p1fire)
				2'd0:
				begin
					b4sX <= xOne;
					b4sY <= yOne - 12'd41;
					b4west <= westOne;
					b4east <= eastOne;
					b4north <= BULLETSPEED;
					b4south <= 4'd0;
				end
				2'd1:
				begin
					b4sX <= xOne;
					b4sY <= yOne + 12'd41;
					b4west <= westOne;
					b4east <= eastOne;
					b4north <= 4'd0;
					b4south <= BULLETSPEED;
				end
				2'd2:
				begin
					b4sX <= xOne + 12'd41;
					b4sY <= yOne;
					b4west <= 4'd0;
					b4east <= BULLETSPEED;
					b4north <= northOne;
					b4south <= southOne;
				end
				2'd3:
				begin
					b4sX <= xOne - 12'd41;
					b4sY <= yOne;
					b4west <= BULLETSPEED;
					b4east <= 4'd0;
					b4north <= northOne;
					b4south <= southOne;
				end
			endcase
		end
		else if(b5active == 1'b0)
		begin
			b5set <= 1'b1;
			case (p1fire)
				2'd0:
				begin
					b5sX <= xOne;
					b5sY <= yOne - 12'd41;
					b5west <= westOne;
					b5east <= eastOne;
					b5north <= BULLETSPEED;
					b5south <= 4'd0;
				end
				2'd1:
				begin
					b5sX <= xOne;
					b5sY <= yOne + 12'd41;
					b5west <= westOne;
					b5east <= eastOne;
					b5north <= 4'd0;
					b5south <= BULLETSPEED;
				end
				2'd2:
				begin
					b5sX <= xOne + 12'd41;
					b5sY <= yOne;
					b5west <= 4'd0;
					b5east <= BULLETSPEED;
					b5north <= northOne;
					b5south <= southOne;
				end
				2'd3:
				begin
					b5sX <= xOne - 12'd41;
					b5sY <= yOne;
					b5west <= BULLETSPEED;
					b5east <= 4'd0;
					b5north <= northOne;
					b5south <= southOne;
				end
			endcase
		end
		else if(b6active == 1'b0)
		begin
			b6set <= 1'b1;
			case (p1fire)
				2'd0:
				begin
					b6sX <= xOne;
					b6sY <= yOne - 12'd41;
					b6west <= westOne;
					b6east <= eastOne;
					b6north <= BULLETSPEED;
					b6south <= 4'd0;
				end
				2'd1:
				begin
					b6sX <= xOne;
					b6sY <= yOne + 12'd41;
					b6west <= westOne;
					b6east <= eastOne;
					b6north <= 4'd0;
					b6south <= BULLETSPEED;
				end
				2'd2:
				begin
					b6sX <= xOne + 12'd41;
					b6sY <= yOne;
					b6west <= 4'd0;
					b6east <= BULLETSPEED;
					b6north <= northOne;
					b6south <= southOne;
				end
				2'd3:
				begin
					b6sX <= xOne - 12'd41;
					b6sY <= yOne;
					b6west <= BULLETSPEED;
					b6east <= 4'd0;
					b6north <= northOne;
					b6south <= southOne;
				end
			endcase
		end
		else if(b7active == 1'b0)
		begin
			b7set <= 1'b1;
			case (p1fire)
				2'd0:
				begin
					b7sX <= xOne;
					b7sY <= yOne - 12'd41;
					b7west <= westOne;
					b7east <= eastOne;
					b7north <= BULLETSPEED;
					b7south <= 4'd0;
				end
				2'd1:
				begin
					b7sX <= xOne;
					b7sY <= yOne + 12'd41;
					b7west <= westOne;
					b7east <= eastOne;
					b7north <= 4'd0;
					b7south <= BULLETSPEED;
				end
				2'd2:
				begin
					b7sX <= xOne + 12'd41;
					b7sY <= yOne;
					b7west <= 4'd0;
					b7east <= BULLETSPEED;
					b7north <= northOne;
					b7south <= southOne;
				end
				2'd3:
				begin
					b7sX <= xOne - 12'd41;
					b7sY <= yOne;
					b7west <= BULLETSPEED;
					b7east <= 4'd0;
					b7north <= northOne;
					b7south <= southOne;
				end
			endcase
		end
		else if(b8active == 1'b0)
		begin
			b8set <= 1'b1;
			case (p1fire)
				2'd0:
				begin
					b8sX <= xOne;
					b8sY <= yOne - 12'd41;
					b8west <= westOne;
					b8east <= eastOne;
					b8north <= BULLETSPEED;
					b8south <= 4'd0;
				end
				2'd1:
				begin
					b8sX <= xOne;
					b8sY <= yOne + 12'd41;
					b8west <= westOne;
					b8east <= eastOne;
					b8north <= 4'd0;
					b8south <= BULLETSPEED;
				end
				2'd2:
				begin
					b8sX <= xOne + 12'd41;
					b8sY <= yOne;
					b8west <= 4'd0;
					b8east <= BULLETSPEED;
					b8north <= northOne;
					b8south <= southOne;
				end
				2'd3:
				begin
					b8sX <= xOne - 12'd41;
					b8sY <= yOne;
					b8west <= BULLETSPEED;
					b8east <= 4'd0;
					b8north <= northOne;
					b8south <= southOne;
				end
			endcase
		end
	end
	else
	begin
		if (fire_flag_1 == 1'b1)
			b1CD <= 1'b0;
	end

	if (set_bullet2 & ~b2CD) // no cooldown, fire
	begin
		b2CD <= 1'b1;
		if(b9active == 1'b0)
		begin
			b9set <= 1'b1;
			case (p2fire)
				2'd0:
				begin
					b9sX <= xTwo;
					b9sY <= yTwo - 12'd41;
					b9west <= westTwo;
					b9east <= eastTwo;
					b9north <= BULLETSPEED;
					b9south <= 4'd0;
				end
				2'd1:
				begin
					b9sX <= xTwo;
					b9sY <= yTwo + 12'd41;
					b9west <= westTwo;
					b9east <= eastTwo;
					b9north <= 4'd0;
					b9south <= BULLETSPEED;
				end
				2'd2:
				begin
					b9sX <= xTwo + 12'd41;
					b9sY <= yTwo;
					b9west <= 4'd0;
					b9east <= BULLETSPEED;
					b9north <= northTwo;
					b9south <= southTwo;
				end
				2'd3:
				begin
					b9sX <= xTwo - 12'd41;
					b9sY <= yTwo;
					b9west <= BULLETSPEED;
					b9east <= 4'd0;
					b9north <= northTwo;
					b9south <= southTwo;
				end
			endcase
		end
		else if(b10active == 1'b0)
		begin
			b10set <= 1'b1;
			case (p2fire)
				2'd0:
				begin
					b10sX <= xTwo;
					b10sY <= yTwo - 12'd41;
					b10west <= westTwo;
					b10east <= eastTwo;
					b10north <= BULLETSPEED;
					b10south <= 4'd0;
				end
				2'd1:
				begin
					b10sX <= xTwo;
					b10sY <= yTwo + 12'd41;
					b10west <= westTwo;
					b10east <= eastTwo;
					b10north <= 4'd0;
					b10south <= BULLETSPEED;
				end
				2'd2:
				begin
					b10sX <= xTwo + 12'd41;
					b10sY <= yTwo;
					b10west <= 4'd0;
					b10east <= BULLETSPEED;
					b10north <= northTwo;
					b10south <= southTwo;
				end
				2'd3:
				begin
					b10sX <= xTwo - 12'd41;
					b10sY <= yTwo;
					b10west <= BULLETSPEED;
					b10east <= 4'd0;
					b10north <= northTwo;
					b10south <= southTwo;
				end
			endcase
		end
		else if(b11active == 1'b0)
		begin
			b11set <= 1'b1;
			case (p2fire)
				2'd0:
				begin
					b11sX <= xTwo;
					b11sY <= yTwo - 12'd41;
					b11west <= westTwo;
					b11east <= eastTwo;
					b11north <= BULLETSPEED;
					b11south <= 4'd0;
				end
				2'd1:
				begin
					b11sX <= xTwo;
					b11sY <= yTwo + 12'd41;
					b11west <= westTwo;
					b11east <= eastTwo;
					b11north <= 4'd0;
					b11south <= BULLETSPEED;
				end
				2'd2:
				begin
					b11sX <= xTwo + 12'd41;
					b11sY <= yTwo;
					b11west <= 4'd0;
					b11east <= BULLETSPEED;
					b11north <= northTwo;
					b11south <= southTwo;
				end
				2'd3:
				begin
					b11sX <= xTwo - 12'd41;
					b11sY <= yTwo;
					b11west <= BULLETSPEED;
					b11east <= 4'd0;
					b11north <= northTwo;
					b11south <= southTwo;
				end
			endcase
		end
		else if(b12active == 1'b0)
		begin
			b12set <= 1'b1;
			case (p2fire)
				2'd0:
				begin
					b12sX <= xTwo;
					b12sY <= yTwo - 12'd41;
					b12west <= westTwo;
					b12east <= eastTwo;
					b12north <= BULLETSPEED;
					b12south <= 4'd0;
				end
				2'd1:
				begin
					b12sX <= xTwo;
					b12sY <= yTwo + 12'd41;
					b12west <= westTwo;
					b12east <= eastTwo;
					b12north <= 4'd0;
					b12south <= BULLETSPEED;
				end
				2'd2:
				begin
					b12sX <= xTwo + 12'd41;
					b12sY <= yTwo;
					b12west <= 4'd0;
					b12east <= BULLETSPEED;
					b12north <= northTwo;
					b12south <= southTwo;
				end
				2'd3:
				begin
					b12sX <= xTwo - 12'd41;
					b12sY <= yTwo;
					b12west <= BULLETSPEED;
					b12east <= 4'd0;
					b12north <= northTwo;
					b12south <= southTwo;
				end
			endcase
		end
		else if(b13active == 1'b0)
		begin
			b13set <= 1'b1;
			case (p2fire)
				2'd0:
				begin
					b13sX <= xTwo;
					b13sY <= yTwo - 12'd41;
					b13west <= westTwo;
					b13east <= eastTwo;
					b13north <= BULLETSPEED;
					b13south <= 4'd0;
				end
				2'd1:
				begin
					b13sX <= xTwo;
					b13sY <= yTwo + 12'd41;
					b13west <= westTwo;
					b13east <= eastTwo;
					b13north <= 4'd0;
					b13south <= BULLETSPEED;
				end
				2'd2:
				begin
					b13sX <= xTwo + 12'd41;
					b13sY <= yTwo;
					b13west <= 4'd0;
					b13east <= BULLETSPEED;
					b13north <= northTwo;
					b13south <= southTwo;
				end
				2'd3:
				begin
					b13sX <= xTwo - 12'd41;
					b13sY <= yTwo;
					b13west <= BULLETSPEED;
					b13east <= 4'd0;
					b13north <= northTwo;
					b13south <= southTwo;
				end
			endcase
		end
		else if(b14active == 1'b0)
		begin
			b14set <= 1'b1;
			case (p2fire)
				2'd0:
				begin
					b14sX <= xTwo;
					b14sY <= yTwo - 12'd41;
					b14west <= westTwo;
					b14east <= eastTwo;
					b14north <= BULLETSPEED;
					b14south <= 4'd0;
				end
				2'd1:
				begin
					b14sX <= xTwo;
					b14sY <= yTwo + 12'd41;
					b14west <= westTwo;
					b14east <= eastTwo;
					b14north <= 4'd0;
					b14south <= BULLETSPEED;
				end
				2'd2:
				begin
					b14sX <= xTwo + 12'd41;
					b14sY <= yTwo;
					b14west <= 4'd0;
					b14east <= BULLETSPEED;
					b14north <= northTwo;
					b14south <= southTwo;
				end
				2'd3:
				begin
					b14sX <= xTwo - 12'd41;
					b14sY <= yTwo;
					b14west <= BULLETSPEED;
					b14east <= 4'd0;
					b14north <= northTwo;
					b14south <= southTwo;
				end
			endcase
		end
		else if(b15active == 1'b0)
		begin
			b15set <= 1'b1;
			case (p2fire)
				2'd0:
				begin
					b15sX <= xTwo;
					b15sY <= yTwo - 12'd41;
					b15west <= westTwo;
					b15east <= eastTwo;
					b15north <= BULLETSPEED;
					b15south <= 4'd0;
				end
				2'd1:
				begin
					b15sX <= xTwo;
					b15sY <= yTwo + 12'd41;
					b15west <= westTwo;
					b15east <= eastTwo;
					b15north <= 4'd0;
					b15south <= BULLETSPEED;
				end
				2'd2:
				begin
					b15sX <= xTwo + 12'd41;
					b15sY <= yTwo;
					b15west <= 4'd0;
					b15east <= BULLETSPEED;
					b15north <= northTwo;
					b15south <= southTwo;
				end
				2'd3:
				begin
					b15sX <= xTwo - 12'd41;
					b15sY <= yTwo;
					b15west <= BULLETSPEED;
					b15east <= 4'd0;
					b15north <= northTwo;
					b15south <= southTwo;
				end
			endcase
		end
		else if(b16active == 1'b0)
		begin
			b16set <= 1'b1;
			case (p2fire)
				2'd0:
				begin
					b16sX <= xTwo;
					b16sY <= yTwo - 12'd41;
					b16west <= westTwo;
					b16east <= eastTwo;
					b16north <= BULLETSPEED;
					b16south <= 4'd0;
				end
				2'd1:
				begin
					b16sX <= xTwo;
					b16sY <= yTwo + 12'd41;
					b16west <= westTwo;
					b16east <= eastTwo;
					b16north <= 4'd0;
					b16south <= BULLETSPEED;
				end
				2'd2:
				begin
					b16sX <= xTwo + 12'd41;
					b16sY <= yTwo;
					b16west <= 4'd0;
					b16east <= BULLETSPEED;
					b16north <= northTwo;
					b16south <= southTwo;
				end
				2'd3:
				begin
					b16sX <= xTwo - 12'd41;
					b16sY <= yTwo;
					b16west <= BULLETSPEED;
					b16east <= 4'd0;
					b16north <= northTwo;
					b16south <= southTwo;
				end
			endcase
		end
	end
	else
	begin
		if (fire_flag_2 == 1'b1)
			b2CD <= 1'b0;
	end
end

// Bullet modules
logic b1set = 1'b0;
logic b2set = 1'b0;
logic b3set = 1'b0;
logic b4set = 1'b0;
logic b5set = 1'b0;
logic b6set = 1'b0;
logic b7set = 1'b0;
logic b8set = 1'b0;
logic b9set = 1'b0;
logic b10set = 1'b0;
logic b11set = 1'b0;
logic b12set = 1'b0;
logic b13set = 1'b0;
logic b14set = 1'b0;
logic b15set = 1'b0;
logic b16set = 1'b0;
logic [11:0] b1sX, b2sX, b3sX, b4sX, b5sX, b6sX, b7sX, b8sX, b9sX, b10sX, b11sX, b12sX, b13sX, b14sX, b15sX, b16sX;
logic [11:0] b1sY, b2sY, b3sY, b4sY, b5sY, b6sY, b7sY, b8sY, b9sY, b10sY, b11sY, b12sY, b13sY, b14sY, b15sY, b16sY;
logic [3:0] b1west, b2west, b3west, b4west, b5west, b6west, b7west, b8west, b9west, b10west, b11west, b12west, b13west, b14west, b15west, b16west;
logic [3:0] b1east, b2east, b3east, b4east, b5east, b6east, b7east, b8east, b9east, b10east, b11east, b12east, b13east, b14east, b15east, b16east;
logic [3:0] b1north, b2north, b3north, b4north, b5north, b6north, b7north, b8north, b9north, b10north, b11north, b12north, b13north, b14north, b15north, b16north;
logic [3:0] b1south, b2south, b3south, b4south, b5south, b6south, b7south, b8south, b9south, b10south, b11south, b12south, b13south, b14south, b15south, b16south;
//logic [11:0] b1X, b2X, b3X, b4X, b5X, b6X, b7X, b8X, b9X, b10X, b11X, b12X, b13X, b14X, b15X, b16X;
//logic [11:0] b1Y, b2Y, b3Y, b4Y, b5Y, b6Y, b7Y, b8Y, b9Y, b10Y, b11Y, b12Y, b13Y, b14Y, b15Y, b16Y;
//logic b1active, b2active, b3active, b4active, b5active, b6active, b7active, b8active, b9active, b10active, b11active, b12active, b13active, b14active, b15active, b16active;
logic b1h1, b2h1, b3h1, b4h1, b5h1, b6h1, b7h1, b8h1, b9h1, b10h1, b11h1, b12h1, b13h1, b14h1, b15h1, b16h1;
logic b1h2, b2h2, b3h2, b4h2, b5h2, b6h2, b7h2, b8h2, b9h2, b10h2, b11h2, b12h2, b13h2, b14h2, b15h2, b16h2;
logic set_bullet1, set_bullet2;

bullet b1 (.Clk(Clk), .frame_clk(VGA_VS), .set(b1set), .startX(b1sX), .startY(b1sY), .nspeedX(b1west), .pspeedX(b1east), .nspeedY(b1north), .pspeedY(b1south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b1X), .posY(b1Y), .active(b1active), .h1(b1h1), .h2(b1h2));
bullet b2 (.Clk(Clk), .frame_clk(VGA_VS), .set(b2set), .startX(b2sX), .startY(b2sY), .nspeedX(b2west), .pspeedX(b2east), .nspeedY(b2north), .pspeedY(b2south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b2X), .posY(b2Y), .active(b2active), .h1(b2h1), .h2(b2h2));
bullet b3 (.Clk(Clk), .frame_clk(VGA_VS), .set(b3set), .startX(b3sX), .startY(b3sY), .nspeedX(b3west), .pspeedX(b3east), .nspeedY(b3north), .pspeedY(b3south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b3X), .posY(b3Y), .active(b3active), .h1(b3h1), .h2(b3h2));
bullet b4 (.Clk(Clk), .frame_clk(VGA_VS), .set(b4set), .startX(b4sX), .startY(b4sY), .nspeedX(b4west), .pspeedX(b4east), .nspeedY(b4north), .pspeedY(b4south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b4X), .posY(b4Y), .active(b4active), .h1(b4h1), .h2(b4h2));
bullet b5 (.Clk(Clk), .frame_clk(VGA_VS), .set(b5set), .startX(b5sX), .startY(b5sY), .nspeedX(b5west), .pspeedX(b5east), .nspeedY(b5north), .pspeedY(b5south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b5X), .posY(b5Y), .active(b5active), .h1(b5h1), .h2(b5h2));
bullet b6 (.Clk(Clk), .frame_clk(VGA_VS), .set(b6set), .startX(b6sX), .startY(b6sY), .nspeedX(b6west), .pspeedX(b6east), .nspeedY(b6north), .pspeedY(b6south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b6X), .posY(b6Y), .active(b6active), .h1(b6h1), .h2(b6h2));
bullet b7 (.Clk(Clk), .frame_clk(VGA_VS), .set(b7set), .startX(b7sX), .startY(b7sY), .nspeedX(b7west), .pspeedX(b7east), .nspeedY(b7north), .pspeedY(b7south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b7X), .posY(b7Y), .active(b7active), .h1(b7h1), .h2(b7h2));
bullet b8 (.Clk(Clk), .frame_clk(VGA_VS), .set(b8set), .startX(b8sX), .startY(b8sY), .nspeedX(b8west), .pspeedX(b8east), .nspeedY(b8north), .pspeedY(b8south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b8X), .posY(b8Y), .active(b8active), .h1(b8h1), .h2(b8h2));
bullet b9 (.Clk(Clk), .frame_clk(VGA_VS), .set(b9set), .startX(b9sX), .startY(b9sY), .nspeedX(b9west), .pspeedX(b9east), .nspeedY(b9north), .pspeedY(b9south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b9X), .posY(b9Y), .active(b9active), .h1(b9h1), .h2(b9h2));
bullet b10 (.Clk(Clk), .frame_clk(VGA_VS), .set(b10set), .startX(b10sX), .startY(b10sY), .nspeedX(b10west), .pspeedX(b10east), .nspeedY(b10north), .pspeedY(b10south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b10X), .posY(b10Y), .active(b10active), .h1(b10h1), .h2(b10h2));
bullet b11 (.Clk(Clk), .frame_clk(VGA_VS), .set(b11set), .startX(b11sX), .startY(b11sY), .nspeedX(b11west), .pspeedX(b11east), .nspeedY(b11north), .pspeedY(b11south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b11X), .posY(b11Y), .active(b11active), .h1(b11h1), .h2(b11h2));
bullet b12 (.Clk(Clk), .frame_clk(VGA_VS), .set(b12set), .startX(b12sX), .startY(b12sY), .nspeedX(b12west), .pspeedX(b12east), .nspeedY(b12north), .pspeedY(b12south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b12X), .posY(b12Y), .active(b12active), .h1(b12h1), .h2(b12h2));
bullet b13 (.Clk(Clk), .frame_clk(VGA_VS), .set(b13set), .startX(b13sX), .startY(b13sY), .nspeedX(b13west), .pspeedX(b13east), .nspeedY(b13north), .pspeedY(b13south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b13X), .posY(b13Y), .active(b13active), .h1(b13h1), .h2(b13h2));
bullet b14 (.Clk(Clk), .frame_clk(VGA_VS), .set(b14set), .startX(b14sX), .startY(b14sY), .nspeedX(b14west), .pspeedX(b14east), .nspeedY(b14north), .pspeedY(b14south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b14X), .posY(b14Y), .active(b14active), .h1(b14h1), .h2(b14h2));
bullet b15 (.Clk(Clk), .frame_clk(VGA_VS), .set(b15set), .startX(b15sX), .startY(b15sY), .nspeedX(b15west), .pspeedX(b15east), .nspeedY(b15north), .pspeedY(b15south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b15X), .posY(b15Y), .active(b15active), .h1(b15h1), .h2(b15h2));
bullet b16 (.Clk(Clk), .frame_clk(VGA_VS), .set(b16set), .startX(b16sX), .startY(b16sY), .nspeedX(b16west), .pspeedX(b16east), .nspeedY(b16north), .pspeedY(b16south), .xOne(xOne), .yOne(yOne), .xTwo(xTwo), .yTwo(yTwo), .posX(b16X), .posY(b16Y), .active(b16active), .h1(b16h1), .h2(b16h2));

//// LOCATION OF PLAYERS
// Location of player on map
assign xOne = _xOne;
assign yOne = _yOne;
assign xTwo = _xTwo;
assign yTwo = _yTwo;

// Location of players on map
logic [11:0] _xOne = 12'd700;
logic [11:0] _yOne = 12'd700;
logic [11:0] _xTwo = 12'd1500;
logic [11:0] _yTwo = 12'd1400;

// Update location
// Prevent players from walking off the map or on top of each other 
always_ff @ (posedge VGA_VS)
begin
	// Check if players are about to walk on top of each other
	if (~((((xOne + eastOne - westOne > xTwo + eastTwo - westTwo)? (xOne + eastOne - westOne) - (xTwo + eastTwo - westTwo):(xTwo + eastTwo - westTwo) - (xOne + eastOne - westOne)) < 12'd37) & (((yOne + southOne - northOne > yTwo + southTwo - northTwo)? (yOne + southOne - northOne) - (yTwo + southTwo - northTwo):(yTwo + southTwo - northTwo) - (yOne + southOne - northOne)) < 12'd37)))
	begin
		_xOne <= ((_xOne + eastOne - westOne >= 12'd64) & (_xOne + eastOne - westOne <= 12'd3136))? _xOne + eastOne - westOne:_xOne;
		_yOne <= ((_yOne + southOne - northOne >= 12'd64) & (_yOne + southOne - northOne <= 12'd2336))? _yOne + southOne - northOne:_yOne;
		_xTwo <= ((_xTwo + eastTwo - westTwo >= 12'd64) & (_xTwo + eastTwo - westTwo <= 12'd3136))? _xTwo + eastTwo - westTwo:_xTwo;
		_yTwo <= ((_yTwo + southTwo - northTwo >= 12'd64) & (_yTwo + southTwo - northTwo <= 12'd2336))? _yTwo + southTwo - northTwo:_yTwo;
	end
end

always_ff @ (posedge VGA_VS)
begin
	// Update player motion and shooting direction
	p1dir <= p1dir_comb;
	p2dir <= p2dir_comb;
	p1fire <= p1fire_comb;
	p2fire <= p2fire_comb;
	// Firing bullets
	if (aOne == 8'h52 | bOne == 8'h52 | cOne == 8'h52 | dOne == 8'h52 | aOne == 8'h51 | bOne == 8'h51 | cOne == 8'h51 | dOne == 8'h51 | aOne == 8'h50 | bOne == 8'h50 | cOne == 8'h50 | dOne == 8'h50 | aOne == 8'h4f | bOne == 8'h4f | cOne == 8'h4f | dOne == 8'h4f)
		set_bullet1 <= 1'b1;
	else
		set_bullet1 <= 1'b0;
	if (aTwo == 8'h75 | bTwo == 8'h75 | cTwo == 8'h75 | dTwo == 8'h75 | aTwo == 8'h72 | bTwo == 8'h72 | cTwo == 8'h72 | dTwo == 8'h72 | aTwo == 8'h6B | bTwo == 8'h6B | cTwo == 8'h6B | dTwo == 8'h6B | aTwo == 8'h74 | bTwo == 8'h74 | cTwo == 8'h74 | dTwo == 8'h74)
		set_bullet2 <= 1'b1;
	else
		set_bullet2 <= 1'b0;
end

// Player 1 motion and shooting
always_comb
begin
	northOne = 12'd0;
	southOne = 12'd0;
	eastOne = 12'd0;
	westOne = 12'd0;
	p1dir_comb = p1dir;
	p1fire_comb = p1fire;
	// set_bullet1 = 1'b0;

	// W
	if (aOne == 8'h1A | bOne == 8'h1A | cOne == 8'h1A | dOne == 8'h1A)
	begin
		northOne = 12'd2;
		p1dir_comb = 2'd0;
	end
	// A
	if (aOne == 8'h04 | bOne == 8'h04 | cOne == 8'h04 | dOne == 8'h04)
	begin
		westOne = 12'd2;
		p1dir_comb = 2'd3;	
	end
	// S
	if (aOne == 8'h16 | bOne == 8'h16 | cOne == 8'h16 | dOne == 8'h16)
	begin
		southOne = 12'd2;
		p1dir_comb = 2'd1;
	end
	// D
	if (aOne == 8'h07 | bOne == 8'h07 | cOne == 8'h07 | dOne == 8'h07)
	begin
		eastOne = 12'd2;
		p1dir_comb = 2'd2;
	end
	// up arrow
	if (aOne == 8'h52 | bOne == 8'h52 | cOne == 8'h52 | dOne == 8'h52)
	begin
		p1dir_comb = 2'd0;
		p1fire_comb = 2'd0;
		// set_bullet1 = 1'b1;
	end
	// down arrow
	if (aOne == 8'h51 | bOne == 8'h51 | cOne == 8'h51 | dOne == 8'h51)
	begin
		p1dir_comb = 2'd1;
		p1fire_comb = 2'd1;
		// set_bullet1 = 1'b1;	
	end
	// left arrow
	if (aOne == 8'h50 | bOne == 8'h50 | cOne == 8'h50 | dOne == 8'h50)
	begin
		p1dir_comb = 2'd3;
		p1fire_comb = 2'd3;
		// set_bullet1 = 1'b1;
	end
	// right arrow
	if (aOne == 8'h4f | bOne == 8'h4f | cOne == 8'h4f | dOne == 8'h4f)
	begin
		p1dir_comb = 2'd2;
		p1fire_comb = 2'd2;
		// set_bullet1 = 1'b1;
	end

end

// Player 2 motion and shooting
always_comb
begin
	northTwo = 12'd0;
	southTwo = 12'd0;
	eastTwo = 12'd0;
	westTwo = 12'd0;
	p2dir_comb = p2dir;
	p2fire_comb = p2fire;
	// set_bullet2 = 1'b0;

	// W
	if (aTwo == 8'h1D | bTwo == 8'h1D | cTwo == 8'h1D | dTwo == 8'h1D)
	begin
		northTwo = 12'd2;
		p2dir_comb = 2'd0;
	end
	// A
	if (aTwo == 8'h1C | bTwo == 8'h1C | cTwo == 8'h1C | dTwo == 8'h1C)
	begin
		westTwo = 12'd2;
		p2dir_comb = 2'd3;
	end
	// S
	if (aTwo == 8'h1B | bTwo == 8'h1B | cTwo == 8'h1B | dTwo == 8'h1B)
	begin
		southTwo = 12'd2;
		p2dir_comb = 2'd1;
	end
	// D
	if (aTwo == 8'h23 | bTwo == 8'h23 | cTwo == 8'h23 | dTwo == 8'h23)
	begin
		eastTwo = 12'd2;
		p2dir_comb = 2'd2;
	end
	// up arrow
	if (aTwo == 8'h75 | bTwo == 8'h75 | cTwo == 8'h75 | dTwo == 8'h75)
	begin
		p2dir_comb = 2'd0;
		p2fire_comb = 2'd0;
		// set_bullet2 = 1'b1;
	end
	// down arrow
	if (aTwo == 8'h72 | bTwo == 8'h72 | cTwo == 8'h72 | dTwo == 8'h72)
	begin
		p2dir_comb = 2'd1;
		p2fire_comb = 2'd1;
		// set_bullet2 = 1'b1;	
	end
	// left arrow
	if (aTwo == 8'h6B | bTwo == 8'h6B | cTwo == 8'h6B | dTwo == 8'h6B)
	begin
		p2dir_comb = 2'd3;
		p2fire_comb = 2'd3;
		// set_bullet2 = 1'b1;
	end
	// right arrow
	if (aTwo == 8'h74 | bTwo == 8'h74 | cTwo == 8'h74 | dTwo == 8'h74)
	begin
		p2dir_comb = 2'd2;
		p2fire_comb = 2'd2;
		// set_bullet2 = 1'b1;
	end
end

endmodule