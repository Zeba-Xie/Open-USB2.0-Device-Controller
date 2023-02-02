//=================================================================
// 
// Config defines
// This module contains bit field definitions and address of CSR
//
// Version: V1.0
// Created by Ultra-Embedded.com 
// http://github.com/ultraembedded/cores
// 
// Version: V2.0
// Modified by Zeba-Xie @github:
// .Added USB_EP_INTSTS
// .Adjusted address 
// .Added defines
//=================================================================

//-----------------------------------------------------------------
// USB_ITF_AHB
// define  : AHB slave interface
// undefine: Others
// warning : USB_ITF_AHB or USB_ITF_ICB must define one.
//-----------------------------------------------------------------
// `define USB_ITF_AHB

//-----------------------------------------------------------------
// USB_ITF_ICB
// define  : ICB slave interface (for E203)
// undefine: Others
// warning : USB_ITF_AHB or USB_ITF_ICB must define one.
//-----------------------------------------------------------------
`define USB_ITF_ICB

`ifdef USB_ITF_ICB
    // must define USB BASE ADDR
    `define USB_BASE_ADDR_31_12 20'h10042 
`endif

//-----------------------------------------------------------------
// USB_REG_FIFO
// define  : usbf_fifo uses ram by reg
// undefine: usbf_fifo uses GENERIC_MEM or FPGA
//-----------------------------------------------------------------
`define USB_REG_FIFO

//-----------------------------------------------------------------
// USB_EP_NUM: number of endpoints
//-----------------------------------------------------------------
`define USB_EP_NUM     4

//-----------------------------------------------------------------
// USB_EP_STRIDE: the address stride of EP regs
// Modification not supported
//-----------------------------------------------------------------
`define USB_EP_STRIDE  'h20

//-----------------------------------------------------------------
//                             GLOBAL
//-----------------------------------------------------------------
`define USB_FUNC_CTRL    8'h0

    `define USB_FUNC_CTRL_INT_EN_RST      9
    `define USB_FUNC_CTRL_INT_EN_RST_DEFAULT    0
    `define USB_FUNC_CTRL_INT_EN_RST_B          9
    `define USB_FUNC_CTRL_INT_EN_RST_T          9
    `define USB_FUNC_CTRL_INT_EN_RST_W          1
    `define USB_FUNC_CTRL_INT_EN_RST_R          9:9

    `define USB_FUNC_CTRL_HS_CHIRP_EN      8
    `define USB_FUNC_CTRL_HS_CHIRP_EN_DEFAULT    0
    `define USB_FUNC_CTRL_HS_CHIRP_EN_B          8
    `define USB_FUNC_CTRL_HS_CHIRP_EN_T          8
    `define USB_FUNC_CTRL_HS_CHIRP_EN_W          1
    `define USB_FUNC_CTRL_HS_CHIRP_EN_R          8:8

    `define USB_FUNC_CTRL_PHY_DMPULLDOWN      7
    `define USB_FUNC_CTRL_PHY_DMPULLDOWN_DEFAULT    0
    `define USB_FUNC_CTRL_PHY_DMPULLDOWN_B          7
    `define USB_FUNC_CTRL_PHY_DMPULLDOWN_T          7
    `define USB_FUNC_CTRL_PHY_DMPULLDOWN_W          1
    `define USB_FUNC_CTRL_PHY_DMPULLDOWN_R          7:7

    `define USB_FUNC_CTRL_PHY_DPPULLDOWN      6
    `define USB_FUNC_CTRL_PHY_DPPULLDOWN_DEFAULT    0
    `define USB_FUNC_CTRL_PHY_DPPULLDOWN_B          6
    `define USB_FUNC_CTRL_PHY_DPPULLDOWN_T          6
    `define USB_FUNC_CTRL_PHY_DPPULLDOWN_W          1
    `define USB_FUNC_CTRL_PHY_DPPULLDOWN_R          6:6

    `define USB_FUNC_CTRL_PHY_TERMSELECT      5
    `define USB_FUNC_CTRL_PHY_TERMSELECT_DEFAULT    0
    `define USB_FUNC_CTRL_PHY_TERMSELECT_B          5
    `define USB_FUNC_CTRL_PHY_TERMSELECT_T          5
    `define USB_FUNC_CTRL_PHY_TERMSELECT_W          1
    `define USB_FUNC_CTRL_PHY_TERMSELECT_R          5:5

    `define USB_FUNC_CTRL_PHY_XCVRSELECT_DEFAULT    0
    `define USB_FUNC_CTRL_PHY_XCVRSELECT_B          3
    `define USB_FUNC_CTRL_PHY_XCVRSELECT_T          4
    `define USB_FUNC_CTRL_PHY_XCVRSELECT_W          2
    `define USB_FUNC_CTRL_PHY_XCVRSELECT_R          4:3

    `define USB_FUNC_CTRL_PHY_OPMODE_DEFAULT    0
    `define USB_FUNC_CTRL_PHY_OPMODE_B          1
    `define USB_FUNC_CTRL_PHY_OPMODE_T          2
    `define USB_FUNC_CTRL_PHY_OPMODE_W          2
    `define USB_FUNC_CTRL_PHY_OPMODE_R          2:1

    `define USB_FUNC_CTRL_INT_EN_SOF      0
    `define USB_FUNC_CTRL_INT_EN_SOF_DEFAULT    0
    `define USB_FUNC_CTRL_INT_EN_SOF_B          0
    `define USB_FUNC_CTRL_INT_EN_SOF_T          0
    `define USB_FUNC_CTRL_INT_EN_SOF_W          1
    `define USB_FUNC_CTRL_INT_EN_SOF_R          0:0

`define USB_FUNC_STAT    8'h4

    `define USB_FUNC_STAT_SOF      14
    `define USB_FUNC_STAT_SOF_DEFAULT    0
    `define USB_FUNC_STAT_SOF_B          14
    `define USB_FUNC_STAT_SOF_T          14
    `define USB_FUNC_STAT_SOF_W          1
    `define USB_FUNC_STAT_SOF_R          14:14

    `define USB_FUNC_STAT_RST      13
    `define USB_FUNC_STAT_RST_DEFAULT    0
    `define USB_FUNC_STAT_RST_B          13
    `define USB_FUNC_STAT_RST_T          13
    `define USB_FUNC_STAT_RST_W          1
    `define USB_FUNC_STAT_RST_R          13:13

    `define USB_FUNC_STAT_LINESTATE_DEFAULT    0
    `define USB_FUNC_STAT_LINESTATE_B          11
    `define USB_FUNC_STAT_LINESTATE_T          12
    `define USB_FUNC_STAT_LINESTATE_W          2
    `define USB_FUNC_STAT_LINESTATE_R          12:11

    `define USB_FUNC_STAT_FRAME_DEFAULT    0
    `define USB_FUNC_STAT_FRAME_B          0
    `define USB_FUNC_STAT_FRAME_T          10
    `define USB_FUNC_STAT_FRAME_W          11
    `define USB_FUNC_STAT_FRAME_R          10:0

`define USB_FUNC_ADDR    8'h8

    `define USB_FUNC_ADDR_DEV_ADDR_DEFAULT    0
    `define USB_FUNC_ADDR_DEV_ADDR_B          0
    `define USB_FUNC_ADDR_DEV_ADDR_T          6
    `define USB_FUNC_ADDR_DEV_ADDR_W          7
    `define USB_FUNC_ADDR_DEV_ADDR_R          6:0

//-----------------------------------------------------------------
// USB_EP_INTSTS
//-----------------------------------------------------------------
`define USB_EP_INTSTS    8'h0C

    //--------------------------------------------------
    // bit[15:0] -> RX_READY EP 0-15
    //--------------------------------------------------

    `define USB_EP_INTSTS_EP0_RX_READY_DEFAULT      0
    `define USB_EP_INTSTS_EP0_RX_READY_B            0
    `define USB_EP_INTSTS_EP0_RX_READY_T            0
    `define USB_EP_INTSTS_EP0_RX_READY_W            1
    `define USB_EP_INTSTS_EP0_RX_READY_R            0:0

    `define USB_EP_INTSTS_EP1_RX_READY_DEFAULT      0
    `define USB_EP_INTSTS_EP1_RX_READY_B            1
    `define USB_EP_INTSTS_EP1_RX_READY_T            1
    `define USB_EP_INTSTS_EP1_RX_READY_W            1
    `define USB_EP_INTSTS_EP1_RX_READY_R            1:1

    `define USB_EP_INTSTS_EP2_RX_READY_DEFAULT      0
    `define USB_EP_INTSTS_EP2_RX_READY_B            2
    `define USB_EP_INTSTS_EP2_RX_READY_T            2
    `define USB_EP_INTSTS_EP2_RX_READY_W            1
    `define USB_EP_INTSTS_EP2_RX_READY_R            2:2

    `define USB_EP_INTSTS_EP3_RX_READY_DEFAULT      0
    `define USB_EP_INTSTS_EP3_RX_READY_B            3
    `define USB_EP_INTSTS_EP3_RX_READY_T            3
    `define USB_EP_INTSTS_EP3_RX_READY_W            1
    `define USB_EP_INTSTS_EP3_RX_READY_R            3:3

    //--------------------------------------------------
    // bit[31:16] -> TX_COMPLETE: 16-31
    //--------------------------------------------------
    `define USB_EP_INTSTS_EP0_TX_COMPLETE_DEFAULT      0
    `define USB_EP_INTSTS_EP0_TX_COMPLETE_B            16
    `define USB_EP_INTSTS_EP0_TX_COMPLETE_T            16
    `define USB_EP_INTSTS_EP0_TX_COMPLETE_W            1
    `define USB_EP_INTSTS_EP0_TX_COMPLETE_R            16:16

    `define USB_EP_INTSTS_EP1_TX_COMPLETE_DEFAULT      0
    `define USB_EP_INTSTS_EP1_TX_COMPLETE_B            17
    `define USB_EP_INTSTS_EP1_TX_COMPLETE_T            17
    `define USB_EP_INTSTS_EP1_TX_COMPLETE_W            1
    `define USB_EP_INTSTS_EP1_TX_COMPLETE_R            17:17

    `define USB_EP_INTSTS_EP2_TX_COMPLETE_DEFAULT      0
    `define USB_EP_INTSTS_EP2_TX_COMPLETE_B            18
    `define USB_EP_INTSTS_EP2_TX_COMPLETE_T            18
    `define USB_EP_INTSTS_EP2_TX_COMPLETE_W            1
    `define USB_EP_INTSTS_EP2_TX_COMPLETE_R            18:18

    `define USB_EP_INTSTS_EP3_TX_COMPLETE_DEFAULT      0
    `define USB_EP_INTSTS_EP3_TX_COMPLETE_B            19
    `define USB_EP_INTSTS_EP3_TX_COMPLETE_T            19
    `define USB_EP_INTSTS_EP3_TX_COMPLETE_W            1
    `define USB_EP_INTSTS_EP3_TX_COMPLETE_R            19:19

//-----------------------------------------------------------------
//                              EP0
//-----------------------------------------------------------------
`define USB_EP0_CFG    8'h20

    `define USB_EP0_CFG_INT_RX      3
    `define USB_EP0_CFG_INT_RX_DEFAULT    0
    `define USB_EP0_CFG_INT_RX_B          3
    `define USB_EP0_CFG_INT_RX_T          3
    `define USB_EP0_CFG_INT_RX_W          1
    `define USB_EP0_CFG_INT_RX_R          3:3

    `define USB_EP0_CFG_INT_TX      2
    `define USB_EP0_CFG_INT_TX_DEFAULT    0
    `define USB_EP0_CFG_INT_TX_B          2
    `define USB_EP0_CFG_INT_TX_T          2
    `define USB_EP0_CFG_INT_TX_W          1
    `define USB_EP0_CFG_INT_TX_R          2:2

    `define USB_EP0_CFG_STALL_EP      1
    `define USB_EP0_CFG_STALL_EP_DEFAULT    0
    `define USB_EP0_CFG_STALL_EP_B          1
    `define USB_EP0_CFG_STALL_EP_T          1
    `define USB_EP0_CFG_STALL_EP_W          1
    `define USB_EP0_CFG_STALL_EP_R          1:1

    `define USB_EP0_CFG_ISO      0
    `define USB_EP0_CFG_ISO_DEFAULT    0
    `define USB_EP0_CFG_ISO_B          0
    `define USB_EP0_CFG_ISO_T          0
    `define USB_EP0_CFG_ISO_W          1
    `define USB_EP0_CFG_ISO_R          0:0

`define USB_EP0_TX_CTRL    8'h24

    `define USB_EP0_TX_CTRL_TX_FLUSH      17
    `define USB_EP0_TX_CTRL_TX_FLUSH_DEFAULT    0
    `define USB_EP0_TX_CTRL_TX_FLUSH_B          17
    `define USB_EP0_TX_CTRL_TX_FLUSH_T          17
    `define USB_EP0_TX_CTRL_TX_FLUSH_W          1
    `define USB_EP0_TX_CTRL_TX_FLUSH_R          17:17

    `define USB_EP0_TX_CTRL_TX_START      16
    `define USB_EP0_TX_CTRL_TX_START_DEFAULT    0
    `define USB_EP0_TX_CTRL_TX_START_B          16
    `define USB_EP0_TX_CTRL_TX_START_T          16
    `define USB_EP0_TX_CTRL_TX_START_W          1
    `define USB_EP0_TX_CTRL_TX_START_R          16:16

    `define USB_EP0_TX_CTRL_TX_LEN_DEFAULT    0
    `define USB_EP0_TX_CTRL_TX_LEN_B          0
    `define USB_EP0_TX_CTRL_TX_LEN_T          10
    `define USB_EP0_TX_CTRL_TX_LEN_W          11
    `define USB_EP0_TX_CTRL_TX_LEN_R          10:0

`define USB_EP0_RX_CTRL    8'h28

    `define USB_EP0_RX_CTRL_RX_FLUSH      1
    `define USB_EP0_RX_CTRL_RX_FLUSH_DEFAULT    0
    `define USB_EP0_RX_CTRL_RX_FLUSH_B          1
    `define USB_EP0_RX_CTRL_RX_FLUSH_T          1
    `define USB_EP0_RX_CTRL_RX_FLUSH_W          1
    `define USB_EP0_RX_CTRL_RX_FLUSH_R          1:1

    `define USB_EP0_RX_CTRL_RX_ACCEPT      0
    `define USB_EP0_RX_CTRL_RX_ACCEPT_DEFAULT    0
    `define USB_EP0_RX_CTRL_RX_ACCEPT_B          0
    `define USB_EP0_RX_CTRL_RX_ACCEPT_T          0
    `define USB_EP0_RX_CTRL_RX_ACCEPT_W          1
    `define USB_EP0_RX_CTRL_RX_ACCEPT_R          0:0

`define USB_EP0_STS    8'h2c

    `define USB_EP0_STS_TX_ERR      20
    `define USB_EP0_STS_TX_ERR_DEFAULT    0
    `define USB_EP0_STS_TX_ERR_B          20
    `define USB_EP0_STS_TX_ERR_T          20
    `define USB_EP0_STS_TX_ERR_W          1
    `define USB_EP0_STS_TX_ERR_R          20:20

    `define USB_EP0_STS_TX_BUSY      19
    `define USB_EP0_STS_TX_BUSY_DEFAULT    0
    `define USB_EP0_STS_TX_BUSY_B          19
    `define USB_EP0_STS_TX_BUSY_T          19
    `define USB_EP0_STS_TX_BUSY_W          1
    `define USB_EP0_STS_TX_BUSY_R          19:19

    `define USB_EP0_STS_RX_ERR      18
    `define USB_EP0_STS_RX_ERR_DEFAULT    0
    `define USB_EP0_STS_RX_ERR_B          18
    `define USB_EP0_STS_RX_ERR_T          18
    `define USB_EP0_STS_RX_ERR_W          1
    `define USB_EP0_STS_RX_ERR_R          18:18

    `define USB_EP0_STS_RX_SETUP      17
    `define USB_EP0_STS_RX_SETUP_DEFAULT    0
    `define USB_EP0_STS_RX_SETUP_B          17
    `define USB_EP0_STS_RX_SETUP_T          17
    `define USB_EP0_STS_RX_SETUP_W          1
    `define USB_EP0_STS_RX_SETUP_R          17:17

    `define USB_EP0_STS_RX_READY      16
    `define USB_EP0_STS_RX_READY_DEFAULT    0
    `define USB_EP0_STS_RX_READY_B          16
    `define USB_EP0_STS_RX_READY_T          16
    `define USB_EP0_STS_RX_READY_W          1
    `define USB_EP0_STS_RX_READY_R          16:16

    `define USB_EP0_STS_RX_COUNT_DEFAULT    0
    `define USB_EP0_STS_RX_COUNT_B          0
    `define USB_EP0_STS_RX_COUNT_T          10
    `define USB_EP0_STS_RX_COUNT_W          11
    `define USB_EP0_STS_RX_COUNT_R          10:0

`define USB_EP0_DATA    8'h30

    `define USB_EP0_DATA_DATA_DEFAULT    0
    `define USB_EP0_DATA_DATA_B          0
    `define USB_EP0_DATA_DATA_T          7
    `define USB_EP0_DATA_DATA_W          8
    `define USB_EP0_DATA_DATA_R          7:0



//-----------------------------------------------------------------
//                              EP1
//-----------------------------------------------------------------
`define USB_EP1_CFG    8'h40

    `define USB_EP1_CFG_INT_RX      3
    `define USB_EP1_CFG_INT_RX_DEFAULT    0
    `define USB_EP1_CFG_INT_RX_B          3
    `define USB_EP1_CFG_INT_RX_T          3
    `define USB_EP1_CFG_INT_RX_W          1
    `define USB_EP1_CFG_INT_RX_R          3:3

    `define USB_EP1_CFG_INT_TX      2
    `define USB_EP1_CFG_INT_TX_DEFAULT    0
    `define USB_EP1_CFG_INT_TX_B          2
    `define USB_EP1_CFG_INT_TX_T          2
    `define USB_EP1_CFG_INT_TX_W          1
    `define USB_EP1_CFG_INT_TX_R          2:2

    `define USB_EP1_CFG_STALL_EP      1
    `define USB_EP1_CFG_STALL_EP_DEFAULT    0
    `define USB_EP1_CFG_STALL_EP_B          1
    `define USB_EP1_CFG_STALL_EP_T          1
    `define USB_EP1_CFG_STALL_EP_W          1
    `define USB_EP1_CFG_STALL_EP_R          1:1

    `define USB_EP1_CFG_ISO      0
    `define USB_EP1_CFG_ISO_DEFAULT    0
    `define USB_EP1_CFG_ISO_B          0
    `define USB_EP1_CFG_ISO_T          0
    `define USB_EP1_CFG_ISO_W          1
    `define USB_EP1_CFG_ISO_R          0:0

`define USB_EP1_TX_CTRL    8'h44

    `define USB_EP1_TX_CTRL_TX_FLUSH      17
    `define USB_EP1_TX_CTRL_TX_FLUSH_DEFAULT    0
    `define USB_EP1_TX_CTRL_TX_FLUSH_B          17
    `define USB_EP1_TX_CTRL_TX_FLUSH_T          17
    `define USB_EP1_TX_CTRL_TX_FLUSH_W          1
    `define USB_EP1_TX_CTRL_TX_FLUSH_R          17:17

    `define USB_EP1_TX_CTRL_TX_START      16
    `define USB_EP1_TX_CTRL_TX_START_DEFAULT    0
    `define USB_EP1_TX_CTRL_TX_START_B          16
    `define USB_EP1_TX_CTRL_TX_START_T          16
    `define USB_EP1_TX_CTRL_TX_START_W          1
    `define USB_EP1_TX_CTRL_TX_START_R          16:16

    `define USB_EP1_TX_CTRL_TX_LEN_DEFAULT    0
    `define USB_EP1_TX_CTRL_TX_LEN_B          0
    `define USB_EP1_TX_CTRL_TX_LEN_T          10
    `define USB_EP1_TX_CTRL_TX_LEN_W          11
    `define USB_EP1_TX_CTRL_TX_LEN_R          10:0

`define USB_EP1_RX_CTRL    8'h48

    `define USB_EP1_RX_CTRL_RX_FLUSH      1
    `define USB_EP1_RX_CTRL_RX_FLUSH_DEFAULT    0
    `define USB_EP1_RX_CTRL_RX_FLUSH_B          1
    `define USB_EP1_RX_CTRL_RX_FLUSH_T          1
    `define USB_EP1_RX_CTRL_RX_FLUSH_W          1
    `define USB_EP1_RX_CTRL_RX_FLUSH_R          1:1

    `define USB_EP1_RX_CTRL_RX_ACCEPT      0
    `define USB_EP1_RX_CTRL_RX_ACCEPT_DEFAULT    0
    `define USB_EP1_RX_CTRL_RX_ACCEPT_B          0
    `define USB_EP1_RX_CTRL_RX_ACCEPT_T          0
    `define USB_EP1_RX_CTRL_RX_ACCEPT_W          1
    `define USB_EP1_RX_CTRL_RX_ACCEPT_R          0:0

`define USB_EP1_STS    8'h4c

    `define USB_EP1_STS_TX_ERR      20
    `define USB_EP1_STS_TX_ERR_DEFAULT    0
    `define USB_EP1_STS_TX_ERR_B          20
    `define USB_EP1_STS_TX_ERR_T          20
    `define USB_EP1_STS_TX_ERR_W          1
    `define USB_EP1_STS_TX_ERR_R          20:20

    `define USB_EP1_STS_TX_BUSY      19
    `define USB_EP1_STS_TX_BUSY_DEFAULT    0
    `define USB_EP1_STS_TX_BUSY_B          19
    `define USB_EP1_STS_TX_BUSY_T          19
    `define USB_EP1_STS_TX_BUSY_W          1
    `define USB_EP1_STS_TX_BUSY_R          19:19

    `define USB_EP1_STS_RX_ERR      18
    `define USB_EP1_STS_RX_ERR_DEFAULT    0
    `define USB_EP1_STS_RX_ERR_B          18
    `define USB_EP1_STS_RX_ERR_T          18
    `define USB_EP1_STS_RX_ERR_W          1
    `define USB_EP1_STS_RX_ERR_R          18:18

    `define USB_EP1_STS_RX_SETUP      17
    `define USB_EP1_STS_RX_SETUP_DEFAULT    0
    `define USB_EP1_STS_RX_SETUP_B          17
    `define USB_EP1_STS_RX_SETUP_T          17
    `define USB_EP1_STS_RX_SETUP_W          1
    `define USB_EP1_STS_RX_SETUP_R          17:17

    `define USB_EP1_STS_RX_READY      16
    `define USB_EP1_STS_RX_READY_DEFAULT    0
    `define USB_EP1_STS_RX_READY_B          16
    `define USB_EP1_STS_RX_READY_T          16
    `define USB_EP1_STS_RX_READY_W          1
    `define USB_EP1_STS_RX_READY_R          16:16

    `define USB_EP1_STS_RX_COUNT_DEFAULT    0
    `define USB_EP1_STS_RX_COUNT_B          0
    `define USB_EP1_STS_RX_COUNT_T          10
    `define USB_EP1_STS_RX_COUNT_W          11
    `define USB_EP1_STS_RX_COUNT_R          10:0

`define USB_EP1_DATA    8'h50

    `define USB_EP1_DATA_DATA_DEFAULT    0
    `define USB_EP1_DATA_DATA_B          0
    `define USB_EP1_DATA_DATA_T          7
    `define USB_EP1_DATA_DATA_W          8
    `define USB_EP1_DATA_DATA_R          7:0



//-----------------------------------------------------------------
//                              EP2
//-----------------------------------------------------------------
`define USB_EP2_CFG    8'h60

    `define USB_EP2_CFG_INT_RX      3
    `define USB_EP2_CFG_INT_RX_DEFAULT    0
    `define USB_EP2_CFG_INT_RX_B          3
    `define USB_EP2_CFG_INT_RX_T          3
    `define USB_EP2_CFG_INT_RX_W          1
    `define USB_EP2_CFG_INT_RX_R          3:3

    `define USB_EP2_CFG_INT_TX      2
    `define USB_EP2_CFG_INT_TX_DEFAULT    0
    `define USB_EP2_CFG_INT_TX_B          2
    `define USB_EP2_CFG_INT_TX_T          2
    `define USB_EP2_CFG_INT_TX_W          1
    `define USB_EP2_CFG_INT_TX_R          2:2

    `define USB_EP2_CFG_STALL_EP      1
    `define USB_EP2_CFG_STALL_EP_DEFAULT    0
    `define USB_EP2_CFG_STALL_EP_B          1
    `define USB_EP2_CFG_STALL_EP_T          1
    `define USB_EP2_CFG_STALL_EP_W          1
    `define USB_EP2_CFG_STALL_EP_R          1:1

    `define USB_EP2_CFG_ISO      0
    `define USB_EP2_CFG_ISO_DEFAULT    0
    `define USB_EP2_CFG_ISO_B          0
    `define USB_EP2_CFG_ISO_T          0
    `define USB_EP2_CFG_ISO_W          1
    `define USB_EP2_CFG_ISO_R          0:0

`define USB_EP2_TX_CTRL    8'h64

    `define USB_EP2_TX_CTRL_TX_FLUSH      17
    `define USB_EP2_TX_CTRL_TX_FLUSH_DEFAULT    0
    `define USB_EP2_TX_CTRL_TX_FLUSH_B          17
    `define USB_EP2_TX_CTRL_TX_FLUSH_T          17
    `define USB_EP2_TX_CTRL_TX_FLUSH_W          1
    `define USB_EP2_TX_CTRL_TX_FLUSH_R          17:17

    `define USB_EP2_TX_CTRL_TX_START      16
    `define USB_EP2_TX_CTRL_TX_START_DEFAULT    0
    `define USB_EP2_TX_CTRL_TX_START_B          16
    `define USB_EP2_TX_CTRL_TX_START_T          16
    `define USB_EP2_TX_CTRL_TX_START_W          1
    `define USB_EP2_TX_CTRL_TX_START_R          16:16

    `define USB_EP2_TX_CTRL_TX_LEN_DEFAULT    0
    `define USB_EP2_TX_CTRL_TX_LEN_B          0
    `define USB_EP2_TX_CTRL_TX_LEN_T          10
    `define USB_EP2_TX_CTRL_TX_LEN_W          11
    `define USB_EP2_TX_CTRL_TX_LEN_R          10:0

`define USB_EP2_RX_CTRL    8'h68

    `define USB_EP2_RX_CTRL_RX_FLUSH      1
    `define USB_EP2_RX_CTRL_RX_FLUSH_DEFAULT    0
    `define USB_EP2_RX_CTRL_RX_FLUSH_B          1
    `define USB_EP2_RX_CTRL_RX_FLUSH_T          1
    `define USB_EP2_RX_CTRL_RX_FLUSH_W          1
    `define USB_EP2_RX_CTRL_RX_FLUSH_R          1:1

    `define USB_EP2_RX_CTRL_RX_ACCEPT      0
    `define USB_EP2_RX_CTRL_RX_ACCEPT_DEFAULT    0
    `define USB_EP2_RX_CTRL_RX_ACCEPT_B          0
    `define USB_EP2_RX_CTRL_RX_ACCEPT_T          0
    `define USB_EP2_RX_CTRL_RX_ACCEPT_W          1
    `define USB_EP2_RX_CTRL_RX_ACCEPT_R          0:0

`define USB_EP2_STS    8'h6c

    `define USB_EP2_STS_TX_ERR      20
    `define USB_EP2_STS_TX_ERR_DEFAULT    0
    `define USB_EP2_STS_TX_ERR_B          20
    `define USB_EP2_STS_TX_ERR_T          20
    `define USB_EP2_STS_TX_ERR_W          1
    `define USB_EP2_STS_TX_ERR_R          20:20

    `define USB_EP2_STS_TX_BUSY      19
    `define USB_EP2_STS_TX_BUSY_DEFAULT    0
    `define USB_EP2_STS_TX_BUSY_B          19
    `define USB_EP2_STS_TX_BUSY_T          19
    `define USB_EP2_STS_TX_BUSY_W          1
    `define USB_EP2_STS_TX_BUSY_R          19:19

    `define USB_EP2_STS_RX_ERR      18
    `define USB_EP2_STS_RX_ERR_DEFAULT    0
    `define USB_EP2_STS_RX_ERR_B          18
    `define USB_EP2_STS_RX_ERR_T          18
    `define USB_EP2_STS_RX_ERR_W          1
    `define USB_EP2_STS_RX_ERR_R          18:18

    `define USB_EP2_STS_RX_SETUP      17
    `define USB_EP2_STS_RX_SETUP_DEFAULT    0
    `define USB_EP2_STS_RX_SETUP_B          17
    `define USB_EP2_STS_RX_SETUP_T          17
    `define USB_EP2_STS_RX_SETUP_W          1
    `define USB_EP2_STS_RX_SETUP_R          17:17

    `define USB_EP2_STS_RX_READY      16
    `define USB_EP2_STS_RX_READY_DEFAULT    0
    `define USB_EP2_STS_RX_READY_B          16
    `define USB_EP2_STS_RX_READY_T          16
    `define USB_EP2_STS_RX_READY_W          1
    `define USB_EP2_STS_RX_READY_R          16:16

    `define USB_EP2_STS_RX_COUNT_DEFAULT    0
    `define USB_EP2_STS_RX_COUNT_B          0
    `define USB_EP2_STS_RX_COUNT_T          10
    `define USB_EP2_STS_RX_COUNT_W          11
    `define USB_EP2_STS_RX_COUNT_R          10:0

`define USB_EP2_DATA    8'h70

    `define USB_EP2_DATA_DATA_DEFAULT    0
    `define USB_EP2_DATA_DATA_B          0
    `define USB_EP2_DATA_DATA_T          7
    `define USB_EP2_DATA_DATA_W          8
    `define USB_EP2_DATA_DATA_R          7:0

//-----------------------------------------------------------------
//                              EP3
//-----------------------------------------------------------------
`define USB_EP3_CFG    8'h80

    `define USB_EP3_CFG_INT_RX      3
    `define USB_EP3_CFG_INT_RX_DEFAULT    0
    `define USB_EP3_CFG_INT_RX_B          3
    `define USB_EP3_CFG_INT_RX_T          3
    `define USB_EP3_CFG_INT_RX_W          1
    `define USB_EP3_CFG_INT_RX_R          3:3

    `define USB_EP3_CFG_INT_TX      2
    `define USB_EP3_CFG_INT_TX_DEFAULT    0
    `define USB_EP3_CFG_INT_TX_B          2
    `define USB_EP3_CFG_INT_TX_T          2
    `define USB_EP3_CFG_INT_TX_W          1
    `define USB_EP3_CFG_INT_TX_R          2:2

    `define USB_EP3_CFG_STALL_EP      1
    `define USB_EP3_CFG_STALL_EP_DEFAULT    0
    `define USB_EP3_CFG_STALL_EP_B          1
    `define USB_EP3_CFG_STALL_EP_T          1
    `define USB_EP3_CFG_STALL_EP_W          1
    `define USB_EP3_CFG_STALL_EP_R          1:1

    `define USB_EP3_CFG_ISO      0
    `define USB_EP3_CFG_ISO_DEFAULT    0
    `define USB_EP3_CFG_ISO_B          0
    `define USB_EP3_CFG_ISO_T          0
    `define USB_EP3_CFG_ISO_W          1
    `define USB_EP3_CFG_ISO_R          0:0

`define USB_EP3_TX_CTRL    8'h84

    `define USB_EP3_TX_CTRL_TX_FLUSH      17
    `define USB_EP3_TX_CTRL_TX_FLUSH_DEFAULT    0
    `define USB_EP3_TX_CTRL_TX_FLUSH_B          17
    `define USB_EP3_TX_CTRL_TX_FLUSH_T          17
    `define USB_EP3_TX_CTRL_TX_FLUSH_W          1
    `define USB_EP3_TX_CTRL_TX_FLUSH_R          17:17

    `define USB_EP3_TX_CTRL_TX_START      16
    `define USB_EP3_TX_CTRL_TX_START_DEFAULT    0
    `define USB_EP3_TX_CTRL_TX_START_B          16
    `define USB_EP3_TX_CTRL_TX_START_T          16
    `define USB_EP3_TX_CTRL_TX_START_W          1
    `define USB_EP3_TX_CTRL_TX_START_R          16:16

    `define USB_EP3_TX_CTRL_TX_LEN_DEFAULT    0
    `define USB_EP3_TX_CTRL_TX_LEN_B          0
    `define USB_EP3_TX_CTRL_TX_LEN_T          10
    `define USB_EP3_TX_CTRL_TX_LEN_W          11
    `define USB_EP3_TX_CTRL_TX_LEN_R          10:0

`define USB_EP3_RX_CTRL    8'h88

    `define USB_EP3_RX_CTRL_RX_FLUSH      1
    `define USB_EP3_RX_CTRL_RX_FLUSH_DEFAULT    0
    `define USB_EP3_RX_CTRL_RX_FLUSH_B          1
    `define USB_EP3_RX_CTRL_RX_FLUSH_T          1
    `define USB_EP3_RX_CTRL_RX_FLUSH_W          1
    `define USB_EP3_RX_CTRL_RX_FLUSH_R          1:1

    `define USB_EP3_RX_CTRL_RX_ACCEPT      0
    `define USB_EP3_RX_CTRL_RX_ACCEPT_DEFAULT    0
    `define USB_EP3_RX_CTRL_RX_ACCEPT_B          0
    `define USB_EP3_RX_CTRL_RX_ACCEPT_T          0
    `define USB_EP3_RX_CTRL_RX_ACCEPT_W          1
    `define USB_EP3_RX_CTRL_RX_ACCEPT_R          0:0

`define USB_EP3_STS    8'h8c

    `define USB_EP3_STS_TX_ERR      20
    `define USB_EP3_STS_TX_ERR_DEFAULT    0
    `define USB_EP3_STS_TX_ERR_B          20
    `define USB_EP3_STS_TX_ERR_T          20
    `define USB_EP3_STS_TX_ERR_W          1
    `define USB_EP3_STS_TX_ERR_R          20:20

    `define USB_EP3_STS_TX_BUSY      19
    `define USB_EP3_STS_TX_BUSY_DEFAULT    0
    `define USB_EP3_STS_TX_BUSY_B          19
    `define USB_EP3_STS_TX_BUSY_T          19
    `define USB_EP3_STS_TX_BUSY_W          1
    `define USB_EP3_STS_TX_BUSY_R          19:19

    `define USB_EP3_STS_RX_ERR      18
    `define USB_EP3_STS_RX_ERR_DEFAULT    0
    `define USB_EP3_STS_RX_ERR_B          18
    `define USB_EP3_STS_RX_ERR_T          18
    `define USB_EP3_STS_RX_ERR_W          1
    `define USB_EP3_STS_RX_ERR_R          18:18

    `define USB_EP3_STS_RX_SETUP      17
    `define USB_EP3_STS_RX_SETUP_DEFAULT    0
    `define USB_EP3_STS_RX_SETUP_B          17
    `define USB_EP3_STS_RX_SETUP_T          17
    `define USB_EP3_STS_RX_SETUP_W          1
    `define USB_EP3_STS_RX_SETUP_R          17:17

    `define USB_EP3_STS_RX_READY      16
    `define USB_EP3_STS_RX_READY_DEFAULT    0
    `define USB_EP3_STS_RX_READY_B          16
    `define USB_EP3_STS_RX_READY_T          16
    `define USB_EP3_STS_RX_READY_W          1
    `define USB_EP3_STS_RX_READY_R          16:16

    `define USB_EP3_STS_RX_COUNT_DEFAULT    0
    `define USB_EP3_STS_RX_COUNT_B          0
    `define USB_EP3_STS_RX_COUNT_T          10
    `define USB_EP3_STS_RX_COUNT_W          11
    `define USB_EP3_STS_RX_COUNT_R          10:0

`define USB_EP3_DATA    8'h90

    `define USB_EP3_DATA_DATA_DEFAULT    0
    `define USB_EP3_DATA_DATA_B          0
    `define USB_EP3_DATA_DATA_T          7
    `define USB_EP3_DATA_DATA_W          8
    `define USB_EP3_DATA_DATA_R          7:0


