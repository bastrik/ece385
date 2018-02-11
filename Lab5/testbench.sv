module testbench();

timeunit 10ns;	// Half clock cycle at 50 MHz
			// This is the amount of time represented by #1 
timeprecision 1ns;

// These signals are internal because the processor will be 
// instantiated as a submodule in testbench.
logic Clk = 0;
logic Reset, ClearA_LoadB, Run;
logic [7:0] S;
logic X;
logic [7:0] Aval, Bval;
logic [6:0] AhexL, AhexU, BhexL, BhexU; 
				
// Instantiating the DUT
// Make sure the module and signal names match with those in your design
lab5_multiply_toplevel multiplier(.*);	

// Toggle the clock
// #1 means wait for a delay of 1 timeunit
always begin : CLOCK_GENERATION
#1 Clk = ~Clk;
end

initial begin: CLOCK_INITIALIZATION
    Clk = 0;
end 

// Testing begins here
// The initial block is not synthesizable
// Everything happens sequentially inside an initial block
// as in a software program
initial begin: TEST_VECTORS
Reset = 1;	
ClearA_LoadB = 1;
Run = 1;
S = 8'b11111111;

#2 Reset = 0;
#2 Reset = 1;

#2 ClearA_LoadB = 0;
#2 ClearA_LoadB = 1;

#2 S = 8'b11111111;

#2 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

#50 Run = 0;
#2 Run = 1;

end

endmodule
