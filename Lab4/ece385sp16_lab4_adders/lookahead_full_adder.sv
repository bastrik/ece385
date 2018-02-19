// 1-bit full adder with propagate and generate bits

module lookahead_full_adder
(
	input logic a, b, c_in,
	output s, p, g
);

	assign s = a^b^c_in;
	assign p = a^b;
	assign g = a&b;
     
endmodule
