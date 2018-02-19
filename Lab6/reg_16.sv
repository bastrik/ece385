// 16-bit register

module reg_16 (input logic Clk, Reset, Load,
               input logic [15:0]  D_in,
               output logic [15:0]  D_out);

    always_ff @ (posedge Clk)
    begin
	 	 if (Reset) //notice this is a synchronous reset, which is recommended on the FPGA
			  D_out <= 16'h0000;
		 else if (Load)
			  D_out <= D_in;
    end

endmodule
