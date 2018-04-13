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
             // SRAM interface (all control signals are active low)
				 output logic 			SRAM_CE_N,	// SRAM chip enable
				 output logic [19:0] SRAM_ADDR,	// SRAM 20-bit address
				 inout wire [15:0]	SRAM_DQ,		// SRAM 20-bit data
				 output logic 			SRAM_OE_N,	// SRAM output enable
				 output logic 			SRAM_WE_N,	// SRAM write enable
				 output logic 			SRAM_LB_N,	// SRAM lower byte enable
				 output logic 			SRAM_UB_N,	// SRAM upper byte enable
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
	
	// Output VGA signals to GPIO pins for second VGA interface
	// Set RGB signals to low during horizontal blanking interval
	assign GPIO[9] = VGA_HS? VGA_R[7]:8'h00; //VGA_R[7];
	assign GPIO[7] = VGA_HS? VGA_R[6]:8'h00; //VGA_R[6];
	assign GPIO[5] = VGA_HS? VGA_R[5]:8'h00; //VGA_R[5];
	assign GPIO[3] = VGA_HS? VGA_R[4]:8'h00; //VGA_R[4];
	assign GPIO[1] = VGA_HS? VGA_R[3]:8'h00; //VGA_R[3];
	assign GPIO[14] = VGA_HS? VGA_G[7]:8'h00; //VGA_G[7];
	assign GPIO[12] = VGA_HS? VGA_G[6]:8'h00; //VGA_G[6];
	assign GPIO[10] = VGA_HS? VGA_G[5]:8'h00; //VGA_G[5];
	assign GPIO[6] = VGA_HS? VGA_G[4]:8'h00; //VGA_G[4];
	assign GPIO[0] = VGA_HS? VGA_G[3]:8'h00; //VGA_G[3];
	assign GPIO[19] = VGA_HS? VGA_B[7]:8'h00; //VGA_B[7];
	assign GPIO[17] = VGA_HS? VGA_B[6]:8'h00; //VGA_B[6];
	assign GPIO[15] = VGA_HS? VGA_B[5]:8'h00; //VGA_B[5];
	assign GPIO[13] = VGA_HS? VGA_B[4]:8'h00; //VGA_B[4];
	assign GPIO[11] = VGA_HS? VGA_B[3]:8'h00; //VGA_B[3];
	assign GPIO[2] = VGA_VS;
	assign GPIO[4] = VGA_HS;
    
    logic Reset_h, Clk;
    logic [31:0] keycode;
    logic [7:0] PS2in;
	 logic [31:0] PS2keycode;
    logic PS2press;
    
    assign Clk = CLOCK_50;
    always_ff @ (posedge Clk) begin
        Reset_h <= ~(KEY[0]);        // The push buttons are active low
    end
    
    logic [1:0] hpi_addr;
    logic [15:0] hpi_data_in, hpi_data_out;
    logic hpi_r, hpi_w, hpi_cs, hpi_reset;
	 
	 // Tri-state buffer to transfer data between FPGA and SRAM
	 tristate #(.N(16)) tri(.Clk(Clk), 
									.tristate_output_enable(~SRAM_WE_N),
									.Data_write(),
									.Data_read(),
									.Data(SRAM_DQ)
									);
    
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
     
     // You need to make sure that the port names here match the ports in Qsys-generated codes.
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
    // You will have to generate it on your own in simulation.
    vga_clk vga_clk_instance(.inclk0(Clk), .c0(VGA_CLK));

    // Connections
    logic [9:0] DrX, DrY;
    logic cancerball;
    
    // TODO: Fill in the connections for the rest of the modules 
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
    
    // Which signal should be frame_clk?
    ball ball_instance(.Clk(Clk),
			.Reset(Reset_h),
			.frame_clk(VGA_VS),
			.keycode(keycode[31:0]),
			.DrawX(DrX),
			.DrawY(DrY),
			.is_ball(cancerball)
		);
    
    color_mapper color_instance(.is_ball(cancerball),
    				.DrawX(DrX),
				.DrawY(DrY),
				.VGA_R(VGA_R),
				.VGA_G(VGA_G),
				.VGA_B(VGA_B)
			);
    
    // Display keycode on hex display
    HexDriver hex_inst_0 (PS2keycode[3:0], HEX0);
    HexDriver hex_inst_1 (PS2keycode[7:4], HEX1);
    HexDriver hex_inst_2 (PS2keycode[11:8], HEX2);
    HexDriver hex_inst_3 (PS2keycode[15:12], HEX3);
    HexDriver hex_inst_4 (PS2keycode[19:16], HEX4);
    HexDriver hex_inst_5 (PS2keycode[23:20], HEX5);
    HexDriver hex_inst_6 (PS2keycode[27:24], HEX6);
    HexDriver hex_inst_7 (PS2keycode[31:28], HEX7);

    always_comb
    begin
	    // Display direction on green LEDs: 0 0 0 0 0 W A S D
	    case (keycode[7:0])
		8'h1A: // W
			LEDG = 9'b000001000;
		8'h04: // A
			LEDG = 9'b000000100;
		8'h16: // S
			LEDG = 9'b000000010;
		8'h07: // D
			LEDG = 9'b000000001;
		default:
			LEDG = 9'b000000000;
	    endcase
    end

	
    
    /**************************************************************************************
        ATTENTION! Please answer the following quesiton in your lab report! Points will be allocated for the answers!
        Hidden Question #1/2:
        What are the advantages and/or disadvantages of using a USB interface over PS/2 interface to
             connect to the keyboard? List any two.  Give an answer in your Post-Lab.
    **************************************************************************************/
endmodule
