
#include "openusb_cdc.h"


//-----------------------------------------------------------------
// Locals:
//-----------------------------------------------------------------
static unsigned char _line_coding[7];

//-----------------------------------------------------------------
// cdc_set_line_coding:
//-----------------------------------------------------------------
static void cdc_set_line_coding(unsigned char *data)
{
	int i;

	for (i=0; i<7; i++)
		_line_coding[i] = data[i];

    DEBUG_INFO("CDC: Set Line Coding\n");
}
//-----------------------------------------------------------------
// cdc_get_line_coding:
//-----------------------------------------------------------------
static void cdc_get_line_coding(unsigned short wLength)
{
    DEBUG_INFO("CDC: Get Line Coding\n");

	usb_control_send( _line_coding, sizeof(_line_coding), wLength );	
}
//-----------------------------------------------------------------
// cdc_set_control_line_state:
//-----------------------------------------------------------------
static void cdc_set_control_line_state(void)
{
    DEBUG_INFO("CDC: Set Control Line State\n");
	openusb_control_endpoint_send_status();
}
//-----------------------------------------------------------------
// cdc_send_break:
//-----------------------------------------------------------------
static void cdc_send_break(void)
{
    DEBUG_INFO("CDC: Send Break\n");
	openusb_control_endpoint_send_status();
}
//-----------------------------------------------------------------
// cdc_send_encapsulated_command:
//-----------------------------------------------------------------
static void cdc_send_encapsulated_command (void)
{
    DEBUG_INFO("CDC: Send encap\n");
}
//-----------------------------------------------------------------
// cdc_get_encapsulated_response:
//-----------------------------------------------------------------
static void cdc_get_encapsulated_response (unsigned short wLength)
{
    DEBUG_INFO("CDC: Get encap\n");

	openusb_control_endpoint_stall();
}
//-----------------------------------------------------------------
// usb_cdc_process_request:
//-----------------------------------------------------------------
void usb_cdc_process_request(unsigned char req, unsigned short wValue, unsigned short WIndex, unsigned char *data, unsigned short wLength)
{
	switch ( req )
	{
	case CDC_SEND_ENCAPSULATED_COMMAND:
        DEBUG_INFO("CDC: Send encap\n");
	    cdc_send_encapsulated_command();
	    break;
	case CDC_GET_ENCAPSULATED_RESPONSE:
        DEBUG_INFO("CDC: Get encap\n");
	    cdc_get_encapsulated_response(wLength);
	    break;
	case CDC_SET_LINE_CODING:
        DEBUG_INFO("CDC: Set line coding\n");
	    cdc_set_line_coding(data);
	    break;
	case CDC_GET_LINE_CODING:
        DEBUG_INFO("CDC: Get line coding\n");
	    cdc_get_line_coding(wLength);
	    break;
	case CDC_SET_CONTROL_LINE_STATE:
        DEBUG_INFO("CDC: Set line state\n");
	    cdc_set_control_line_state();
	    break;
	case CDC_SEND_BREAK:
        DEBUG_INFO("CDC: Send break\n");
	    cdc_send_break();
	    break;
	default:
        DEBUG_INFO("CDC: Unknown command\n");
		openusb_control_endpoint_stall();
		break;
	}
}
//-----------------------------------------------------------------
// usb_cdc_init:
//-----------------------------------------------------------------
void usb_cdc_init(void)
{
	_line_coding[0] = 0x00;          // UART baud rate (32-bit word, LSB first)
	_line_coding[1] = 0xC2;
	_line_coding[2] = 0x01;
	_line_coding[3] = 0x00;
	_line_coding[4] = 0;             // stop bit #2
	_line_coding[5] = 0;             // parity
	_line_coding[6] = 8;             // data bits
}
