// Drawing logic for ECE 385 final project
// April 13, 2018

module draw_map (input logic Clk,
				 input logic [11:0] xOne, // player 1's absolute location on map
				 input logic [11:0] yOne,
				 input logic [11:0] xTwo, // player 2's absolute location on map
				 input logic [11:0] yTwo,
				 input logic [1:0]  p1dir,	// direction player is facing
				 input logic [1:0]  p2dir,
				 input logic [9:0] DrX,
				 input logic [9:0] DrY, 
				 input logic VGA_VS,
				 input logic VGA_HS,
				 output logic [7:0] VGA_R,
				 output logic [7:0] VGA_G,
				 output logic [7:0] VGA_B,
				 output logic [35:0] GPIO);

	// Offset DrXplus and DrYplus to align logic and graphics
	logic [9:0] DrXplus, DrYplus;
	assign DrXplus = (DrX + 10'd2 > 10'd799)? DrX + 10'd2 - 10'd800:DrX + 10'd2;
	assign DrYplus = (DrY + 10'd1 > 10'd524)? DrX + 10'd1 - 10'd525:DrY + 10'd1;

	// MAP FOR PLAYER ONE
	logic [6:0] xTileOne; // tile in the 100 x 75 mapinfo
	logic [6:0] yTileOne; 
	logic [4:0] xTileOneOffset; // pixel being drawn on current tile
	logic [4:0] yTileOneOffset;
	logic [23:0] mapOne;

	// MAP FOR PLAYER TWO
	logic [6:0] xTileTwo; // tile in the 100 x 75 mapinfo
	logic [6:0] yTileTwo; 
	logic [4:0] xTileTwoOffset; // pixel being drawn on current tile
	logic [4:0] yTileTwoOffset;
	logic [23:0] mapTwo;

	// FOR PLAYER SPRITE
	logic [23:0] player;

	// Flags
	logic inMapOne, inMapTwo; // flag to check if current pixel is in map
	logic inPlayer; // flag to check if current pixel is in player sprite
	logic toggle; // alternate which screen is fetching from on-chip memory

	// Horizontal blanking signal for GPIO RGB
	logic blanking;

	// Is current pixel in the map?
	assign inMapOne = ((xOne - 320 + DrXplus) >= 32) & ((xOne - 320 + DrXplus) < 3168) & ((yOne - 240 + DrYplus) >= 32) & ((yOne - 240 + DrYplus) < 2368);
	assign inMapTwo = ((xTwo - 320 + DrXplus) >= 32) & ((xTwo - 320 + DrXplus) < 3168) & ((yTwo - 240 + DrYplus) >= 32) & ((yTwo - 240 + DrYplus) < 2368);

	// Toggle on every clock edge
	always_ff @ (posedge Clk)
	begin
		toggle <= ~toggle;
	end

	// Set blanking signal
	always_ff @ (posedge Clk)
	begin
	if (DrX > 10'd645 & DrX < 10'd795)
		blanking <= 0;
	else
		blanking <= 1;
	end

	always_ff @ (posedge Clk)
	begin
		// Get pixel for player sprite
		player <= inPlayer? playerNorth[(DrYplus - 165)*150 + DrXplus]:24'h0ff0d2;
		// Determine map pixel for both monitors
		if (~toggle)
		begin
			case (p1dir)
				2'd0:
					memoryValueOne <= playerNorth[logic here];
				2'd1:
					memoryValueOne <= playerSouth[logic here];
				2'd2:
					memoryValueOne <= playerEast[logic here];
				2'd3:
					memoryValueOne <= playerWest[logic here];
			endcase

			case (mapdata[yTileOne*100 + xTileOne])
				2'b01:
					mapOne <= inMapOne? grass[yTileOneOffset*32 + xTileOneOffset]:24'h0000;
				2'b10:
					mapOne <= inMapOne? water[yTileOneOffset*32 + xTileOneOffset]:24'h0000;
				2'b11:
					mapOne <= inMapOne? sand[yTileOneOffset*32 + xTileOneOffset]:24'h0000;
			endcase
		end
		else
		begin
			case (mapdata[yTileTwo*100 + xTileTwo])
				2'b01:
					mapTwo <= inMapTwo? grass[yTileTwoOffset*32 + xTileTwoOffset]:24'h0000;
				2'b10:
					mapTwo <= inMapTwo? water[yTileTwoOffset*32 + xTileTwoOffset]:24'h0000;
				2'b11:
					mapTwo <= inMapTwo? sand[yTileTwoOffset*32 + xTileTwoOffset]:24'h0000;
			endcase
		end
	end

	// Assign VGA values for player 1
	assign VGA_R = (player == 24'h0ff0d2)? {mapOne[23:19], 3'b000}:{player[23:19], 3'b000};
	assign VGA_G = (player == 24'h0ff0d2)? {mapOne[15:11], 3'b000}:{player[15:11], 3'b000};
	assign VGA_B = (player == 24'h0ff0d2)? {mapOne[7:3], 3'b000}:{player[7:3], 3'b000};

	// Assign GPIO values for player 2
	// Set RGB signals to low during horizontal blanking interval
	assign GPIO[9] = blanking? mapTwo[23]:1'b0;
	assign GPIO[7] = blanking? mapTwo[22]:1'b0;
	assign GPIO[5] = blanking? mapTwo[21]:1'b0;
	assign GPIO[3] = blanking? mapTwo[20]:1'b0;
	assign GPIO[1] = blanking? mapTwo[19]:1'b0;
	assign GPIO[14] = blanking? mapTwo[15]:1'b0;
	assign GPIO[12] = blanking? mapTwo[14]:1'b0;
	assign GPIO[10] = blanking? mapTwo[13]:1'b0;
	assign GPIO[6] = blanking? mapTwo[12]:1'b0;
	assign GPIO[0] = blanking? mapTwo[11]:1'b0;
	assign GPIO[19] = blanking? mapTwo[7]:1'b0;
	assign GPIO[17] = blanking? mapTwo[6]:1'b0;
	assign GPIO[15] = blanking? mapTwo[5]:1'b0;
	assign GPIO[13] = blanking? mapTwo[4]:1'b0;
	assign GPIO[11] = blanking? mapTwo[3]:1'b0;
	assign GPIO[2] = VGA_VS;
	assign GPIO[4] = VGA_HS;

	// Grass/sand/water tiles and map layout info
	logic [23:0] grass[1024];
	logic [23:0] sand[1024];
	logic [23:0] water[1024];
	logic [1:0] mapdata[7500];
	initial
	begin
		$readmemh("grass.txt", grass);
		$readmemh("sand.txt", sand);
		$readmemh("water.txt", water);
		$readmemh("mapdata.txt", mapdata);
	end

	// Player with gun (150 x 150)
	// One sprite for each direction
	logic [23:0] playerNorth[22500];
	logic [23:0] playerSouth[22500];
	logic [23:0] playerEast[22500];
	logic [23:0] playerWest[22500];
	initial
	begin
		$readmemh("player2_1.txt", playerNorth);
		$readmemh("player2_2.txt", playerEast);
		$readmemh("player2_3.txt", playerSouth);
		$readmemh("player2_4.txt", playerWest);
	end

	// Calculate if current pixel is in player sprite
	assign inPlayer = (DrXplus > 245) & (DrXplus < 395) & (DrYplus > 165) & (DrYplus < 315);

	// Calculate background tile for player 1
	assign xTileOne = (xOne - 320 + DrXplus) >> 5; // each tile is 32 x 32
	assign yTileOne = (yOne - 240 + DrYplus) >> 5;
	assign xTileOneOffset = (xOne - 320 + DrXplus) & 12'b000000011111; // xMap - 32*xTileOne
	assign yTileOneOffset = (yOne - 240 + DrYplus) & 12'b000000011111;

	// Calculate background tile for player 2
	assign xTileTwo = (xTwo - 320 + DrXplus) >> 5; // each tile is 32 x 32
	assign yTileTwo = (yTwo - 240 + DrYplus) >> 5;
	assign xTileTwoOffset = (xTwo - 320 + DrXplus) & 12'b000000011111; // xMap - 32*xTileTwo
	assign yTileTwoOffset = (yTwo - 240 + DrYplus) & 12'b000000011111;

endmodule

