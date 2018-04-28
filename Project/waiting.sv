// On-chip memory 

module waiting(input logic clk,
			 input logic d,
			 input logic [12:0] write_address, read_address,
			 input we,
			 output logic q);

	logic mem [7500];

	initial
	begin
		$readmemb("waiting.txt", mem);
	end

	always_ff @ (posedge clk)
	begin
		if (we)
			mem[write_address] <= d;
		q <= mem[read_address];
	end

endmodule