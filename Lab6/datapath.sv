// SLC-3 datapath 

module datapath(input logic Clk, Reset,
		input logic LD_MAR, LD_MDR, LD_IR, LD_BEN, LD_CC, LD_REG, LD_PC, LD_LED,
		input logic GatePC, GateMDR, GateALU, GateMARMUX,
		input logic ADDR1MUX_SELECT, DRMUX_SELECT, SR1MUX_SELECT, SR2MUX_SELECT, 
		input logic MIO_EN,  
		input logic [1:0] PCMUX_SELECT, ADDR2MUX_SELECT, ALUK, 
		input logic [15:0] MDR_In,
		output logic BEN_OUT, 
		output logic [15:0] MAR_OUT, MDR_OUT, IR_OUT, PC_OUT,
		output logic [11:0] LED
);

// Global data bus
logic [15:0] bus;

// Internal connections
logic[15:0] ADDER_OUT, ADDR1MUX_OUT, ADDR2MUX_OUT, PCMUX_OUT, ALU_OUT;
logic[15:0] SR1_OUT, SR2_OUT, SR2MUX_OUT, MDRMUX_OUT;
logic[3:0] BUSMUX_SELECT;
logic[2:0] DRMUX_OUT, SR1MUX_OUT;
logic BEN;

// Replaces 4 internal tri-state buffers
// Determines which signal is set by the bus
always_comb
begin
	BUSMUX_SELECT = {GatePC, GateMDR, GateALU, GateMARMUX};
	
	case (BUSMUX_SELECT)
		4'b1000:
			bus = PC_OUT;
		4'b0100:
			bus = MDR_OUT;
		4'b0010:
			bus = ALU_OUT;
		4'b0001:
			bus = ADDER_OUT;
		// Error message for debugging
		default:
			bus = 16'hBAAD;
	endcase	
end

// PCMUX
MUX4to1 PCMUX(
		.in00(bus),
		.in01(ADDER_OUT),
		.in10(PC_OUT + 16'h0001),
		.in11({16{1'bX}}),
		.select(PCMUX_SELECT),
		.out(PCMUX_OUT)
		);

// PC
reg_16 regPC(		
		.Clk(Clk), 
		.Reset(Reset), 
		.Load(LD_PC), 
		.D_in(PCMUX_OUT), 
		.D_out(PC_OUT)
		);

// Add ADDR1MUX and ADDR2MUX
assign ADDER_OUT = ADDR1MUX_OUT + ADDR2MUX_OUT;

// ADDR1MUX
MUX2to1 ADDR1MUX(
		.in0(SR1_OUT), 
		.in1(PC_OUT), 
		.select(ADDR1MUX_SELECT), 
		.out(ADDR1MUX_OUT)
		);

// ADDR2MUX
MUX4to1 ADDR2MUX(
		.in00({{5{IR_OUT[10]}}, IR_OUT[10:0]}),
		.in01({{7{IR_OUT[8]}}, IR_OUT[8:0]}),
		.in10({{10{IR_OUT[5]}}, IR_OUT[5:0]}),
		.in11(16'h0000),
		.select(ADDR2MUX_SELECT),
		.out(ADDR2MUX_OUT)
		);

// DRMUX
MUX2to1 #(3) DRMUX(
		.in0(3'b111), 
		.in1(IR_OUT[11:9]), 
		.select(DRMUX_SELECT),
		.out(DRMUX_OUT)
		);

// SR1MUX
MUX2to1 #(3) SR1MUX(
		.in0(IR_OUT[11:9]), 
		.in1(IR_OUT[8:6]), 
		.select(SR1MUX_SELECT),
		.out(SR1MUX_OUT)
		);

// SR2MUX
MUX2to1 SR2MUX(
		.in0({{11{IR_OUT[4]}}, IR_OUT[4:0]}), 
		.in1(SR2_OUT), 
		.select(SR2MUX_SELECT),
		.out(SR2MUX_OUT)
		);

// Register file
reg_file regFile(
		.Clk(Clk),
		.Reset(Reset),
		.LD_REG(LD_REG),
		.DRMUX_OUT(DRMUX_OUT),
		.SR1MUX_OUT(SR1MUX_OUT),
		.SR2(IR_OUT[2:0]),
		.D_in(bus),
		.SR1_OUT(SR1_OUT),
		.SR2_OUT(SR2_OUT)
		);

// ALU
ALU ALU1(
		.A(SR1_OUT), 
		.B(SR2MUX_OUT), 
		.select(ALUK), 
		.out(ALU_OUT)
		);

// Determine branch-enable
NZP NZP1(
		.bus(bus), 
		.instruction(IR_OUT[11:9]), 
		.BEN(BEN)
		);

// Branch-enable register
reg_1 regBEN(
		.Clk(Clk), 
		.Reset(Reset),
		.Load(LD_BEN), 
		.D_in(BEN), 
		.D_out(BEN_OUT)
		);

// MAR
reg_16 regMAR(		
		.Clk(Clk), 
		.Reset(Reset), 
		.Load(LD_MAR), 
		.D_in(bus), 
		.D_out(MAR_OUT) 
		);

// MDRMUX
MUX2to1 MDRMUX(
		.in0(bus), 
		.in1(MDR_In), 
		.select(MIO_EN),
		.out(MDRMUX_OUT)
		);

// MDR
reg_16 regMDR(		
		.Clk(Clk), 
		.Reset(Reset), 
		.Load(LD_MDR), 
		.D_in(MDRMUX_OUT), 
		.D_out(MDR_OUT)
		);

// IR
reg_16 regIR(		
		.Clk(Clk), 
		.Reset(Reset), 
		.Load(LD_IR), 
		.D_in(bus), 
		.D_out(IR_OUT)
		);

endmodule
