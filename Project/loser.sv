// On-chip memory 

module loser(input logic clk,
			 input logic d,
			 input logic [14:0] write_address, read_address,
			 input we,
			 output logic q);

	logic mem [20000];

	initial
	begin
		$readmemb("loser.txt", mem);
	end

	always_ff @ (posedge clk)
	begin
		if (we)
			mem[write_address] <= d;
		q <= mem[read_address];
	end

endmodule