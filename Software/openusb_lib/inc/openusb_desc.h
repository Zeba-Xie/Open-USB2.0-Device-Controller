#ifndef __OPENUSB_DESC_H__
#define __OPENUSB_DESC_H__

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "openusb_defs.h"


unsigned char *usb_get_descriptor( unsigned char bDescriptorType, unsigned char bDescriptorIndex, unsigned short wLength, unsigned char *pSize );
int usb_is_bus_powered(void);


#endif
