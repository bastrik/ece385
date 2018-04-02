module testbench();

timeunit 10ns;	// Half clock cycle at 50 MHz
			// This is the amount of time represented by #1 
timeprecision 1ns;

// These signals are internal because the processor will be 
// instantiated as a submodule in testbench.
logic CLK;
logic RESET;
logic AVL_READ;
logic AVL_WRITE;
logic AVL_CS;
logic [3:0] AVL_BYTE_EN;
logic [3:0] AVL_ADDR;
logic [31:0] AVL_WRITEDATA;
logic [31:0] AVL_READDATA;
logic [31:0] EXPORT_DATA;

// Instantiating the DUT
// Make sure the module and signal names match with those in your design
avalon_aes_interface carcrash(.*);	

// Toggle the clock
// #1 means wait for a delay of 1 timeunit
always begin : CLOCK_GENERATION
#1 CLK = ~CLK;
end

initial begin: CLOCK_INITIALIZATION
    CLK = 0;
end 

// Testing begins here
// The initial block is not synthesizable
// Everything happens sequentially inside an initial block
// as in a software program
initial begin: TEST_VECTORS
RESET = 1'b1;
AVL_READ = 1'b0;
AVL_WRITE = 1'b0;
AVL_CS = 1'b0;
AVL_BYTE_EN = 4'b0000;
AVL_ADDR = 4'b0000;
AVL_WRITEDATA = 32'h0;
AVL_READDATA = 32'h0;
EXPORT_DATA = 32'h0;

#10 RESET = 1'b0;

// Write key to reg
#2 AVL_WRITE = 1'b1;
   AVL_CS = 1'b1;
   AVL_BYTE_EN = 4'b1111;
   AVL_ADDR = 4'b0000;
   AVL_WRITEDATA = 32'h00010203;

#2 AVL_BYTE_EN = 4'b1111;
   AVL_ADDR = 4'b0001;
   AVL_WRITEDATA = 32'h04050607;

#2 AVL_BYTE_EN = 4'b1111;
   AVL_ADDR = 4'b0010;
   AVL_WRITEDATA = 32'h08090A0B;
    
#2 AVL_BYTE_EN = 4'b1111;
   AVL_ADDR = 4'b0011;
   AVL_WRITEDATA = 32'h0C0D0E0F;

// Write encrypted message to reg
#2 AVL_BYTE_EN = 4'b1111;
   AVL_ADDR = 4'b0100;
   AVL_WRITEDATA = 32'hDAEC3055;

#2 AVL_BYTE_EN = 4'b1111;
   AVL_ADDR = 4'b0101;
   AVL_WRITEDATA = 32'hDF058E1C;

#2 AVL_BYTE_EN = 4'b1111;
   AVL_ADDR = 4'b0110;
   AVL_WRITEDATA = 32'h39E814EA;
    
#2 AVL_BYTE_EN = 4'b1111;
   AVL_ADDR = 4'b0111;
   AVL_WRITEDATA = 32'h76F6747E;

// Start signal
#2 AVL_BYTE_EN = 4'b1111;
   AVL_ADDR = 4'b1110;
   AVL_WRITEDATA = 32'h00000001;

#2 AVL_WRITE = 1'b0;
   AVL_CS = 1'b0;

// Start signal low
#350 AVL_CS = 1'b1;
   AVL_WRITE = 1'b1;
   AVL_BYTE_EN = 4'b1111;
   AVL_ADDR = 4'b1110;
   AVL_WRITEDATA = 32'h00000000;

// Write encrypted message to reg
#2 AVL_BYTE_EN = 4'b1111;
   AVL_ADDR = 4'b0100;
   AVL_WRITEDATA = 32'hDAEC3055;

#2 AVL_BYTE_EN = 4'b1111;
   AVL_ADDR = 4'b0101;
   AVL_WRITEDATA = 32'hDF058E1C;

#2 AVL_BYTE_EN = 4'b1111;
   AVL_ADDR = 4'b0110;
   AVL_WRITEDATA = 32'h39E814EA;
    
#2 AVL_BYTE_EN = 4'b1111;
   AVL_ADDR = 4'b0111;
   AVL_WRITEDATA = 32'h76F6747E;

// Start signal
#2 AVL_BYTE_EN = 4'b1111;
   AVL_ADDR = 4'b1110;
   AVL_WRITEDATA = 32'h00000001;

#2 AVL_WRITE = 1'b0;
   AVL_CS = 0;

end

endmodule
