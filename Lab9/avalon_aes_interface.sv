/************************************************************************
Avalon-MM Interface for AES Decryption IP Core

Dong Kai Wang, Fall 2017

For use with ECE 385 Experiment 9
University of Illinois ECE Department

Register Map:

 0-3 : 4x 32bit AES Key
 4-7 : 4x 32bit AES Encrypted Message
 8-11: 4x 32bit AES Decrypted Message
   12: Not Used
	13: Not Used
   14: 32bit Start Register
   15: 32bit Done Register

************************************************************************/

module avalon_aes_interface (
	// Avalon Clock Input
	input logic CLK,
	
	// Avalon Reset Input
	input logic RESET,
	
	// Avalon-MM Slave Signals
	input  logic AVL_READ,					// Avalon-MM Read
	input  logic AVL_WRITE,					// Avalon-MM Write
	input  logic AVL_CS,						// Avalon-MM Chip Select
	input  logic [3:0] AVL_BYTE_EN,		// Avalon-MM Byte Enable
	input  logic [3:0] AVL_ADDR,			// Avalon-MM Address
	input  logic [31:0] AVL_WRITEDATA,	// Avalon-MM Write Data
	output logic [31:0] AVL_READDATA,	// Avalon-MM Read Data
	
	// Exported Conduit
	output logic [31:0] EXPORT_DATA		// Exported Conduit Signal to LEDs
);

// 16 32-bit registers
logic [31:0] regs[16];
logic [1407:0] RoundKeyArr;
logic [127:0] SubByteOut;
logic [127:0] shiftRowsOut;
logic [127:0] addRoundKeyOut;
logic [127:0] Intermediate_in;
logic [127:0] Intermediate_out;
logic [31:0] Curr_Column_in;
logic [31:0] Curr_Column_out;
logic [1:0]   muxSelect;

always_ff @ (posedge CLK)
begin
	if (RESET) // Synchronous reset
	begin
		for (int i = 0; i < 16; i++) 
		begin
			regs[i] <= 32'h00000000;
		end
	end
	else if (AVL_CS && AVL_WRITE) // Write operation
	begin
		// Check which byte to write
		if (AVL_BYTE_EN[3])
			regs[AVL_ADDR][31:24] <= AVL_WRITEDATA[31:24];
		if (AVL_BYTE_EN[2])
			regs[AVL_ADDR][23:16] <= AVL_WRITEDATA[23:16];
		if (AVL_BYTE_EN[1])
			regs[AVL_ADDR][15:8] <= AVL_WRITEDATA[15:8];
		if (AVL_BYTE_EN[0])
			regs[AVL_ADDR][7:0] <= AVL_WRITEDATA[7:0];
	end
end

AES State_Machine (
	.CLK,
	.RESET,
	.AES_START(regs[14][31]),
	.AES_DONE(regs[15][31]),
	.AES_KEY({regs[0][31:0], regs[1][31:0], regs[2][31:0], regs[3][31:0]}),
	.AES_MSG_ENC({regs[4][31:0], regs[5][31:0], regs[6][31:0], regs[7][31:0]}),
	.AES_MSG_DEC({regs[8][31:0], regs[9][31:0], regs[10][31:0], regs[11][31:0]}),
	.Curr_Column_in(Curr_Column_in),
	.Curr_Column_out(Curr_Column_out),
	.Intermediate_in,
	.Intermediate_out,
	.RoundKeyArr(RoundKeyArr),
	.RoundKey,
	.muxSelect(muxSelect)
	);
InvMixColumns mixColumns (
	.in(Curr_Column_out),
	.out(Curr_Column_in)
	);
InvShiftRows shiftRows (
	.data_in(Intermediate_out),
	.data_out(shiftRowsOut)
	);
KeyExpansion keyExpansion (
	.clk(CLK),
	.Cipherkey(AES_KEY),
	.KeySchedule(RoundKeyArr)
	);
SubBytes SubByte1 (
	.clk(CLK),
	.in(Intermediate_out[7:0]),
	.out(SubByteOut[7:0])
	);
SubBytes SubByte2 (
	.clk(CLK),
	.in(Intermediate_out[15:8]),
	.out(SubByteOut[15:8])
	);
SubBytes SubByte3 (
	.clk,
	.in(Intermediate_out[23:16]),
	.out(SubByteOut[23:16])
	);
SubBytes SubByte4 (
	.clk,
	.in(Intermediate_out[31:24]),
	.out(SubByteOut[31:24])
	);
SubBytes SubByte5 (
	.clk,
	.in(Intermediate_out[39:32]),
	.out(SubByteOut[39:32])
	);
SubBytes SubByte6 (
	.clk,
	.in(Intermediate_out[47:40]),
	.out(SubByteOut[47:40])
	);
SubBytes SubByte7 (
	.clk,
	.in(Intermediate_out[55:48]),
	.out(SubByteOut[55:48])
	);
SubBytes SubByte8 (
	.clk,
	.in(Intermediate_out[63:56]),
	.out(SubByteOut[63:56])
	);
SubBytes SubByte9 (
	.clk,
	.in(Intermediate_out[71:64]),
	.out(SubByteOut[71:64])
	);
SubBytes SubByteA (
	.clk,
	.in(Intermediate_out[79:72]),
	.out(SubByteOut[79:72])
	);
SubBytes SubByteB (
	.clk,
	.in(Intermediate_out[87:80]),
	.out(SubByteOut[87:80])
	);
SubBytes SubByteC (
	.clk,
	.in(Intermediate_out[95:88]),
	.out(SubByteOut[95:88])
	);
SubBytes SubByteD (
	.clk,
	.in(Intermediate_out[103:96]),
	.out(SubByteOut[103:96])
	);
SubBytes SubByteE (
	.clk,
	.in(Intermediate_out[111:104]),
	.out(SubByteOut[111:104])
	);
SubBytes SubByteF (
	.clk,
	.in(Intermediate_out[119:112]),
	.out(SubByteOut[119:112])
	);
SubBytes SubByte0 (
	.clk,
	.in(Intermediate_out[127:120]),
	.out(SubByteOut[127:120])
	);
AddRoundKey addRoundKey (
	.state(Intermediate_out),
	.RoundKey,
	.newState(addRoundKeyOut)
	);

always_comb
begin
	case (muxSelect)
		2'b00:		// roundkey
			Intermediate_in = addRoundKeyOut;
		2'b01:
			Intermediate_in = shiftRowsOut;
		2'b10:
			Intermediate_in = SubByteOut;
		default : ;
	endcase
end
// Read operation
assign AVL_READDATA = (AVL_CS && AVL_READ)? regs[AVL_ADDR]:32'h00000000;

// Done signal
assign EXPORT_DATA = {regs[0][31:16], regs[3][15:0]};

endmodule
