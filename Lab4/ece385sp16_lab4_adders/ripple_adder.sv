module ripple_adder
(
	input   logic[15:0]     A,
	input   logic[15:0]     B,
	output  logic[15:0]     Sum,
	output  logic           CO
);

	/* TODO
	*
	* Insert code here to implement a ripple adder.
	* Your code should be completly combinational (don't use always_ff or always_latch).
	* Feel free to create sub-modules or other files. */

	// Internal carry bits in the 16-bit adder
	logic c1, c2, c3;

	// Four 4-bit adders
	adder4 FB1 (.A (A[3:0]), .B (B[3:0]), .C_in (1'b0), .S (Sum[3:0]), .C_out (c1));
	adder4 FB2 (.A (A[7:4]), .B (B[7:4]), .C_in (c1), .S (Sum[7:4]), .C_out (c2));
	adder4 FB3 (.A (A[11:8]), .B (B[11:8]), .C_in (c2), .S (Sum[11:8]), .C_out (c3));
	adder4 FB4 (.A (A[15:12]), .B (B[15:12]), .C_in (c3), .S (Sum[15:12]), .C_out (CO));

     
endmodule
