// Hierarchical lookahead unit that takes inputs from the 4-bit lookahead
// adders

module lookahead_unit
(
	input logic C0,
	input logic P0, P4, P8, P12,
	input logic G0, G4, G8, G12,
	output logic C4, C8, C12, C16
);

	assign C4 = G0|(C0&P0);	
	assign C8 = G4|(G0&P4)|(C0&P4&P0);
	assign C12 = G8|(G4&P8)|(G0&P8&P4)|(C0&P8&P4&P0);
	assign C16 = G12|(G8&P12)|(G4&P12&P8)|(G0&P12&P8&P4)|(C0&P12&P8&P4&P0);

endmodule
