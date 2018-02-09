module ripple_adder
(
	input   logic[7:0]     A,
	input   logic[7:0]     B,
	output  logic[7:0]     Sum,
	output  logic           CO
);

	// Internal carry bits in the 8-bit adder
	logic c1;

	// Four 4-bit adders
	adder4 FB1 (.A (A[3:0]), .B (B[3:0]), .C_in (1'b0), .S (Sum[3:0]), .C_out (c1));
	adder4 FB2 (.A (A[7:4]), .B (B[7:4]), .C_in (c1), .S (Sum[7:4]), .C_out (CO));

     
endmodule
