// On-chip memory 

module player2_2(input logic clk,
			 input logic [15:0] d,
			 input logic [12:0] write_address, read_address,
			 input we,
			 output logic [15:0] q);

	logic [15:0] mem [5625];

	initial
	begin
		$readmemh("player_e.txt", mem);
	end

	always_ff @ (posedge clk)
	begin
		if (we)
			mem[write_address] <= d;
		q <= mem[read_address];
	end

endmodule