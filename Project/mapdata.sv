// On-chip memory 

module mapdata(input logic clk,
			 input logic [1:0] d,
			 input logic [12:0] write_address, read_address,
			 input we,
			 output logic [1:0] q);

	logic [1:0] mem [7500];

	initial
	begin
		$readmemh("mapinfo.txt", mem);
	end

	always_ff @ (posedge clk)
	begin
		if (we)
			mem[write_address] <= d;
		q <= mem[read_address];
	end

endmodule