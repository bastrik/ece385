//io_handler.c
#include "io_handler.h"
#include <stdio.h>

void IO_init(void)
{
	*otg_hpi_reset = 1;
	*otg_hpi_cs = 1;
	*otg_hpi_r = 1;
	*otg_hpi_w = 1;
	*otg_hpi_address = 0;
	*otg_hpi_data = 0;
	// Reset OTG chip
	*otg_hpi_cs = 0;
	*otg_hpi_reset = 0;
	*otg_hpi_reset = 1;
	*otg_hpi_cs = 1;
}
/*
 *	Active low, IO_write implementation to the OTG 
 */
void IO_write(alt_u8 Address, alt_u16 Data)
{
	// Init
	*otg_hpi_cs = 0;				// Select chip (handshake)
	*otg_hpi_address = Address;		// Populate address
	*otg_hpi_data = Data;			// Populate data
	// Control
	*otg_hpi_w = 0;					// Write Enable
	*otg_hpi_w = 1;
	*otg_hpi_cs = 1;				// Terminate handshake
}

alt_u16 IO_read(alt_u8 Address)
{
	alt_u16 ret;

	*otg_hpi_cs = 0;				// Select chip (handshake)
	*otg_hpi_address = Address;		// Populate address
	*otg_hpi_r = 0;

	ret = *otg_hpi_data;
	*otg_hpi_r = 1;
	*otg_hpi_cs = 1;
	//printf("%x\n",temp);
	return ret;
}
