// On-chip memory 

module winner(input logic clk,
			 input logic d,
			 input logic [14:0] write_address, read_address,
			 input we,
			 output logic q);

	logic mem [26000];

	initial
	begin
		$readmemb("winner.txt", mem);
	end

	always_ff @ (posedge clk)
	begin
		if (we)
			mem[write_address] <= d;
		q <= mem[read_address];
	end

endmodule