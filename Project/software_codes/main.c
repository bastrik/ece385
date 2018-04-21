/*---------------------------------------------------------------------------
  --      main.c                                                    	   --
  --      Mickey Zhang                                                     --
  --      Handles USB keyboard io and SD card based audio player           --
  ---------------------------------------------------------------------------*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <io.h>
#include <fcntl.h>

#include "system.h"
#include "alt_types.h"
#include <unistd.h>  // usleep 
#include "sys/alt_irq.h"
#include "io_handler.h"

#include "cy7c67200.h"
#include "usb.h"
#include "lcp_cmd.h"
#include "lcp_data.h"

#include ".\audio_driver\terasic_includes.h"
#include ".\audio_driver\LED.h"
#include ".\fat_fs\FatFileSystem.h"
#include ".\fat_fs\FatInternal.h"
#include ".\audio_driver\WaveLib.h"
#include ".\audio_driver\I2C.h"
#include ".\audio_driver\AUDIO.h"
#include ".\sd_driver\sd_lib.h"

/* ------------------------------ USB Stack Variables ----------------------------------- */
#ifndef USB_STACK
#define USB_STACK
	alt_u16 intStat;
	alt_u16 usb_ctl_val;
	static alt_u16 ctl_reg = 0;
	static alt_u16 no_device = 0;
	alt_u16 fs_device = 0;
	int keycode1 = 0;
	int keycode2 = 0;
	int keycode = 0;
	alt_u8 toggle = 0;
	alt_u8 data_size;
	alt_u8 hot_plug_count;
	alt_u16 code;
#endif

void usb_init()
{
	IO_init();

	/*while(1)
	{
		IO_write(HPI_MAILBOX,COMM_EXEC_INT);
		printf("[ERROR]:routine mailbox data is %x\n",IO_read(HPI_MAILBOX));
		//UsbWrite(0xc008,0x000f);
		//UsbRead(0xc008);
		usleep(10*10000);
	}*/



	printf("USB keyboard setup...\n\n");

	//----------------------------------------SIE1 initial---------------------------------------------------//
	USB_HOT_PLUG:
	UsbSoftReset();

	// STEP 1a:
	UsbWrite (HPI_SIE1_MSG_ADR, 0);
	UsbWrite (HOST1_STAT_REG, 0xFFFF);

	/* Set HUSB_pEOT time */
	UsbWrite(HUSB_pEOT, 600); // adjust the according to your USB device speed

	usb_ctl_val = SOFEOP1_TO_CPU_EN | RESUME1_TO_HPI_EN;// | SOFEOP1_TO_HPI_EN;
	UsbWrite(HPI_IRQ_ROUTING_REG, usb_ctl_val);

	intStat = A_CHG_IRQ_EN | SOF_EOP_IRQ_EN ;
	UsbWrite(HOST1_IRQ_EN_REG, intStat);
	// STEP 1a end

	// STEP 1b begin
	UsbWrite(COMM_R0,0x0000);//reset time
	UsbWrite(COMM_R1,0x0000);  //port number
	UsbWrite(COMM_R2,0x0000);  //r1
	UsbWrite(COMM_R3,0x0000);  //r1
	UsbWrite(COMM_R4,0x0000);  //r1
	UsbWrite(COMM_R5,0x0000);  //r1
	UsbWrite(COMM_R6,0x0000);  //r1
	UsbWrite(COMM_R7,0x0000);  //r1
	UsbWrite(COMM_R8,0x0000);  //r1
	UsbWrite(COMM_R9,0x0000);  //r1
	UsbWrite(COMM_R10,0x0000);  //r1
	UsbWrite(COMM_R11,0x0000);  //r1
	UsbWrite(COMM_R12,0x0000);  //r1
	UsbWrite(COMM_R13,0x0000);  //r1
	UsbWrite(COMM_INT_NUM,HUSB_SIE1_INIT_INT); //HUSB_SIE1_INIT_INT
	IO_write(HPI_MAILBOX,COMM_EXEC_INT);

	while (!(IO_read(HPI_STATUS) & 0xFFFF) )  //read sie1 msg register
	{
	}
	while (IO_read(HPI_MAILBOX) != COMM_ACK)
	{
		printf("[ERROR]:routine mailbox data is %x\n",IO_read(HPI_MAILBOX));
		goto USB_HOT_PLUG;
	}
	// STEP 1b end

	printf("STEP 1 Complete");
	// STEP 2 begin
	UsbWrite(COMM_INT_NUM,HUSB_RESET_INT); //husb reset
	UsbWrite(COMM_R0,0x003c);//reset time
	UsbWrite(COMM_R1,0x0000);  //port number
	UsbWrite(COMM_R2,0x0000);  //r1
	UsbWrite(COMM_R3,0x0000);  //r1
	UsbWrite(COMM_R4,0x0000);  //r1
	UsbWrite(COMM_R5,0x0000);  //r1
	UsbWrite(COMM_R6,0x0000);  //r1
	UsbWrite(COMM_R7,0x0000);  //r1
	UsbWrite(COMM_R8,0x0000);  //r1
	UsbWrite(COMM_R9,0x0000);  //r1
	UsbWrite(COMM_R10,0x0000);  //r1
	UsbWrite(COMM_R11,0x0000);  //r1
	UsbWrite(COMM_R12,0x0000);  //r1
	UsbWrite(COMM_R13,0x0000);  //r1

	IO_write(HPI_MAILBOX,COMM_EXEC_INT);

	while (IO_read(HPI_MAILBOX) != COMM_ACK)
	{
		printf("[ERROR]:routine mailbox data is %x\n",IO_read(HPI_MAILBOX));
		goto USB_HOT_PLUG;
	}
	// STEP 2 end

	ctl_reg = USB1_CTL_REG;
	no_device = (A_DP_STAT | A_DM_STAT);
	fs_device = A_DP_STAT;
	usb_ctl_val = UsbRead(ctl_reg);

	if (!(usb_ctl_val & no_device))
	{
		for(hot_plug_count = 0 ; hot_plug_count < 5 ; hot_plug_count++)
		{
			usleep(5*1000);
			usb_ctl_val = UsbRead(ctl_reg);
			if(usb_ctl_val & no_device) break;
		}
		if(!(usb_ctl_val & no_device))
		{
			printf("\n[INFO]: no device is present in SIE1!\n");
			printf("[INFO]: please insert a USB keyboard in SIE1!\n");
			while (!(usb_ctl_val & no_device))
			{
				usb_ctl_val = UsbRead(ctl_reg);
				if(usb_ctl_val & no_device)
					goto USB_HOT_PLUG;

				usleep(2000);
			}
		}
	}
	else
	{
		/* check for low speed or full speed by reading D+ and D- lines */
		if (usb_ctl_val & fs_device)
		{
			printf("[INFO]: full speed device\n");
		}
		else
		{
			printf("[INFO]: low speed device\n");
		}
	}



	// STEP 3 begin
	//------------------------------------------------------set address -----------------------------------------------------------------
	UsbSetAddress();

	while (!(IO_read(HPI_STATUS) & HPI_STATUS_SIE1msg_FLAG) )  //read sie1 msg register
	{
		UsbSetAddress();
		usleep(10*1000);
	}

	UsbWaitTDListDone();

	IO_write(HPI_ADDR,0x0506); // i
	printf("[ENUM PROCESS]:step 3 TD Status Byte is %x\n",IO_read(HPI_DATA));

	IO_write(HPI_ADDR,0x0508); // n
	usb_ctl_val = IO_read(HPI_DATA);
	printf("[ENUM PROCESS]:step 3 TD Control Byte is %x\n",usb_ctl_val);
	while (usb_ctl_val != 0x03) // retries occurred
	{
		usb_ctl_val = UsbGetRetryCnt();

		goto USB_HOT_PLUG;
	}

	printf("------------[ENUM PROCESS]:set address done!---------------\n");

	// STEP 4 begin
	//-------------------------------get device descriptor-1 -----------------------------------//
	// TASK: Call the appropriate function for this step.
	UsbGetDeviceDesc1(); 	// Get Device Descriptor -1

	//usleep(10*1000);
	while (!(IO_read(HPI_STATUS) & HPI_STATUS_SIE1msg_FLAG) )  //read sie1 msg register
	{
		// TASK: Call the appropriate function again if it wasn't processed successfully.
		UsbGetDeviceDesc1();
		usleep(10*1000);
	}

	UsbWaitTDListDone();

	IO_write(HPI_ADDR,0x0506);
	printf("[ENUM PROCESS]:step 4 TD Status Byte is %x\n",IO_read(HPI_DATA));

	IO_write(HPI_ADDR,0x0508);
	usb_ctl_val = IO_read(HPI_DATA);
	printf("[ENUM PROCESS]:step 4 TD Control Byte is %x\n",usb_ctl_val);
	while (usb_ctl_val != 0x03)
	{
		usb_ctl_val = UsbGetRetryCnt();
	}

	printf("---------------[ENUM PROCESS]:get device descriptor-1 done!-----------------\n");


	//--------------------------------get device descriptor-2---------------------------------------------//
	//get device descriptor
	// TASK: Call the appropriate function for this step.
	UsbGetDeviceDesc2(); 	// Get Device Descriptor -2

	//if no message
	while (!(IO_read(HPI_STATUS) & HPI_STATUS_SIE1msg_FLAG) )  //read sie1 msg register
	{
		//resend the get device descriptor
		//get device descriptor
		// TASK: Call the appropriate function again if it wasn't processed successfully.
		UsbGetDeviceDesc2();
		usleep(10*1000);
	}

	UsbWaitTDListDone();

	IO_write(HPI_ADDR,0x0506);
	printf("[ENUM PROCESS]:step 4 TD Status Byte is %x\n",IO_read(HPI_DATA));

	IO_write(HPI_ADDR,0x0508);
	usb_ctl_val = IO_read(HPI_DATA);
	printf("[ENUM PROCESS]:step 4 TD Control Byte is %x\n",usb_ctl_val);
	while (usb_ctl_val != 0x03)
	{
		usb_ctl_val = UsbGetRetryCnt();
	}

	printf("------------[ENUM PROCESS]:get device descriptor-2 done!--------------\n");


	// STEP 5 begin
	//-----------------------------------get configuration descriptor -1 ----------------------------------//
	// TASK: Call the appropriate function for this step.
	UsbGetConfigDesc1(); 	// Get Configuration Descriptor -1

	//if no message
	while (!(IO_read(HPI_STATUS) & HPI_STATUS_SIE1msg_FLAG) )  //read sie1 msg register
	{
		//resend the get device descriptor
		//get device descriptor

		// TASK: Call the appropriate function again if it wasn't processed successfully.
		UsbGetConfigDesc1();
		usleep(10*1000);
	}

	UsbWaitTDListDone();

	IO_write(HPI_ADDR,0x0506);
	printf("[ENUM PROCESS]:step 5 TD Status Byte is %x\n",IO_read(HPI_DATA));

	IO_write(HPI_ADDR,0x0508);
	usb_ctl_val = IO_read(HPI_DATA);
	printf("[ENUM PROCESS]:step 5 TD Control Byte is %x\n",usb_ctl_val);
	while (usb_ctl_val != 0x03)
	{
		usb_ctl_val = UsbGetRetryCnt();
	}
	printf("------------[ENUM PROCESS]:get configuration descriptor-1 pass------------\n");

	// STEP 6 begin
	//-----------------------------------get configuration descriptor-2------------------------------------//
	//get device descriptor
	// TASK: Call the appropriate function for this step.
	UsbGetConfigDesc2(); 	// Get Configuration Descriptor -2

	usleep(100*1000);
	//if no message
	while (!(IO_read(HPI_STATUS) & HPI_STATUS_SIE1msg_FLAG) )  //read sie1 msg register
	{
		// TASK: Call the appropriate function again if it wasn't processed successfully.
		UsbGetConfigDesc2();
		usleep(10*1000);
	}

	UsbWaitTDListDone();

	IO_write(HPI_ADDR,0x0506);
	printf("[ENUM PROCESS]:step 6 TD Status Byte is %x\n",IO_read(HPI_DATA));

	IO_write(HPI_ADDR,0x0508);
	usb_ctl_val = IO_read(HPI_DATA);
	printf("[ENUM PROCESS]:step 6 TD Control Byte is %x\n",usb_ctl_val);
	while (usb_ctl_val != 0x03)
	{
		usb_ctl_val = UsbGetRetryCnt();
	}


	printf("-----------[ENUM PROCESS]:get configuration descriptor-2 done!------------\n");


	// ---------------------------------get device info---------------------------------------------//

	// TASK: Write the address to read from the memory for byte 7 of the interface descriptor to HPI_ADDR.
	IO_write(HPI_ADDR,0x056c);
	code = IO_read(HPI_DATA);
	code = code & 0x003;
	printf("\ncode = %x\n", code);

	if (code == 0x01)
	{
		printf("\n[INFO]:check TD rec data7 \n[INFO]:Keyboard Detected!!!\n\n");
	}
	else
	{
		printf("\n[INFO]:Keyboard Not Detected!!! \n\n");
	}

	// TASK: Write the address to read from the memory for the endpoint descriptor to HPI_ADDR.

	IO_write(HPI_ADDR,0x0576);
	IO_write(HPI_DATA,0x073F);
	IO_write(HPI_DATA,0x8105);
	IO_write(HPI_DATA,0x0003);
	IO_write(HPI_DATA,0x0008);
	IO_write(HPI_DATA,0xAC0A);
	UsbWrite(HUSB_SIE1_pCurrentTDPtr,0x0576); //HUSB_SIE1_pCurrentTDPtr

	//data_size = (IO_read(HPI_DATA)>>8)&0x0ff;
	//data_size = 0x08;//(IO_read(HPI_DATA))&0x0ff;
	//UsbPrintMem();
	IO_write(HPI_ADDR,0x057c);
	data_size = (IO_read(HPI_DATA))&0x0ff;
	printf("[ENUM PROCESS]:data packet size is %d\n",data_size);
	// STEP 7 begin
	//------------------------------------set configuration -----------------------------------------//
	// TASK: Call the appropriate function for this step.
	UsbSetConfig();		// Set Configuration

	while (!(IO_read(HPI_STATUS) & HPI_STATUS_SIE1msg_FLAG) )  //read sie1 msg register
	{
		// TASK: Call the appropriate function again if it wasn't processed successfully.
		UsbSetConfig();		// Set Configuration
		usleep(10*1000);
	}

	UsbWaitTDListDone();

	IO_write(HPI_ADDR,0x0506);
	printf("[ENUM PROCESS]:step 7 TD Status Byte is %x\n",IO_read(HPI_DATA));

	IO_write(HPI_ADDR,0x0508);
	usb_ctl_val = IO_read(HPI_DATA);
	printf("[ENUM PROCESS]:step 7 TD Control Byte is %x\n",usb_ctl_val);
	while (usb_ctl_val != 0x03)
	{
		usb_ctl_val = UsbGetRetryCnt();
	}

	printf("------------[ENUM PROCESS]:set configuration done!-------------------\n");

	//----------------------------------------------class request out ------------------------------------------//
	// TASK: Call the appropriate function for this step.
	UsbClassRequest();

	while (!(IO_read(HPI_STATUS) & HPI_STATUS_SIE1msg_FLAG) )  //read sie1 msg register
	{
		// TASK: Call the appropriate function again if it wasn't processed successfully.
		UsbClassRequest();
		usleep(10*1000);
	}

	UsbWaitTDListDone();

	IO_write(HPI_ADDR,0x0506);
	printf("[ENUM PROCESS]:step 8 TD Status Byte is %x\n",IO_read(HPI_DATA));

	IO_write(HPI_ADDR,0x0508);
	usb_ctl_val = IO_read(HPI_DATA);
	printf("[ENUM PROCESS]:step 8 TD Control Byte is %x\n",usb_ctl_val);
	while (usb_ctl_val != 0x03)
	{
		usb_ctl_val = UsbGetRetryCnt();
	}


	printf("------------[ENUM PROCESS]:class request out done!-------------------\n");

	// STEP 8 begin
	//----------------------------------get descriptor(class 0x21 = HID) request out --------------------------------//
	// TASK: Call the appropriate function for this step.
	UsbGetHidDesc();

	while (!(IO_read(HPI_STATUS) & HPI_STATUS_SIE1msg_FLAG) )  //read sie1 msg register
	{
		// TASK: Call the appropriate function again if it wasn't processed successfully.
		UsbGetHidDesc();
		usleep(10*1000);
	}

	UsbWaitTDListDone();

	IO_write(HPI_ADDR,0x0506);
	printf("[ENUM PROCESS]:step 8 TD Status Byte is %x\n",IO_read(HPI_DATA));

	IO_write(HPI_ADDR,0x0508);
	usb_ctl_val = IO_read(HPI_DATA);
	printf("[ENUM PROCESS]:step 8 TD Control Byte is %x\n",usb_ctl_val);
	while (usb_ctl_val != 0x03)
	{
		usb_ctl_val = UsbGetRetryCnt();
	}

	printf("------------[ENUM PROCESS]:get descriptor (class 0x21) done!-------------------\n");

	// STEP 9 begin
	//-------------------------------get descriptor (class 0x22 = report)-------------------------------------------//
	// TASK: Call the appropriate function for this step.
	UsbGetReportDesc();
	//if no message
	while (!(IO_read(HPI_STATUS) & HPI_STATUS_SIE1msg_FLAG) )  //read sie1 msg register
	{
		// TASK: Call the appropriate function again if it wasn't processed successfully.
		UsbGetReportDesc();
		usleep(10*1000);
	}

	UsbWaitTDListDone();

	IO_write(HPI_ADDR,0x0506);
	printf("[ENUM PROCESS]: step 9 TD Status Byte is %x\n",IO_read(HPI_DATA));

	IO_write(HPI_ADDR,0x0508);
	usb_ctl_val = IO_read(HPI_DATA);
	printf("[ENUM PROCESS]: step 9 TD Control Byte is %x\n",usb_ctl_val);
	while (usb_ctl_val != 0x03)
	{
		usb_ctl_val = UsbGetRetryCnt();
	}

	printf("---------------[ENUM PROCESS]:get descriptor (class 0x22) done!----------------\n");
}

void usb_getkey()
{
	toggle++;
		IO_write(HPI_ADDR,0x0500); //the start address
		//data phase IN-1
		IO_write(HPI_DATA,0x051c); //500

		IO_write(HPI_DATA,0x000f & data_size);//2 data length

		IO_write(HPI_DATA,0x0291);//4 //endpoint 1
		if(toggle%2)
		{
			IO_write(HPI_DATA,0x0001);//6 //data 1
		}
		else
		{
			IO_write(HPI_DATA,0x0041);//6 //data 1
		}
		IO_write(HPI_DATA,0x0013);//8
		IO_write(HPI_DATA,0x0000);//a
		UsbWrite(HUSB_SIE1_pCurrentTDPtr,0x0500); //HUSB_SIE1_pCurrentTDPtr
		
		while (!(IO_read(HPI_STATUS) & HPI_STATUS_SIE1msg_FLAG) )  //read sie1 msg register
		{
			IO_write(HPI_ADDR,0x0500); //the start address
			//data phase IN-1
			IO_write(HPI_DATA,0x051c); //500

			IO_write(HPI_DATA,0x000f & data_size);//2 data length

			IO_write(HPI_DATA,0x0291);//4 //endpoint 1
			if(toggle%2)
			{
				IO_write(HPI_DATA,0x0001);//6 //data 1
			}
			else
			{
				IO_write(HPI_DATA,0x0041);//6 //data 1
			}
			IO_write(HPI_DATA,0x0013);//8
			IO_write(HPI_DATA,0x0000);//
			UsbWrite(HUSB_SIE1_pCurrentTDPtr,0x0500); //HUSB_SIE1_pCurrentTDPtr
			usleep(10*1000);
		}//end while

		usb_ctl_val = UsbWaitTDListDone();

		// The first two keycodes are stored in 0x051E. Other keycodes are in 
		// subsequent addresses.
		keycode1 = UsbRead(0x051e);
		keycode2 = UsbRead(0x051f);
		keycode = (keycode1 << 16) | keycode2;
		printf("\nfirst two keycode values are %04x\n",keycode);
		// We only need the first keycode, which is at the lower byte of keycode.
		// Send the keycode to hardware via PIO.
		*keycode_base = keycode & 0xff; 

		usleep(200);//usleep(5000);
		usb_ctl_val = UsbRead(ctl_reg);

		if(!(usb_ctl_val & no_device))
		{
			//USB hot plug routine
			for(hot_plug_count = 0 ; hot_plug_count < 7 ; hot_plug_count++)
			{
				usleep(5*1000);
				usb_ctl_val = UsbRead(ctl_reg);
				if(usb_ctl_val & no_device) break;
			}
			if(!(usb_ctl_val & no_device))
			{
				printf("\n[INFO]: the keyboard has been removed!!! \n");
				printf("[INFO]: please insert again!!! \n");
			}
		}

		while (!(usb_ctl_val & no_device))
		{

			usb_ctl_val = UsbRead(ctl_reg);
			usleep(5*1000);
			usb_ctl_val = UsbRead(ctl_reg);
			usleep(5*1000);
			usb_ctl_val = UsbRead(ctl_reg);
			usleep(5*1000);

			if(usb_ctl_val & no_device)
				goto USB_HOT_PLUG;

			usleep(200);
		}
}

/* ------------------------------ SD Audio Setup ----------------------------------- */
#ifndef AUDIO_STACK
#define AUDIO_STACK
	#define MAX_FILE_NUM    128
	#define FILENAME_LEN    32
	#define WAVE_BUF_SIZE  512
	int nPlayIndex;
    alt_u32 cnt, uSongStartTime, uTimeElapsed;
    alt_8 led_mask = 0x03;
    alt_u8 szWaveFile[FILENAME_LEN];
#endif


typedef struct{
    int nFileNum;
    char szFilename[MAX_FILE_NUM][FILENAME_LEN];
}WAVE_PLAY_LIST;

typedef struct{
    FAT_FILE_HANDLE hFile;
    alt_u8          szBuf[WAVE_BUF_SIZE];  // one sector size of sd-card
    alt_u32         uWavePlayIndex;
    alt_u32         uWaveReadPos;
    alt_u32         uWavePlayPos;
    alt_u32         uWaveMaxPlayPos;
    char szFilename[FILENAME_LEN];
    alt_u8          nVolume;
    bool            bRepeatMode;
}PLAYWAVE_CONTEXT;

static WAVE_PLAY_LIST gWavePlayList;
static PLAYWAVE_CONTEXT gWavePlay;// = {{0},{0}, HW_DEFAULT_VOL, {0}, 0, 0, 0};
static FAT_HANDLE hFat;

//===== function prototype =====
void welcome_display(void);
void update_status(void);
void wait_sdcard_insert(void);
int build_wave_play_list(FAT_HANDLE hFat);
void handle_key(bool *pNexSongPressed);
void handle_IrDA(bool * pNexSongPressed,alt_u32 id);
void IRDA_init();
bool waveplay_start(char *pFilename);
bool waveplay_execute(bool *bEOF);
// void DisplayTime(alt_u32 TimeElapsed);
void lcd_open(void);
void lcd_display(char *pText);
// void led_display(alt_u32 mask);
// void led_display_count(alt_u8 count);
bool Fat_Test(FAT_HANDLE hFat, char *pDumpFile);

int audio_init()
{
	IRDA_init();
	lcd_open();
	if (!AUDIO_Init()){
        lcd_display(("Audio Init fail!\n\n"));
        return 0;
    }

    memset(&gWavePlay, 0, sizeof(gWavePlay));
    gWavePlay.nVolume = 120;
    AUDIO_SetLineOutVol(gWavePlay.nVolume, gWavePlay.nVolume); 

    wait_sdcard_insert();

    hFat = Fat_Mount(FAT_SD_CARD, 0);
        if (!hFat){
            lcd_display(("SD card mount fail.\n\n"));
            return 0;
        }  
        else{
           if (build_wave_play_list(hFat) == 0){
            lcd_display(("No Wave Files.\n\n"));
            return 0;
            }
        }
}


/* ------------------------------ Display config ----------------------------------- */
#define LCD_DISPLAY
void update_status(void){  
    char szText[64];       
    sprintf(szText, "\r%s\nVol:%d%C\n", gWavePlay.szFilename, gWavePlay.nVolume, 
        gWavePlay.bRepeatMode?'R':'S');
    lcd_display((szText));  
}
void lcd_open(void){
    LCD_Open();
}
void lcd_display(char *pText){
    LCD_Clear();  
    LCD_TextOut(pText);
}

/* ------------------------------ SD card init ----------------------------------- */

void wait_sdcard_insert(void){
    bool bFirstTime2Detect = TRUE;
    alt_u8 led_mask = 0x02;
    LED_AllOff();
    //led = IORD_ALTERA_AVALON_PIO_DATA(LED_RED_SPAN); // low-active
    while(!SDLIB_Init()){
        if (bFirstTime2Detect){
            lcd_display(("\rPlease insert\nSD card.\n"));
            bFirstTime2Detect = FALSE;
        } 
        usleep(100*1000);
    }
    lcd_display(("\rSD card loaded.\n"));        
}

bool is_supporrted_sample_rate(int sample_rate){
    bool bSupport = FALSE;
    switch(sample_rate){
        case 96000:
        case 48000:
        case 44100:
        case 32000:
        case 8000:
            bSupport = TRUE;
            break;
    }
    return bSupport;
}

int build_wave_play_list(FAT_HANDLE hFat){
    int count = 0;
    FAT_BROWSE_HANDLE hFileBrowse;
    //FAT_DIRECTORY Directory;
    FILE_CONTEXT FileContext;
    FAT_FILE_HANDLE hFile;
    alt_u8 szHeader[128];
    char szWaveFilename[MAX_FILENAME_LENGTH];
    int sample_rate;
    bool bFlag = FALSE;
    int nPos = 0;
    int length=0;
    //
    gWavePlayList.nFileNum = 0;
    if (!Fat_FileBrowseBegin(hFat,&hFileBrowse)){
        lcd_display("\rbrowse file fail.\n");
        return 0;
    } 
    
    //
    while (Fat_FileBrowseNext(&hFileBrowse,&FileContext)){
        if (FileContext.bLongFilename){
                nPos = 0;
                alt_u16 *pData16;
                alt_u8 *pData8;
                pData16 = (alt_u16 *)FileContext.szName;
                pData8 = FileContext.szName;
                while(*pData16){
                    if (*pData8 && *pData8 != ' ')
                        szWaveFilename[nPos++] = *pData8;
                    pData8++;
                    if (*pData8 && *pData8 != ' ')
                        szWaveFilename[nPos++] = *pData8;
                    pData8++;                    
                    //    
                    pData16++;
                }
                szWaveFilename[nPos] = 0;
                //printf("\n--Music Name:%s --\n",szWaveFilename);
            }else{
                strcpy(szWaveFilename,FileContext.szName);
                //printf("\n--Music Name:%s --\n",FileContext.szName);
            }       
            
            length= strlen(szWaveFilename);   
            if(length >= 4){
               if((szWaveFilename[length-1] =='V' || szWaveFilename[length-1] =='v')
                &&(szWaveFilename[length-2] == 'A' || szWaveFilename[length-2] =='a')
                &&(szWaveFilename[length-3] == 'W' || szWaveFilename[length-3] == 'w')
                &&(szWaveFilename[length-4] == '.')){
                   bFlag = TRUE;
                } 
            }
       
        if (bFlag){
            // parsing wave format
            hFile = Fat_FileOpen(hFat,szWaveFilename);
            if (!hFile){
                  lcd_display("\rwave file open fail.\n");
                  continue;
            }
            lcd_display("\rRead OK.\n");
            
            //memset(szHeader,0,sizeof(szHeader));
                    
            if (!Fat_FileRead(hFile, szHeader, sizeof(szHeader))){
                  lcd_display("\rwave file read fail.\n");
                  continue;
            }
            Fat_FileClose(hFile);
                
                        // check wave format
            sample_rate =  Wave_GetSampleRate(szHeader, sizeof(szHeader));           
            if (WAVE_IsWaveFile(szHeader, sizeof(szHeader)) &&
                is_supporrted_sample_rate(sample_rate) &&
                Wave_GetChannelNum(szHeader, sizeof(szHeader))==2 &&
                Wave_GetSampleBitNum(szHeader, sizeof(szHeader))==16){
                    strcpy(gWavePlayList.szFilename[count],szWaveFilename);
                    count++;
            }
        }
    } // while  
    gWavePlayList.nFileNum = count;
    
    //Fat_FileBrowseEnd(&hFileBrowse);   
    
    return count;
}

bool Fat_Test(FAT_HANDLE hFat, char *pDumpFile){
    bool bSuccess;
    int nCount = 0;
    FAT_BROWSE_HANDLE hBrowse;
    FILE_CONTEXT FileContext;
    
    bSuccess = Fat_FileBrowseBegin(hFat, &hBrowse);
    if (bSuccess){
        while(Fat_FileBrowseNext(&hBrowse, &FileContext)){
            if (FileContext.bLongFilename){
                alt_u16 *pData16;
                alt_u8 *pData8;
                pData16 = (alt_u16 *)FileContext.szName;
                pData8 = FileContext.szName;
                printf("[%d]", nCount);
                while(*pData16){
                    if (*pData8)
                        printf("%c", *pData8);
                    pData8++;
                    if (*pData8)
                        printf("%c", *pData8);
                    pData8++;                    
                    //    
                    pData16++;
                }
                printf("\n");
            }else{
                printf("---[%d]%s\n", nCount, FileContext.szName);
            }                
            nCount++;
        }    
    }
    if (bSuccess && pDumpFile && strlen(pDumpFile)){
        FAT_FILE_HANDLE hFile;
        hFile =  Fat_FileOpen(hFat, pDumpFile);
        if (hFile){
            char szRead[256];
            int nReadSize, nFileSize, nTotalReadSize=0;
            nFileSize = Fat_FileSize(hFile);
            if (nReadSize > sizeof(szRead))
                nReadSize = sizeof(szRead);
            printf("%s dump:\n", pDumpFile);
            while(bSuccess && nTotalReadSize < nFileSize){
                nReadSize = sizeof(szRead);
                if (nReadSize > (nFileSize - nTotalReadSize))
                    nReadSize = (nFileSize - nTotalReadSize);
                //    
                if (Fat_FileRead(hFile, szRead, nReadSize)){
                    int i;
                    for(i=0;i<nReadSize;i++){
                        printf("%c", szRead[i]);
                    }
                    nTotalReadSize += nReadSize;
                }else{
                    bSuccess = FALSE;
                    printf("\nFaied to read the file \"%s\"\n", pDumpFile);
                }     
            } // while
            if (bSuccess)
                printf("\n");
            Fat_FileClose(hFile);
        }else{            
            bSuccess = FALSE;
            printf("Cannot find the file \"%s\"\n", pDumpFile);
        }            
    }
    
    return bSuccess;
}



/* ------------------------------ Wav output function ----------------------------------- */

bool waveplay_start(char *pFilename){
    bool bSuccess;
    int nSize;
    //waveplay_stop();
    
  //  strcpyn(gWavePlay.szFilename, pFilename, FILENAME_LEN-1);
    strcpy(gWavePlay.szFilename, pFilename);
    gWavePlay.hFile = Fat_FileOpen(hFat, pFilename);
    if (!gWavePlay.hFile)
        lcd_display("\rwave file open fail.\n");
    
    //gWavePlay.szBuf = Fat_FileSize(gWavePlay.hFile);
    nSize = Fat_FileSize(gWavePlay.hFile);

    if (gWavePlay.hFile){                    
        bSuccess = Fat_FileRead(gWavePlay.hFile, gWavePlay.szBuf, WAVE_BUF_SIZE);
        if (!bSuccess)
            lcd_display("\rwave file read fail.\n");
    }            
                
                        // check wave format
    if (bSuccess){      
            int sample_rate =  Wave_GetSampleRate(gWavePlay.szBuf, WAVE_BUF_SIZE);                 
            if (WAVE_IsWaveFile(gWavePlay.szBuf, WAVE_BUF_SIZE) &&
                is_supporrted_sample_rate(sample_rate) &&
                Wave_GetChannelNum(gWavePlay.szBuf, WAVE_BUF_SIZE)==2 &&
                Wave_GetSampleBitNum(gWavePlay.szBuf, WAVE_BUF_SIZE)==16){
                    
                gWavePlay.uWavePlayPos = Wave_GetWaveOffset(gWavePlay.szBuf, WAVE_BUF_SIZE);
                gWavePlay.uWaveMaxPlayPos = gWavePlay.uWavePlayPos + Wave_GetDataByteSize(gWavePlay.szBuf, WAVE_BUF_SIZE);
                gWavePlay.uWaveReadPos = WAVE_BUF_SIZE;

                // setup sample rate
                AUDIO_SetSampleRate(RATE_ADC44K1_DAC44K1);
                AUDIO_FifoClear();
                AUDIO_InterfaceActive(TRUE);
   
            }else{
                bSuccess = FALSE;
            }    
    }            

    if (!bSuccess)
        waveplay_stop();    
    
    return bSuccess;
}

bool waveplay_execute(bool *bEOF){
    bool bSuccess = TRUE;
    bool bDataReady = FALSE;
   
    
    // end of play data !
    if (gWavePlay.uWavePlayPos >= gWavePlay.uWaveMaxPlayPos){
        *bEOF = TRUE;
        return TRUE;
    }
    
    //
    *bEOF = FALSE;
    while (!bDataReady && bSuccess){
        if (gWavePlay.uWavePlayPos < gWavePlay.uWaveReadPos){
            bDataReady = TRUE;
            //DEBUG_PRINTF("it is not neccessary to read data from sd-card\r\n");
        }else{
            int read_size = WAVE_BUF_SIZE;
            if (read_size > (gWavePlay.uWaveMaxPlayPos - gWavePlay.uWavePlayPos))
                read_size = gWavePlay.uWaveMaxPlayPos - gWavePlay.uWavePlayPos;
            bSuccess = Fat_FileRead(gWavePlay.hFile, gWavePlay.szBuf, read_size);
            if (bSuccess)
                gWavePlay.uWaveReadPos += read_size;
            else    
                lcd_display("\rsdcard read fail\n");
        }  
    }

    if (bDataReady && bSuccess){
        int play_size; 
        short *pSample = (short *)(gWavePlay.szBuf + gWavePlay.uWavePlayPos%WAVE_BUF_SIZE);
        int i = 0;
        play_size = gWavePlay.uWaveReadPos - gWavePlay.uWavePlayPos;
        play_size = play_size/4*4;
        while(i < play_size){
            if(AUDIO_DacFifoNotFull()){ // if audio ready (not full)
                short ch_right, ch_left;
                ch_left = *pSample++;
                ch_right = *pSample++;

                AUDIO_DacFifoSetData(ch_left, ch_right); // play wave
                i+=4;
            }
        } // while
        gWavePlay.uWavePlayPos += play_size;
                    
    }
    
    return bSuccess;
}

/* ------------------------------ Interrupt handler ----------------------------------- */

void IRDA_init()
{
    alt_irq_register(TERASIC_IRDA_0_IRQ,0,handle_IrDA);            //irda irq register
    alt_irq_enable_all(TERASIC_IRDA_0_IRQ);
    IOWR(TERASIC_IRDA_0_BASE,0,0);
}

//modify this
void handle_IrDA(bool * p,alt_u32 id){
    static bool bFirsTime2SetupVol = TRUE;
    alt_u32 button;
    bool bLastSong,bNextSong, bVolUp, bVolDown,bMute,bPlay;
    int nHwVol;
   
    button = IORD(TERASIC_IRDA_0_BASE,0);
    button <<= 8;
    button >>= 24;
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(TERASIC_IRDA_0_BASE, 0); // clear flag 
    
    IOWR(TERASIC_IRDA_0_BASE,0,0);
    bLastSong = (button == 0x1a) ? TRUE : FALSE;
    bNextSong = (button == 0x1e) ? TRUE : FALSE;
    bVolUp    = (button == 0x1b) ? TRUE : FALSE;
    bVolDown  = (button == 0x1f) ? TRUE : FALSE;
    bMute     = (button == 0x0c) ? TRUE : FALSE;
    bPlay     = (button == 0x16) ? TRUE : FALSE;
   
    
    if(bPlay){
        bPlaySwitch = !bPlaySwitch;
        if(bPlaySwitch)
           printf("Play Continue...\r\n");
        else
           printf("Play Pause...\r\n");
        AUDIO_InterfaceActive(bPlaySwitch);
    }
}

int main(void)
{
	// usb_init();

	if (audio_init() == 0)
	{
		printf("Audio init failed");
		return 1;
	}

	//usleep(10000);
	while(1)
	{
		// usb_getkey();

		bool bSdacrdReady = TRUE;
        nPlayIndex = 0;
        while(bSdacrdReady){
            // find a wave file
            bool bPlayDone = FALSE;
            // strcpy(szWaveFile, "background.wav");
            if (!waveplay_start("background.wav")){
                lcd_display("Play Error.\n\n");
                bSdacrdReady = FALSE;
            }                
            update_status();
            while(!bPlayDone && bSdacrdReady){
                bool bEndOfFile = FALSE;
                // play wave file
                if (!waveplay_execute(&bEndOfFile)){
                    lcd_display("Play Error.\n\n");
                    bSdacrdReady = FALSE;
                }    
                
                // handle bullet?
                // handle_key(&bNextSongPressed);

                //repeat
                if (bSdacrdReady && bEndOfFile)                    
                    bPlayDone = TRUE;
                
            }  // while(!bPlayNextSong && bSdacrdReady)
            // waveplay_stop();    
        }  // while(bSdacrdReady)

	}//end while

	return 0;
}

