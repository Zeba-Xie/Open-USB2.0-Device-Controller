//=================================================================
//
// Control and status module
// This module reads and writes control and status registers 
// according to the instruction of BIU.
// This module works in the H clock domain completely.
// 
// Version: V1.0
// Created by Zeba-Xie @github
//
// TODO:
// 1)[auto_clr] needs reg?
//=================================================================

`include "usbf_cfg_defs.v"

module usbf_csr(
     input                                          hclk_i
    ,input                                          rstn_i

    ////// BIU interface
    ,input                                          wt_en_i
    ,input                                          rd_en_i
    ,input                                          enable_i
    ,input [31:0]                                   addr_i
    ,input [31:0]                                   wdata_i
    ,output[31:0]                                   rdata_o

    ,output                                         wt_ready_o // MEM fifos are in PHY clock domain
    ,output                                         rd_ready_o // so writing/reading data to fifo needs waiting CDC
 
    ////// Device core interface
    ,output                                         func_ctrl_hs_chirp_en_o
    ,output [ `USB_FUNC_ADDR_DEV_ADDR_W-1:0]        func_addr_dev_addr_o
    ,output [`USB_EP_NUM-1:0]                       ep_cfg_stall_ep_o
    ,output [`USB_EP_NUM-1:0]                       ep_cfg_iso_o
    ,input  [`USB_FUNC_STAT_FRAME_W-1:0]            func_stat_frame_i
    ,input                                          rst_intr_set_i
    ,input                                          sof_intr_set_i
    ,input  [`USB_EP_NUM-1:0]                       ep_rx_ready_intr_set_i
    ,input  [`USB_EP_NUM-1:0]                       ep_tx_complete_intr_set_i

    ////// EPU(endpoint) interface
    ,output [`USB_EP_NUM-1:0]                       ep_tx_ctrl_tx_start_o
    ,output [`USB_EP0_TX_CTRL_TX_LEN_W*`USB_EP_NUM-1:0]   ep_tx_ctrl_tx_len_o     
    ,output [`USB_EP_NUM-1:0]                       ep_rx_ctrl_rx_accept_o        
    ,input  [`USB_EP_NUM-1:0]                       ep_sts_tx_err_i
    ,input  [`USB_EP_NUM-1:0]                       ep_sts_tx_busy_i
    ,input  [`USB_EP_NUM-1:0]                       ep_sts_rx_err_i 
    ,input  [`USB_EP_NUM-1:0]                       ep_sts_rx_setup_i
    ,input  [`USB_EP_NUM-1:0]                       ep_sts_rx_ready_i 
    ,input  [`USB_EP0_STS_RX_COUNT_W*`USB_EP_NUM-1:0] ep_sts_rx_count_i

    ////// MEM(memory) interface
        // RX
    ,output [`USB_EP_NUM-1:0]                       ep_rx_ctrl_rx_flush_o      
    ,output [`USB_EP_NUM-1:0]                       ep_data_rd_req_o   
    ,input  [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  ep_rx_data_i 
        // TX
    ,output [`USB_EP_NUM-1:0]                       ep_tx_ctrl_tx_flush_o
    ,output [`USB_EP_NUM-1:0]                       ep_data_wt_req_o
    ,output [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  ep_tx_data_o
    
    ////// Device interface
    ,output                                         func_ctrl_phy_dmpulldown_o
    ,output                                         func_ctrl_phy_dppulldown_o
    ,output                                         func_ctrl_phy_termselect_o
    ,output [1:0]                                   func_ctrl_phy_xcvrselect_o
    ,output [1:0]                                   func_ctrl_phy_opmode_o
    ,input  [1:0]                                   func_stat_linestate_i

    ////// Others
    ,output                                         intr_o

    ,input                                          mem_wt_ready_i // MEM fifos are in PHY clock domain
    ,input                                          mem_rd_ready_i // so writing/reading data to fifo needs waiting CDC
);
//==========================================================================================
// Register Write {
//==========================================================================================
//-----------------------------------------------------------------
// Register usb_func_ctrl
//-----------------------------------------------------------------

wire sel_func_ctrl = enable_i & (addr_i[7:0] == `USB_FUNC_CTRL);
wire func_ctrl_wt_en = wt_en_i & sel_func_ctrl;
wire func_ctrl_rd_en = rd_en_i & sel_func_ctrl;


// func_ctrl_hs_chirp_en [internal]
wire func_ctrl_hs_chirp_en_r;
wire func_ctrl_hs_chirp_en_ena = func_ctrl_wt_en;
wire func_ctrl_hs_chirp_en_next = wdata_i[`USB_FUNC_CTRL_HS_CHIRP_EN_R];
usbf_gnrl_dfflrd #(`USB_FUNC_CTRL_HS_CHIRP_EN_W, `USB_FUNC_CTRL_HS_CHIRP_EN_DEFAULT) 
    func_ctrl_hs_chirp_en_difflrd(
        func_ctrl_hs_chirp_en_ena,func_ctrl_hs_chirp_en_next,
        func_ctrl_hs_chirp_en_r,
        hclk_i,rstn_i
    );
assign func_ctrl_hs_chirp_en_o = func_ctrl_hs_chirp_en_r;

// usb_func_ctrl_phy_dmpulldown [internal]
wire func_ctrl_phy_dmpulldown_r;
wire func_ctrl_phy_dmpulldown_ena = func_ctrl_wt_en;
wire func_ctrl_phy_dmpulldown_next = wdata_i[`USB_FUNC_CTRL_PHY_DMPULLDOWN_R];
usbf_gnrl_dfflrd #(`USB_FUNC_CTRL_PHY_DMPULLDOWN_W, `USB_FUNC_CTRL_PHY_DMPULLDOWN_DEFAULT) 
    func_ctrl_phy_dmpulldown_difflrd(
        func_ctrl_phy_dmpulldown_ena,func_ctrl_phy_dmpulldown_next,
        func_ctrl_phy_dmpulldown_r,
        hclk_i,rstn_i
    );
assign func_ctrl_phy_dmpulldown_o = func_ctrl_phy_dmpulldown_r;

// usb_func_ctrl_phy_dppulldown [internal]
wire func_ctrl_phy_dppulldown_r;
wire func_ctrl_phy_dppulldown_ena = func_ctrl_wt_en;
wire func_ctrl_phy_dppulldown_next = wdata_i[`USB_FUNC_CTRL_PHY_DPPULLDOWN_R];
usbf_gnrl_dfflrd #(`USB_FUNC_CTRL_PHY_DPPULLDOWN_W, `USB_FUNC_CTRL_PHY_DPPULLDOWN_DEFAULT) 
    func_ctrl_phy_dppulldown_difflrd(
        func_ctrl_phy_dppulldown_ena,func_ctrl_phy_dppulldown_next,
        func_ctrl_phy_dppulldown_r,
        hclk_i,rstn_i
    );
assign func_ctrl_phy_dppulldown_o = func_ctrl_phy_dppulldown_r;

// usb_func_ctrl_phy_termselect [internal]
wire func_ctrl_phy_termselect_r;
wire func_ctrl_phy_termselect_ena = func_ctrl_wt_en;
wire func_ctrl_phy_termselect_next = wdata_i[`USB_FUNC_CTRL_PHY_TERMSELECT_R];
usbf_gnrl_dfflrd #(`USB_FUNC_CTRL_PHY_TERMSELECT_W, `USB_FUNC_CTRL_PHY_TERMSELECT_DEFAULT) 
    func_ctrl_phy_termselect_difflrd(
        func_ctrl_phy_termselect_ena,func_ctrl_phy_termselect_next,
        func_ctrl_phy_termselect_r,
        hclk_i,rstn_i
    );
assign func_ctrl_phy_termselect_o = func_ctrl_phy_termselect_r;

// usb_func_ctrl_phy_xcvrselect [internal]
wire [`USB_FUNC_CTRL_PHY_XCVRSELECT_W-1:0] func_ctrl_phy_xcvrselect_r;
wire func_ctrl_phy_xcvrselect_ena = func_ctrl_wt_en;
wire [`USB_FUNC_CTRL_PHY_XCVRSELECT_W-1:0] func_ctrl_phy_xcvrselect_next = wdata_i[`USB_FUNC_CTRL_PHY_XCVRSELECT_R];
usbf_gnrl_dfflrd #(`USB_FUNC_CTRL_PHY_XCVRSELECT_W, `USB_FUNC_CTRL_PHY_XCVRSELECT_DEFAULT) 
    func_ctrl_phy_xcvrselect_difflrd(
        func_ctrl_phy_xcvrselect_ena,func_ctrl_phy_xcvrselect_next,
        func_ctrl_phy_xcvrselect_r,
        hclk_i,rstn_i
    );
assign func_ctrl_phy_xcvrselect_o = func_ctrl_phy_xcvrselect_r;

// usb_func_ctrl_phy_opmode [internal]
wire [`USB_FUNC_CTRL_PHY_OPMODE_W-1:0] func_ctrl_phy_opmode_r;
wire func_ctrl_phy_opmode_ena = func_ctrl_wt_en;
wire [`USB_FUNC_CTRL_PHY_OPMODE_W-1:0] func_ctrl_phy_opmode_next = wdata_i[`USB_FUNC_CTRL_PHY_OPMODE_R];
usbf_gnrl_dfflrd #(`USB_FUNC_CTRL_PHY_OPMODE_W, `USB_FUNC_CTRL_PHY_OPMODE_DEFAULT) 
    func_ctrl_phy_opmode_difflrd(
        func_ctrl_phy_opmode_ena,func_ctrl_phy_opmode_next,
        func_ctrl_phy_opmode_r,
        hclk_i,rstn_i
    );
assign func_ctrl_phy_opmode_o = func_ctrl_phy_opmode_r;

// usb_func_ctrl_int_en_sof [internal]
wire func_ctrl_int_en_sof_r;
wire func_ctrl_int_en_sof_ena = func_ctrl_wt_en;
wire func_ctrl_int_en_sof_next = wdata_i[`USB_FUNC_CTRL_INT_EN_SOF_R];
usbf_gnrl_dfflrd #(`USB_FUNC_CTRL_INT_EN_SOF_W, `USB_FUNC_CTRL_INT_EN_SOF_DEFAULT) 
    func_ctrl_int_en_sof_difflrd(
        func_ctrl_int_en_sof_ena,func_ctrl_int_en_sof_next,
        func_ctrl_int_en_sof_r,
        hclk_i,rstn_i
    );
// assign func_ctrl_int_en_sof_o = func_ctrl_int_en_sof_r;

// usb_func_ctrl_int_en_rst [internal]
wire func_ctrl_int_en_rst_r;
wire func_ctrl_int_en_rst_ena = func_ctrl_wt_en;
wire func_ctrl_int_en_rst_next = wdata_i[`USB_FUNC_CTRL_INT_EN_RST_R];
usbf_gnrl_dfflrd #(`USB_FUNC_CTRL_INT_EN_RST_W, `USB_FUNC_CTRL_INT_EN_RST_DEFAULT) 
    func_ctrl_int_en_rst_difflrd(
        func_ctrl_int_en_rst_ena,func_ctrl_int_en_rst_next,
        func_ctrl_int_en_rst_r,
        hclk_i,rstn_i
    );
// assign func_ctrl_int_en_rst_o = func_ctrl_int_en_rst_r;



//-----------------------------------------------------------------
// Register usb_func_stat
//-----------------------------------------------------------------
wire sel_func_stat = enable_i & (addr_i[7:0] == `USB_FUNC_STAT);
wire func_stat_wt_en = wt_en_i & sel_func_stat;
wire func_stat_rd_en = rd_en_i & sel_func_stat;


// usb_func_stat_rst [auto_clr]: clear rst interrupt, and it's a pulse signal

//// without reg, the signal is valid 1 cycle ahead of other singal
// wire func_stat_rst = func_stat_wt_en & (wdata_i[`USB_FUNC_STAT_RST_R] == `USB_FUNC_STAT_RST_W{1'b1});

//// with reg
wire func_stat_rst_r;
wire func_stat_rst_set = func_stat_wt_en & wdata_i[`USB_FUNC_STAT_RST_R];
wire func_stat_rst_clr = func_stat_rst_r;
wire func_stat_rst_ena = func_stat_rst_set | func_stat_rst_clr;
wire func_stat_rst_next = func_stat_rst_set | (~func_stat_rst_clr);

usbf_gnrl_dfflrd #(`USB_FUNC_STAT_RST_W, `USB_FUNC_STAT_RST_DEFAULT) 
    func_stat_rst_difflrd(
        func_stat_rst_ena,func_stat_rst_next,
        func_stat_rst_r,
        hclk_i,rstn_i
    );
    
wire stat_rst_clr = func_stat_rst_r;

// usb_func_stat_sof [auto_clr]: clear sof interrupt, and it's a pulse singal

//// without reg, the signal is valid 1 cycle ahead of other singal
// wire func_stat_sof = func_stat_wt_en & (wdata_i[`USB_FUNC_STAT_SOF_R] == `USB_FUNC_STAT_SOF_W{1'b1});

//// with reg
wire func_stat_sof_r;
wire func_stat_sof_set = func_stat_wt_en & wdata_i[`USB_FUNC_STAT_SOF_R];
wire func_stat_sof_clr = func_stat_sof_r;
wire func_stat_sof_ena = func_stat_sof_set | func_stat_sof_clr;
wire func_stat_sof_next = func_stat_sof_set | (~func_stat_sof_clr);

usbf_gnrl_dfflrd #(`USB_FUNC_STAT_SOF_W, `USB_FUNC_STAT_SOF_DEFAULT) 
    func_stat_sof_difflrd(
        func_stat_sof_ena,func_stat_sof_next,
        func_stat_sof_r,
        hclk_i,rstn_i
    );
    
wire stat_sof_clr = func_stat_sof_r;


//-----------------------------------------------------------------
// Register usb_func_addr
//-----------------------------------------------------------------
wire sel_func_addr = enable_i & (addr_i[7:0] == `USB_FUNC_ADDR);
wire func_addr_wt_en = wt_en_i & sel_func_addr;
wire func_addr_rd_en = rd_en_i & sel_func_addr;

// usb_func_addr_dev_addr [internal]
wire [ `USB_FUNC_ADDR_DEV_ADDR_W-1:0] func_addr_dev_addr_r;
wire func_addr_dev_addr_ena = func_addr_wt_en;
wire [ `USB_FUNC_ADDR_DEV_ADDR_W-1:0] func_addr_dev_addr_next = wdata_i[`USB_FUNC_ADDR_DEV_ADDR_R];
usbf_gnrl_dfflrd #(`USB_FUNC_ADDR_DEV_ADDR_W, `USB_FUNC_ADDR_DEV_ADDR_DEFAULT) 
    func_addr_dev_addr_difflrd(
        func_addr_dev_addr_ena,func_addr_dev_addr_next,
        func_addr_dev_addr_r,
        hclk_i,rstn_i
    );
assign func_addr_dev_addr_o = func_addr_dev_addr_r;

//==========================================================================================
//==========================================================================================
genvar i;
//// generate CSR for each endpoint
//// the difference of endpoints is addr, 
//// and the configuration of bit fields is the same
generate //{
    //// USB_EPx_CFG
    wire sel_ep_cfg[`USB_EP_NUM-1:0];
    wire ep_cfg_wt_en[`USB_EP_NUM-1:0];
    wire ep_cfg_rd_en[`USB_EP_NUM-1:0];

    wire ep_cfg_int_rx_r[`USB_EP_NUM-1:0];
    wire ep_cfg_int_rx_ena[`USB_EP_NUM-1:0];
    wire ep_cfg_int_rx_next[`USB_EP_NUM-1:0];

    wire ep_cfg_int_tx_r[`USB_EP_NUM-1:0];
    wire ep_cfg_int_tx_ena[`USB_EP_NUM-1:0];
    wire ep_cfg_int_tx_next[`USB_EP_NUM-1:0];

    wire ep_cfg_stall_ep_ack[`USB_EP_NUM-1:0];
    wire ep_cfg_stall_ep_r[`USB_EP_NUM-1:0];
    wire ep_cfg_stall_ep_set[`USB_EP_NUM-1:0];
    wire ep_cfg_stall_ep_clr[`USB_EP_NUM-1:0];
    wire ep_cfg_stall_ep_ena[`USB_EP_NUM-1:0];
    wire ep_cfg_stall_ep_next[`USB_EP_NUM-1:0];

    wire ep_cfg_iso_r[`USB_EP_NUM-1:0];
    wire ep_cfg_iso_ena[`USB_EP_NUM-1:0];
    wire ep_cfg_iso_next[`USB_EP_NUM-1:0];

    //// USB_EPx_TX_CTRL
    wire sel_ep_tx_ctrl[`USB_EP_NUM-1:0];
    wire ep_tx_ctrl_wt_en[`USB_EP_NUM-1:0];
    wire ep_tx_ctrl_rd_en[`USB_EP_NUM-1:0];

    wire ep_tx_ctrl_tx_flush_r[`USB_EP_NUM-1:0];
    wire ep_tx_ctrl_tx_flush_set[`USB_EP_NUM-1:0];
    wire ep_tx_ctrl_tx_flush_clr[`USB_EP_NUM-1:0];
    wire ep_tx_ctrl_tx_flush_ena[`USB_EP_NUM-1:0];
    wire ep_tx_ctrl_tx_flush_next[`USB_EP_NUM-1:0];

    wire ep_tx_ctrl_tx_start_r[`USB_EP_NUM-1:0];
    wire ep_tx_ctrl_tx_start_set[`USB_EP_NUM-1:0];
    wire ep_tx_ctrl_tx_start_clr[`USB_EP_NUM-1:0];
    wire ep_tx_ctrl_tx_start_ena[`USB_EP_NUM-1:0];
    wire ep_tx_ctrl_tx_start_next[`USB_EP_NUM-1:0];

    wire [`USB_EP0_TX_CTRL_TX_LEN_W-1:0] ep_tx_ctrl_tx_len_r[`USB_EP_NUM-1:0];
    wire ep_tx_ctrl_tx_len_ena[`USB_EP_NUM-1:0];
    wire [`USB_EP0_TX_CTRL_TX_LEN_W-1:0] ep_tx_ctrl_tx_len_next[`USB_EP_NUM-1:0];

    //// USB_EPx_RX_CTRL
    wire sel_ep_rx_ctrl[`USB_EP_NUM-1:0];
    wire ep_rx_ctrl_wt_en[`USB_EP_NUM-1:0];
    wire ep_rx_ctrl_rd_en[`USB_EP_NUM-1:0];

    wire ep_rx_ctrl_rx_flush_r[`USB_EP_NUM-1:0];
    wire ep_rx_ctrl_rx_flush_set[`USB_EP_NUM-1:0];
    wire ep_rx_ctrl_rx_flush_clr[`USB_EP_NUM-1:0];
    wire ep_rx_ctrl_rx_flush_ena[`USB_EP_NUM-1:0];
    wire ep_rx_ctrl_rx_flush_next[`USB_EP_NUM-1:0];

    wire ep_rx_ctrl_rx_accept_r[`USB_EP_NUM-1:0];
    wire ep_rx_ctrl_rx_accept_set[`USB_EP_NUM-1:0];
    wire ep_rx_ctrl_rx_accept_clr[`USB_EP_NUM-1:0];
    wire ep_rx_ctrl_rx_accept_ena[`USB_EP_NUM-1:0];
    wire ep_rx_ctrl_rx_accept_next[`USB_EP_NUM-1:0];

    //// USB_EPx_STS
    wire sel_ep_sts[`USB_EP_NUM-1:0];
    wire ep_sts_wt_en[`USB_EP_NUM-1:0];
    wire ep_sts_rd_en[`USB_EP_NUM-1:0];

    //// USB_EPx_DATA
    wire sel_ep_data[`USB_EP_NUM-1:0];
    wire ep_data_wt_en[`USB_EP_NUM-1:0];
    wire ep_data_rd_en[`USB_EP_NUM-1:0];

    wire [`USB_EP0_DATA_DATA_W-1:0] ep_tx_data[`USB_EP_NUM-1:0];

    for(i=0; i<`USB_EP_NUM; i=i+1)begin:regs_ep
        //-----------------------------------------------------------------
        // Register usb_ep_cfg
        //-----------------------------------------------------------------
        assign sel_ep_cfg[i] = enable_i & (addr_i[7:0] == (`USB_EP0_CFG + i*`USB_EP_STRIDE));
        assign ep_cfg_wt_en[i] = wt_en_i & sel_ep_cfg[i];
        assign ep_cfg_rd_en[i] = rd_en_i & sel_ep_cfg[i];

        // usb_ep_cfg_int_rx [internal]
        assign ep_cfg_int_rx_ena[i] = ep_cfg_wt_en[i];
        assign ep_cfg_int_rx_next[i] = wdata_i[`USB_EP0_CFG_INT_RX_R];
        usbf_gnrl_dfflrd #(`USB_EP0_CFG_INT_RX_W, `USB_EP0_CFG_INT_RX_DEFAULT) 
            ep_cfg_int_rx_difflrd(
                ep_cfg_int_rx_ena[i],ep_cfg_int_rx_next[i],
                ep_cfg_int_rx_r[i],
                hclk_i,rstn_i
            );
        // assign ep_cfg_int_rx_o[i] = ep_cfg_int_rx_r[i];

        // usb_ep_cfg_int_tx [internal]
        assign ep_cfg_int_tx_ena[i] = ep_cfg_wt_en[i];
        assign ep_cfg_int_tx_next[i] = wdata_i[`USB_EP0_CFG_INT_TX_R];
        usbf_gnrl_dfflrd #(`USB_EP0_CFG_INT_TX_W, `USB_EP0_CFG_INT_TX_DEFAULT) 
            ep_cfg_int_tx_difflrd(
                ep_cfg_int_tx_ena[i],ep_cfg_int_tx_next[i],
                ep_cfg_int_tx_r[i],
                hclk_i,rstn_i
            );
        // assign ep_cfg_int_tx_o[i] = ep_cfg_int_tx_r[i];

        // usb_ep_cfg_stall_ep [clearable]
        assign ep_cfg_stall_ep_ack[i] = ep_sts_rx_setup_i[i];
        assign ep_cfg_stall_ep_set[i] = ep_cfg_wt_en[i] & wdata_i[`USB_EP0_CFG_STALL_EP_R];
        assign ep_cfg_stall_ep_clr[i] = ep_cfg_stall_ep_ack[i];
        assign ep_cfg_stall_ep_ena[i] = ep_cfg_stall_ep_set[i] | ep_cfg_stall_ep_clr[i];
        assign ep_cfg_stall_ep_next[i] = ep_cfg_stall_ep_set[i] | (~ep_cfg_stall_ep_clr[i]);
        usbf_gnrl_dfflrd #(`USB_EP0_CFG_STALL_EP_W, `USB_EP0_CFG_STALL_EP_DEFAULT) 
            ep_cfg_stall_ep_difflrd(
                ep_cfg_stall_ep_ena[i],ep_cfg_stall_ep_next[i],
                ep_cfg_stall_ep_r[i],
                hclk_i,rstn_i
            );
        assign ep_cfg_stall_ep_o[i] = ep_cfg_stall_ep_r[i];

        // usb_ep_cfg_iso [internal]
        assign ep_cfg_iso_ena[i] = ep_cfg_wt_en[i];
        assign ep_cfg_iso_next[i] = wdata_i[`USB_EP0_CFG_ISO_R];
        usbf_gnrl_dfflrd #(`USB_EP0_CFG_ISO_W, `USB_EP0_CFG_ISO_DEFAULT) 
            usb_ep_cfg_iso_difflrd(
                ep_cfg_iso_ena[i],ep_cfg_iso_next[i],
                ep_cfg_iso_r[i],
                hclk_i,rstn_i
            );
        assign ep_cfg_iso_o[i] = ep_cfg_iso_r[i];

        //-----------------------------------------------------------------
        // Register usb_ep_tx_ctrl
        //-----------------------------------------------------------------
        assign sel_ep_tx_ctrl[i] = enable_i & (addr_i[7:0] == (`USB_EP0_TX_CTRL + i*`USB_EP_STRIDE));
        assign ep_tx_ctrl_wt_en[i] = wt_en_i & sel_ep_tx_ctrl[i];
        assign ep_tx_ctrl_rd_en[i] = rd_en_i & sel_ep_tx_ctrl[i];

        // usb_ep_tx_ctrl_tx_flush [auto_clr]
        assign ep_tx_ctrl_tx_flush_set[i] = ep_tx_ctrl_wt_en[i] & wdata_i[`USB_EP0_TX_CTRL_TX_FLUSH_R];
        assign ep_tx_ctrl_tx_flush_clr[i] = ep_tx_ctrl_tx_flush_r[i];
        assign ep_tx_ctrl_tx_flush_ena[i] = ep_tx_ctrl_tx_flush_set[i] | ep_tx_ctrl_tx_flush_clr[i];
        assign ep_tx_ctrl_tx_flush_next[i] = ep_tx_ctrl_tx_flush_set[i] | (~ep_tx_ctrl_tx_flush_clr[i]);
        usbf_gnrl_dfflrd #(`USB_EP0_TX_CTRL_TX_FLUSH_W, `USB_EP0_TX_CTRL_TX_FLUSH_DEFAULT) 
            ep_tx_ctrl_tx_flush_difflrd(
                ep_tx_ctrl_tx_flush_ena[i],ep_tx_ctrl_tx_flush_next[i],
                ep_tx_ctrl_tx_flush_r[i],
                hclk_i,rstn_i
            );
        assign ep_tx_ctrl_tx_flush_o[i] = ep_tx_ctrl_tx_flush_r[i];

        // usb_ep_tx_ctrl_tx_start [auto_clr]
        assign ep_tx_ctrl_tx_start_set[i] = ep_tx_ctrl_wt_en[i] & wdata_i[`USB_EP0_TX_CTRL_TX_START_R];
        assign ep_tx_ctrl_tx_start_clr[i] = ep_tx_ctrl_tx_start_r[i];
        assign ep_tx_ctrl_tx_start_ena[i] = ep_tx_ctrl_tx_start_set[i] | ep_tx_ctrl_tx_start_clr[i];
        assign ep_tx_ctrl_tx_start_next[i] = ep_tx_ctrl_tx_start_set[i] | (~ep_tx_ctrl_tx_start_clr[i]);
        usbf_gnrl_dfflrd #(`USB_EP0_TX_CTRL_TX_START_W, `USB_EP0_TX_CTRL_TX_START_DEFAULT) 
            ep_tx_ctrl_tx_start_difflrd(
                ep_tx_ctrl_tx_start_ena[i],ep_tx_ctrl_tx_start_next[i],
                ep_tx_ctrl_tx_start_r[i],
                hclk_i,rstn_i
            );
        assign ep_tx_ctrl_tx_start_o[i] = ep_tx_ctrl_tx_start_r[i];

        // usb_ep_tx_ctrl_tx_len [internal]
        assign ep_tx_ctrl_tx_len_ena[i] = ep_tx_ctrl_wt_en[i];
        assign ep_tx_ctrl_tx_len_next[i] = wdata_i[`USB_EP0_TX_CTRL_TX_LEN_R];
        usbf_gnrl_dfflrd #(`USB_EP0_TX_CTRL_TX_LEN_W, `USB_EP0_TX_CTRL_TX_LEN_DEFAULT) 
            ep_tx_ctrl_tx_len_difflrd(
                ep_tx_ctrl_tx_len_ena[i],ep_tx_ctrl_tx_len_next[i],
                ep_tx_ctrl_tx_len_r[i],
                hclk_i,rstn_i
            );
        assign ep_tx_ctrl_tx_len_o[i*`USB_EP0_TX_CTRL_TX_LEN_W +: `USB_EP0_TX_CTRL_TX_LEN_W] = ep_tx_ctrl_tx_len_r[i];

        //-----------------------------------------------------------------
        // Register usb_ep_rx_ctrl
        //-----------------------------------------------------------------
        assign sel_ep_rx_ctrl[i] = enable_i & (addr_i[7:0] == (`USB_EP0_RX_CTRL + i*`USB_EP_STRIDE));
        assign ep_rx_ctrl_wt_en[i] = wt_en_i & sel_ep_rx_ctrl[i];
        assign ep_rx_ctrl_rd_en[i] = rd_en_i & sel_ep_rx_ctrl[i];

        // usb_ep_rx_ctrl_rx_flush [auto_clr]
        assign ep_rx_ctrl_rx_flush_set[i] = ep_rx_ctrl_wt_en[i] & wdata_i[`USB_EP0_RX_CTRL_RX_FLUSH_R];
        assign ep_rx_ctrl_rx_flush_clr[i] = ep_rx_ctrl_rx_flush_r[i];
        assign ep_rx_ctrl_rx_flush_ena[i] = ep_rx_ctrl_rx_flush_set[i] | ep_rx_ctrl_rx_flush_clr[i];
        assign ep_rx_ctrl_rx_flush_next[i] = ep_rx_ctrl_rx_flush_set[i] | (~ep_rx_ctrl_rx_flush_clr[i]);
        usbf_gnrl_dfflrd #(`USB_EP0_RX_CTRL_RX_FLUSH_W, `USB_EP0_RX_CTRL_RX_FLUSH_DEFAULT) 
            ep_rx_ctrl_rx_flush_difflrd(
                ep_rx_ctrl_rx_flush_ena[i],ep_rx_ctrl_rx_flush_next[i],
                ep_rx_ctrl_rx_flush_r[i],
                hclk_i,rstn_i
            );
        assign ep_rx_ctrl_rx_flush_o[i] = ep_rx_ctrl_rx_flush_r[i];

        // usb_ep_rx_ctrl_rx_accept [auto_clr]
        assign ep_rx_ctrl_rx_accept_set[i] = ep_rx_ctrl_wt_en[i] & wdata_i[`USB_EP0_RX_CTRL_RX_ACCEPT_R];
        assign ep_rx_ctrl_rx_accept_clr[i] = ep_rx_ctrl_rx_accept_r[i];
        assign ep_rx_ctrl_rx_accept_ena[i] = ep_rx_ctrl_rx_accept_set[i] | ep_rx_ctrl_rx_accept_clr[i];
        assign ep_rx_ctrl_rx_accept_next[i] = ep_rx_ctrl_rx_accept_set[i] | (~ep_rx_ctrl_rx_accept_clr[i]);
        usbf_gnrl_dfflrd #(`USB_EP0_RX_CTRL_RX_ACCEPT_W, `USB_EP0_RX_CTRL_RX_ACCEPT_DEFAULT) 
            ep_rx_ctrl_rx_accept_difflrd(
                ep_rx_ctrl_rx_accept_ena[i],ep_rx_ctrl_rx_accept_next[i],
                ep_rx_ctrl_rx_accept_r[i],
                hclk_i,rstn_i
            );
        assign ep_rx_ctrl_rx_accept_o[i] = ep_rx_ctrl_rx_accept_r[i];

        //-----------------------------------------------------------------
        // Register usb_ep_sts
        //-----------------------------------------------------------------
        assign sel_ep_sts[i] = enable_i & (addr_i[7:0] == (`USB_EP0_STS + i*`USB_EP_STRIDE));
        assign ep_sts_wt_en[i] = wt_en_i & sel_ep_sts[i];
        assign ep_sts_rd_en[i] = rd_en_i & sel_ep_sts[i];

        //-----------------------------------------------------------------
        // Register usb_ep_data
        //-----------------------------------------------------------------
        assign sel_ep_data[i]= enable_i & (addr_i[7:0] == (`USB_EP0_DATA + i*`USB_EP_STRIDE));
        assign ep_data_wt_en[i] = wt_en_i & sel_ep_data[i];
        assign ep_data_rd_en[i] = rd_en_i & sel_ep_data[i];

        // usb_ep_data_data [external]
        //// out to tx fifo
        // assign ep_tx_data[i] = {`USB_EP0_DATA_DATA_W{ep_data_wt_en[i]}} & wdata_i[`USB_EP0_DATA_DATA_R];
        // data must keep
        assign ep_tx_data[i] = wdata_i[`USB_EP0_DATA_DATA_R];
        assign ep_tx_data_o[i*`USB_EP0_DATA_DATA_W +: `USB_EP0_DATA_DATA_W] = ep_tx_data[i];



    end
endgenerate //}

//-----------------------------------------------------------------
// Register USB_EP_INTSTS
//-----------------------------------------------------------------
wire sel_ep_intsts = enable_i & (addr_i[7:0] == `USB_EP_INTSTS);
wire ep_intsts_wt_en = wt_en_i & sel_ep_intsts;
wire ep_intsts_rd_en = rd_en_i & sel_ep_intsts;

generate
    wire [`USB_EP_NUM-1:0]  ep_intsts_rx_ready_r;
    wire [`USB_EP_NUM-1:0]  ep_intsts_rx_ready_set;
    wire [`USB_EP_NUM-1:0]  ep_intsts_rx_ready_clr;
    wire [`USB_EP_NUM-1:0]  ep_intsts_rx_ready_ena;
    wire [`USB_EP_NUM-1:0]  ep_intsts_rx_ready_next;
    
    wire [`USB_EP_NUM-1:0]  ep_intsts_tx_complete_r;
    wire [`USB_EP_NUM-1:0]  ep_intsts_tx_complete_set;
    wire [`USB_EP_NUM-1:0]  ep_intsts_tx_complete_clr;
    wire [`USB_EP_NUM-1:0]  ep_intsts_tx_complete_ena;
    wire [`USB_EP_NUM-1:0]  ep_intsts_tx_complete_next;

    for(i=0; i<`USB_EP_NUM; i=i+1)begin
        // rx-ready [auto_clr]
        assign ep_intsts_rx_ready_set[i] = ep_intsts_wt_en & wdata_i[(`USB_EP_INTSTS_EP0_RX_READY_B+i) +: `USB_EP_INTSTS_EP0_RX_READY_W];
        assign ep_intsts_rx_ready_clr[i] = ep_intsts_rx_ready_r[i];
        assign ep_intsts_rx_ready_ena[i] = ep_intsts_rx_ready_set[i] | ep_intsts_rx_ready_clr[i];
        assign ep_intsts_rx_ready_next[i] = ep_intsts_rx_ready_set[i] | (~ep_intsts_rx_ready_clr[i]);
        usbf_gnrl_dfflrd #(`USB_EP_INTSTS_EP0_RX_READY_W, `USB_EP_INTSTS_EP0_RX_READY_DEFAULT) 
            ep_intsts_rx_ready_difflrd(
                ep_intsts_rx_ready_ena[i],ep_intsts_rx_ready_next[i],
                ep_intsts_rx_ready_r[i],
                hclk_i,rstn_i
            );

        // tx-complete [auto_clr]
        assign ep_intsts_tx_complete_set[i] = ep_intsts_wt_en & wdata_i[(`USB_EP_INTSTS_EP0_TX_COMPLETE_B+i) +: `USB_EP_INTSTS_EP0_TX_COMPLETE_W];
        assign ep_intsts_tx_complete_clr[i] = ep_intsts_tx_complete_r[i];
        assign ep_intsts_tx_complete_ena[i] = ep_intsts_tx_complete_set[i] | ep_intsts_tx_complete_clr[i];
        assign ep_intsts_tx_complete_next[i] = ep_intsts_tx_complete_set[i] | (~ep_intsts_tx_complete_clr[i]);
        usbf_gnrl_dfflrd #(`USB_EP_INTSTS_EP0_TX_COMPLETE_W, `USB_EP_INTSTS_EP0_TX_COMPLETE_DEFAULT) 
            ep_intsts_tx_complete_difflrd(
                ep_intsts_tx_complete_ena[i],ep_intsts_tx_complete_next[i],
                ep_intsts_tx_complete_r[i],
                hclk_i,rstn_i
            );
    end
endgenerate

//// 
// wire [`USB_EP_NUM-1:0] ep_intsts_rx_ready_clr = ep_intsts_rx_ready_r;
// wire [`USB_EP_NUM-1:0] ep_intsts_tx_complete_clr = ep_intsts_tx_complete_r;
//==========================================================================================
// Register Write }
//==========================================================================================

//==========================================================================================
// Register Read {
//==========================================================================================
//-----------------------------------------------------------------
// Wire
//-----------------------------------------------------------------
wire intr_ep_rx_ready_r[`USB_EP_NUM-1:0];
wire intr_ep_tx_complete_r[`USB_EP_NUM-1:0];
wire intr_sof_r;
wire intr_reset_r;

//-----------------------------------------------------------------
// Register usb_func_ctrl
//-----------------------------------------------------------------
reg [32-1:0] func_ctrl_r;
always @(*)begin
    func_ctrl_r = 32'b0;

    func_ctrl_r[`USB_FUNC_CTRL_HS_CHIRP_EN_R] = func_ctrl_hs_chirp_en_r;
    func_ctrl_r[`USB_FUNC_CTRL_PHY_DMPULLDOWN_R] = func_ctrl_phy_dmpulldown_r;
    func_ctrl_r[`USB_FUNC_CTRL_PHY_DPPULLDOWN_R] = func_ctrl_phy_dppulldown_r;
    func_ctrl_r[`USB_FUNC_CTRL_PHY_TERMSELECT_R] = func_ctrl_phy_termselect_r;
    func_ctrl_r[`USB_FUNC_CTRL_PHY_XCVRSELECT_R] = func_ctrl_phy_xcvrselect_r;
    func_ctrl_r[`USB_FUNC_CTRL_PHY_OPMODE_R] = func_ctrl_phy_opmode_r;
    func_ctrl_r[`USB_FUNC_CTRL_INT_EN_SOF_R] = func_ctrl_int_en_sof_r;
    func_ctrl_r[`USB_FUNC_CTRL_INT_EN_RST_R] = func_ctrl_int_en_rst_r;
end
//-----------------------------------------------------------------
// Register usb_func_stat
//-----------------------------------------------------------------
reg [32-1:0] func_stat_r;
always @(*)begin
    func_stat_r = 32'b0;

    func_stat_r[`USB_FUNC_STAT_SOF_R] = intr_sof_r;
    func_stat_r[`USB_FUNC_STAT_RST_R] = intr_reset_r;
    func_stat_r[`USB_FUNC_STAT_LINESTATE_R] = func_stat_linestate_i;
    func_stat_r[`USB_FUNC_STAT_FRAME_R] = func_stat_frame_i;
end

//-----------------------------------------------------------------
// Register usb_func_addr
//-----------------------------------------------------------------
reg [32-1:0] func_addr_r;
always @(*)begin
    func_addr_r = 32'b0;

    func_addr_r[`USB_FUNC_ADDR_DEV_ADDR_R] = func_addr_dev_addr_r;
end

//-----------------------------------------------------------------
// Register usb_ep_intsts
//-----------------------------------------------------------------
reg [32-1:0] ep_intsts_r;
integer j;
generate
    always @(*)begin
        ep_intsts_r = 32'b0;
        for(j=0; j<`USB_EP_NUM; j=j+1)begin
            ep_intsts_r[(`USB_EP_INTSTS_EP0_RX_READY_B+j) +: `USB_EP_INTSTS_EP0_RX_READY_W] = intr_ep_rx_ready_r[j];
            ep_intsts_r[(`USB_EP_INTSTS_EP0_TX_COMPLETE_B+j) +: `USB_EP_INTSTS_EP0_TX_COMPLETE_W] = intr_ep_tx_complete_r[j];

        end
    end
endgenerate

reg [32-1:0] ep_cfg_r[`USB_EP_NUM-1:0];
reg [32-1:0] ep_tx_ctrl_r[`USB_EP_NUM-1:0]; 
reg [32-1:0] ep_sts_r[`USB_EP_NUM-1:0]; 

wire ep_data_ena[`USB_EP_NUM-1:0];
wire [32-1:0] ep_data_next[`USB_EP_NUM-1:0];
wire [32-1:0] ep_data_r[`USB_EP_NUM-1:0];

generate //{
    always @(*)begin
        for(j=0; j<`USB_EP_NUM; j=j+1) begin //{
            ep_cfg_r[j] = 32'b0;
            ep_tx_ctrl_r[j] = 32'b0;
            ep_sts_r[j] = 32'b0;
        end //}

        for(j=0; j<`USB_EP_NUM; j=j+1) begin //{
            //-----------------------------------------------------------------
            // Register usb_ep_cfg
            //-----------------------------------------------------------------
            ep_cfg_r[j][`USB_EP0_CFG_INT_RX_R] = ep_cfg_int_rx_r[j];
            ep_cfg_r[j][`USB_EP0_CFG_INT_TX_R] = ep_cfg_int_tx_r[j];
            ep_cfg_r[j][`USB_EP0_CFG_ISO_R] = ep_cfg_iso_r[j];

            //-----------------------------------------------------------------
            // Register usb_ep_tx_ctrl
            //-----------------------------------------------------------------
            ep_tx_ctrl_r[j][`USB_EP0_TX_CTRL_TX_LEN_R] = ep_tx_ctrl_tx_len_r[j];

            //-----------------------------------------------------------------
            // Register usb_ep_sts
            //-----------------------------------------------------------------
            ep_sts_r[j][`USB_EP0_STS_TX_ERR_R] = ep_sts_tx_err_i;
            ep_sts_r[j][`USB_EP0_STS_TX_BUSY_R] = ep_sts_tx_busy_i;
            ep_sts_r[j][`USB_EP0_STS_RX_ERR_R] = ep_sts_rx_err_i;
            ep_sts_r[j][`USB_EP0_STS_RX_SETUP_R] = ep_sts_rx_setup_i;
            ep_sts_r[j][`USB_EP0_STS_RX_READY_R] = ep_sts_rx_ready_i;
            ep_sts_r[j][`USB_EP0_STS_RX_COUNT_R] = ep_sts_rx_count_i[j*`USB_EP0_STS_RX_COUNT_W +: `USB_EP0_STS_RX_COUNT_W];

        end //}

    end

    //-----------------------------------------------------------------
    // Register usb_ep_data
    //-----------------------------------------------------------------
    // `ifdef USB_ITF_ICB
    for(i=0; i<`USB_EP_NUM; i=i+1) begin //{
        assign ep_data_r[i][7:0] = ep_rx_data_i[i*`USB_EP0_DATA_DATA_W +: `USB_EP0_DATA_DATA_W];
        assign ep_data_r[i][31:8] = 24'b0;
    end //}

    // `else // ~USB_ITF_ICB
    // for(i=0; i<`USB_EP_NUM; i=i+1) begin //{
    //     assign ep_data_ena[i] = ep_data_rd_en[i];
    //     assign ep_data_next[i][7:0] = ep_rx_data_i[i*`USB_EP0_DATA_DATA_W +: `USB_EP0_DATA_DATA_W];
    //     assign ep_data_next[i][31:8] = 24'b0;
    //     usbf_gnrl_dfflrd #(32, 32'b0) 
    //         ep_data_difflrd(
    //             ep_data_ena[i],ep_data_next[i],
    //             ep_data_r[i],
    //             hclk_i,rstn_i
    //         );        
    // end //}
    // `endif // USB_ITF_ICB

endgenerate //}

//-----------------------------------------------------------------
// Read MUX
//-----------------------------------------------------------------
reg  [31:0]     ep_rdata_r;
wire [31:0]     rdata;
generate //{

    always @(*)begin
        ep_rdata_r = 32'b0;

        for(j=0; j<`USB_EP_NUM; j=j+1) begin //{
            ep_rdata_r =    ep_rdata_r |
                            ({32{sel_ep_cfg[j]}} & ep_cfg_r[j]) |
                            ({32{sel_ep_tx_ctrl[j]}} & ep_tx_ctrl_r[j]) |
                            ({32{sel_ep_sts[j]}} & ep_sts_r[j]) |
                            ({32{sel_ep_data[j]}} & ep_data_r[j]);
        end //}
    end
   
    assign rdata =  ({32{sel_func_ctrl}} & func_ctrl_r) |
                    ({32{sel_func_stat}} & func_stat_r) |
                    ({32{sel_func_addr}} & func_addr_r) |
                    ({32{sel_ep_intsts}} & ep_intsts_r) |
                    ep_rdata_r;

    assign rdata_o = enable_i ? rdata : 32'b0;
endgenerate //}
//==========================================================================================
// Register Read }
//==========================================================================================

//-----------------------------------------------------------------
// MEM Read and Write req
//-----------------------------------------------------------------
generate //{
    for(i=0; i<`USB_EP_NUM; i=i+1) begin //{
        assign ep_data_rd_req_o[i] = ep_data_rd_en[i];
        assign ep_data_wt_req_o[i] = ep_data_wt_en[i];
    end //}
endgenerate //}

//-----------------------------------------------------------------
// wt_ready and rd_ready
// Just MEM read and write need waiting CDC.
// It's a pulse signal.
//-----------------------------------------------------------------
reg mem_wt_access;
reg mem_rd_access;
reg mem_access   ;
generate //{
    always @(*)begin
        mem_wt_access = 1'b0;
        mem_rd_access = 1'b0;
        mem_access    = 1'b0;
        for(j=0; j<`USB_EP_NUM; j=j+1) begin //{
            mem_wt_access = mem_wt_access | ep_data_wt_en[j];
            mem_rd_access = mem_rd_access | ep_data_rd_en[j];
            mem_access    = mem_access    | sel_ep_data[j];
        end //}
    end
endgenerate //}


assign wt_ready_o = mem_access ?    mem_wt_ready_i : wt_en_i;
assign rd_ready_o = mem_access ?    mem_rd_ready_i : rd_en_i;


//==========================================================================================
// Interrupt {
//==========================================================================================
//-----------------------------------------------------------------
// EP rx ready and tx complete
//-----------------------------------------------------------------
generate //{
    // wire intr_ep_rx_ready_r[`USB_EP_NUM-1:0]; // define ahead
    wire intr_ep_rx_ready_set[`USB_EP_NUM-1:0];
    wire intr_ep_rx_ready_clr[`USB_EP_NUM-1:0];
    wire intr_ep_rx_ready_ena[`USB_EP_NUM-1:0];
    wire intr_ep_rx_ready_next[`USB_EP_NUM-1:0];

    // wire intr_ep_tx_complete_r[`USB_EP_NUM-1:0]; // define ahead
    wire intr_ep_tx_complete_set[`USB_EP_NUM-1:0];
    wire intr_ep_tx_complete_clr[`USB_EP_NUM-1:0];
    wire intr_ep_tx_complete_ena[`USB_EP_NUM-1:0];
    wire intr_ep_tx_complete_next[`USB_EP_NUM-1:0];     

    for(i=0; i<`USB_EP_NUM; i=i+1) begin //{
        assign intr_ep_rx_ready_set[i] = (~intr_ep_rx_ready_r[i]) & ep_rx_ready_intr_set_i[i];
        assign intr_ep_rx_ready_clr[i] = intr_ep_rx_ready_r[i] & ep_intsts_rx_ready_clr[i];
        assign intr_ep_rx_ready_ena[i] = intr_ep_rx_ready_set[i] | intr_ep_rx_ready_clr[i];
        assign intr_ep_rx_ready_next[i] = intr_ep_rx_ready_set[i] | (~intr_ep_rx_ready_clr[i]);
        usbf_gnrl_dfflrd #(1, 1'b0) 
            intr_ep_rx_ready_difflrd(
                intr_ep_rx_ready_ena[i],intr_ep_rx_ready_next[i],
                intr_ep_rx_ready_r[i],
                hclk_i,rstn_i
            );

        assign intr_ep_tx_complete_set[i] = (~intr_ep_tx_complete_r[i]) & ep_tx_complete_intr_set_i[i];
        assign intr_ep_tx_complete_clr[i] = intr_ep_tx_complete_r[i] & ep_intsts_tx_complete_clr[i];
        assign intr_ep_tx_complete_ena[i] = intr_ep_tx_complete_set[i] | intr_ep_tx_complete_clr[i];
        assign intr_ep_tx_complete_next[i] = intr_ep_tx_complete_set[i] | (~intr_ep_tx_complete_clr[i]);
        usbf_gnrl_dfflrd #(1, 1'b0) 
            intr_ep_tx_complete_difflrd(
                intr_ep_tx_complete_ena[i],intr_ep_tx_complete_next[i],
                intr_ep_tx_complete_r[i],
                hclk_i,rstn_i
            );

    end //}
endgenerate //}

//-----------------------------------------------------------------
// SOF
//-----------------------------------------------------------------
// wire intr_sof_r; // define ahead
wire intr_sof_set = (~intr_sof_r) & sof_intr_set_i;
wire intr_sof_clr = intr_sof_r & stat_sof_clr;
wire intr_sof_ena = intr_sof_set | intr_sof_clr;
wire intr_sof_next = intr_sof_set | (~intr_sof_clr);
usbf_gnrl_dfflrd #(1, 1'b0) 
    intr_sof_difflrd(
        intr_sof_ena,intr_sof_next,
        intr_sof_r,
        hclk_i,rstn_i
    );

//-----------------------------------------------------------------
// RESET
//-----------------------------------------------------------------
// wire intr_reset_r; // define ahead
wire intr_reset_set = (~intr_reset_r) & rst_intr_set_i;
wire intr_reset_clr = intr_reset_r & stat_rst_clr;
wire intr_reset_ena = intr_reset_set | intr_reset_clr;
wire intr_reset_next = intr_reset_set | (~intr_reset_clr);
usbf_gnrl_dfflrd #(1, 1'b0) 
    intr_reset_difflrd(
        intr_reset_ena,intr_reset_next,
        intr_reset_r,
        hclk_i,rstn_i
    );

//-----------------------------------------------------------------
// EP rx ready and tx complete
//-----------------------------------------------------------------
wire [`USB_EP_NUM-1:0] intr_ep;
wire [`USB_EP_NUM-1:0] intr_ep_rx_ready;
wire [`USB_EP_NUM-1:0] intr_ep_tx_complete;
generate //{
    for(i=0; i<`USB_EP_NUM; i=i+1) begin //{
        assign intr_ep_rx_ready[i] = intr_ep_rx_ready_r[i] & ep_cfg_int_rx_r[i];
        assign intr_ep_tx_complete[i] = intr_ep_tx_complete_r[i] & ep_cfg_int_tx_r[i];
        assign intr_ep[i] = intr_ep_rx_ready[i] | intr_ep_tx_complete[i];
    end //}
endgenerate //}

wire intr_sof   = func_ctrl_int_en_sof_r & intr_sof_r;
wire intr_reset = func_ctrl_int_en_rst_r & intr_reset_r;

assign intr_o = (|intr_ep)      |
                intr_sof        |
                intr_reset;


endmodule