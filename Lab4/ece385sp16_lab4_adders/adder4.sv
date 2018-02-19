// 4-bit adder using four 1-bit full adders

module adder4
(
	input logic[3:0] A, B,
	input logic C_in,
	output logic[3:0] S,
	output logic C_out
);

	// Internal carry bits in the 4-bit adder
	logic c1, c2, c3;

	// Four 1-bit adders
	full_adder FA1 (.a (A[0]), .b (B[0]), .c_in (C_in), .s (S[0]), .c_out (c1));
	full_adder FA2 (.a (A[1]), .b (B[1]), .c_in (c1), .s (S[1]), .c_out (c2));
	full_adder FA3 (.a (A[2]), .b (B[2]), .c_in (c2), .s (S[2]), .c_out (c3));
	full_adder FA4 (.a (A[3]), .b (B[3]), .c_in (c3), .s (S[3]), .c_out (C_out));
     
endmodule
