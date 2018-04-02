/************************************************************************
Add Round Key

Written by Justin Song on April 1 2018

For use with ECE 385 Experiment 9
University of Illinois ECE Department
************************************************************************/

// AddRoundKey
// Input : 128-bit state, 128-bit round key
// Output: XOR result
module AddRoundKey (
	input  logic [127:0] state,
	input  logic [127:0] RoundKey,
	output logic [127:0] newState
);


// Assign output by XORing the above results
assign newState = state ^ RoundKey;

endmodule

