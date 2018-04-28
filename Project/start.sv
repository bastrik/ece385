// On-chip memory 

module start(input logic clk,
			 input logic d,
			 input logic [15:0] write_address, read_address,
			 input we,
			 output logic q);

	logic mem [48400];

	initial
	begin
		$readmemb("start.txt", mem);
	end

	always_ff @ (posedge clk)
	begin
		if (we)
			mem[write_address] <= d;
		q <= mem[read_address];
	end

endmodule