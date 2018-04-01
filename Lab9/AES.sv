/************************************************************************
AES Decryption Core Logic

Dong Kai Wang, Fall 2017

For use with ECE 385 Experiment 9
University of Illinois ECE Department
************************************************************************/

module AES (
	input  logic 			CLK,
	input  logic 			RESET,
	input  logic 			AES_START,
	output logic 			AES_DONE,
	input  logic [127:0] 	AES_KEY,
	input  logic [127:0] 	AES_MSG_ENC,
	output logic [127:0] 	AES_MSG_DEC,
	input  logic [31:0] 	Curr_Column_in,
	output logic [31:0]		Curr_Column_out,
	output logic [127:0] 	Intermediate_in;
	output logic [127:0] 	Intermediate_out;
	input  logic [1407:0]	RoundKeyArr;
	output logic [127:0] 	RoundKey;
	output logic [1:0]	 	muxSelect;
);

enum logic [3:0] {
					Halted,
					keyExpansion,
					addRoundKey_0,
					invShiftRows_loop,
					invSubBytes_loop,
					addRoundKey_loop,
					invMixColumns_loop1,
					invMixColumns_loop2,
					invMixColumns_loop3,
					invMixColumns_loop4,
					invMixColumns_loop5,
					invShiftRows,
					invSubBytes,
					addRoundKey_1,
					Done
	} State, Next_state;

	logic [3:0] count, slowASS;
	logic [127:0] currRoundKey;

	assign count = 4'b0000;
	assign slowASS = 4'b0000;

	always_ff @ (posedge Clk)
	begin
		if (Reset) 
			State <= Halted;
		else 
			State <= Next_state;
	end

	always_comb
	begin 
		// Default next state is staying at current state
		Next_state = State;

		unique case (State)
			Halted : 
				if (AES_START) 
					Next_state = keyExpansion;
			keyExpansion :
				if (slowASS = 4'b1001)
					Next_state = addRoundKey_0;
				else
					Next_state = keyExpansion;
			addRoundKey_0 :
				Next_state = invShiftRows_loop;
			invShiftRows_loop :
				Next_state = invSubBytes_loop;
			invSubBytes_loop :
				Next_state = addRoundKey_loop;
			addRoundKey_loop :
				Next_state = invMixColumns_loop1;
			invMixColumns_loop1 :
				Next_state = invMixColumns_loop2;
			invMixColumns_loop2 :
				Next_state = invMixColumns_loop3;
			invMixColumns_loop3 :
				Next_state = invMixColumns_loop4;
			invMixColumns_loop4 :
				Next_state = invMixColumns_loop5;
			invMixColumns_loop5 :
				if (count == 4'b1000)
					Next_state = invShiftRows;
				else
					Next_state = invShiftRows_loop;
			invShiftRows :
				Next_state = invSubBytes;
			invSubBytes :
				Next_state = addRoundKey_1;
			addRoundKey_1 :
				Next_state = Done;
			Done : 
				if(AES_START)
					Next_state = Done;
				else
					Next_state = Halted;
		endcase

		case (State)
			keyExpansion :
				slowASS = slowASS + 1'b1;
			addRoundKey_0 :
			begin
				muxSelect = 2'b00;
				Intermediate_out = AES_MSG_ENC;
				currRoundKey = RoundKeyArr[1407:1280];	
			end
			invShiftRows_loop :
			begin
				muxSelect = 2'b01;
				Intermediate_out = Intermediate_in;
			end
			invSubBytes : 
			begin
				muxSelect = 2'b10;
				Intermediate_out = Intermediate_in;
			end 
			addRoundKey_loop : 
			begin
				muxSelect = 2'b00;
				currRoundKey = RoundKeyArr[(1279-128*count):(1152-128*count)];
			end
			invMixColumns_loop1 :
			begin
				Curr_Column_out = Intermediate_in[31:0];

			end
			invMixColumns_loop2 :
			begin
				Intermediate_out[31:0] = Curr_Column_in;
				Curr_Column_out = Intermediate_in[63:32];
			end
			invMixColumns_loop3 :
			begin
				Intermediate_out[63:32] = Curr_Column_in;
				Curr_Column_out = Intermediate_in[95:64];
			end
			invMixColumns_loop4 : 
			begin
				Intermediate_out[95:64] = Curr_Column_in;
				Curr_Column_out = Intermediate_in[127:96];
			end
			invMixColumns_loop5 : 
			begin
				Intermediate_out[127:96] = Curr_Column_in;
				count = count + 1'b1;
			end
			invShiftRows : 
			begin
				muxSelect = 2'b01;
			end
			invSubBytes : 
			begin
				muxSelect = 2'b10;
				Intermediate_out = Intermediate_in;
			end 
			addRoundKey_1 :
			begin
				muxSelect = 2'b00;
				currRoundKey = RoundKeyArr[127:0];
				Intermediate_out = Intermediate_in;
			Done :
			begin
				AES_MSG_DEC = Intermediate_in;
				AES_DONE = 1'b1;
			end
			default : ;
		endcase
	end


endmodule
