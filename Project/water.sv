// On-chip memory 

module water(input logic clk,
			 input logic [15:0] d,
			 input logic [9:0] write_address, read_address,
			 input we,
			 output logic [15:0] q);

	logic [15:0] mem [1024];

	initial
	begin
		$readmemh("water.txt", mem);
	end

	always_ff @ (posedge clk)
	begin
		if (we)
			mem[write_address] <= d;
		q <= mem[read_address];
	end

endmodule