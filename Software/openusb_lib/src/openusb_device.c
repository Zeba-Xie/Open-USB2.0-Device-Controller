#include "openusb_device.h"



//-----------------------------------------------------------------
// Types
//-----------------------------------------------------------------

// SETUP packet data format
typedef struct _DEVICE_REQUEST_TypeDef
{
    uint8_t  bmRequestType;
    uint8_t  bRequest;
    uint16_t wValue;
    uint16_t wIndex;
    uint16_t wLength;
} DEVICE_REQUEST_TypeDef;

typedef struct _CONTROL_TRANSFER_TypeDef
{
    // SETUP packet
    DEVICE_REQUEST_TypeDef  request;

    // DATA(OUT) stage expected?
    int                     data_expected;

    // Data buffer
    uint8_t                 data_buffer[MAX_CTRL_DATA_LENGTH];

    // Data received index
    int                     data_idx;

} CONTROL_TRANSFER_TypeDef;


//-----------------------------------------------------------------
// Locals:
//-----------------------------------------------------------------
static CONTROL_TRANSFER_TypeDef _ctrl_xfer;
static int                      _remote_wake_enabled;
static FP_CLASS_REQUEST         _class_request;

//-----------------------------------------------------------------
// usb_control_send: Perform a transfer via IN
//-----------------------------------------------------------------
int usb_control_send(uint8_t *buf, int size, int requested_size){
    int send;
    int remain;
    int count = 0;
    int err = 0;

    OPEN_USB_EPx_CFG_TypeDef ep_cfg;

    // Mask the ep 0 rx_ready intr
    ep_cfg.d32 = OPEN_USB_READ_REG(USB_EP_CFG(ENDPOINT_CONTROL));
    ep_cfg.b.int_rx = 0;
    OPEN_USB_WRITE_REG(USB_EP_CFG(ENDPOINT_CONTROL), ep_cfg.d32);

    DEBUG_INFO("USB: usb_control_send %d\n", size);

    // Loop until partial packet sent
    do
    {
        remain = size - count;
        send = MIN(remain, EP0_MAX_PACKET_SIZE);

        DEBUG_INFO(" Remain %d, Send %d\n", remain, send);

        // Do not send ZLP if requested size was size transferred
        if (remain == 0 && size == requested_size)
            break;

        openusb_tx_data(ENDPOINT_CONTROL, buf, send);

        buf += send;
        count += send;

        DEBUG_INFO(" Sent %d, Remain %d\n", send, (size - count));

        while ( !openusb_has_tx_space( ENDPOINT_CONTROL ) )
        {
            // Give up on early OUT (STATUS stage)
            if (openusb_is_rx_ready(ENDPOINT_CONTROL))
            {
                DEBUG_INFO("USB: Early ACK received...\n");
                break;
            }
        }
    }
    while (send >= EP0_MAX_PACKET_SIZE);

    if (!err)
    {
        DEBUG_INFO("USB: Sent total %d\n", count);

        // Wait for ACK from host
        do
        {
            
        } 
        while (!openusb_is_rx_ready(ENDPOINT_CONTROL));

        openusb_clear_rx_ready_flag(ENDPOINT_CONTROL);

        if (!err)
        {
            DEBUG_INFO("USB: ACK received\n");
        }
    }

    // Unmask the ep 0 rx_ready intr
    ep_cfg.b.int_rx = 1;
    OPEN_USB_WRITE_REG(USB_EP_CFG(ENDPOINT_CONTROL), ep_cfg.d32);

    return !err;
}

//-----------------------------------------------------------------
// get_status:
//-----------------------------------------------------------------
static void get_status(DEVICE_REQUEST_TypeDef *request)
{    
    uint8_t bRecipient = request->bmRequestType & USB_RECIPIENT_MASK;
    uint8_t data[2] = {0, 0};

    DEBUG_INFO("USB: Get Status %x\n", bRecipient);

    if ( bRecipient == USB_RECIPIENT_DEVICE )
    {
        // Self-powered
        if (!usb_is_bus_powered()) 
            data[0] |= (1 << 0);

        // Remote Wake-up enabled
        if (_remote_wake_enabled) 
            data[0] |= (1 << 1);

        usb_control_send( data, 2, request->wLength );
    }
    else if ( bRecipient == USB_RECIPIENT_INTERFACE )
    {
        usb_control_send( data, 2, request->wLength );
    }
    else if ( bRecipient == USB_RECIPIENT_ENDPOINT )
    {
        if (openusb_is_endpoint_stalled( request->wIndex & ENDPOINT_ADDR_MASK)) 
            data[0] = 1;
        usb_control_send( data, 2, request->wLength );
    }
    else
        openusb_control_endpoint_stall();
}

//-----------------------------------------------------------------
// clear_feature:
//-----------------------------------------------------------------
static void clear_feature(DEVICE_REQUEST_TypeDef *request)
{
    uint8_t bRecipient = request->bmRequestType & USB_RECIPIENT_MASK;

    DEBUG_INFO("USB: Clear Feature %x\n", bRecipient);

    if ( bRecipient == USB_RECIPIENT_DEVICE )
    {
        if ( request->wValue == USB_FEATURE_REMOTE_WAKEUP )
        {
            DEBUG_INFO("USB: Disable remote wake\n");
            _remote_wake_enabled = 0;
            openusb_control_endpoint_send_status();
        }
        else if ( request->wValue == USB_FEATURE_TEST_MODE )
        {
            DEBUG_INFO("USB: Disable test mode\n");
            openusb_control_endpoint_send_status();
        }
        else
            openusb_control_endpoint_stall();
    }
    else if ( bRecipient == USB_RECIPIENT_ENDPOINT && 
              request->wValue == USB_FEATURE_ENDPOINT_STATE )
    {
        openusb_control_endpoint_send_status();
        openusb_clear_endpoint_stall( request->wIndex & ENDPOINT_ADDR_MASK );
    }
    else
        openusb_control_endpoint_stall();
}

//-----------------------------------------------------------------
// set_feature:
//-----------------------------------------------------------------
static void set_feature(DEVICE_REQUEST_TypeDef *request)
{
    unsigned char bRecipient = request->bmRequestType & USB_RECIPIENT_MASK;

    DEBUG_INFO("USB: Set Feature %x\n", bRecipient);

    if ( bRecipient == USB_RECIPIENT_DEVICE )
    {
        if ( request->wValue == USB_FEATURE_REMOTE_WAKEUP )
        {
            DEBUG_INFO("USB: Enable remote wake\n");
            _remote_wake_enabled = 1;
            openusb_control_endpoint_send_status();
        }
        else if ( request->wValue == USB_FEATURE_TEST_MODE )
        {
            DEBUG_INFO("USB: Enable test mode\n");
            openusb_control_endpoint_send_status();
        }
        else
            openusb_control_endpoint_stall();
    }
    else if ( bRecipient == USB_RECIPIENT_ENDPOINT && 
              request->wValue == USB_FEATURE_ENDPOINT_STATE )
    {
        openusb_control_endpoint_send_status();
        openusb_set_endpoint_stall(request->wIndex & ENDPOINT_ADDR_MASK);
    }
    else
        openusb_control_endpoint_stall();
}

//-----------------------------------------------------------------
// set_address:
//-----------------------------------------------------------------
static void set_address(DEVICE_REQUEST_TypeDef *request)
{
    unsigned char addr = (LO_BYTE(request->wValue)) & USB_ADDRESS_MASK;
    
    openusb_set_address(addr);
    openusb_control_endpoint_send_status();

    DEBUG_INFO("USB: Set address %x\n", addr);
}

//-----------------------------------------------------------------
// get_descriptor:
//-----------------------------------------------------------------
static void get_descriptor(DEVICE_REQUEST_TypeDef *request)
{
    unsigned char  bDescriptorType = HI_BYTE(request->wValue);
    unsigned char  bDescriptorIndex = LO_BYTE( request->wValue );
    unsigned short wLength = request->wLength;
    unsigned char  bCount = 0;
    unsigned char *desc_ptr;

    desc_ptr = usb_get_descriptor(bDescriptorType, bDescriptorIndex, wLength, &bCount);

    unsigned short i, actual_len;
    actual_len = MIN(wLength, 18);
    DEBUG_INFO("USB: Descriptor:\n");
    for(i=0; i<(actual_len); i++){
        DEBUG_INFO("%x ", desc_ptr[i]);
    }
    DEBUG_INFO("\n");

    if (desc_ptr)
        usb_control_send(desc_ptr, bCount, request->wLength);
    else
        openusb_control_endpoint_stall();
}

//-----------------------------------------------------------------
// get_configuration:
//-----------------------------------------------------------------
static void get_configuration(DEVICE_REQUEST_TypeDef *request)
{
    unsigned char conf = openusb_is_configured() ? 1 : 0;

    DEBUG_INFO("USB: Get configuration %x\n", conf);

    usb_control_send( &conf, 1, request->wLength );
}

//-----------------------------------------------------------------
// set_configuration:
//-----------------------------------------------------------------
static void set_configuration(DEVICE_REQUEST_TypeDef *request)
{
    DEBUG_INFO("USB: set_configuration %x\n", request->wValue);

    if ( request->wValue == 0 )
    {
        openusb_control_endpoint_send_status();
        openusb_set_configured(0);
    }
    // Only support one configuration for now
    else if ( request->wValue == 1 )
    {
        openusb_control_endpoint_send_status();
        openusb_set_configured(1);
    }
    else
        openusb_control_endpoint_stall();
}

//-----------------------------------------------------------------
// get_interface:
//-----------------------------------------------------------------
static void get_interface(DEVICE_REQUEST_TypeDef *request)
{
    DEBUG_INFO("USB: Get interface\n");
    openusb_control_endpoint_stall();
}

//-----------------------------------------------------------------
// set_interface:
//-----------------------------------------------------------------
static void set_interface(DEVICE_REQUEST_TypeDef *request)
{
    DEBUG_INFO("USB: set_interface %x %x\n", request->wValue, request->wIndex);

    if ( request->wValue == 0 && request->wIndex == 0 )
        openusb_control_endpoint_send_status();
    else
        openusb_control_endpoint_stall();
}

//-----------------------------------------------------------------
// set_descriptor:
//-----------------------------------------------------------------
static void set_descriptor(DEVICE_REQUEST_TypeDef *request, unsigned char *data)
{
    DEBUG_INFO("USB: set_descriptor %x %x %x\n", request->wValue, request->wIndex, request->wLength);

    uint16_t i=0;

    DEBUG_INFO("Set data: ");
    for(i=0; i < request->wLength; i++)
        DEBUG_INFO("[%x] ", *(data + i));
    DEBUG_INFO("\n");
}

//-----------------------------------------------------------------
// usb_process_request:
//-----------------------------------------------------------------
static void usb_process_request(DEVICE_REQUEST_TypeDef *request, unsigned char type, unsigned char req, unsigned char *data)
{
    if ( type == USB_STANDARD_REQUEST )
    {
        // Standard requests
        switch (req)
        {
        case REQ_GET_STATUS:
            get_status(request);
            break;
        case REQ_CLEAR_FEATURE:
            clear_feature(request);
            break;
        case REQ_SET_FEATURE:
            set_feature(request);
            break;
        case REQ_SET_ADDRESS:
            set_address(request);
            break;
        case REQ_GET_DESCRIPTOR:
            get_descriptor(request);
            break;
        case REQ_GET_CONFIGURATION:
            get_configuration(request);
            break;
        case REQ_SET_CONFIGURATION:
            set_configuration(request);
            break;
        case REQ_GET_INTERFACE:
            get_interface(request);
            break;
        case REQ_SET_INTERFACE:
            set_interface(request);
            break;
        case REQ_SET_DESCRIPTOR:
            set_descriptor(request, data);
            break;
        default:
            DEBUG_INFO("USB: Unknown standard request %x\n", req);
            openusb_control_endpoint_stall();
            break;
        }
    }
    else if ( type == USB_VENDOR_REQUEST )
    {
        DEBUG_INFO("Vendor: Unknown command\n");

        // None supported
        openusb_control_endpoint_stall();
    }
    else if ( type == USB_CLASS_REQUEST && _class_request)
    {
        _class_request(req, request->wValue, request->wIndex, data, request->wLength);
    }
    else
        openusb_control_endpoint_stall();
}

//-----------------------------------------------------------------
// usb_process_setup: Process SETUP packet
//-----------------------------------------------------------------
static void usb_process_setup(void)
{
    uint8_t type, req;
    uint8_t setup_pkt[EP0_MAX_PACKET_SIZE];
    uint16_t len;

    len=openusb_get_rx_data(ENDPOINT_CONTROL, setup_pkt, EP0_MAX_PACKET_SIZE);
    openusb_clear_rx_ready_flag(ENDPOINT_CONTROL);

    #if (LOG_SETUP_PACKET)
    {
        int i;

        DEBUG_INFO("USB: SETUP data %d bytes\n", len);
        
        for (i=0;i<len;i++)
            DEBUG_INFO("%02x ", setup_pkt[i]);

        DEBUG_INFO("\n");
    }
    #endif

    // Extract packet to local endian format
    _ctrl_xfer.request.bmRequestType = setup_pkt[0];
    _ctrl_xfer.request.bRequest      = setup_pkt[1];
    _ctrl_xfer.request.wValue        = setup_pkt[3];
    _ctrl_xfer.request.wValue      <<= 8;
    _ctrl_xfer.request.wValue       |= setup_pkt[2];
    _ctrl_xfer.request.wIndex        = setup_pkt[5];
    _ctrl_xfer.request.wIndex      <<= 8;
    _ctrl_xfer.request.wIndex       |= setup_pkt[4];
    _ctrl_xfer.request.wLength       = setup_pkt[7];
    _ctrl_xfer.request.wLength     <<= 8;
    _ctrl_xfer.request.wLength      |= setup_pkt[6];

    _ctrl_xfer.data_idx      = 0;
    _ctrl_xfer.data_expected = 0;

    type = _ctrl_xfer.request.bmRequestType & USB_REQUEST_TYPE_MASK;
    req  = _ctrl_xfer.request.bRequest;

    // SETUP - GET
    if (_ctrl_xfer.request.bmRequestType & ENDPOINT_DIR_IN)
    {
        DEBUG_INFO("USB: SETUP Get wValue=0x%x wIndex=0x%x wLength=%d\n", 
                    _ctrl_xfer.request.wValue,
                    _ctrl_xfer.request.wIndex,
                    _ctrl_xfer.request.wLength);

        usb_process_request(&_ctrl_xfer.request, type, req, _ctrl_xfer.data_buffer);           
    }
    // SETUP - SET
    else
    {
        // No data
        if ( _ctrl_xfer.request.wLength == 0 )
        {
            DEBUG_INFO("USB: SETUP Set wValue=0x%x wIndex=0x%x wLength=%d\n", 
                                        _ctrl_xfer.request.wValue,
                                        _ctrl_xfer.request.wIndex,
                                        _ctrl_xfer.request.wLength);
            usb_process_request(&_ctrl_xfer.request, type, req, _ctrl_xfer.data_buffer);
        }
        // Data expected
        else
        {
            DEBUG_INFO("USB: SETUP Set wValue=0x%x wIndex=0x%x wLength=%d [OUT expected]\n", 
                                        _ctrl_xfer.request.wValue,
                                        _ctrl_xfer.request.wIndex,
                                        _ctrl_xfer.request.wLength);
            
            if ( _ctrl_xfer.request.wLength <= MAX_CTRL_DATA_LENGTH )
            {
                // OUT packets expected to follow containing data
                _ctrl_xfer.data_expected = 1;
            }
            // Error: Too much data!
            else
            {
                DEBUG_INFO("USB: More data than max transfer size\n");
                openusb_control_endpoint_stall();
            }
        }
    }
}

//-----------------------------------------------------------------
// usb_process_out: Process OUT (on control EP0)
//-----------------------------------------------------------------
static void usb_process_out(void)
{
    unsigned short received;
    unsigned char type;
    unsigned char req;

    // Error: Not expecting DATA-OUT!
    if (!_ctrl_xfer.data_expected)
    {
        DEBUG_INFO("USB: (EP0) OUT received but not expected, STALL\n");
        openusb_control_endpoint_stall();
    }
    else
    {
        received = openusb_get_rx_count( ENDPOINT_CONTROL );

        DEBUG_INFO("USB: OUT received (%d bytes)\n", received);

        if ( (_ctrl_xfer.data_idx + received) > MAX_CTRL_DATA_LENGTH )
        {
            DEBUG_INFO("USB: Too much OUT EP0 data %d > %d, STALL\n", (_ctrl_xfer.data_idx + received), MAX_CTRL_DATA_LENGTH);
            openusb_control_endpoint_stall();
        }
        else
        {
            openusb_get_rx_data(ENDPOINT_CONTROL, &_ctrl_xfer.data_buffer[_ctrl_xfer.data_idx], received);
            openusb_clear_rx_ready_flag(ENDPOINT_CONTROL);
            _ctrl_xfer.data_idx += received;

            DEBUG_INFO("USB: OUT packet re-assembled %d\n", _ctrl_xfer.data_idx);

            // End of transfer (short transfer received?)
            if (received < EP0_MAX_PACKET_SIZE || _ctrl_xfer.data_idx >= _ctrl_xfer.request.wLength)
            {
                // Send ZLP (ACK for Status stage)
                DEBUG_INFO("USB: Send ZLP status stage %d %d\n", _ctrl_xfer.data_idx, _ctrl_xfer.request.wLength);

                openusb_control_endpoint_send_status();

                _ctrl_xfer.data_expected = 0;

                type = _ctrl_xfer.request.bmRequestType & USB_REQUEST_TYPE_MASK;
                req  = _ctrl_xfer.request.bRequest;

                usb_process_request(&_ctrl_xfer.request, type, req, _ctrl_xfer.data_buffer);
            }
            else
                DEBUG_INFO("DEV: More data expected!\n");
        }
    }
}

//-----------------------------------------------------------------
// usbf_init:
//-----------------------------------------------------------------
void usbf_init(unsigned int base, FP_BUS_RESET bus_reset, FP_CLASS_REQUEST class_request)
{
    _class_request = class_request;
    openusb_init(base, bus_reset, usb_process_setup, usb_process_out);
}
