// Calculates and holds condition codes

module NZP (input logic Clk, Reset, Load, 
	    input logic [15:0] bus,
	    output logic [2:0] NZP);

always_ff @ (posedge Clk)
begin
	// Determine NZP
	if (bus == 16'h0000)
	begin
		NZP = 3'b010;
	end

	else
	begin
		case (bus[15])
			1'b0:
			begin
				NZP = 3'b001;
			end
			1'b1:
			begin
				NZP = 3'b100;
			end
	       endcase
       end
end

endmodule
