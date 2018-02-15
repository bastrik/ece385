// The datapath module should handle 

module datapath(input logic Clk, Reset, Run,
				input logic LD_MAR, LD_MDR, LD_IR, LD_PC,
				input logic [15:0] MAR, MDR, IR, PC, Data,
				output MAR_OUT, MDR_OUT, IR_OUT, PC_OUT;
);

Reg_16 regMAR(		// MAR <- PC
		.Clk
		.Reset
		.Load(LD_MAR)
		.D_in(PC)
		.D_out(MAR_OUT)
		);
Reg_16 regMDR(		// MDR <- M(MAR)
		.Clk
		.Reset
		.Load(LD_MDR)
		.D_in(Data)
		.D_out(MDR_OUT)
		);
Reg_16 regIR(		// IR <- MDR
		.Clk
		.Reset
		.Load(LD_IR)
		.D_in(MDR)
		.D_out(IR_OUT)
		);
Reg_16 regPC(		// PC <- PC + 1
		.Clk
		.Reset
		.Load(LD_PC)
		.D_in(PC + 1)
		.D_out(PC_OUT)
		);

endmodule