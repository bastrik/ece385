//-------------------------------------------------------------------------
//      project.sv                                                          --
//      Christine Chen                                                   --
//      Fall 2014                                                        --
//                                                                       --
//      Modified by Po-Han Huang                                         --
//      10/06/2017                                                       --
//                                                                       --
//      Fall 2017 Distribution                                           --
//                                                                       --
//      For use with ECE 385 Lab 8                                       --
//      UIUC ECE Department                                              --
//-------------------------------------------------------------------------


module project( input               CLOCK_50,
             input        [3:0]  KEY,          //bit 0 is set up as Reset
	     input logic PS2_CLK, PS2_DAT,
             output logic [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7,
             // VGA Interface 
             output logic [7:0]  VGA_R,        //VGA Red
                                 VGA_G,        //VGA Green
                                 VGA_B,        //VGA Blue
             output logic        VGA_CLK,      //VGA Clock
                                 VGA_SYNC_N,   //VGA Sync signal
                                 VGA_BLANK_N,  //VGA Blank signal
                                 VGA_VS,       //VGA virtical sync signal
                                 VGA_HS,       //VGA horizontal sync signal
			output logic [35:0]		GPIO,
             // CY7C67200 Interface
             inout  wire  [15:0] OTG_DATA,     //CY7C67200 Data bus 16 Bits
             output logic [1:0]  OTG_ADDR,     //CY7C67200 Address 2 Bits
             output logic        OTG_CS_N,     //CY7C67200 Chip Select
                                 OTG_RD_N,     //CY7C67200 Write
                                 OTG_WR_N,     //CY7C67200 Read
                                 OTG_RST_N,    //CY7C67200 Reset
             input               OTG_INT,      //CY7C67200 Interrupt
     //         // SRAM interface (all control signals are active low)
				 // output logic 			SRAM_CE_N,	// SRAM chip enable
				 // output logic [19:0] SRAM_ADDR,	// SRAM 20-bit address
				 // inout wire [15:0]	SRAM_DQ,		// SRAM 16-bit data
				 // output logic 			SRAM_OE_N,	// SRAM output enable
				 // output logic 			SRAM_WE_N,	// SRAM write enable
				 // output logic 			SRAM_LB_N,	// SRAM lower byte enable
				 // output logic 			SRAM_UB_N,	// SRAM upper byte enable
				 // SDRAM Interface for Nios II Software
             output logic [12:0] DRAM_ADDR,    //SDRAM Address 13 Bits
             inout  wire  [31:0] DRAM_DQ,      //SDRAM Data 32 Bits
             output logic [1:0]  DRAM_BA,      //SDRAM Bank Address 2 Bits
             output logic [3:0]  DRAM_DQM,     //SDRAM Data Mast 4 Bits
             output logic        DRAM_RAS_N,   //SDRAM Row Address Strobe
                                 DRAM_CAS_N,   //SDRAM Column Address Strobe
                                 DRAM_CKE,     //SDRAM Clock Enable
                                 DRAM_WE_N,    //SDRAM Write Enable
                                 DRAM_CS_N,    //SDRAM Chip Select
                                 DRAM_CLK,     //SDRAM Clock
	     output logic [8:0]  LEDG	       //Directions
                    );

    logic Reset_h, Clk;
    logic [31:0] keycode; // USB keycodes
    logic [7:0] PS2in; // PS2 keycode
	logic [31:0] PS2keycode; // PS2 keycodes
    logic PS2press; // PS2 key press flag
    logic [11:0] xOne, yOne, xTwo, yTwo; // Position of players
    logic [9:0] DrX, DrY; // VGA controller scanning position
    logic [1:0] p1dir, p2dir; // Direction each player is facing
    logic [11:0] b1X, b1Y, b2X, b2Y, b3X, b3Y, b4X, b4Y, b5X, b5Y, b6X, b6Y, b7X, b7Y, b8X, b8Y, b9X, b9Y, b10X, b10Y, b11X, b11Y, b12X, b12Y, b13X, b13Y, b14X, b14Y, b15X, b15Y, b16X, b16Y;
    logic b1active, b2active, b3active, b4active, b5active, b6active, b7active, b8active, b9active, b10active, b11active, b12active, b13active, b14active, b15active, b16active;

    assign Clk = CLOCK_50;
    always_ff @ (posedge Clk) begin
        Reset_h <= ~(KEY[0]);        // The push buttons are active low
    end
    
    // EZ-OTG signals
    logic [1:0] hpi_addr;
    logic [15:0] hpi_data_in, hpi_data_out;
    logic hpi_r, hpi_w, hpi_cs, hpi_reset;

    // Determines pixel colors
    draw_map drawing_engine(.*);

    // Determines game logic
    game_logic game_engine(.*);
    
    // Interface between NIOS II and EZ-OTG chip
    hpi_io_intf hpi_io_inst(
                            .Clk(Clk),
                            .Reset(Reset_h),
                            // signals connected to NIOS II
                            .from_sw_address(hpi_addr),
                            .from_sw_data_in(hpi_data_in),
                            .from_sw_data_out(hpi_data_out),
                            .from_sw_r(hpi_r),
                            .from_sw_w(hpi_w),
                            .from_sw_cs(hpi_cs),
                            .from_sw_reset(hpi_reset),
                            // signals connected to EZ-OTG chip
                            .OTG_DATA(OTG_DATA),    
                            .OTG_ADDR(OTG_ADDR),    
                            .OTG_RD_N(OTG_RD_N),    
                            .OTG_WR_N(OTG_WR_N),    
                            .OTG_CS_N(OTG_CS_N),
                            .OTG_RST_N(OTG_RST_N)
    );
     
    // Qsys SoC
     project_soc nios_system(
                             .clk_clk(Clk),         
                             .reset_reset_n(1'b1),    // Never reset NIOS
                             .sdram_wire_addr(DRAM_ADDR), 
                             .sdram_wire_ba(DRAM_BA),   
                             .sdram_wire_cas_n(DRAM_CAS_N),
                             .sdram_wire_cke(DRAM_CKE),  
                             .sdram_wire_cs_n(DRAM_CS_N), 
                             .sdram_wire_dq(DRAM_DQ),   
                             .sdram_wire_dqm(DRAM_DQM),  
                             .sdram_wire_ras_n(DRAM_RAS_N),
                             .sdram_wire_we_n(DRAM_WE_N), 
                             .sdram_clk_clk(DRAM_CLK),
                             .keycode_export(keycode),  
                             .otg_hpi_address_export(hpi_addr),
                             .otg_hpi_data_in_port(hpi_data_in),
                             .otg_hpi_data_out_port(hpi_data_out),
                             .otg_hpi_cs_export(hpi_cs),
                             .otg_hpi_r_export(hpi_r),
                             .otg_hpi_w_export(hpi_w),
                             .otg_hpi_reset_export(hpi_reset)
    );

    // PS/2 keyboard driver
    keyboard PS2key(.Clk(Clk), .psClk(PS2_CLK), .psData(PS2_DAT), .reset(Reset_h), .keyCode(PS2in), .press(PS2press));
	
	// Store PS2 key presses
	PS2reg PS2keys(.Clk(Clk), .Reset(Reset_h), .keycode(PS2in), .press(PS2press), .keycode_out(PS2keycode));
    
    // Use PLL to generate the 25MHZ VGA_CLK.
    vga_clk vga_clk_instance(.inclk0(Clk), .c0(VGA_CLK));
    
    // VGA controller 
    VGA_controller vga_controller_instance(.Clk(Clk),
    					.Reset(Reset_h),
					.VGA_HS(VGA_HS),
					.VGA_VS(VGA_VS),
					.VGA_CLK(VGA_CLK),
					.VGA_BLANK_N(VGA_BLANK_N),
					.VGA_SYNC_N(VGA_SYNC_N),
					.DrawX(DrX),
					.DrawY(DrY)
				);

    // logic cancerball;
    
  //   ball ball_instance(.Clk(Clk),
		// 	.Reset(Reset_h),
		// 	.frame_clk(VGA_VS),
		// 	.keycode(keycode[31:0]),
		// 	.DrawX(DrX),
		// 	.DrawY(DrY),
		// 	.is_ball(cancerball)
		// );
    
  //   color_mapper color_instance(.is_ball(cancerball),
  //   				.DrawX(DrX),
		// 		.DrawY(DrY),
		// 		.VGA_R(VGA_R),
		// 		.VGA_G(VGA_G),
		// 		.VGA_B(VGA_B)
		// 	);
    logic[6:0] xTileTwo, yTileTwo;
    // Display keycode on hex display
    HexDriver hex_inst_0 (PS2keycode[3:0], HEX0);
    HexDriver hex_inst_1 (PS2keycode[7:4], HEX1);
    HexDriver hex_inst_2 (PS2keycode[11:8], HEX2);
    HexDriver hex_inst_3 (PS2keycode[15:12], HEX3);
    HexDriver hex_inst_4 (xTileTwo[3:0], HEX4);
    HexDriver hex_inst_5 ({1'b0,xTileTwo[6:4]}, HEX5);
    HexDriver hex_inst_6 (yTileTwo[3:0], HEX6);
    HexDriver hex_inst_7 ({1'b0,yTileTwo[6:4]}, HEX7);

    always_comb
    begin
	    // For testing
	    LEDG[0] = b9active;
    end

endmodule
