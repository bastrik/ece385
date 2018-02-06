module carry_select_adder4
(
    input   logic[3:0]	A,
    input   logic[3:0]	B,
    input	logic		C_in
    output  logic[3:0] 	S,
    output  logic		C_out
);

	logic select, S0, S1, C0, C1;
	adder4 A1 (.A (A), .B (B), .C_in (1'b0), .S (S0), .C_out (C0));
	adder4 A2 (.A (A), .B (B), .C_in (1'b0), .S (S1), .C_out (C1));

	always_comb
	begin
		if (C_in)
			S = S1;
			C_out = C1;
		else
			S = S0;
			C_out = C0;
	end
endmodule	
