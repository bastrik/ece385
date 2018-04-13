module PS2reg (input logic Clk, Reset,
		input logic [7:0] keycode, 
		input logic press,
		output logic [31:0] keycode_out);
		
	logic Load1, Load2, Load3, Load4;
	logic [7:0] keycode1, keycode2, keycode3, keycode4;
	
	always_ff @ (posedge Clk)
    begin
	 	if (Reset) ; //notice this is a synchronous reset, which is recommended on the FPGA
			  // keycode_out <= 32'h00000000;
	end
	
	always_comb
	begin
	Load1 = 1'b0;
	Load2 = 1'b0;
	Load3 = 1'b0;
	Load4 = 1'b0;
	Reset1 = 1'b0;
	Reset2 = 1'b0;
	Reset3 = 1'b0;
	Reset4 = 1'b0;
		if (press)
		begin
			if (keycode == keycode1 | keycode == keycode2 | keycode == keycode3 | keycode == keycode4) ;
			  // do nothing
			else
			begin
				if (keycode1 == 8'h00)
					Load1 = 1'b1;
				else if (keycode2 == 8'h00)
					Load2 = 1'b1;
				else if (keycode3 == 8'h00)
					Load3 = 1'b1;
				else if (keycode4 == 8'h00)
					Load4 = 1'b1;	
			end					
		end
		else if (!press)
		begin
			if (keycode == keycode1 | keycode == keycode2 | keycode == keycode3 | keycode == keycode4)
			begin
				if (keycode1 == keycode)
					Reset1 = 1'b1;
				else if (keycode2 == keycode)
					Reset2 = 1'b1;
				else if (keycode3 == keycode)
					Reset3 = 1'b1;
				else if (keycode4 == keycode)
					Reset4 = 1'b1;	
			end
		end
    end
	
	assign keycode_out = {keycode4, keycode3, keycode2, keycode1};
	
    // Hold each of the four keycodes
	reg_8 keyreg1(.Clk(Clk), .Reset(Reset1), .Load(Load1), .D(keycode), .Data_Out(keycode1));
	reg_8 keyreg2(.Clk(Clk), .Reset(Reset2), .Load(Load2), .D(keycode), .Data_Out(keycode2));
    reg_8 keyreg3(.Clk(Clk), .Reset(Reset3), .Load(Load3), .D(keycode), .Data_Out(keycode3));
    reg_8 keyreg4(.Clk(Clk), .Reset(Reset4), .Load(Load4), .D(keycode), .Data_Out(keycode4));	

endmodule
