// 1-bit register

module reg_1 (input logic Clk, Reset, Load,
              input logic D_in,
              output logic D_out);

    always_ff @ (posedge Clk)
    begin
	 	 if (Reset) //notice this is a synchronous reset, which is recommended on the FPGA
			  D_out <= 1'b0;
		 else if (Load)
			  D_out <= D_in;
    end

endmodule
