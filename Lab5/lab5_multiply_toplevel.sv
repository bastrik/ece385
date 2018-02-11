/*  Date Created: Fri Feb 9 2018.
 *  
 *  ECE 385 Lab 5 (multiplier) template code.  This is the top level entity which
 *  connects an multiplier circuit to LEDs and buttons on the device.  It also
 *  declares some registers on the inputs and outputs of the adder to help
 *  generate timing information (fmax) and multiplex the DE115's 16 switches
 *  onto the inputs.
 *
 *  This is adapted from Lab 4 template code with necessary modifications for lab 5
 

 * Module declaration.  Everything within the parentheses()
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
    output  logic[6:0]      AhexL,      // Hex drivers to display the results of the computation.
    output  logic[6:0]      AhexU,
    output  logic[6:0]      BhexL,
    output  logic[6:0]      BhexU,
    output  logic[7:0]      Aval,       // Outputs included for simulation.
    output  logic[7:0]      Bval        
);

    // Synchronized button inputs
    logic Reset_SH, ClearA_LoadB_SH, Run_SH;

    // Shift register I/O
    logic X_in;
    logic[7:0] A_in;

    // Control unit outputs
    logic ClrX, LdX, ShX, ClrA, LdA, ShA, ClrB, LdB, ShB, Sub;

    // Adder I/O
    logic[7:0] negS, fromS;

    // Instantiate shift registers A and B 
    reg_1 regX (.Clk(Clk), .Reset(ClrX), .Shift_In(X), .Load(LdX),
	    .Shift_En(ShX), .D(X_in), .Data_Out(X));
    reg_8 regA (.Clk(Clk), .Reset(ClrA), .Shift_In(X), .Load(LdA),
	    .Shift_En(ShA), .D(A_in), .Data_Out(Aval));
    reg_8 regB (.Clk(Clk), .Reset(ClrB), .Shift_In(Aval[0]), .Load(LdB),
	    .Shift_En(ShB), .D(S), .Data_Out(Bval));

    // Instantiate control unit
    control control_unit (.Clk(Clk), .Reset(Reset_SH), .ClearA_LoadB(ClearA_LoadB_SH),
	    .Run(Run_SH), .M(Bval[0]), .ClrX(ClrX), .LdX(LdX), .ShX(ShX), 
	    .ClrA(ClrA), .LdA(LdA), .ShA(ShA), .ClrB(ClrB), .LdB(LdB), .ShB(ShB), .Sub(Sub));

    // Instantiate 9-bit adder for addition and subtraction
    adder9 adder_add (.A(Aval), .B(S^{8{Sub}}), .C_in(Sub), .S(A_in), .X(X_in));

    /* Declare Internal Wires
     * Whether an internal logic signal becomes a register or wire depends
     * on if it is written inside an always_ff or always_comb block respectivly */
    logic[6:0]      AhexL_comb;
    logic[6:0]      AhexU_comb;
    logic[6:0]      BhexL_comb;
    logic[6:0]      BhexU_comb;
    
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
 
    HexDriver AhexL_inst
    (
        .In0(Aval[3:0]),   // This connects the 4 least significant bits of 
        .Out0(AhexL_comb)  // register A to the input of a hex driver named AhexL_comb
    );
    
    HexDriver AhexU_inst
    (
        .In0(Aval[7:4]),
        .Out0(AhexU_comb)
    );
    
    HexDriver BhexL_inst
    (
        .In0(Bval[3:0]),
        .Out0(BhexL_comb)
    );
    
    HexDriver BhexU_inst
    (
        .In0(Bval[7:4]),
        .Out0(BhexU_comb)
    );

    // Input synchronizers for asynchronous inputs from the buttons
    sync button_sync[2:0] (Clk, {~Reset, ~ClearA_LoadB, ~Run}, {Reset_SH, ClearA_LoadB_SH, Run_SH});
    
endmodule
