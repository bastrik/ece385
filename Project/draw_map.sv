// Drawing logic for ECE 385 final project
// April 13, 2018

module draw_map (input logic Clk,
				 input logic [11:0] xOne, // player 1's absolute location on map
				 input logic [11:0] yOne,
				 input logic [11:0] xTwo, // player 2's absolute location on map
				 input logic [11:0] yTwo,
				 input logic [1:0]  p1dir, // direction player is facing
				 input logic [1:0]  p2dir,
				 input logic [9:0] DrX, // pixel being drawn
				 input logic [9:0] DrY, 
				 input logic VGA_VS,
				 input logic VGA_HS,
				 // bullet positions and status
				 input logic [11:0] b1X, b1Y, b2X, b2Y, b3X, b3Y, b4X, b4Y, b5X, b5Y, b6X, b6Y, b7X, b7Y, b8X, b8Y, b9X, b9Y, b10X, b10Y, b11X, b11Y, b12X, b12Y, b13X, b13Y, b14X, b14Y, b15X, b15Y, b16X, b16Y,
				 input logic b1active, b2active, b3active, b4active, b5active, b6active, b7active, b8active, b9active, b10active, b11active, b12active, b13active, b14active, b15active, b16active,
				 input logic [3:0] p1health, p2health, // player health
				 input logic p1wins, // did player 1 win?
				 input logic [2:0] currState, // current game state
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

	// FOR HEALTH BAR
	logic [23:0] hbonp1, hbonp2;

	// FOR SPRITE OF BULLETS ON MONITORS
	logic [23:0] bullet1, bullet2;

	// FOR DRAWING NON-MAP PIXELS
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
			// Check if the health bar should be drawn
			// Draw border
			if (hbBorderX & hbBorderY)
				hbonp1 <= 24'ha0a0a0;
			// Draw green bar
			else if (((p1health == 4'd8) & hbBarX8 & hbBarY) | ((p1health == 4'd7) & hbBarX7 & hbBarY) | ((p1health == 4'd6) & hbBarX6 & hbBarY) | ((p1health == 4'd5) & hbBarX5 & hbBarY))
				hbonp1 <= 24'h00ff00;
			// Draw orange bar
			else if (((p1health == 4'd4) & hbBarX4 & hbBarY) | ((p1health == 4'd3) & hbBarX3 & hbBarY))
				hbonp1 <= 24'hff8000;
			// Draw red bar
			else if (((p1health == 4'd2) & hbBarX2 & hbBarY) | ((p1health == 4'd1) & hbBarX1 & hbBarY))
				hbonp1 <= 24'hff0000;
			// Don't draw a bar (sentinel color)
			else
				hbonp1 <= 24'hff00d2;
			// Check if bullets are onscreen
			if (b1active & b1on1 & b1on1offset >= 5'd0 & b1on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b1X)? xOne - 12'd320 + DrXplus - b1X:b1X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b1Y)? yOne - 12'd240 + DrYplus - b1Y:b1Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet1a_out;
			else if (b2active & b2on1 & b2on1offset >= 5'd0 & b2on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b2X)? xOne - 12'd320 + DrXplus - b2X:b2X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b2Y)? yOne - 12'd240 + DrYplus - b2Y:b2Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet2a_out;
			else if (b3active & b3on1 & b3on1offset >= 5'd0 & b3on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b3X)? xOne - 12'd320 + DrXplus - b3X:b3X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b3Y)? yOne - 12'd240 + DrYplus - b3Y:b3Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet3a_out;
			else if (b4active & b4on1 & b4on1offset >= 5'd0 & b4on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b4X)? xOne - 12'd320 + DrXplus - b4X:b4X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b4Y)? yOne - 12'd240 + DrYplus - b4Y:b4Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet4a_out;
			else if (b5active & b5on1 & b5on1offset >= 5'd0 & b5on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b5X)? xOne - 12'd320 + DrXplus - b5X:b5X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b5Y)? yOne - 12'd240 + DrYplus - b5Y:b5Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet5a_out;
			else if (b6active & b6on1 & b6on1offset >= 5'd0 & b6on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b6X)? xOne - 12'd320 + DrXplus - b6X:b6X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b6Y)? yOne - 12'd240 + DrYplus - b6Y:b6Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet6a_out;
			else if (b7active & b7on1 & b7on1offset >= 5'd0 & b7on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b7X)? xOne - 12'd320 + DrXplus - b7X:b7X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b7Y)? yOne - 12'd240 + DrYplus - b7Y:b7Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet7a_out;
			else if (b8active & b8on1 & b8on1offset >= 5'd0 & b8on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b8X)? xOne - 12'd320 + DrXplus - b8X:b8X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b8Y)? yOne - 12'd240 + DrYplus - b8Y:b8Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet8a_out;
			else if (b9active & b9on1 & b9on1offset >= 5'd0 & b9on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b9X)? xOne - 12'd320 + DrXplus - b9X:b9X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b9Y)? yOne - 12'd240 + DrYplus - b9Y:b9Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet9a_out;
			else if (b10active & b10on1 & b10on1offset >= 5'd0 & b10on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b10X)? xOne - 12'd320 + DrXplus - b10X:b10X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b10Y)? yOne - 12'd240 + DrYplus - b10Y:b10Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet10a_out;
			else if (b11active & b11on1 & b11on1offset >= 5'd0 & b11on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b11X)? xOne - 12'd320 + DrXplus - b11X:b11X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b11Y)? yOne - 12'd240 + DrYplus - b11Y:b11Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet11a_out;
			else if (b12active & b12on1 & b12on1offset >= 5'd0 & b12on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b12X)? xOne - 12'd320 + DrXplus - b12X:b12X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b12Y)? yOne - 12'd240 + DrYplus - b12Y:b12Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet12a_out;
			else if (b13active & b13on1 & b13on1offset >= 5'd0 & b13on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b13X)? xOne - 12'd320 + DrXplus - b13X:b13X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b13Y)? yOne - 12'd240 + DrYplus - b13Y:b13Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet13a_out;
			else if (b14active & b14on1 & b14on1offset >= 5'd0 & b14on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b14X)? xOne - 12'd320 + DrXplus - b14X:b14X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b14Y)? yOne - 12'd240 + DrYplus - b14Y:b14Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet14a_out;
			else if (b15active & b15on1 & b15on1offset >= 5'd0 & b15on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b15X)? xOne - 12'd320 + DrXplus - b15X:b15X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b15Y)? yOne - 12'd240 + DrYplus - b15Y:b15Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet15a_out;
			else if (b16active & b16on1 & b16on1offset >= 5'd0 & b16on1offset < 5'd25 & (((xOne - 12'd320 + DrXplus > b16X)? xOne - 12'd320 + DrXplus - b16X:b16X - (xOne - 12'd320 + DrXplus)) < 2) & (((yOne - 12'd240 + DrYplus > b16Y)? yOne - 12'd240 + DrYplus - b16Y:b16Y - (yOne - 12'd240 + DrYplus)) < 2))
				bullet1 <= bullet16a_out;
			else
				bullet1 <= 24'hff00d2;
		end

		// Determine map and sprite pixels for player 2
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
			// Check if the health bar should be drawn
			// Draw border
			if (hbBorderX & hbBorderY)
				hbonp2 <= 24'ha0a0a0;
			// Draw green bar
			else if (((p2health == 4'd8) & hbBarX8 & hbBarY) | ((p2health == 4'd7) & hbBarX7 & hbBarY) | ((p2health == 4'd6) & hbBarX6 & hbBarY) | ((p2health == 4'd5) & hbBarX5 & hbBarY))
				hbonp2 <= 24'h00ff00;
			// Draw orange bar
			else if (((p2health == 4'd4) & hbBarX4 & hbBarY) | ((p2health == 4'd3) & hbBarX3 & hbBarY))
				hbonp2 <= 24'hff8000;
			// Draw red bar
			else if (((p2health == 4'd2) & hbBarX2 & hbBarY) | ((p2health == 4'd1) & hbBarX1 & hbBarY))
				hbonp2 <= 24'hff0000;
			// Don't draw a bar (sentinel color)
			else
				hbonp2 <= 24'hff00d2;
			// Check if bullets are onscreen
			if (b1active & b1on2 & b1on2offset >= 5'd0 & b1on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b1X)? xTwo - 12'd320 + DrXplus - b1X:b1X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b1Y)? yTwo - 12'd240 + DrYplus - b1Y:b1Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet1b_out;
			else if (b2active & b2on2 & b2on2offset >= 5'd0 & b2on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b2X)? xTwo - 12'd320 + DrXplus - b2X:b2X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b2Y)? yTwo - 12'd240 + DrYplus - b2Y:b2Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet2b_out;
			else if (b3active & b3on2 & b3on2offset >= 5'd0 & b3on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b3X)? xTwo - 12'd320 + DrXplus - b3X:b3X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b3Y)? yTwo - 12'd240 + DrYplus - b3Y:b3Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet3b_out;
			else if (b4active & b4on2 & b4on2offset >= 5'd0 & b4on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b4X)? xTwo - 12'd320 + DrXplus - b4X:b4X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b4Y)? yTwo - 12'd240 + DrYplus - b4Y:b4Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet4b_out;
			else if (b5active & b5on2 & b5on2offset >= 5'd0 & b5on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b5X)? xTwo - 12'd320 + DrXplus - b5X:b5X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b5Y)? yTwo - 12'd240 + DrYplus - b5Y:b5Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet5b_out;
			else if (b6active & b6on2 & b6on2offset >= 5'd0 & b6on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b6X)? xTwo - 12'd320 + DrXplus - b6X:b6X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b6Y)? yTwo - 12'd240 + DrYplus - b6Y:b6Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet6b_out;
			else if (b7active & b7on2 & b7on2offset >= 5'd0 & b7on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b7X)? xTwo - 12'd320 + DrXplus - b7X:b7X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b7Y)? yTwo - 12'd240 + DrYplus - b7Y:b7Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet7b_out;
			else if (b8active & b8on2 & b8on2offset >= 5'd0 & b8on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b8X)? xTwo - 12'd320 + DrXplus - b8X:b8X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b8Y)? yTwo - 12'd240 + DrYplus - b8Y:b8Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet8b_out;
			else if (b9active & b9on2 & b9on2offset >= 5'd0 & b9on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b9X)? xTwo - 12'd320 + DrXplus - b9X:b9X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b9Y)? yTwo - 12'd240 + DrYplus - b9Y:b9Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet9b_out;
			else if (b10active & b10on2 & b10on2offset >= 5'd0 & b10on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b10X)? xTwo - 12'd320 + DrXplus - b10X:b10X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b10Y)? yTwo - 12'd240 + DrYplus - b10Y:b10Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet10b_out;
			else if (b11active & b11on2 & b11on2offset >= 5'd0 & b11on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b11X)? xTwo - 12'd320 + DrXplus - b11X:b11X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b11Y)? yTwo - 12'd240 + DrYplus - b11Y:b11Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet11b_out;
			else if (b12active & b12on2 & b12on2offset >= 5'd0 & b12on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b12X)? xTwo - 12'd320 + DrXplus - b12X:b12X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b12Y)? yTwo - 12'd240 + DrYplus - b12Y:b12Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet12b_out;
			else if (b13active & b13on2 & b13on2offset >= 5'd0 & b13on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b13X)? xTwo - 12'd320 + DrXplus - b13X:b13X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b13Y)? yTwo - 12'd240 + DrYplus - b13Y:b13Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet13b_out;
			else if (b14active & b14on2 & b14on2offset >= 5'd0 & b14on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b14X)? xTwo - 12'd320 + DrXplus - b14X:b14X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b14Y)? yTwo - 12'd240 + DrYplus - b14Y:b14Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet14b_out;
			else if (b15active & b15on2 & b15on2offset >= 5'd0 & b15on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b15X)? xTwo - 12'd320 + DrXplus - b15X:b15X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b15Y)? yTwo - 12'd240 + DrYplus - b15Y:b15Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet15b_out;
			else if (b16active & b16on2 & b16on2offset >= 5'd0 & b16on2offset < 5'd25 & (((xTwo - 12'd320 + DrXplus > b16X)? xTwo - 12'd320 + DrXplus - b16X:b16X - (xTwo - 12'd320 + DrXplus)) < 2) & (((yTwo - 12'd240 + DrYplus > b16Y)? yTwo - 12'd240 + DrYplus - b16Y:b16Y - (yTwo - 12'd240 + DrYplus)) < 2))
				bullet2 <= bullet16b_out;
			else
				bullet2 <= 24'hff00d2;
		end
	end

	always_comb
	begin
		// Get start/end screen pixel
		start_in = screenOffset;
		waiting_in = screenOffset;
		winner_in = screenOffset;
		loser_in = screenOffset;
		// Default values
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
		bullet1a_in = 5'd0;
		bullet1b_in = 5'd0;
		bullet2a_in = 5'd0;
		bullet2b_in = 5'd0;
		bullet3a_in = 5'd0;
		bullet3b_in = 5'd0;
		bullet4a_in = 5'd0;
		bullet4b_in = 5'd0;
		bullet5a_in = 5'd0;
		bullet5b_in = 5'd0;
		bullet6a_in = 5'd0;
		bullet6b_in = 5'd0;
		bullet7a_in = 5'd0;
		bullet7b_in = 5'd0;
		bullet8a_in = 5'd0;
		bullet8b_in = 5'd0;
		bullet9a_in = 5'd0;
		bullet9b_in = 5'd0;
		bullet10a_in = 5'd0;
		bullet10b_in = 5'd0;
		bullet11a_in = 5'd0;
		bullet11b_in = 5'd0;
		bullet12a_in = 5'd0;
		bullet12b_in = 5'd0;
		bullet13a_in = 5'd0;
		bullet13b_in = 5'd0;
		bullet14a_in = 5'd0;
		bullet14b_in = 5'd0;
		bullet15a_in = 5'd0;
		bullet15b_in = 5'd0;
		bullet16a_in = 5'd0;
		bullet16b_in = 5'd0;

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
			// Get bullet pixel
			bullet1a_in = b1on1offset;
			bullet2a_in = b2on1offset;
			bullet3a_in = b3on1offset;
			bullet4a_in = b4on1offset;
			bullet5a_in = b5on1offset;
			bullet6a_in = b6on1offset;
			bullet7a_in = b7on1offset;
			bullet8a_in = b8on1offset;
			bullet9a_in = b9on1offset;
			bullet10a_in = b10on1offset;
			bullet11a_in = b11on1offset;
			bullet12a_in = b12on1offset;
			bullet13a_in = b13on1offset;
			bullet14a_in = b14on1offset;
			bullet15a_in = b15on1offset;
			bullet16a_in = b16on1offset;
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
			// Get bullet pixel
			bullet1b_in = b1on2offset;
			bullet2b_in = b2on2offset;
			bullet3b_in = b3on2offset;
			bullet4b_in = b4on2offset;
			bullet5b_in = b5on2offset;
			bullet6b_in = b6on2offset;
			bullet7b_in = b7on2offset;
			bullet8b_in = b8on2offset;
			bullet9b_in = b9on2offset;
			bullet10b_in = b10on2offset;
			bullet11b_in = b11on2offset;
			bullet12b_in = b12on2offset;
			bullet13b_in = b13on2offset;
			bullet14b_in = b14on2offset;
			bullet15b_in = b15on2offset;
			bullet16b_in = b16on2offset;
		end
	end

	// For drawing non-map pixels
	always_comb
	begin
		// For player 1's screen
		if (hbonp1 != 24'hff00d2)
			sprite1 = hbonp1;
		else if (player1 != 24'hff00d2)
			sprite1 = player1;
		else if (p2onp1 != 24'hff00d2)
			sprite1 = p2onp1;
		else if (bullet1 != 24'hff00d2)
			sprite1 = bullet1;
		else
			sprite1 = 24'hff00d2;

		// For player 2's screen
		if (hbonp2 != 24'hff00d2)
			sprite2 = hbonp2;
		else if (player2 != 24'hff00d2)
			sprite2 = player2;
		else if (p1onp2 != 24'hff00d2)
			sprite2 = p1onp2;
		else if (bullet2 != 24'hff00d2)
			sprite2 = bullet2;
		else
			sprite2 = 24'hff00d2;
	end

	// Assign VGA values for player 1 based on game state
	always_comb
	begin
		// Default values (unused)
		VGA_R = 8'd0;
		VGA_G = 8'd0;
		VGA_B = 8'd0;
		case (currState)
			3'd0:
			begin
				VGA_R = (centerRegion)? {start_out[23:19], 3'b000}:{8'd0};
				VGA_G = (centerRegion)? {start_out[15:11], 3'b000}:{8'd0};
				VGA_B = (centerRegion)? {start_out[7:3], 3'b000}:{8'd0};
			end
			3'd1:
			begin
				VGA_R = (centerRegion)? {waiting_out[23:19], 3'b000}:{8'd0};
				VGA_G = (centerRegion)? {waiting_out[15:11], 3'b000}:{8'd0};
				VGA_B = (centerRegion)? {waiting_out[7:3], 3'b000}:{8'd0};
			end
			3'd2:
			begin
				VGA_R = (centerRegion)? {start_out[23:19], 3'b000}:{8'd0};
				VGA_G = (centerRegion)? {start_out[15:11], 3'b000}:{8'd0};
				VGA_B = (centerRegion)? {start_out[7:3], 3'b000}:{8'd0};
			end
			3'd3:
			begin
				VGA_R = (sprite1 == 24'hff00d2)? {mapOne[23:19], 3'b000}:{sprite1[23:19], 3'b000};
				VGA_G = (sprite1 == 24'hff00d2)? {mapOne[15:11], 3'b000}:{sprite1[15:11], 3'b000};
				VGA_B = (sprite1 == 24'hff00d2)? {mapOne[7:3], 3'b000}:{sprite1[7:3], 3'b000};
			end
			3'd4:
			begin
				if (p1wins)
				begin
					VGA_R = (centerRegion)? {winner_out[23:19], 3'b000}:{8'd0};
					VGA_G = (centerRegion)? {winner_out[15:11], 3'b000}:{8'd0};
					VGA_B = (centerRegion)? {winner_out[7:3], 3'b000}:{8'd0};
				end
				else
				begin
					VGA_R = (centerRegion)? {loser_out[23:19], 3'b000}:{8'd0};
					VGA_G = (centerRegion)? {loser_out[15:11], 3'b000}:{8'd0};
					VGA_B = (centerRegion)? {loser_out[7:3], 3'b000}:{8'd0};
				end
			end
		endcase
	end

	// Assign GPIO values for player 2 based on game state
	// Set RGB signals to low during horizontal blanking interval
	always_comb
	begin
		// Default values (unused)
		GPIO[9] = 1'b0;
		GPIO[7] = 1'b0;
		GPIO[5] = 1'b0;
		GPIO[3] = 1'b0;
		GPIO[1] = 1'b0;
		GPIO[14] = 1'b0;
		GPIO[12] = 1'b0;
		GPIO[10] = 1'b0;
		GPIO[6] = 1'b0;
		GPIO[0] = 1'b0;
		GPIO[19] = 1'b0;
		GPIO[17] = 1'b0;
		GPIO[15] = 1'b0;
		GPIO[13] = 1'b0;
		GPIO[11] = 1'b0;
		case (currState)
			3'd0:
			begin
				GPIO[9] = blanking? ((centerRegion)? start_out[23]:1'b0):1'b0;
				GPIO[7] = blanking? ((centerRegion)? start_out[22]:1'b0):1'b0;
				GPIO[5] = blanking? ((centerRegion)? start_out[21]:1'b0):1'b0;
				GPIO[3] = blanking? ((centerRegion)? start_out[20]:1'b0):1'b0;
				GPIO[1] = blanking? ((centerRegion)? start_out[19]:1'b0):1'b0;
				GPIO[14] = blanking? ((centerRegion)? start_out[15]:1'b0):1'b0;
				GPIO[12] = blanking? ((centerRegion)? start_out[14]:1'b0):1'b0;
				GPIO[10] = blanking? ((centerRegion)? start_out[13]:1'b0):1'b0;
				GPIO[6] = blanking? ((centerRegion)? start_out[12]:1'b0):1'b0;
				GPIO[0] = blanking? ((centerRegion)? start_out[11]:1'b0):1'b0;
				GPIO[19] = blanking? ((centerRegion)? start_out[7]:1'b0):1'b0;
				GPIO[17] = blanking? ((centerRegion)? start_out[6]:1'b0):1'b0;
				GPIO[15] = blanking? ((centerRegion)? start_out[5]:1'b0):1'b0;
				GPIO[13] = blanking? ((centerRegion)? start_out[4]:1'b0):1'b0;
				GPIO[11] = blanking? ((centerRegion)? start_out[3]:1'b0):1'b0;
			end
			3'd1:
			begin
				GPIO[9] = blanking? ((centerRegion)? start_out[23]:1'b0):1'b0;
				GPIO[7] = blanking? ((centerRegion)? start_out[22]:1'b0):1'b0;
				GPIO[5] = blanking? ((centerRegion)? start_out[21]:1'b0):1'b0;
				GPIO[3] = blanking? ((centerRegion)? start_out[20]:1'b0):1'b0;
				GPIO[1] = blanking? ((centerRegion)? start_out[19]:1'b0):1'b0;
				GPIO[14] = blanking? ((centerRegion)? start_out[15]:1'b0):1'b0;
				GPIO[12] = blanking? ((centerRegion)? start_out[14]:1'b0):1'b0;
				GPIO[10] = blanking? ((centerRegion)? start_out[13]:1'b0):1'b0;
				GPIO[6] = blanking? ((centerRegion)? start_out[12]:1'b0):1'b0;
				GPIO[0] = blanking? ((centerRegion)? start_out[11]:1'b0):1'b0;
				GPIO[19] = blanking? ((centerRegion)? start_out[7]:1'b0):1'b0;
				GPIO[17] = blanking? ((centerRegion)? start_out[6]:1'b0):1'b0;
				GPIO[15] = blanking? ((centerRegion)? start_out[5]:1'b0):1'b0;
				GPIO[13] = blanking? ((centerRegion)? start_out[4]:1'b0):1'b0;
				GPIO[11] = blanking? ((centerRegion)? start_out[3]:1'b0):1'b0;
			end
			3'd2:
			begin
				GPIO[9] = blanking? ((centerRegion)? waiting_out[23]:1'b0):1'b0;
				GPIO[7] = blanking? ((centerRegion)? waiting_out[22]:1'b0):1'b0;
				GPIO[5] = blanking? ((centerRegion)? waiting_out[21]:1'b0):1'b0;
				GPIO[3] = blanking? ((centerRegion)? waiting_out[20]:1'b0):1'b0;
				GPIO[1] = blanking? ((centerRegion)? waiting_out[19]:1'b0):1'b0;
				GPIO[14] = blanking? ((centerRegion)? waiting_out[15]:1'b0):1'b0;
				GPIO[12] = blanking? ((centerRegion)? waiting_out[14]:1'b0):1'b0;
				GPIO[10] = blanking? ((centerRegion)? waiting_out[13]:1'b0):1'b0;
				GPIO[6] = blanking? ((centerRegion)? waiting_out[12]:1'b0):1'b0;
				GPIO[0] = blanking? ((centerRegion)? waiting_out[11]:1'b0):1'b0;
				GPIO[19] = blanking? ((centerRegion)? waiting_out[7]:1'b0):1'b0;
				GPIO[17] = blanking? ((centerRegion)? waiting_out[6]:1'b0):1'b0;
				GPIO[15] = blanking? ((centerRegion)? waiting_out[5]:1'b0):1'b0;
				GPIO[13] = blanking? ((centerRegion)? waiting_out[4]:1'b0):1'b0;
				GPIO[11] = blanking? ((centerRegion)? waiting_out[3]:1'b0):1'b0;
			end
			3'd3:
			begin
				GPIO[9] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[23]:sprite2[23]):1'b0;
				GPIO[7] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[22]:sprite2[22]):1'b0;
				GPIO[5] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[21]:sprite2[21]):1'b0;
				GPIO[3] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[20]:sprite2[20]):1'b0;
				GPIO[1] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[19]:sprite2[19]):1'b0;
				GPIO[14] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[15]:sprite2[15]):1'b0;
				GPIO[12] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[14]:sprite2[14]):1'b0;
				GPIO[10] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[13]:sprite2[13]):1'b0;
				GPIO[6] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[12]:sprite2[12]):1'b0;
				GPIO[0] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[11]:sprite2[11]):1'b0;
				GPIO[19] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[7]:sprite2[7]):1'b0;
				GPIO[17] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[6]:sprite2[6]):1'b0;
				GPIO[15] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[5]:sprite2[5]):1'b0;
				GPIO[13] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[4]:sprite2[4]):1'b0;
				GPIO[11] = blanking? ((sprite2 == 24'hff00d2)? mapTwo[3]:sprite2[3]):1'b0;
			end
			3'd4:
			begin
				if (p1wins)
				begin
					GPIO[9] = blanking? ((centerRegion)? loser_out[23]:1'b0):1'b0;
					GPIO[7] = blanking? ((centerRegion)? loser_out[22]:1'b0):1'b0;
					GPIO[5] = blanking? ((centerRegion)? loser_out[21]:1'b0):1'b0;
					GPIO[3] = blanking? ((centerRegion)? loser_out[20]:1'b0):1'b0;
					GPIO[1] = blanking? ((centerRegion)? loser_out[19]:1'b0):1'b0;
					GPIO[14] = blanking? ((centerRegion)? loser_out[15]:1'b0):1'b0;
					GPIO[12] = blanking? ((centerRegion)? loser_out[14]:1'b0):1'b0;
					GPIO[10] = blanking? ((centerRegion)? loser_out[13]:1'b0):1'b0;
					GPIO[6] = blanking? ((centerRegion)? loser_out[12]:1'b0):1'b0;
					GPIO[0] = blanking? ((centerRegion)? loser_out[11]:1'b0):1'b0;
					GPIO[19] = blanking? ((centerRegion)? loser_out[7]:1'b0):1'b0;
					GPIO[17] = blanking? ((centerRegion)? loser_out[6]:1'b0):1'b0;
					GPIO[15] = blanking? ((centerRegion)? loser_out[5]:1'b0):1'b0;
					GPIO[13] = blanking? ((centerRegion)? loser_out[4]:1'b0):1'b0;
					GPIO[11] = blanking? ((centerRegion)? loser_out[3]:1'b0):1'b0;
				end
				else
				begin
					GPIO[9] = blanking? ((centerRegion)? winner_out[23]:1'b0):1'b0;
					GPIO[7] = blanking? ((centerRegion)? winner_out[22]:1'b0):1'b0;
					GPIO[5] = blanking? ((centerRegion)? winner_out[21]:1'b0):1'b0;
					GPIO[3] = blanking? ((centerRegion)? winner_out[20]:1'b0):1'b0;
					GPIO[1] = blanking? ((centerRegion)? winner_out[19]:1'b0):1'b0;
					GPIO[14] = blanking? ((centerRegion)? winner_out[15]:1'b0):1'b0;
					GPIO[12] = blanking? ((centerRegion)? winner_out[14]:1'b0):1'b0;
					GPIO[10] = blanking? ((centerRegion)? winner_out[13]:1'b0):1'b0;
					GPIO[6] = blanking? ((centerRegion)? winner_out[12]:1'b0):1'b0;
					GPIO[0] = blanking? ((centerRegion)? winner_out[11]:1'b0):1'b0;
					GPIO[19] = blanking? ((centerRegion)? winner_out[7]:1'b0):1'b0;
					GPIO[17] = blanking? ((centerRegion)? winner_out[6]:1'b0):1'b0;
					GPIO[15] = blanking? ((centerRegion)? winner_out[5]:1'b0):1'b0;
					GPIO[13] = blanking? ((centerRegion)? winner_out[4]:1'b0):1'b0;
					GPIO[11] = blanking? ((centerRegion)? winner_out[3]:1'b0):1'b0;
				end
			end
		endcase
	end
	assign GPIO[2] = VGA_VS;
	assign GPIO[4] = VGA_HS;

	// On-chip memory
	logic [16:0] start_in, waiting_in, winner_in, loser_in;
	logic [9:0]	 grass_in, sand_in, water_in;
	logic [12:0] player1North_in, player1South_in, player1West_in, player1East_in; 
	logic [12:0] player2North_in, player2South_in, player2West_in, player2East_in;
	logic [12:0] map_in; 
	logic [4:0] bullet1a_in, bullet1b_in, bullet2a_in, bullet2b_in, bullet3a_in, bullet3b_in, bullet4a_in, bullet4b_in, bullet5a_in, bullet5b_in, bullet6a_in, bullet6b_in, bullet7a_in, bullet7b_in, bullet8a_in, bullet8b_in, bullet9a_in, bullet9b_in, bullet10a_in, bullet10b_in, bullet11a_in, bullet11b_in, bullet12a_in, bullet12b_in, bullet13a_in, bullet13b_in, bullet14a_in, bullet14b_in, bullet15a_in, bullet15b_in, bullet16a_in, bullet16b_in;
	logic [23:0] start_out, waiting_out, winner_out, loser_out;
	logic [23:0] grass_out, sand_out, water_out;
	logic [23:0] player1North_out, player1South_out, player1West_out, player1East_out;
	logic [23:0] player2North_out, player2South_out, player2West_out, player2East_out;
	logic [1:0] map_out;
	logic [23:0] bullet1a_out, bullet1b_out, bullet2a_out, bullet2b_out, bullet3a_out, bullet3b_out, bullet4a_out, bullet4b_out, bullet5a_out, bullet5b_out, bullet6a_out, bullet6b_out, bullet7a_out, bullet7b_out, bullet8a_out, bullet8b_out, bullet9a_out, bullet9b_out, bullet10a_out, bullet10b_out, bullet11a_out, bullet11b_out, bullet12a_out, bullet12b_out, bullet13a_out, bullet13b_out, bullet14a_out, bullet14b_out, bullet15a_out, bullet15b_out, bullet16a_out, bullet16b_out;
	start startScreen(.clk(Clk), .d(0), .write_address(0), .read_address(start_in), .we(0), .q(start_out));
	start waitingScreen(.clk(Clk), .d(0), .write_address(0), .read_address(waiting_in), .we(0), .q(waiting_out));
	start winnerScreen(.clk(Clk), .d(0), .write_address(0), .read_address(winner_in), .we(0), .q(winner_out));
	start loserScreen(.clk(Clk), .d(0), .write_address(0), .read_address(loser_in), .we(0), .q(loser_out));
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
	bulletmem bullet1a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet1a_in), .we(0), .q(bullet1a_out));
	bulletmem bullet1b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet1b_in), .we(0), .q(bullet1b_out));
	bulletmem bullet2a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet2a_in), .we(0), .q(bullet2a_out));
	bulletmem bullet2b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet2b_in), .we(0), .q(bullet2b_out));
	bulletmem bullet3a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet3a_in), .we(0), .q(bullet3a_out));
	bulletmem bullet3b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet3b_in), .we(0), .q(bullet3b_out));
	bulletmem bullet4a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet4a_in), .we(0), .q(bullet4a_out));
	bulletmem bullet4b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet4b_in), .we(0), .q(bullet4b_out));
	bulletmem bullet5a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet5a_in), .we(0), .q(bullet5a_out));
	bulletmem bullet5b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet5b_in), .we(0), .q(bullet5b_out));
	bulletmem bullet6a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet6a_in), .we(0), .q(bullet6a_out));
	bulletmem bullet6b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet6b_in), .we(0), .q(bullet6b_out));
	bulletmem bullet7a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet7a_in), .we(0), .q(bullet7a_out));
	bulletmem bullet7b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet7b_in), .we(0), .q(bullet7b_out));
	bulletmem bullet8a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet8a_in), .we(0), .q(bullet8a_out));
	bulletmem bullet8b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet8b_in), .we(0), .q(bullet8b_out));
	bulletmem bullet9a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet9a_in), .we(0), .q(bullet9a_out));
	bulletmem bullet9b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet9b_in), .we(0), .q(bullet9b_out));
	bulletmem bullet10a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet10a_in), .we(0), .q(bullet10a_out));
	bulletmem bullet10b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet10b_in), .we(0), .q(bullet10b_out));
	bulletmem bullet11a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet11a_in), .we(0), .q(bullet11a_out));
	bulletmem bullet11b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet11b_in), .we(0), .q(bullet11b_out));
	bulletmem bullet12a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet12a_in), .we(0), .q(bullet12a_out));
	bulletmem bullet12b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet12b_in), .we(0), .q(bullet12b_out));
	bulletmem bullet13a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet13a_in), .we(0), .q(bullet13a_out));
	bulletmem bullet13b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet13b_in), .we(0), .q(bullet13b_out));
	bulletmem bullet14a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet14a_in), .we(0), .q(bullet14a_out));
	bulletmem bullet14b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet14b_in), .we(0), .q(bullet14b_out));
	bulletmem bullet15a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet15a_in), .we(0), .q(bullet15a_out));
	bulletmem bullet15b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet15b_in), .we(0), .q(bullet15b_out));
	bulletmem bullet16a(.clk(Clk), .d(0), .write_address(0), .read_address(bullet16a_in), .we(0), .q(bullet16a_out));
	bulletmem bullet16b(.clk(Clk), .d(0), .write_address(0), .read_address(bullet16b_in), .we(0), .q(bullet16b_out));


	//// HEALTH BAR LOGIC
	logic hbBorderX, hbBorderY, hbBarX1, hbBarX2, hbBarX3, hbBarX4, hbBarX5, hbBarX6, hbBarX7, hbBarX8, hbBarY;
	assign hbBorderX = ((DrXplus >= 10'd276) & (DrXplus <= 10'd278)) | ((DrXplus >= 10'd363) & (DrXplus <= 10'd365));
	assign hbBorderY = ((DrYplus >= 10'd442) & (DrYplus <= 10'd444)) | ((DrYplus >= 10'd459) & (DrYplus <= 10'd461));
	assign hbBarX1 = ((DrXplus >= 10'd281) & (DrXplus <= 10'd290));
	assign hbBarX2 = ((DrXplus >= 10'd281) & (DrXplus <= 10'd300));
	assign hbBarX3 = ((DrXplus >= 10'd281) & (DrXplus <= 10'd310));
	assign hbBarX4 = ((DrXplus >= 10'd281) & (DrXplus <= 10'd320));
	assign hbBarX5 = ((DrXplus >= 10'd281) & (DrXplus <= 10'd330));
	assign hbBarX6 = ((DrXplus >= 10'd281) & (DrXplus <= 10'd340));
	assign hbBarX7 = ((DrXplus >= 10'd281) & (DrXplus <= 10'd350));
	assign hbBarX8 = ((DrXplus >= 10'd281) & (DrXplus <= 10'd360));
	assign hbBarY = ((DrYplus >= 10'd447) & (DrYplus <= 10'd456));
	////


	//// BULLET LOGIC
	logic b1on1, b1on2;
	logic [4:0] b1on1offset, b1on2offset;
	assign b1on1 = (((b1X > xOne)? b1X - xOne:xOne - b1X) < 12'd330) & (((b1Y > yOne)? b1Y - yOne:yOne - b1Y) < 12'd250);
	assign b1on2 = (((b1X > xTwo)? b1X - xTwo:xTwo - b1X) < 12'd330) & (((b1Y > yTwo)? b1Y - yTwo:yTwo - b1Y) < 12'd250);
	assign b1on1offset = (DrYplus - ((b1Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b1X - 12'd2) - (xOne - 12'd320)));
	assign b1on2offset = (DrYplus - ((b1Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b1X - 12'd2) - (xTwo - 12'd320)));
	logic b2on1, b2on2;
	logic [4:0] b2on1offset, b2on2offset;
	assign b2on1 = (((b2X > xOne)? b2X - xOne:xOne - b2X) < 12'd330) & (((b2Y > yOne)? b2Y - yOne:yOne - b2Y) < 12'd250);
	assign b2on2 = (((b2X > xTwo)? b2X - xTwo:xTwo - b2X) < 12'd330) & (((b2Y > yTwo)? b2Y - yTwo:yTwo - b2Y) < 12'd250);
	assign b2on1offset = (DrYplus - ((b2Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b2X - 12'd2) - (xOne - 12'd320)));
	assign b2on2offset = (DrYplus - ((b2Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b2X - 12'd2) - (xTwo - 12'd320)));
	logic b3on1, b3on2;
	logic [4:0] b3on1offset, b3on2offset;
	assign b3on1 = (((b3X > xOne)? b3X - xOne:xOne - b3X) < 12'd330) & (((b3Y > yOne)? b3Y - yOne:yOne - b3Y) < 12'd250);
	assign b3on2 = (((b3X > xTwo)? b3X - xTwo:xTwo - b3X) < 12'd330) & (((b3Y > yTwo)? b3Y - yTwo:yTwo - b3Y) < 12'd250);
	assign b3on1offset = (DrYplus - ((b3Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b3X - 12'd2) - (xOne - 12'd320)));
	assign b3on2offset = (DrYplus - ((b3Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b3X - 12'd2) - (xTwo - 12'd320)));
	logic b4on1, b4on2;
	logic [4:0] b4on1offset, b4on2offset;
	assign b4on1 = (((b4X > xOne)? b4X - xOne:xOne - b4X) < 12'd330) & (((b4Y > yOne)? b4Y - yOne:yOne - b4Y) < 12'd250);
	assign b4on2 = (((b4X > xTwo)? b4X - xTwo:xTwo - b4X) < 12'd330) & (((b4Y > yTwo)? b4Y - yTwo:yTwo - b4Y) < 12'd250);
	assign b4on1offset = (DrYplus - ((b4Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b4X - 12'd2) - (xOne - 12'd320)));
	assign b4on2offset = (DrYplus - ((b4Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b4X - 12'd2) - (xTwo - 12'd320)));
	logic b5on1, b5on2;
	logic [4:0] b5on1offset, b5on2offset;
	assign b5on1 = (((b5X > xOne)? b5X - xOne:xOne - b5X) < 12'd330) & (((b5Y > yOne)? b5Y - yOne:yOne - b5Y) < 12'd250);
	assign b5on2 = (((b5X > xTwo)? b5X - xTwo:xTwo - b5X) < 12'd330) & (((b5Y > yTwo)? b5Y - yTwo:yTwo - b5Y) < 12'd250);
	assign b5on1offset = (DrYplus - ((b5Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b5X - 12'd2) - (xOne - 12'd320)));
	assign b5on2offset = (DrYplus - ((b5Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b5X - 12'd2) - (xTwo - 12'd320)));
	logic b6on1, b6on2;
	logic [4:0] b6on1offset, b6on2offset;
	assign b6on1 = (((b6X > xOne)? b6X - xOne:xOne - b6X) < 12'd330) & (((b6Y > yOne)? b6Y - yOne:yOne - b6Y) < 12'd250);
	assign b6on2 = (((b6X > xTwo)? b6X - xTwo:xTwo - b6X) < 12'd330) & (((b6Y > yTwo)? b6Y - yTwo:yTwo - b6Y) < 12'd250);
	assign b6on1offset = (DrYplus - ((b6Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b6X - 12'd2) - (xOne - 12'd320)));
	assign b6on2offset = (DrYplus - ((b6Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b6X - 12'd2) - (xTwo - 12'd320)));
	logic b7on1, b7on2;
	logic [4:0] b7on1offset, b7on2offset;
	assign b7on1 = (((b7X > xOne)? b7X - xOne:xOne - b7X) < 12'd330) & (((b7Y > yOne)? b7Y - yOne:yOne - b7Y) < 12'd250);
	assign b7on2 = (((b7X > xTwo)? b7X - xTwo:xTwo - b7X) < 12'd330) & (((b7Y > yTwo)? b7Y - yTwo:yTwo - b7Y) < 12'd250);
	assign b7on1offset = (DrYplus - ((b7Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b7X - 12'd2) - (xOne - 12'd320)));
	assign b7on2offset = (DrYplus - ((b7Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b7X - 12'd2) - (xTwo - 12'd320)));
	logic b8on1, b8on2;
	logic [4:0] b8on1offset, b8on2offset;
	assign b8on1 = (((b8X > xOne)? b8X - xOne:xOne - b8X) < 12'd330) & (((b8Y > yOne)? b8Y - yOne:yOne - b8Y) < 12'd250);
	assign b8on2 = (((b8X > xTwo)? b8X - xTwo:xTwo - b8X) < 12'd330) & (((b8Y > yTwo)? b8Y - yTwo:yTwo - b8Y) < 12'd250);
	assign b8on1offset = (DrYplus - ((b8Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b8X - 12'd2) - (xOne - 12'd320)));
	assign b8on2offset = (DrYplus - ((b8Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b8X - 12'd2) - (xTwo - 12'd320)));
	logic b9on1, b9on2;
	logic [4:0] b9on1offset, b9on2offset;
	assign b9on1 = (((b9X > xOne)? b9X - xOne:xOne - b9X) < 12'd330) & (((b9Y > yOne)? b9Y - yOne:yOne - b9Y) < 12'd250);
	assign b9on2 = (((b9X > xTwo)? b9X - xTwo:xTwo - b9X) < 12'd330) & (((b9Y > yTwo)? b9Y - yTwo:yTwo - b9Y) < 12'd250);
	assign b9on1offset = (DrYplus - ((b9Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b9X - 12'd2) - (xOne - 12'd320)));
	assign b9on2offset = (DrYplus - ((b9Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b9X - 12'd2) - (xTwo - 12'd320)));
	logic b10on1, b10on2;
	logic [4:0] b10on1offset, b10on2offset;
	assign b10on1 = (((b10X > xOne)? b10X - xOne:xOne - b10X) < 12'd330) & (((b10Y > yOne)? b10Y - yOne:yOne - b10Y) < 12'd250);
	assign b10on2 = (((b10X > xTwo)? b10X - xTwo:xTwo - b10X) < 12'd330) & (((b10Y > yTwo)? b10Y - yTwo:yTwo - b10Y) < 12'd250);
	assign b10on1offset = (DrYplus - ((b10Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b10X - 12'd2) - (xOne - 12'd320)));
	assign b10on2offset = (DrYplus - ((b10Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b10X - 12'd2) - (xTwo - 12'd320)));
	logic b11on1, b11on2;
	logic [4:0] b11on1offset, b11on2offset;
	assign b11on1 = (((b11X > xOne)? b11X - xOne:xOne - b11X) < 12'd330) & (((b11Y > yOne)? b11Y - yOne:yOne - b11Y) < 12'd250);
	assign b11on2 = (((b11X > xTwo)? b11X - xTwo:xTwo - b11X) < 12'd330) & (((b11Y > yTwo)? b11Y - yTwo:yTwo - b11Y) < 12'd250);
	assign b11on1offset = (DrYplus - ((b11Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b11X - 12'd2) - (xOne - 12'd320)));
	assign b11on2offset = (DrYplus - ((b11Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b11X - 12'd2) - (xTwo - 12'd320)));
	logic b12on1, b12on2;
	logic [4:0] b12on1offset, b12on2offset;
	assign b12on1 = (((b12X > xOne)? b12X - xOne:xOne - b12X) < 12'd330) & (((b12Y > yOne)? b12Y - yOne:yOne - b12Y) < 12'd250);
	assign b12on2 = (((b12X > xTwo)? b12X - xTwo:xTwo - b12X) < 12'd330) & (((b12Y > yTwo)? b12Y - yTwo:yTwo - b12Y) < 12'd250);
	assign b12on1offset = (DrYplus - ((b12Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b12X - 12'd2) - (xOne - 12'd320)));
	assign b12on2offset = (DrYplus - ((b12Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b12X - 12'd2) - (xTwo - 12'd320)));
	logic b13on1, b13on2;
	logic [4:0] b13on1offset, b13on2offset;
	assign b13on1 = (((b13X > xOne)? b13X - xOne:xOne - b13X) < 12'd330) & (((b13Y > yOne)? b13Y - yOne:yOne - b13Y) < 12'd250);
	assign b13on2 = (((b13X > xTwo)? b13X - xTwo:xTwo - b13X) < 12'd330) & (((b13Y > yTwo)? b13Y - yTwo:yTwo - b13Y) < 12'd250);
	assign b13on1offset = (DrYplus - ((b13Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b13X - 12'd2) - (xOne - 12'd320)));
	assign b13on2offset = (DrYplus - ((b13Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b13X - 12'd2) - (xTwo - 12'd320)));
	logic b14on1, b14on2;
	logic [4:0] b14on1offset, b14on2offset;
	assign b14on1 = (((b14X > xOne)? b14X - xOne:xOne - b14X) < 12'd330) & (((b14Y > yOne)? b14Y - yOne:yOne - b14Y) < 12'd250);
	assign b14on2 = (((b14X > xTwo)? b14X - xTwo:xTwo - b14X) < 12'd330) & (((b14Y > yTwo)? b14Y - yTwo:yTwo - b14Y) < 12'd250);
	assign b14on1offset = (DrYplus - ((b14Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b14X - 12'd2) - (xOne - 12'd320)));
	assign b14on2offset = (DrYplus - ((b14Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b14X - 12'd2) - (xTwo - 12'd320)));
	logic b15on1, b15on2;
	logic [4:0] b15on1offset, b15on2offset;
	assign b15on1 = (((b15X > xOne)? b15X - xOne:xOne - b15X) < 12'd330) & (((b15Y > yOne)? b15Y - yOne:yOne - b15Y) < 12'd250);
	assign b15on2 = (((b15X > xTwo)? b15X - xTwo:xTwo - b15X) < 12'd330) & (((b15Y > yTwo)? b15Y - yTwo:yTwo - b15Y) < 12'd250);
	assign b15on1offset = (DrYplus - ((b15Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b15X - 12'd2) - (xOne - 12'd320)));
	assign b15on2offset = (DrYplus - ((b15Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b15X - 12'd2) - (xTwo - 12'd320)));
	logic b16on1, b16on2;
	logic [4:0] b16on1offset, b16on2offset;
	assign b16on1 = (((b16X > xOne)? b16X - xOne:xOne - b16X) < 12'd330) & (((b16Y > yOne)? b16Y - yOne:yOne - b16Y) < 12'd250);
	assign b16on2 = (((b16X > xTwo)? b16X - xTwo:xTwo - b16X) < 12'd330) & (((b16Y > yTwo)? b16Y - yTwo:yTwo - b16Y) < 12'd250);
	assign b16on1offset = (DrYplus - ((b16Y - 12'd2) - (yOne - 12'd240)))*12'd5 + (DrXplus - ((b16X - 12'd2) - (xOne - 12'd320)));
	assign b16on2offset = (DrYplus - ((b16Y - 12'd2) - (yTwo - 12'd240)))*12'd5 + (DrXplus - ((b16X - 12'd2) - (xTwo - 12'd320)));
	////


	//// OTHER PLAYER SPRITE LOGIC
	// Calculate pixel of other player
	assign onscreen = (((xTwo > xOne)? xTwo - xOne:xOne - xTwo) < 12'd360) & (((yTwo > yOne)? yTwo - yOne:yOne - yTwo) < 12'd280);
	// assign onscreen = (xOne + 320 > xTwo) & (xOne - 320 < xTwo) & (yOne + 240 > yTwo) & (yOne - 240 < yTwo);
	assign player2offset = (DrYplus - ((yTwo - 12'd37) - (yOne - 12'd240)))*12'd75 + (DrXplus - ((xTwo - 12'd37) - (xOne - 12'd320)));
	assign player1offset = (DrYplus - ((yOne - 12'd37) - (yTwo - 12'd240)))*12'd75 + (DrXplus - ((xOne - 12'd37) - (xTwo - 12'd320)));
	////


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


	//// START/END SCREEN LOGIC
	logic centerRegion;
	logic [16:0] screenOffset;
	assign centerRegion = (DrXplus >= 10'd161) & (DrXplus <= 10'd480) & (DrYplus >= 10'd121) & (DrYplus <= 10'd360);
	assign screenOffset = (DrYplus - 10'd121)*10'd320 + (DrXplus - 10'd161);


endmodule

