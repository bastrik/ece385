// 8 x 16 register file

module reg_file (input logic Clk, Reset, LD_REG,
		 input logic [2:0] DRMUX_OUT, SR1MUX_OUT, SR2,
                 input logic [15:0]  D_in,
                 output logic [15:0]  SR1_OUT, SR2_OUT);

logic[15:0] data[8];
	
always_ff @ (posedge Clk)
begin
	if (Reset) //notice this is a synchronous reset, which is recommended on the FPGA
	begin
		for (int i = 0; i < 8; i++) 
		begin
			data[i] = 16'h0000;
		end
	end
	else if (LD_REG)
		data[DRMUX_OUT] = D_in;
end

assign SR1_OUT = data[SR1MUX_OUT];
assign SR2_OUT = data[SR2];

endmodule
