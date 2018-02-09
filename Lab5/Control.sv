//Two-always example for state machine

module control 
(
    input	logic		Clk(,
    input	logic       Reset,
    input	logic       Execute,
    input   logic       M,          // the least significant bit of regB
    output  logic       ClearA_LoadB;
    output	logic       Shift,
    output  logic       Ld_A,
    output  logic       Ld_B,
    output	logic       Add,
    output	logic       Sub 
);
    // how many states do we need?
    enum logic [3:0] {A, B, C, D, E, F, G, H, I, J}   curr_state, next_state; 

    always_ff @ (posedge Clk)  
    begin
        if (!Reset)
            curr_state <= A;
        else 
            curr_state <= next_state;
    end

    // TODO:
    always_comb
    begin
        
		next_state  = curr_state;
        unique case (curr_state) 

            A :    if (!Execute)        // hold state
                       next_state = B;
            B :    next_state = C;
            C :    next_state = D;
            D :    next_state = E;
            E :    next_state = F;
            F :    next_state = G;
            G :    next_state = H;
            H :    next_state = I;
            I :    next_state = J;
            J :    if (Execute) 
                       next_state = A;
							  
        endcase
   
		// Assign outputs based on ‘state’
        // TODO: write to regB when ClearA_LoadB pressed
        case (curr_state) 
	   	   A: 
             begin
                Ld_A = LoadA;
                Ld_B = LoadB;
                Shift_En = 1'b0;
             end
           H:       // the 7th shift, determine if we want to do 2's complement
             begin
                if (M)
                    Sub = 1b'1;
             end
	   	   J: 
             begin
                Ld_A = 1'b0;
                Ld_B = 1'b0;
                Shift_En = 1'b0;
             end
	   	   default:  //default case
            begin 
                Sub = 1b'0;
                if (M)// if M is 1, we want to add S to regA
                begin  
                    Add = 1b'1;
                    Ld_A = 1b'1;
                end
                else begin
                    Add = 1b'0;
                    Ld_A = 1b'0;
                end
            end
        endcase
    end

endmodule