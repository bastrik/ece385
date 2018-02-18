// Determines branch-enable signal

module NZP (input logic [15:0] bus,
	    input logic [2:0] instruction,
            output logic BEN);

// Internal connections
logic N, Z, P;

always_comb
begin
	// Determine NZP
	if (bus == 16'h0000)
	begin
		N = 1'b0;
		Z = 1'b1;
		P = 1'b0;
	end

	else
	begin
		case (bus[15])
			1'b0:
			begin
				N = 1'b0;
				Z = 1'b0;
				P = 1'b1;
			end
			1'b1:
			begin
				N = 1'b1;
				Z = 1'b0;
				P = 1'b0;
			end
	       endcase
       end

       // Default
       BEN = 1'b0;

       // Compare to IR[11:9]
       if (((N == 1'b1) && (instruction[2] == 1'b1)) || ((Z == 1'b1) && (instruction[1] == 1'b1)) || ((P == 1'b1) && (instruction[0] == 1'b1)))
       begin
	       BEN = 1'b1;
       end
end

endmodule
