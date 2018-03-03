// Main.c - makes LEDG0 on DE2-115 board blink if NIOS II is set up correctly
// for ECE 385 - University of Illinois - Electrical and Computer Engineering
// Author: Zuofu Cheng
void blinkLED();
int accumulator(int);


int main()
{
	volatile unsigned int *LED_PIO = (unsigned int*)0x50; //make a pointer to access the PIO block
	volatile unsigned int *SWITCH_PIO = (unsigned int*)0x20; 
	volatile unsigned int *BUTTON_PIO = (unsigned int*)0x30;
	*LED_PIO = 0; //clear all LEDs
	int tally = 0;

	while (1) //infinite loop
	{
		//blinkLED();
		tally = accumulator(tally);
	}
	return 1; //never gets here
}

void blinkLED()
{
	int i;
	for (i = 0; i < 100000; i++); //software delay
	*LED_PIO |= 0x1; //set LSB
	for (i = 0; i < 100000; i++); //software delay
	*LED_PIO &= ~0x1; //clear LSB
}

int accumulator(int tally)
{
	*LED_PIO = tally;
	if (*BUTTON_PIO == 0x1011)		// reset;
	{
		while(*BUTTON_PIO == 0x1011);
		tally = 0;
	}
	else if (*BUTTON_PIO == 0x0111)	// accumulate
	{
		while(*BUTTON_PIO == 0x0111);
		tally += *SWITCH_PIO;
		tally = tally % 256;
	}
	return tally;
}