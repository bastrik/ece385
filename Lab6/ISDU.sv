//------------------------------------------------------------------------------
// Company:          UIUC ECE Dept.
// Engineer:         Stephen Kempf
//
// Create Date:    17:44:03 10/08/06
// Design Name:    ECE 385 Lab 6 Given Code - Incomplete ISDU
// Module Name:    ISDU - Behavioral
//
// Comments:
//    Revised 03-22-2007
//    Spring 2007 Distribution
//    Revised 07-26-2013
//    Spring 2015 Distribution
//    Revised 02-13-2017
//    Spring 2017 Distribution
//------------------------------------------------------------------------------


module ISDU (   input logic         Clk, 
									Reset,
									Run,
									Continue,
									
				input logic[3:0]    Opcode, 
				input logic         IR_5,
				input logic         IR_11,
				input logic         BEN,
				  
				output logic        LD_MAR,
									LD_MDR,
									LD_IR,
									LD_BEN,
									LD_CC,
									LD_REG,
									LD_PC,
									LD_LED, // for PAUSE instruction
									
				output logic        GatePC,
									GateMDR,
									GateALU,
									GateMARMUX,
									
				output logic [1:0]  PCMUX_SELECT,
				output logic        DRMUX_SELECT,
									SR1MUX_SELECT,
									SR2MUX_SELECT,
									ADDR1MUX_SELECT,
				output logic [1:0]  ADDR2MUX_SELECT,
									ALUK,
				  
				output logic        Mem_CE,
									Mem_UB,
									Mem_LB,
									Mem_OE_sync,
									Mem_WE_sync
				);

	enum logic [5:0] 	{Halted, 
						PauseIR1, 
						PauseIR2, 
						S_18, 
						S_33_1, 
						S_33_2, 
						S_33_3,
						S_35, 
						S_32, 
						S_01,
						S_01_1,
						S_05,
						S_05_1,
						S_09,
						S_09_1,
						S_06_0,
						S_06_1,
						S_25_0,
						S_25_1,
						S_25_2,
						S_27,
						S_07_0,
						S_07_1,
						S_23,
						S_16_0,
						S_16_1,
						S_16_2,						
						S_00,
						S_22,
						S_22_1,
						S_12,
						S_12_1,
						S_04,
						S_04_1,
						S_21,
						S_21_1}   State, Next_state;   // Internal state logic

	// Declare asynchronous internal memory control signals
	logic Mem_OE, Mem_WE;

	// Synchronize critical asynchronous outputs to memory
	sync output_sync[1:0] (Clk, {Mem_OE, Mem_WE}, {Mem_OE_sync, Mem_WE_sync});

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
		
		// Default control signal values
		LD_MAR = 1'b0;
		LD_MDR = 1'b0;
		LD_IR = 1'b0;
		LD_BEN = 1'b0;
		LD_CC = 1'b0;
		LD_REG = 1'b0;
		LD_PC = 1'b0;
		LD_LED = 1'b0;
		 
		GatePC = 1'b0;
		GateMDR = 1'b0;
		GateALU = 1'b0;
		GateMARMUX = 1'b0;
		 
		LD_BEN = 1'b0;
		ALUK = 2'b00;
		 
		// Default behavior is PC = PC + 1
		PCMUX_SELECT = 2'b00;
		DRMUX_SELECT = 1'b0;
		SR1MUX_SELECT = 1'b0;
		SR2MUX_SELECT = 1'b0;
		ADDR1MUX_SELECT = 1'b0;
		ADDR2MUX_SELECT = 2'b00;
		 
		Mem_OE = 1'b1;
		Mem_WE = 1'b1;
	
		// Assign next state
		unique case (State)
			Halted : 
				if (Run) 
					Next_state = S_18;                      
			S_18 : 
				Next_state = S_33_1;
			// Any states involving SRAM require more than one clock cycles.
			// The exact number will be discussed in lecture.
			S_33_1 : 
				Next_state = S_33_2;
			S_33_2 : 
				Next_state = S_33_3;
			S_33_3 :
				Next_state = S_35;
			S_35 : 
				Next_state = S_32;
			// PauseIR1 and PauseIR2 are only for Week 1 such that TAs can see 
			// the values in IR.
			PauseIR1 : 
				if (~Continue) 
					Next_state = PauseIR1;
				else 
					Next_state = PauseIR2;
			PauseIR2 : 
				if (Continue) 
					Next_state = PauseIR2;
				else 
					Next_state = S_18;
			S_32 : 
				case (Opcode)
					4'b0001 : 	// ADD & ADDi
						Next_state = S_01;
					4'b0101 : 	// AND & ANDi
						Next_state = S_05;
					4'b1001 : 	// NOT
						Next_state = S_09;
					4'b0000 : 	// BR nzp
						Next_state = S_00;
					4'b1100 : 	// JMP
						Next_state = S_12;
					4'b0100 : 	// JSR
						Next_state = S_04;
					4'b0110 : 	// LDR
						Next_state = S_06_0;
					4'b0111 : 	// STR
						Next_state = S_07_0;
					4'b1101 : 	// PAUSE
						Next_state = PauseIR1;					

					default : 
						Next_state = S_18;
				endcase

			S_01 :
				Next_state = S_01_1;
			S_05 :
				Next_state = S_05_1;
			S_06_0 :
				Next_state = S_06_1;
			S_06_1 : 
				Next_state = S_25_0;
			// reading from SRAM takes 3 cycles to guarantee data retrival
			S_25_0 : 
				Next_state = S_25_1;
			S_25_1 : 
				Next_state = S_25_2;
			S_25_2 :
				Next_state = S_27;

			S_09 :
				Next_state = S_09_1;

			S_07_0 : 
				Next_state = S_07_1;
			S_07_1 : 
				Next_state = S_23;
			S_23 : 
				Next_state = S_16_0;
			// writing to SRAM takes 3 cycles, remember to have correct addr
			S_16_0 : 
				Next_state = S_16_1;
			S_16_1 : 
				Next_state = S_16_2;
			S_16_2 :
				Next_state = S_18;

			S_00 : 
				case (BEN)
					1'b1 :
						Next_state = S_22;
					default :
						Next_state = S_18;
				endcase
			S_22 :
				Next_state = S_22_1;
			S_12 :
				Next_state = S_12_1;

			S_21 :
				Next_state = S_21_1;
			S_04 :
				Next_state = S_04_1;
			S_04_1 : 
				Next_state = S_21;

			default : 
				Next_state = S_18;

		endcase
		
		// Assign control signals based on current state
		case (State)
			Halted: ;
			S_18 : 					// ld pc, ld mar
				begin 
					GatePC = 1'b1;
					LD_MAR = 1'b1;
					PCMUX_SELECT = 2'b10;
					LD_PC = 1'b1;
				end
			S_33_1, S_33_2 : 		// mdr <- m
				begin
					Mem_OE = 1'b0;
				end
			S_33_3 : 
				begin 
					Mem_OE = 1'b0;
					LD_MDR = 1'b1;
				end
			S_35 : 					// ir <- mdr
				begin 
					GateMDR = 1'b1;
					LD_IR = 1'b1;
				end
			PauseIR1: 
				LD_LED = 1'b1;
			PauseIR2: ;
				// LD_LED = 1'b1;
			S_32 : 
				LD_BEN = 1'b1;
			S_01 : 					// add, addi
				case (IR_5)
					1'b0:
					begin 
						SR1MUX_SELECT = 1'b1;
						SR2MUX_SELECT = 1'b1;
						ALUK = 2'b00;
						GateALU = 1'b1;												
					end
					1'b1:
					begin
						SR1MUX_SELECT = 1'b1;
						SR2MUX_SELECT = 1'b0;
						ALUK = 2'b00;
						GateALU = 1'b1;
					end
				endcase
			S_01_1 : 
			begin
				DRMUX_SELECT = 1'b1;
				LD_REG = 1'b1;
				LD_CC = 1'b1;
			end

			S_05 : 					// and, andi
				case (IR_5)
					1'b0:
					begin 
						SR1MUX_SELECT = 1'b1;
						SR2MUX_SELECT = 1'b1;
						ALUK = 2'b01;
						GateALU = 1'b1;												
					end
					1'b1:
					begin
						SR1MUX_SELECT = 1'b1;
						SR2MUX_SELECT = 1'b0;
						ALUK = 2'b01;
						GateALU = 1'b1;
					end
				endcase
			S_05_1 : 
			begin
				DRMUX_SELECT = 1'b1;
				LD_REG = 1'b1;
				LD_CC = 1'b1;
			end

			S_09 :					// NOT
			begin
				ALUK = 2'b10;
				SR1MUX_SELECT = 1'b1;
				GateALU = 1'b1;
			end
			S_09_1 :
			begin
				LD_REG = 1'b1;
				DRMUX_SELECT = 1'b1;
				LD_CC = 1'b1;
			end

			//JSR
			S_04 : 
			begin
				DRMUX_SELECT = 1'b1;
				GatePC = 1'b1;
			end
			S_04_1 :
				LD_REG = 1'b1;
			S_21 : 
			begin
				ADDR2MUX_SELECT = 2'b00;
				ADDR1MUX_SELECT = 1'b1;
				PCMUX_SELECT = 2'b01;
			end
			S_21_1 : 
				LD_PC = 1'b1;


			// LDR
			S_06_0 : 	
			begin				
				SR1MUX_SELECT = 1'b1;
				ADDR1MUX_SELECT = 1'b0;
				ADDR2MUX_SELECT = 2'b10;
				GateMARMUX = 1'b1;
			end
			S_06_1 : 
				LD_MAR = 1'b1;
			S_25_0, S_25_1 : 		
				begin
					Mem_OE = 1'b0;
				end
			S_25_2 : 
				begin 
					Mem_OE = 1'b0;
					LD_MDR = 1'b1;
				end
			S_27 : 
				begin
					GateMDR = 1'b1;
					DRMUX_SELECT = 1'b1;
					LD_REG = 1'b1;
					LD_CC = 1'b1;
				end

			// STR
			S_07_0 : 	
			begin				
				SR1MUX_SELECT = 1'b1;
				ADDR1MUX_SELECT = 1'b0;
				ADDR2MUX_SELECT = 2'b10;
				GateMARMUX = 1'b1;
			end
			S_07_1 : 
				LD_MAR = 1'b1;
			S_23 : 
				begin
					SR1MUX_SELECT = 1'b0;
					LD_MDR = 1'b1;
				end
			S_16_0, S_16_1, S_16_2 : 		
				begin
					Mem_WE = 1'b0;
				end

			// BR
			S_00 : ;
			S_22 : 
				begin
					ADDR1MUX_SELECT = 1'b1;
					ADDR2MUX_SELECT = 2'b01;
					PCMUX_SELECT = 2'b01;
				end
			S_22_1 :
				begin
					LD_PC = 1'b1;
				end

			// JMP
			S_12 : 
				begin
					SR1MUX_SELECT = 1'b1;
					ADDR1MUX_SELECT = 1'b0;
					PCMUX_SELECT = 2'b01;
				end
			S_12_1 :
				LD_PC = 1'b1;


			default : ;
		endcase
	end 

	 // These should always be active
	assign Mem_CE = 1'b0;
	assign Mem_UB = 1'b0;
	assign Mem_LB = 1'b0;
	
endmodule
