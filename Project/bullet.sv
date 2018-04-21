// On-chip memory 

module bullet(input logic Clk, frame_clk, 
			 input logic set, // bullet is fired
			 input logic [11:0] startX, startY, // initial position
			 input logic [3:0] nspeedX, pspeedX,
			 input logic [3:0] nspeedY, pspeedY, // bullet speed
			 input logic [11:0] xOne, yOne, // player one location
			 input logic [11:0] xTwo, yTwo, // player two location
			 output logic [11:0] posX, posY, // bullet position
			 output logic active, // is bullet active?
			 output logic h1, h2 // were player one or player two hit?
			 );

	// Detect the rising edge of frame_clk
	logic frame_clk_delayed, frame_clk_rising_edge;
	always_ff @ (posedge Clk)
	begin
		frame_clk_delayed <= frame_clk;
		frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
	end

	// Keep track of how many frames bullet was active
	logic [6:0] counter;

	// Bullet speed
	logic [3:0] _nspeedX, _pspeedX, _nspeedY, _pspeedY;

	// Is bullet active?
	logic _active = 1'b0;

	assign active = _active;

	always_ff @ (posedge Clk)
	begin
		if (set)
		begin
			posX <= startX;
			posY <= startY;
			_nspeedX <= nspeedX;
			_pspeedX <= pspeedX;
			_nspeedY <= nspeedY;
			_pspeedY <= pspeedY;
			_active <= 1'b1;
			counter <= 7'd0;
		end
		else if (frame_clk_rising_edge & _active)
		begin
			posX <= posX - _nspeedX + _pspeedX;
			posY <= posY - _nspeedY + _pspeedY;
			counter <= counter + 1'b1;
			if (counter > 7'd100)
				_active <= 1'b0;
			if (h1 | h2)
				_active <= 1'b0;
		end
	end

	int dX1, dY1, dX2, dY2, radius;
	assign dX1 = posX - xOne;
	assign dY1 = posY - yOne;
	assign dX2 = posX - xTwo;
	assign dY2 = posY - yTwo;
	assign radius = 18;

	always_comb
	begin
		h1 = 1'b0;
		h2 = 1'b0;
		if ((dX1*dX1 + dY1*dY1) <= (radius*radius))
			h1 = 1'b1;
		if ((dX2*dX2 + dY2*dY2) <= (radius*radius))
			h2 = 1'b1;
	end

endmodule