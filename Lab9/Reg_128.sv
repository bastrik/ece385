module reg_128 (input  logic Clk, Reset, Load,
		input  logic [31:0] Column,
		input  logic [2:0] Select,
	      	input  logic [127:0]  D,
	      	output logic [127:0]  Data_Out);

    always_ff @ (posedge Clk)
    begin
	 	 if (Reset) //notice this is a synchronous reset, which is recommended on the FPGA
			  Data_Out <= 128'h0;
		 else if (Load && Select[2])
		 begin
			 Data_Out <= D;
		 end
		 else if (Load && ~Select[2])
		 begin
			 case (Select[1:0])
				 2'b00:
					 Data_Out[127:96] <= Column;
				 2'b01:
					 Data_Out[95:64] <= Column;
				 2'b10:
					 Data_Out[63:32] <= Column;
				 2'b11:
					 Data_Out[31:0] <= Column;
			 endcase
		 end
    end
	
endmodule
