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
	logic [23:0] player1, player2;
	logic [12:0] playerOffset;

	// FOR SPRITE OF OTHER PLAYER ON YOUR SCREEN
	logic onscreen;
	logic [23:0] p2onp1, p1onp2;
	logic [12:0] player1offset, player2offset;

	//
	logic [23:0] sprite1, sprite2;

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
	if (DrX > 10'd640 & DrX < 10'd799)
		blanking <= 0;
	else
		blanking <= 1;
	end

	always_ff @ (posedge Clk)
	begin
		// Determine map and sprite pixels for player 1
		if (~toggle)
		begin
			// Get map pixel
			case (mapdata[yTileOne*100 + xTileOne])
				2'b01:
					mapOne <= inMapOne? grass_out : 24'h0000;
				2'b10:
					mapOne <= inMapOne? water_out : 24'h0000;
				2'b11:
					mapOne <= inMapOne? sand_out : 24'h0000;
			endcase
			// Get player sprite pixel
			case (p1dir)
				2'b00:
					player1 <= inPlayer? playerNorth_out : 24'hff00d2;
				2'b01:
					player1 <= inPlayer? playerSouth_out : 24'hff00d2;
				2'b10:
					player1 <= inPlayer? playerEast_out : 24'hff00d2;
				2'b11:
					player1 <= inPlayer? playerWest_out : 24'hff00d2;
			endcase
			// Check if player 2 is onscreen
			if (onscreen & player2offset > 0 & player2offset < 5625)
			begin
				case (p2dir)
					2'b00:
						p2onp1 <= playerNorth_out;
					2'b01:
						p2onp1 <= playerSouth_out;
					2'b10:
						p2onp1 <= playerEast_out;
					2'b11:
						p2onp1 <= playerWest_out;
				endcase 
			end
			else
				p2onp1 <= 24'hff00d2;
		end
		else
		begin
			// Get map pixel
			case (mapdata[yTileTwo*100 + xTileTwo])
				2'b01:
					mapTwo <= inMapTwo? grass_out : 24'h0000;
				2'b10:
					mapTwo <= inMapTwo? water_out : 24'h0000;
				2'b11:
					mapTwo <= inMapTwo? sand_out : 24'h0000;
			endcase
			// Get player sprite pixel
			case (p2dir)
				2'b00:
					player2 <= inPlayer? playerNorth_out : 24'hff00d2;
				2'b01:
					player2 <= inPlayer? playerSouth_out : 24'hff00d2;
				2'b10:
					player2 <= inPlayer? playerEast_out : 24'hff00d2;
				2'b11:
					player2 <= inPlayer? playerWest_out : 24'hff00d2;
			endcase
			// Check if player 1 is onscreen
			if (onscreen & player1offset > 0 & player1offset < 5625)
			begin
				case (p1dir)
					2'b00:
						p1onp2 <= playerNorth_out;
					2'b01:
						p1onp2 <= playerSouth_out;
					2'b10:
						p1onp2 <= playerEast_out;
					2'b11:
						p1onp2 <= playerWest_out;
				endcase  
			end
			else
				p1onp2 <= 24'hff00d2;
		end
	end

	always_comb
	begin
		if (~toggle)
		begin
			// Get map pixel
			case (mapdata[yTileOne*100 + xTileOne])
				2'b01:
					grass_in = yTileOneOffset*32 + xTileOneOffset;
				2'b10:
					water_in = yTileOneOffset*32 + xTileOneOffset;
				2'b11:
					sand_in = yTileOneOffset*32 + xTileOneOffset;
			endcase
			// Get player sprite pixel
			case (p1dir)
				2'b00:
					playerNorth_in = playerOffset;
				2'b01:
					playerSouth_in = playerOffset;
				2'b10:
					playerEast_in = playerOffset;
				2'b11:
					playerWest_in = playerOffset;
			endcase
			// Check if player 2 is onscreen
			if (onscreen & player2offset > 0 & player2offset < 5625)
			begin
				case (p2dir)
					2'b00:
						playerNorth_in = player2offset;
					2'b01:
						playerSouth_in = player2offset;
					2'b10:
						playerEast_in = player2offset;
					2'b11:
						playerWest_in = player2offset;
				endcase 
			end
		end
		else
		begin
			// Get map pixel
			case (mapdata[yTileTwo*100 + xTileTwo])
				2'b01:
					grass_in = yTileTwoOffset*32 + xTileTwoOffset;
				2'b10:
					water_in = yTileTwoOffset*32 + xTileTwoOffset;
				2'b11:
					sand_in  = yTileTwoOffset*32 + xTileTwoOffset;
			endcase
			// Get player sprite pixel
			case (p2dir)
				2'b00:
					playerNorth_in = playerOffset;
				2'b01:
					playerSouth_in = playerOffset;
				2'b10:
					playerEast_in = playerOffset;
				2'b11:
					playerWest_in = playerOffset;
			endcase
			// Check if player 1 is onscreen
			if (onscreen & player1offset > 0 & player1offset < 5625)
			begin
				case (p1dir)
					2'b00:
						playerNorth_in = player1offset;
					2'b01:
						playerSouth_in = player1offset;
					2'b10:
						playerEast_in = player1offset;
					2'b11:
						playerWest_in = player1offset;
				endcase 
			end
		end
	end

	
	// For drawing non-map pixels
	always_comb
	begin
		if (player1 != 24'hff00d2)
			sprite1 = player1;
		else if (p2onp1 != 24'hff00d2)
			sprite1 = p2onp1;
		else
			sprite1 = 24'hff00d2;
		if (player2 != 24'hff00d2)
			sprite2 = player2;
		else if (p1onp2 != 24'hff00d2)
			sprite2 = p1onp2;
		else
			sprite2 = 24'hff00d2;
	end

	// Assign VGA values for player 1
	assign VGA_R = (sprite1 == 24'hff00d2)? {mapOne[23:19], 3'b000}:{sprite1[23:19], 3'b000};
	assign VGA_G = (sprite1 == 24'hff00d2)? {mapOne[15:11], 3'b000}:{sprite1[15:11], 3'b000};
	assign VGA_B = (sprite1 == 24'hff00d2)? {mapOne[7:3], 3'b000}:{sprite1[7:3], 3'b000};

	// Assign GPIO values for player 2
	// Set RGB signals to low during horizontal blanking interval
	assign GPIO[9] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[23]:sprite2[23]):1'b0;
	assign GPIO[7] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[22]:sprite2[22]):1'b0;
	assign GPIO[5] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[21]:sprite2[21]):1'b0;
	assign GPIO[3] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[20]:sprite2[20]):1'b0;
	assign GPIO[1] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[19]:sprite2[19]):1'b0;
	assign GPIO[14] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[15]:sprite2[15]):1'b0;
	assign GPIO[12] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[14]:sprite2[14]):1'b0;
	assign GPIO[10] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[13]:sprite2[13]):1'b0;
	assign GPIO[6] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[12]:sprite2[12]):1'b0;
	assign GPIO[0] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[11]:sprite2[11]):1'b0;
	assign GPIO[19] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[7]:sprite2[7]):1'b0;
	assign GPIO[17] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[6]:sprite2[6]):1'b0;
	assign GPIO[15] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[5]:sprite2[5]):1'b0;
	assign GPIO[13] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[4]:sprite2[4]):1'b0;
	assign GPIO[11] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[3]:sprite2[3]):1'b0;
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

	// Player with gun (75 x 75)
	// One sprite for each direction
	logic [23:0] playerNorth[5625];
	logic [23:0] playerSouth[5625];
	logic [23:0] playerEast[5625];
	logic [23:0] playerWest[5625];
	initial
	begin
		$readmemh("player2_1.txt", playerNorth);
		$readmemh("player2_2.txt", playerEast);
		$readmemh("player2_3.txt", playerSouth);
		$readmemh("player2_4.txt", playerWest);
	end

	logic [9:0]	 grass_in, sand_in, water_in;
	logic [12:0] playerNorth_in, playerSouth_in, playerWest_in, playerEast_in; 
	logic [12:0] map_in;
	logic [1:0]  map_out;
	logic [23:0] grass_out, sand_out, water_out, playerNorth_out, playerSouth_out, playerWest_out, playerEast_out;
	grass grassTile(.clk(Clk), d(0), write_address(0), read_address(grass_in), we(0), q(grass_out));
	sand  sandTile (.clk(Clk), d(0), write_address(0), read_address(sand_in), we(0), q(sand_out));
	water waterTile(.clk(Clk), d(0), write_address(0), read_address(water_in), we(0), q(water_out));
	player2_1 playerNorth(.clk(Clk), d(0), write_address(0), read_address(playerNorth_in), we(0), q(playerNorth_out));
	player2_2 playerSouth(.clk(Clk), d(0), write_address(0), read_address(playerSouth_in), we(0), q(playerSouth_out));
	player2_3 playerEast(.clk(Clk), d(0), write_address(0), read_address(playerEast_in), we(0), q(playerEast_out));
	player2_4 playerWest(.clk(Clk), d(0), write_address(0), read_address(playerWest_in), we(0), q(playerWest_out));
	mapdata   mapdata(.clk(Clk), d(0), write_address(0), read_address(map_in), we(0), q(map_out));


	//// OTHER SPRITE LOGIC
	// Calculate pixel of other player
	assign onscreen = (((xTwo > xOne)? xTwo - xOne:xOne - xTwo) < 283) | (((yTwo > yOne)? yTwo - yOne:yOne - yTwo) < 203);
	assign player2offset = (DrYplus - (yTwo - 37) - (yOne - 240))*75 + (DrXplus - (xTwo - 37) - (xOne - 320));
	assign player1offset = (DrYplus - (yOne - 37) - (yTwo - 240))*75 + (DrXplus - (xOne - 37) - (xTwo - 320));


	//// CENTERED PLAYER SPRITE LOGIC
	// Calculate if current pixel is in player sprite
	assign inPlayer = (DrXplus > 283) & (DrXplus < 357) & (DrYplus > 203) & (DrYplus < 277);

	// Calculate pixel in player sprite
	assign playerOffset = (DrYplus - 203)*75 + (DrXplus - 283);
	////


	//// BACKGROUND TILE LOGIC
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
	////


endmodule

