// 4-bit adder using four 1-bit full adders with group propagate and generate bits

module lookahead_adder4
(
	input logic[3:0] A, B,
	input logic C_in,
	output logic[3:0] S,
	output logic P, G
);

	// Internal carry-in bits in the 4-bit adder
	logic c1, c2, c3;

	// Propagate and generate bits
	logic p0, p1, p2, p3;
	logic g0, g1, g2, g3;

	// Four 1-bit adders
	lookahead_full_adder FA1 (.a (A[0]), .b (B[0]), .c_in (C_in), .s (S[0]), .p (p0), .g (g0));
	lookahead_full_adder FA2 (.a (A[1]), .b (B[1]), .c_in (c1), .s (S[1]), .p (p1), .g (g1));
	lookahead_full_adder FA3 (.a (A[2]), .b (B[2]), .c_in (c2), .s (S[2]), .p (p2), .g (g2));
	lookahead_full_adder FA4 (.a (A[3]), .b (B[3]), .c_in (c3), .s (S[3]), .p (p3), .g (g3));

	// Calculation of the carry-in bits
	assign c1 = (C_in&p0)|g0;
	assign c2 = (C_in&p0&p1)|(g0&p1)|g1;
	assign c3 = (C_in&p0&p1&p2)|(g0&p1&p2)|(g1&p2)|g2;

	// Group propagate and generate bits
	assign P = p0&p1&p2&p3;
	assign G = g3|(g2&p3)|(g1&p3&p2)|(g0&p3&p2&p1);
     
endmodule
