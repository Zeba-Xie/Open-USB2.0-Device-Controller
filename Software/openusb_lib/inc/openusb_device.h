#ifndef __OPENUSB_DEVICE_H__
#define __OPENUSB_DEVICE_H__

#include "openusb_common.h"
#include "openusb_defs.h"
#include "openusb_desc.h"

//-----------------------------------------------------------------
// Types
//-----------------------------------------------------------------
typedef void (*FP_CLASS_REQUEST) (unsigned char req, unsigned short wValue, unsigned short WIndex, unsigned char *data, unsigned short wLength);
typedef void (*FP_BUS_RESET)(void);

int usb_control_send(uint8_t *buf, int size, int requeseted_size);
void usbf_init(unsigned int base, FP_BUS_RESET bus_reset, FP_CLASS_REQUEST class_request);

#endif
