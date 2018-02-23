// Register with logic to calculate branch-enable

module reg_BEN (input logic Clk, Reset, Load,
		input logic [2:0] IR_NZP, CC, 
		output logic BEN);

    logic BEN_out;

    always_ff @ (posedge Clk)
    begin
	 	 if (Reset) //notice this is a synchronous reset, which is recommended on the FPGA
			  BEN <= 1'b0;
		 else if (Load)
			  BEN <= BEN_out;
    end

    always_comb
    begin
		// Default value
		BEN_out = 1'b0;
		// Check if any of the NZP codes match the condition codes
		if ((IR_NZP[2] & CC[2]) | (IR_NZP[1] & CC[1]) | (IR_NZP[0] & CC[0]))
			BEN_out = 1'b1;
		end

endmodule
