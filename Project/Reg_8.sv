module reg_8 (input  logic Clk, Reset, Load,
              input  logic [7:0]  D,
              output logic [7:0]  Data_Out);

    always_ff @ (posedge Clk)
    begin
	 	 if (Reset) //notice this is a synchronous reset, which is recommended on the FPGA
			  Data_Out <= 8'h00;
		 else if (Load)
			  Data_Out <= D; 
    end

endmodule
