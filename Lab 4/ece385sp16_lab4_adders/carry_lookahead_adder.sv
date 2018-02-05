module carry_lookahead_adder
(
	input   logic[15:0]     A,
	input   logic[15:0]     B,
	output  logic[15:0]     Sum,
	output  logic           CO
);

	/* TODO
	*
	* Insert code here to implement a CLA adder.
	* Your code should be completly combinational (don't use always_ff or always_latch).
	* Feel free to create sub-modules or other files. */

	// Group propagate and generate bits
	logic P0, P4, P8, P12;
	logic G0, G4, G8, G12;

	// Group carry-in bits
	logic C4, C8, C12;

	// Four 4-bit carry-lookahead adders
	lookahead_adder4 LA1 (.A (A[3:0]), .B (B[3:0]), .C_in (1'b0), .S (Sum[3:0]), .P (P0), .G (G0));
	lookahead_adder4 LA2 (.A (A[7:4]), .B (B[7:4]), .C_in (C4), .S (Sum[7:4]), .P (P4), .G (G4));
	lookahead_adder4 LA3 (.A (A[11:8]), .B (B[11:8]), .C_in (C8), .S (Sum[11:8]), .P (P8), .G (G8));
	lookahead_adder4 LA4 (.A (A[15:12]), .B (B[15:12]), .C_in (C12), .S (Sum[15:12]), .P (P12), .G (G12));

	// Hierarchical carry-lookahead unit
	lookahead_unit LU (.C0 (1'b0), .P0 (P0), .P4 (P4), .P8 (P8), .P12 (P12), .G0 (G0), .G4 (G4), .G8 (G8), .G12 (G12), .C4 (C4), .C8 (C8), .C12 (C12), .C16 (CO));
     
endmodule
