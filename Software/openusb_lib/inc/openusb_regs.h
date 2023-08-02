#ifndef __OPENUSB_REGS_H__
#define __OPENUSB_REGS_H__

#include <stdio.h>
// #include "demosoc.h"

//-----------------------------------------------------------------
// define
//-----------------------------------------------------------------
typedef volatile unsigned int reg32_t;
#define OPEN_USB_READ_REG(addr) (*(reg32_t *)(addr))
#define OPEN_USB_WRITE_REG(addr, wdata) (*(reg32_t *)(addr) = (wdata))

//-----------------------------------------------------------------
// addr
//-----------------------------------------------------------------
#define  USB_BASE        (0x10042000)

#define  USB_FUNC_CTRL   (USB_BASE | 0x00)
#define  USB_FUNC_STAT   (USB_BASE | 0x04)
#define  USB_FUNC_ADDR   (USB_BASE | 0x08)
#define  USB_EP_INTSTS   (USB_BASE | 0x0C)

#define  USB_EP0_CFG     (USB_BASE | 0x20)
#define  USB_EP0_TX_CTRL (USB_BASE | 0x24)
#define  USB_EP0_RX_CTRL (USB_BASE | 0x28)
#define  USB_EP0_STS     (USB_BASE | 0x2C)
#define  USB_EP0_DATA    (USB_BASE | 0x30)

#define  USB_EP1_CFG     (USB_BASE | 0x40)
#define  USB_EP1_TX_CTRL (USB_BASE | 0x44)
#define  USB_EP1_RX_CTRL (USB_BASE | 0x48)
#define  USB_EP1_STS     (USB_BASE | 0x4C)
#define  USB_EP1_DATA    (USB_BASE | 0x50)


#define  USB_EP_STRIDE   (0x20)

#define  USB_EP_CFG(ep)         (USB_EP0_CFG     + (ep * USB_EP_STRIDE))
#define  USB_EP_TX_CTRL(ep)     (USB_EP0_TX_CTRL + (ep * USB_EP_STRIDE))
#define  USB_EP_RX_CTRL(ep)     (USB_EP0_RX_CTRL + (ep * USB_EP_STRIDE))
#define  USB_EP_STS(ep)         (USB_EP0_STS     + (ep * USB_EP_STRIDE))
#define  USB_EP_DATA(ep)        (USB_EP0_DATA    + (ep * USB_EP_STRIDE))



//-----------------------------------------------------------------
// USB_FUNC_CTRL
//-----------------------------------------------------------------
typedef union _OPEN_USB_FUNC_CTRL_TypeDef
{
    uint32_t d32;
    struct 
    {
        uint32_t int_en_sof :
        1;
        uint32_t phy_opmode :
        2;
        uint32_t phy_xcvrselect :
        2;
        uint32_t phy_termselect :
        1;
        uint32_t phy_dppulldown :
        1;
        uint32_t phy_dmpulldown :
        1;
        uint32_t hs_chirp_en :
        1;
        uint32_t int_en_rst :
        1;
        uint32_t reserved10_31 :
        (32-10);
    }
    b;
    
} OPEN_USB_FUNC_CTRL_TypeDef;

//-----------------------------------------------------------------
// USB_FUNC_STAT
//-----------------------------------------------------------------
typedef union _OPEN_USB_FUNC_STAT_TypeDef{
    uint32_t d32;
    struct
    {
        uint32_t frame :
        11;
        uint32_t linestate :
        2;
        uint32_t rst : // W1C
        1;
        uint32_t sof : // W1C
        1;
        uint32_t reserved15_31 :
        (32-15);
    }
    b;
} OPEN_USB_FUNC_STAT_TypeDef;

//-----------------------------------------------------------------
// USB_FUNC_ADDR
//-----------------------------------------------------------------
typedef union _OPEN_USB_FUNC_ADDR_TypeDef{
    uint32_t d32;
    struct {
        uint32_t dev_addr :
        7;
        uint32_t reserved7_31 :
        (32-7);
    }
    b;
} OPEN_USB_FUNC_ADDR_TypeDef;

//-----------------------------------------------------------------
// USB_EPx_CFG
//-----------------------------------------------------------------
typedef union _OPEN_USB_EPx_CFG_TypeDef{
    uint32_t d32;
    struct {
        uint32_t iso :
        1;
        uint32_t stall_ep :
        1;
        uint32_t int_tx :
        1;
        uint32_t int_rx :
        1;
        uint32_t reserved4_31 :
        (32-4);
    }
    b;
} OPEN_USB_EPx_CFG_TypeDef;

//-----------------------------------------------------------------
// USB_EPx_TX_CTRL
//-----------------------------------------------------------------
typedef union _OPEN_USB_EPx_TX_CTRL_TypeDef{
    uint32_t d32;
    struct {
        uint32_t tx_len :
        11;
        uint32_t reserved11_15 :
        5;
        uint32_t tx_start :
        1;
        uint32_t tx_flush :
        1;
        uint32_t reserved18_31 :
        (32-18);
    }
    b;
} OPEN_USB_EPx_TX_CTRL_TypeDef;

//-----------------------------------------------------------------
// USB_EPx_RX_CTRL
//-----------------------------------------------------------------
typedef union _OPEN_USB_EPx_RX_CTRL_TypeDef{
    uint32_t d32;
    struct {
        uint32_t rx_accept :
        1;
        uint32_t rx_flush :
        1;
        uint32_t reserved2_31 :
        (32-2);
    }
    b;
} OPEN_USB_EPx_RX_CTRL_TypeDef;

//-----------------------------------------------------------------
// USB_EPx_STS
//-----------------------------------------------------------------
typedef union _OPEN_USB_EPx_STS_TypeDef{
    uint32_t d32;
    struct {
        uint32_t rx_count :
        11;
        uint32_t reserved11_15 :
        5;
        uint32_t rx_ready :
        1;
        uint32_t rx_setup :
        1;
        uint32_t rx_err :
        1;
        uint32_t tx_busy :
        1;
        uint32_t tx_err :
        1;
        uint32_t reserved21_31 :
        (32-21);
    }
    b;
} OPEN_USB_EPx_STS_TypeDef;

//-----------------------------------------------------------------
// USB_EP_INTSTS
//-----------------------------------------------------------------
typedef union _OPEN_USB_EP_INTSTS_TypeDef{
    uint32_t d32;
    struct {
        uint32_t ep0_rx_ready :    // W1C
        1;
        uint32_t ep1_rx_ready :    // W1C
        1;
        uint32_t ep2_rx_ready :    // W1C
        1;
        uint32_t ep3_rx_ready :    // W1C
        1;
        
        uint32_t reserved4_15 :
        (16-4);

        uint32_t ep0_tx_complete : // W1C
        1;
        uint32_t ep1_tx_complete : // W1C
        1;
        uint32_t ep2_tx_complete : // W1C
        1;
        uint32_t ep3_tx_complete : // W1C
        1;

        uint32_t reserved20_31 :
        (32-20);
    }
    b;
} OPEN_USB_EP_INTSTS_TypeDef;


#endif
