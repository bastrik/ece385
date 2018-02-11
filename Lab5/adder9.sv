// 9-bit adder using nine 1-bit full adders
// Takes as inputs two 8-bit signals and sign-extends them
// Returns an 8-bit sum, with the 9th bit in the sum becoming X

module adder9
(
	input logic[7:0] A, B,
	input logic C_in,
	output logic[7:0] S,
	output logic X, C_out
);

	// Internal carry bits in the 9-bit adder
	logic c1, c2, c3, c4, c5, c6, c7, c8;

	// Nine 1-bit adders
	full_adder FA0 (.a (A[0]), .b (B[0]), .c_in (C_in), .s (S[0]), .c_out (c1));
	full_adder FA1 (.a (A[1]), .b (B[1]), .c_in (c1), .s (S[1]), .c_out (c2));
	full_adder FA2 (.a (A[2]), .b (B[2]), .c_in (c2), .s (S[2]), .c_out (c3));
	full_adder FA3 (.a (A[3]), .b (B[3]), .c_in (c3), .s (S[3]), .c_out (c4));
	full_adder FA4 (.a (A[4]), .b (B[4]), .c_in (c4), .s (S[4]), .c_out (c5));
	full_adder FA5 (.a (A[5]), .b (B[5]), .c_in (c5), .s (S[5]), .c_out (c6));
	full_adder FA6 (.a (A[6]), .b (B[6]), .c_in (c6), .s (S[6]), .c_out (c7));
	full_adder FA7 (.a (A[7]), .b (B[7]), .c_in (c7), .s (S[7]), .c_out (c8));
	full_adder FA8 (.a (A[7]), .b (B[7]), .c_in (c8), .s (X), .c_out (C_out));
     
endmodule
