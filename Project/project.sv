//-------------------------------------------------------------------------
//      TOP-LEVEL FILE FOR TWO-PLAYER SHOOTER                            --
//      ECE 385 Final Project                                            --
//      Justin Song and Mickey Zhang                                     --
//      Spring 2018                                                      --
//-------------------------------------------------------------------------


module project( input               CLOCK_50,
             input        [3:0]  KEY,          //bit 0 is set up as Reset
             input        [17:0] SW,
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
			 output logic [35:0] GPIO,
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
	         output logic [8:0]  LEDG,	   //Directions
             input logic         AUD_ADCDAT, // Audio signals
             output logic        AUD_DACDAT, AUD_XCK, I2C_SCLK,
             inout wire          AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, I2C_SDAT 
                    );

    // Miscellaneous signals
    logic Reset_h, Clk;
    logic [31:0] keycode; // USB keycodes
    logic [7:0] PS2in; // PS2 keycode
	logic [31:0] PS2keycode; // PS2 keycodes
    logic PS2press; // PS2 key press flag
    logic [11:0] xOne, yOne, xTwo, yTwo; // Position of players
    logic [9:0] DrX, DrY; // VGA controller scanning position
    logic [1:0] p1dir, p2dir; // Direction each player is facing
    // Bullet positions and whether each bullet is active
    logic [11:0] b1X, b1Y, b2X, b2Y, b3X, b3Y, b4X, b4Y, b5X, b5Y, b6X, b6Y, b7X, b7Y, b8X, b8Y, b9X, b9Y, b10X, b10Y, b11X, b11Y, b12X, b12Y, b13X, b13Y, b14X, b14Y, b15X, b15Y, b16X, b16Y;
    logic b1active, b2active, b3active, b4active, b5active, b6active, b7active, b8active, b9active, b10active, b11active, b12active, b13active, b14active, b15active, b16active;
    logic [3:0] p1health, p2health; // Health of each player
    logic p1wins; // Did player 1 win?
    logic [2:0] currState; // What game state are we in?
    logic isAlt1, isAlt2; // which player sprite to draw (for animation)
    logic set_bullet1, set_bullet2; // has a bullet been fired?
    logic b1CD, b2CD;

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

    // Audio interface
    logic [31:0] LDATA, RDATA;
    audio_interface literal_cancer(.LDATA(LDATA), .RDATA(RDATA), .clk(Clk),
        .Reset(0), .INIT(INIT), .INIT_FINISH(INIT_FINISH), .adc_full(0),
        .data_over(0), .AUD_XCK(AUD_XCK), .AUD_BCLK(AUD_BCLK),
        .AUD_ADCDAT(AUD_ADCDAT), .AUD_DACDAT(AUD_DACDAT), 
        .AUD_DACLRCK(AUD_DACLRCK), .AUD_ADCLRCK(AUD_ADCLRCK),
        .I2C_SDAT(I2C_SDAT), .I2C_SCLK(I2C_SCLK), .ADCDATA(0));

    // Initialize the audio codec
    logic INIT, INIT_FINISH;
    assign INIT = ~INIT_FINISH;

    // Toggle flag to set sound frequency
    logic hiLo;
    logic [18:0] sound_count;
    logic [18:0] sound = 19'd56818;  // Concert A (440 Hz)
    always_ff @ (posedge Clk)
    begin
        if (sound_count == sound)
        begin
            sound_count <= 19'd0;
            hiLo <= ~hiLo;
        end
        else
            sound_count <= sound_count + 19'd1;
    end

    // Counter for the duration of the sound
    logic [24:0] soundDuration = 25'd0;
    logic playSound = 1'b0;
    always_ff @ (posedge Clk)
    begin
        if ((set_bullet1 & ~b1CD) | (set_bullet2 & ~b2CD))
        begin
            soundDuration <= 25'd0;
            playSound <= 1'b1;
        end
        else if (soundDuration >= 25'd3000000)
        begin
            soundDuration <= 25'd0;
            playSound <= 1'b0;
        end
        else
            soundDuration <= soundDuration + 25'd1;
    end 

    // Send sound to audio chip
    assign LDATA = playSound? (hiLo? 32'd20000000:32'd0):32'd0;
    assign RDATA = playSound? (hiLo? 32'd20000000:32'd0):32'd0;

    // // Audio interface
    // logic [31:0] LDATA, RDATA;
    // logic write_audio_out, audio_out_allowed;
    // Audio_Controller literal_cancer(.CLOCK_50(Clk), .reset(0), .clear_audio_in_memory(0),
    //     .read_audio_in(0), .clear_audio_out_memory(0), .left_channel_audio_out(LDATA),
    //     .right_channel_audio_out(RDATA), .write_audio_out(write_audio_out), .AUD_ADCDAT(AUD_ADCDAT),
    //     .AUD_BCLK(AUD_BCLK), .AUD_ADCLRCK(AUD_ADCLRCK), .AUD_DACLRCK(AUD_DACLRCK),
    //     .left_channel_audio_in(0), .right_channel_audio_in(0), .audio_in_available(0),
    //     .audio_out_allowed(audio_out_allowed), .AUD_XCK(AUD_XCK), .AUD_DACDAT(AUD_DACDAT));

    // avconf death(.CLOCK_50(Clk), .reset(0), .I2C_SCLK(I2C_SCLK), .I2C_SDAT(I2C_SDAT));

    // // Toggle flag to set sound frequency
    // logic hiLo;
    // logic [18:0] sound_count;
    // logic [18:0] sound = 19'd56818;
    // always_ff @ (posedge Clk)
    // begin
    //     if (sound_count == sound)
    //     begin
    //         sound_count <= 19'd0;
    //         hiLo <= ~hiLo;
    //     end
    //     else
    //         sound_count <= sound_count + 19'd1;
    // end

    // // Counter for the duration of the sound
    // logic [24:0] soundDuration = 25'd0;
    // logic playSound = 1'b0;
    // always_ff @ (posedge Clk)
    // begin
    //     if ((set_bullet1 & ~b1CD) | (set_bullet2 & ~b2CD))
    //     begin
    //         soundDuration <= 25'd0;
    //         playSound <= 1'b1;
    //     end
    //     else if (soundDuration >= 25'd3000000)
    //     begin
    //         soundDuration <= 25'd0;
    //         playSound <= 1'b0;
    //     end
    //     else
    //         soundDuration <= soundDuration + 25'd1;
    // end 

    // // Send sound to audio chip
    // assign LDATA = hiLo? 32'd20000000:32'd0; //(left_channel_audio_in + 32'd10000000) : (left_channel_audio_in - 32'd10000000);
    // assign RDATA = hiLo? 32'd20000000:32'd0; //(right_channel_audio_in + 32'd10000000) : (right_channel_audio_in - 32'd10000000);
    // assign write_audio_out = playSound & audio_out_allowed;

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

    // Hex displays
    HexDriver hex_inst_0 (PS2keycode[3:0], HEX0);
    HexDriver hex_inst_1 (PS2keycode[7:4], HEX1);
    HexDriver hex_inst_2 (PS2keycode[11:8], HEX2);
    HexDriver hex_inst_3 (PS2keycode[15:12], HEX3);
    HexDriver hex_inst_4 (PS2keycode[19:16], HEX4);
    HexDriver hex_inst_5 (PS2keycode[23:20], HEX5);
    HexDriver hex_inst_6 (PS2in[3:0], HEX6);
    HexDriver hex_inst_7 (PS2in[7:4], HEX7);

    // Green LEDs
    always_comb
    begin
	    LEDG[0] = currState[0];
        LEDG[1] = currState[1];
        LEDG[2] = currState[2];
        // LEDG[3] = write_audio_out;
        // LEDG[4] = audio_out_allowed;
        LEDG[5] = PS2press;
    end

endmodule
