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
				 output logic [35:0] GPIO,
				 output logic [6:0] xTileTwo, yTileTwo);

	// Offset DrXplus and DrYplus to align logic and graphics
	logic [9:0] DrXplus, DrYplus;
	assign DrXplus = (DrX + 10'd2 > 10'd799)? DrX + 10'd2 - 10'd800:DrX + 10'd2;
	assign DrYplus = (DrY + 10'd1 > 10'd524)? DrX + 10'd1 - 10'd525:DrY + 10'd1;

	// MAP FOR PLAYER ONE
	logic [6:0] xTileOne; // tile in the 100 x 75 mapinfo
	logic [6:0] yTileOne; 
	logic [9:0] xTileOneOffset; // pixel being drawn on current tile
	logic [9:0] yTileOneOffset;
	logic [23:0] mapOne;

	// MAP FOR PLAYER TWO
	// logic [6:0] xTileTwo; // tile in the 100 x 75 mapinfo
	// logic [6:0] yTileTwo; 
	logic [9:0] xTileTwoOffset; // pixel being drawn on current tile
	logic [9:0] yTileTwoOffset;
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
	assign inMapOne = ((xOne - 12'd320 + DrXplus) >= 12'd32) & ((xOne - 12'd320 + DrXplus) < 12'd3168) & ((yOne - 12'd240 + DrYplus) >= 12'd32) & ((yOne - 12'd240 + DrYplus) < 12'd2368);
	assign inMapTwo = ((xTwo - 12'd320 + DrXplus) >= 12'd32) & ((xTwo - 12'd320 + DrXplus) < 12'd3168) & ((yTwo - 12'd240 + DrYplus) >= 12'd32) & ((yTwo - 12'd240 + DrYplus) < 12'd2368);

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
			case (map_out)
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
					player1 <= inPlayer? player1North_out : 24'hff00d2;
				2'b01:
					player1 <= inPlayer? player1South_out : 24'hff00d2;
				2'b10:
					player1 <= inPlayer? player1East_out : 24'hff00d2;
				2'b11:
					player1 <= inPlayer? player1West_out : 24'hff00d2;
			endcase
			// Check if player 2 is onscreen
			if (onscreen & player2offset >= 13'd0 & player2offset < 13'd5625)
			begin
				if ((((xOne - 12'd320 + DrXplus > xTwo)? xOne - 12'd320 + DrXplus - xTwo:xTwo - (xOne - 12'd320 + DrXplus)) < 37) & (((yOne - 12'd240 + DrYplus > yTwo)? yOne - 12'd240 + DrYplus - yTwo:yTwo - (yOne - 12'd240 + DrYplus)) < 37))
				begin
					case (p2dir)
						2'b00:
							p2onp1 <= player2North_out;
						2'b01:
							p2onp1 <= player2South_out;
						2'b10:
							p2onp1 <= player2East_out;
						2'b11:
							p2onp1 <= player2West_out;
					endcase 
				end
				else
					p2onp1 <= 24'hff00d2;
			end
			else
				p2onp1 <= 24'hff00d2;
		end
		else
		begin
			// Get map pixel
			case (map_out)
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
					player2 <= inPlayer? player2North_out : 24'hff00d2;
				2'b01:
					player2 <= inPlayer? player2South_out : 24'hff00d2;
				2'b10:
					player2 <= inPlayer? player2East_out : 24'hff00d2;
				2'b11:
					player2 <= inPlayer? player2West_out : 24'hff00d2;
			endcase
			// Check if player 1 is onscreen
			if (onscreen & player1offset >= 13'd0 & player1offset < 13'd5625)
			begin
				if ((((xTwo - 12'd320 + DrXplus > xOne)? xTwo - 12'd320 + DrXplus - xOne:xOne - (xTwo - 12'd320 + DrXplus)) < 37) & (((yTwo - 12'd240 + DrYplus > yOne)? yTwo - 12'd240 + DrYplus - yOne:yOne - (yTwo - 12'd240 + DrYplus)) < 37))
				begin
					case (p1dir)
						2'b00:
							p1onp2 <= player1North_out;
						2'b01:
							p1onp2 <= player1South_out;
						2'b10:
							p1onp2 <= player1East_out;
						2'b11:
							p1onp2 <= player1West_out;
					endcase  
				end
				else
					p1onp2 <= 24'hff00d2;
			end
			else
				p1onp2 <= 24'hff00d2;
		end
	end

	always_comb
	begin
		grass_in = 10'd0;
		water_in = 10'd0;
		sand_in = 10'd0;
		player1North_in = 13'd0;
		player1South_in = 13'd0;
		player1East_in = 13'd0;
		player1West_in = 13'd0;
		player2North_in = 13'd0;
		player2South_in = 13'd0;
		player2East_in = 13'd0;
		player2West_in = 13'd0;

		if (toggle)
		begin
			// Get map pixel
			grass_in = yTileOneOffset*10'd32 + xTileOneOffset;
			water_in = yTileOneOffset*10'd32 + xTileOneOffset;
			sand_in = yTileOneOffset*10'd32 + xTileOneOffset;
			map_in = yTileOne*7'd100 + xTileOne;
			// Get player sprite pixel
			player1North_in = playerOffset;
			player1South_in = playerOffset;
			player1East_in = playerOffset;
			player1West_in = playerOffset;
			player2North_in = player2offset;
			player2South_in = player2offset;
			player2East_in = player2offset;
			player2West_in = player2offset;
		end
		else
		begin
			// Get map pixel
			grass_in = yTileTwoOffset*10'd32 + xTileTwoOffset;
			water_in = yTileTwoOffset*10'd32 + xTileTwoOffset;
			sand_in  = yTileTwoOffset*10'd32 + xTileTwoOffset;
			map_in = yTileTwo*7'd100 + xTileTwo;
			// Get player sprite pixel
			player2North_in = playerOffset;
			player2South_in = playerOffset;
			player2East_in = playerOffset;
			player2West_in = playerOffset;
			player1North_in = player1offset;
			player1South_in = player1offset;
			player1East_in = player1offset;
			player1West_in = player1offset;
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

	// On-chip memory
	logic [9:0]	 grass_in, sand_in, water_in;
	logic [12:0] player1North_in, player1South_in, player1West_in, player1East_in; 
	logic [12:0] player2North_in, player2South_in, player2West_in, player2East_in;
	logic [12:0] map_in; 
	logic [23:0] grass_out, sand_out, water_out;
	logic [23:0] player1North_out, player1South_out, player1West_out, player1East_out;
	logic [23:0] player2North_out, player2South_out, player2West_out, player2East_out;
	logic [1:0] map_out;
	grass grassTile(.clk(Clk), .d(0), .write_address(0), .read_address(grass_in), .we(0), .q(grass_out));
	sand  sandTile (.clk(Clk), .d(0), .write_address(0), .read_address(sand_in), .we(0), .q(sand_out));
	water waterTile(.clk(Clk), .d(0), .write_address(0), .read_address(water_in), .we(0), .q(water_out));
	player2_1 playerNorthmem1(.clk(Clk), .d(0), .write_address(0), .read_address(player1North_in), .we(0), .q(player1North_out));
	player2_2 playerSouthmem1(.clk(Clk), .d(0), .write_address(0), .read_address(player1East_in), .we(0), .q(player1East_out));
	player2_3 playerEastmem1(.clk(Clk), .d(0), .write_address(0), .read_address(player1South_in), .we(0), .q(player1South_out));
	player2_4 playerWestmem1(.clk(Clk), .d(0), .write_address(0), .read_address(player1West_in), .we(0), .q(player1West_out));
	player2_1 playerNorthmem2(.clk(Clk), .d(0), .write_address(0), .read_address(player2North_in), .we(0), .q(player2North_out));
	player2_2 playerSouthmem2(.clk(Clk), .d(0), .write_address(0), .read_address(player2East_in), .we(0), .q(player2East_out));
	player2_3 playerEastmem2(.clk(Clk), .d(0), .write_address(0), .read_address(player2South_in), .we(0), .q(player2South_out));
	player2_4 playerWestmem2(.clk(Clk), .d(0), .write_address(0), .read_address(player2West_in), .we(0), .q(player2West_out));
	mapdata mapinfo(.clk(Clk), .d(0), .write_address(0), .read_address(map_in), .we(0), .q(map_out));


	//// OTHER SPRITE LOGIC
	// Calculate pixel of other player
	assign onscreen = (((xTwo > xOne)? xTwo - xOne:xOne - xTwo) < 12'd360) & (((yTwo > yOne)? yTwo - yOne:yOne - yTwo) < 12'd280);
	// assign onscreen = (xOne + 320 > xTwo) & (xOne - 320 < xTwo) & (yOne + 240 > yTwo) & (yOne - 240 < yTwo);
	assign player2offset = (DrYplus - ((yTwo - 12'd37) - (yOne - 12'd240)))*12'd75 + (DrXplus - ((xTwo - 12'd37) - (xOne - 12'd320)));
	assign player1offset = (DrYplus - ((yOne - 12'd37) - (yTwo - 12'd240)))*12'd75 + (DrXplus - ((xOne - 12'd37) - (xTwo - 12'd320)));


	//// CENTERED PLAYER SPRITE LOGIC
	// Calculate if current pixel is in player sprite
	assign inPlayer = (DrXplus > 10'd283) & (DrXplus < 10'd357) & (DrYplus > 10'd203) & (DrYplus < 10'd277);

	// Calculate pixel in player sprite
	assign playerOffset = (DrYplus - 10'd203)*10'd75 + (DrXplus - 10'd283);
	////


	//// BACKGROUND TILE LOGIC
	// Calculate background tile for player 1
	assign xTileOne = (xOne - 12'd320 + DrXplus) >> 3'd5; // each tile is 32 x 32
	assign yTileOne = (yOne - 12'd240 + DrYplus) >> 3'd5;
	assign xTileOneOffset = (xOne - 12'd320 + DrXplus) & 12'b000000011111; // xMap - 32*xTileOne
	assign yTileOneOffset = (yOne - 12'd240 + DrYplus) & 12'b000000011111;

	// Calculate background tile for player 2
	assign xTileTwo = (xTwo - 12'd320 + DrXplus) >> 5; // each tile is 32 x 32
	assign yTileTwo = (yTwo - 12'd240 + DrYplus) >> 5;
	assign xTileTwoOffset = (xTwo - 12'd320 + DrXplus) & 12'b000000011111; // xMap - 32*xTileTwo
	assign yTileTwoOffset = (yTwo - 12'd240 + DrYplus) & 12'b000000011111;
	////


endmodule

