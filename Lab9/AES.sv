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
	output logic [31:0]		Curr_Column_out,
	input logic [127:0] 	Intermediate_in,
	output logic [127:0] 	Intermediate_out,
	input  logic [1407:0]	RoundKeyArr,
	output logic [127:0] 	RoundKey,
	output logic [1:0]	 	muxSelect,
	output logic LD_REG,
	output logic [2:0] Select
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

	logic [3:0] count;
	logic [3:0] slowASS;
	logic count_reset, slowASS_reset;
	logic count_plus, slowASS_plus;

	always_ff @ (posedge CLK)
	begin
		if (RESET) 
			State <= Halted;
		else 
			State <= Next_state;
		if (count_reset)
			count <= 4'b0000;
		else if (count_plus)
			count <= count + 4'b0001;
		if (slowASS_reset)
			slowASS <= 4'b0000;
		else if (slowASS_plus)
			slowASS <= slowASS + 4'b0001;
	end

	always_comb
	begin 
		// Default next state is staying at current state
		Next_state = State;

		// Default values
		AES_DONE = 1'b0;
		AES_MSG_DEC = Intermediate_in;
		Curr_Column_out = 32'h0;
		Intermediate_out = Intermediate_in;
		RoundKey = 128'h0;
		muxSelect = 2'b00;
		LD_REG = 1'b0;
		Select = 3'b000;
		count_reset = 1'b0;
		count_plus = 1'b0;
		slowASS_reset = 1'b0;
		slowASS_plus = 1'b0;

		unique case (State)
			Halted : 
				if (AES_START) 
					Next_state = keyExpansion;
			keyExpansion :
				if (slowASS == 4'b1011)
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
			default : ;
		endcase

		case (State)
			Halted : 
			begin
				count_reset = 1'b1;
				slowASS_reset = 1'b1;
			end
			keyExpansion :
				slowASS_plus = 1;
			addRoundKey_0 :
			begin
				muxSelect = 2'b00;
				Intermediate_out = AES_MSG_ENC;
				RoundKey = RoundKeyArr[127:0];
				LD_REG = 1'b1;
				Select = 3'b100;
			end
			invShiftRows_loop :
			begin
				muxSelect = 2'b01;
				LD_REG = 1'b1;
				Select = 3'b100;
			end
			invSubBytes_loop : 
			begin
				muxSelect = 2'b10;
				LD_REG = 1'b1;
				Select = 3'b100;
			end 
			addRoundKey_loop : 
			begin
				muxSelect = 2'b00;
				case (count)
					4'b0000:
						RoundKey = RoundKeyArr[255:128];
					4'b0001:
						RoundKey = RoundKeyArr[383:256];
					4'b0010:
						RoundKey = RoundKeyArr[511:384];
					4'b0011:
						RoundKey = RoundKeyArr[639:512];
					4'b0100:
						RoundKey = RoundKeyArr[767:640];
					4'b0101:
						RoundKey = RoundKeyArr[895:768];
					4'b0110:
						RoundKey = RoundKeyArr[1023:896];
					4'b0111:
						RoundKey = RoundKeyArr[1151:1024];
					4'b1000:
						RoundKey = RoundKeyArr[1279:1152];
					default: ;
				endcase
				LD_REG = 1'b1;
				Select = 3'b100;
			end
			invMixColumns_loop1 :
			begin
				Curr_Column_out = Intermediate_in[127:96];
				LD_REG = 1'b1;
				Select = 3'b000;

			end
			invMixColumns_loop2 :
			begin
				Curr_Column_out = Intermediate_in[95:64];
				LD_REG = 1'b1;
				Select = 3'b001;
			end
			invMixColumns_loop3 :
			begin
				Curr_Column_out = Intermediate_in[63:32];
				LD_REG = 1'b1;
				Select = 3'b010;
			end
			invMixColumns_loop4 : 
			begin
				Curr_Column_out = Intermediate_in[31:0];
				LD_REG = 1'b1;
				Select = 3'b011;
			end
			invMixColumns_loop5 : 
			begin
				count_plus = 1'b1;
			end
			invShiftRows : 
			begin
				muxSelect = 2'b01;
				LD_REG = 1'b1;
				Select = 3'b100;
			end
			invSubBytes : 
			begin
				muxSelect = 2'b10;
				LD_REG = 1'b1;
				Select = 3'b100;
			end 
			addRoundKey_1 :
			begin
				muxSelect = 2'b00;
				RoundKey = RoundKeyArr[1407:1280];	
				LD_REG = 1'b1;
				Select = 3'b100;
			end
			Done :
			begin
				AES_MSG_DEC = Intermediate_in;
				AES_DONE = 1'b1;
			end
			default : ;
		endcase
	end


endmodule
