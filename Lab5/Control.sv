//Two-always example for state machine

module control 
(
    input logic Clk,
    input logic Reset,
    input logic ClearA_LoadB,
    input logic Run,
    input logic M,  // The least significant bit of register B
    output logic ClrX, LdX, ShX,  // Clear, Load, and Shift controls for register X
    output logic ClrA, LdA, ShA,
    output logic ClrB, LdB, ShB,
    output logic Sub 
);

    enum logic [4:0] {ST, A0, A1, BA, BS, BH, CA, CS, CH, DA, DS, DH, EA, ES, EH, FA, FS, FH, GA, GS, GH, HA, HS, HH, IA, IS, IH} curr_state, next_state; 

    // Reset switch
    always_ff @ (posedge Clk)  
    begin
        if (Reset)
            curr_state <= ST;
        else 
            curr_state <= next_state;
    end

    // Next-state logic
    always_comb
    begin
        
	next_state  = curr_state;

        unique case (curr_state) 

	    // Starting state
            ST:    if (Run)   
		       if (M)
                           next_state = A1;
		       else
			   next_state = A0;
	    // Preparation states
	    A1:    next_state = BA;
	    A0:    next_state = BS;
	    // 'A' denotes arithmetic (either ADD or SUBTRACT)
	    BA:    next_state = BS;
	    // 'S' denotes SHIFT
	    BS:    next_state = BH;
	    // 'H' denotes HOLD
	    BH:    if (M)
		       next_state = CA;
	           else
		       next_state = CS;
	    CA:    next_state = CS;
	    CS:    next_state = CH;
	    CH:    if (M)
		       next_state = DA;
	           else
		       next_state = DS;
	    DA:    next_state = DS;
	    DS:    next_state = DH;
	    DH:    if (M)
		       next_state = EA;
	           else
		       next_state = ES;
	    EA:    next_state = ES;
	    ES:    next_state = EH;
	    EH:    if (M)
		       next_state = FA;
	           else
		       next_state = FS;
	    FA:    next_state = FS;
	    FS:    next_state = FH;
	    FH:    if (M)
		       next_state = GA;
	           else
		       next_state = GS;
	    GA:    next_state = GS;
	    GS:    next_state = GH;
	    GH:    if (M)
		       next_state = HA;
	           else
		       next_state = HS;
	    HA:    next_state = HS;
	    HS:    next_state = HH;
	    HH:    if (M)
		       next_state = IA;
	           else
		       next_state = IS;
	    IA:    next_state = IS;
	    IS:    next_state = IH;
	    IH:    if (~Run)
		       next_state = ST;
 
        endcase
   
	// Assign outputs based on state
        case (curr_state) 
	    ST: 
                begin
		    // Clear A, X, and B
		    if (Reset)
		 	begin
			ClrX = 1'b1;
		        LdX = 1'b0;
			ShX = 1'b0;
		        ClrA = 1'b1;
			LdA = 1'b0;
			ShA = 1'b0;
			ClrB = 1'b1;
			LdB = 1'b0;
			ShB = 1'b0;
			Sub = 1'b0;
		    	end
		    // Clear A and X and Load B
		    else if (ClearA_LoadB)
		 	begin
			ClrX = 1'b1;
		        LdX = 1'b0;
			ShX = 1'b0;
		        ClrA = 1'b1;
			LdA = 1'b0;
			ShA = 1'b0;
			ClrB = 1'b0;
			LdB = 1'b1;
			ShB = 1'b0;
			Sub = 1'b0;
		    	end
		    // Do nothing
		    else
		    	begin
			ClrX = 1'b0;
		        LdX = 1'b0;
			ShX = 1'b0;
		        ClrA = 1'b0;
			LdA = 1'b0;
			ShA = 1'b0;
			ClrB = 1'b0;
			LdB = 1'b0;
			ShB = 1'b0;
			Sub = 1'b0;
		    	end
                end
	    A0, A1: 
		// Clear A and X
                begin
		    ClrX = 1'b1;
		    LdX = 1'b0;
		    ShX = 1'b0;
		    ClrA = 1'b1;
		    LdA = 1'b0;
		    ShA = 1'b0;
		    ClrB = 1'b0;
		    LdB = 1'b0;
		    ShB = 1'b0;
		    Sub = 1'b0;
                end
	    BA, CA, DA, EA, FA, GA, HA:
		// ADD
                begin
		    ClrX = 1'b0;
		    LdX = 1'b1;
		    ShX = 1'b0;
		    ClrA = 1'b0;
		    LdA = 1'b1;
		    ShA = 1'b0;
		    ClrB = 1'b0;
		    LdB = 1'b0;
		    ShB = 1'b0;
		    Sub = 1'b0;
                end
	    IA:
		// SUBTRACT
                begin
		    ClrX = 1'b0;
		    LdX = 1'b1;
		    ShX = 1'b0;
		    ClrA = 1'b0;
		    LdA = 1'b1;
		    ShA = 1'b0;
		    ClrB = 1'b0;
		    LdB = 1'b0;
		    ShB = 1'b0;
		    Sub = 1'b1;
                end
	    BS, CS, DS, ES, FS, GS, HS, IS:
		// SHIFT
                begin
		    ClrX = 1'b0;
		    LdX = 1'b0;
		    ShX = 1'b1;
		    ClrA = 1'b0;
		    LdA = 1'b0;
		    ShA = 1'b1;
		    ClrB = 1'b0;
		    LdB = 1'b0;
		    ShB = 1'b1;
		    Sub = 1'b0;
                end

	    BH, CH, DH, EH, FH, GH, HH, IH:
		// SHIFT
                begin
		    ClrX = 1'b0;
		    LdX = 1'b0;
		    ShX = 1'b0;
		    ClrA = 1'b0;
		    LdA = 1'b0;
		    ShA = 1'b0;
		    ClrB = 1'b0;
		    LdB = 1'b0;
		    ShB = 1'b0;
		    Sub = 1'b0;
                end

        endcase

    end

endmodule
