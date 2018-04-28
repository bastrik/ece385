// On-chip memory 

module loser(input logic clk,
			 input logic [23:0] d,
			 input logic [16:0] write_address, read_address,
			 input we,
			 output logic [23:0] q);

	logic [23:0] mem [76800];

	initial
	begin
		$readmemh("loser.txt", mem);
	end

	always_ff @ (posedge clk)
	begin
		if (we)
			mem[write_address] <= d;
		q <= mem[read_address];
	end

endmodule