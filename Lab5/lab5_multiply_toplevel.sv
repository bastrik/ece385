/*  Date Created: Fri Feb 9 2018.
 *  
 *  ECE 385 Lab 5 (multiplier) template code.  This is the top level entity which
 *  connects an multiplier circuit to LEDs and buttons on the device.  It also
 *  declares some registers on the inputs and outputs of the adder to help
 *  generate timing information (fmax) and multiplex the DE115's 16 switches
 *  onto the inputs.
 *
 *	This is taken from Lab 4 template code. With necessary modifications for lab 5
 

/* Module declaration.  Everything within the parentheses()
 * is a port between this module and the outside world */
 
module lab5_multiply_toplevel
(
    input   logic           Clk,        // 50MHz clock (PIN_Y2)
    input   logic           Reset,      // push-button 0, active LOW (PIN_M23)
    input   logic           ClearA_LoadB,      // push-button 2 (PIN_N21)
    input   logic           Run,        // push-button 3 (PIN_R24)
    input   logic[7:0]      S,          // slider switches SW0-SW7
    
    // all outputs are registered
    output  logic           X,          // Carry-out.  Goes to the green LED to the left of the hex displays.
    output  logic[6:0]      AhexL,      // Hex drivers display both inputs to the adder.
    output  logic[6:0]      AhexU,
    output  logic[6:0]      BhexL,
    output  logic[6:0]      BhexU,
    output  logic[7:0]      Aval,       // DEBUG
    output  logic[7:0]      Bval        // DEBUG
);

    /* Declare Internal Registers */
    logic[7:0]     A;  // use this as an input to regA
    logic[7:0]     B;  // use this as an input to regB
    
    /* Declare Internal Wires
     * Wheather an internal logic signal becomes a register or wire depends
     * on if it is written inside an always_ff or always_comb block respectivly */
    logic[6:0]      AhexL_comb;
    logic[6:0]      AhexU_comb;
    logic[6:0]      BhexL_comb;
    logic[6:0]      BhexU_comb;
    
    /* Behavior of registers A, B, _X */
    always_ff @(posedge Clk) begin
        
        if (!Reset) begin
            // if reset is pressed, reset everything to 0
            A <= 16'h0000;
            B <= 16'h0000;
            X <= 1'b0;
        end 
        else if (!ClearA_LoadB) begin
            // If ClearA_LoadB is pressed, reset A and X, and copy switches to register B
            A <= 16'h0000;
            X <= 1'b0;
            B <= S;
        end 
                
    end
    
    /* Decoders for HEX drivers and output registers
     * Note that the hex drivers are calculated one cycle after Sum so
     * that they have minimal interfere with timing (fmax) analysis.
     * The human eye can't see this one-cycle latency so it's OK. */
    always_ff @(posedge Clk) begin
        
        AhexL <= AhexL_comb;
        AhexU <= AhexU_comb;
        BhexL <= BhexL_comb;
        BhexU <= BhexU_comb;
        
    end
    
    /* Module instantiation
	  * You can think of the lines below as instantiating objects (analogy to C++).
     * The things with names like Ahex0_inst, Ahex1_inst... are like a objects
     * The thing called HexDriver is like a class
     * Each time you instantate an "object", you consume physical hardware on the FPGA
     * in the same way that you'd place a 74-series hex driver chip on your protoboard */

     // TODO: WORK IN PROGRESS!
	  
	control     control_unit (
                        .Clk(Clk),
                        .Reset,
                        .Execute(Run),
                        .M,
                        .Shift,
                        .Add,
                        .Sub );
    register_unit    reg_unit (
                        .Clk(Clk),
                        .Reset,
                        .Ld_A, //note these are inferred assignments, because of the existence a logic variable of the same name
                        .Ld_B,
                        .Shift_En,
                        .D(Din_S),
                        .A_In(newA),
                        .B_In(newB),
                        .A_out(opA),
                        .B_out(opB),
                        .A(A),
                        .B(B) );
    ripple_adder8   adder (
                        .A,
                        .B,
                        .Sum,
                        .CO(X) );

    
    HexDriver AhexL_inst
    (
        .In0(A[3:0]),   // This connects the 4 least significant bits of 
                        // register A to the input of a hex driver named Ahex0_inst
        .Out0(AhexL_comb)
    );
    
    HexDriver AhexU_inst
    (
        .In0(A[7:4]),
        .Out0(AhexU_comb)
    );
    
    HexDriver BhexL_inst
    (
        .In0(B[3:0]),
        .Out0(BhexL_comb)
    );
    
    HexDriver BhexU_inst
    (
        .In0(B[7:4]),
        .Out0(BhexU_comb)
    );
    
endmodule
