// 1-bit shift register, designed to hold X in Lab 5
// Removed the Shift_Out bit, which is identical to Data_Out

module reg_1 (input  logic Clk, Reset, Shift_In, Load, Shift_En,
              input  logic D,
              output logic Data_Out);

    always_ff @ (posedge Clk)
    begin
	 	 if (Reset) //notice this is a synchronous reset, which is recommended on the FPGA
			  Data_Out <= 1'b0;
		 else if (Load)
			  Data_Out <= D;
		 else if (Shift_En)
			  Data_Out <= Shift_In; 
    end
	
endmodule
