//=================================================================
//
// Device top module
// This module integrates CORE+EPU+MEM+CSR+BIU
//
// Version: V1.0
// Created by Zeba-Xie @github
//
// The integrated structure is as follows:
// |------|           |-----|       |-----------|
// |      |--RX SIE-->|     |--wt-->|  RX-FIFO  |
// | CORE |           | EPU |       |    MEM    |   
// |      |--TX SIE<--|     |--rd<--|  TX-FIFO  |
// |------|           |-----|       |-----------|
//    ^                  ^                ^
//    |------------------|----------------|
//                       v
//                    |SYNC |
//                       v
//                    | CSR |
//                    |-----|
//                       v
//                    | BIU |
// 
//=================================================================

`include "usbf_cfg_defs.v"

module usbf_device(
     input                  hclk_i
    ,input                  hrstn_i

    `ifdef USB_ITF_AHB
    ////// AHB slave interface
    ,input                  hsel_i
    ,input                  hwrite_i
    ,input  [1:0]           htrans_i
    ,input  [2:0]           hburst_i
    ,input  [31:0]          hwdata_i
    ,input  [31:0]          haddr_i
    ,input  [2:0]           hsize_i
    ,input                  hready_i
    ,output                 hready_o
    ,output [1:0]           hresp_o
    ,output [31:0]          hrdata_o
    `endif

    `ifdef USB_ITF_ICB
    ////// ICB slave interface
    // CMD
    ,input                  icb_cmd_valid_i
    ,output                 icb_cmd_ready_o
    ,input  [32-1:0]        icb_cmd_addr_i
    ,input                  icb_cmd_read_i
    ,input  [32-1:0]        icb_cmd_wdata_i
    // RSP
    ,output                 icb_rsp_valid_o
    ,input                  icb_rsp_ready_i
    ,output [32-1:0]        icb_rsp_rdata_o
    `endif

    ////// UTMI interface
    ,input                  phy_clk_i
    ,input  [7:0]           utmi_data_in_i
    ,input                  utmi_txready_i
    ,input                  utmi_rxvalid_i
    ,input                  utmi_rxactive_i
    ,input                  utmi_rxerror_i
    ,input  [1:0]           utmi_linestate_i
    ,output [7:0]           utmi_data_out_o
    ,output                 utmi_txvalid_o
    ,output [1:0]           utmi_op_mode_o
    ,output [1:0]           utmi_xcvrselect_o
    ,output                 utmi_termselect_o
    ,output                 utmi_dppulldown_o
    ,output                 utmi_dmpulldown_o

    ////// Interrupt
    ,output                 intr_o

    ////// Others
    ,input  [1:0]           usb_scaledown_mode_i

);

//-----------------------------------------------------------------
// Wire
//-----------------------------------------------------------------
////// CSR<-->BIU 
wire                                            wt_en;
wire                                            rd_en;
wire                                            enable;
wire    [31:0]                                  addr ;
wire    [31:0]                                  wdata;
wire    [31:0]                                  rdata;

wire                                            wt_ready;
wire                                            rd_ready;
wire                                            mem_wt_ready;
wire                                            mem_rd_ready;

////// CSR<-->CORE
wire                                            csr_func_ctrl_hs_chirp_en;
wire    [`USB_FUNC_ADDR_DEV_ADDR_W-1:0]         csr_func_addr_dev_addr;
wire    [`USB_EP_NUM-1:0]                       csr_ep_cfg_stall_ep;
wire    [`USB_EP_NUM-1:0]                       csr_ep_cfg_iso;
wire    [`USB_FUNC_STAT_FRAME_W-1:0]            csr_func_stat_frame;
wire                                            csr_rst_intr_set;
wire                                            csr_sof_intr_set;
wire    [`USB_EP_NUM-1:0]                       csr_ep_rx_ready_intr_set;
wire    [`USB_EP_NUM-1:0]                       csr_ep_tx_complete_intr_set;

wire                                            func_ctrl_hs_chirp_en;
wire    [`USB_FUNC_ADDR_DEV_ADDR_W-1:0]         func_addr_dev_addr;
wire    [`USB_EP_NUM-1:0]                       ep_cfg_stall_ep;
wire    [`USB_EP_NUM-1:0]                       ep_cfg_iso;
wire    [`USB_FUNC_STAT_FRAME_W-1:0]            func_stat_frame;
wire                                            rst_intr_set;
wire                                            sof_intr_set;
wire    [`USB_EP_NUM-1:0]                       ep_rx_ready_intr_set;
wire    [`USB_EP_NUM-1:0]                       ep_tx_complete_intr_set;

////// CSR<-->EPU
wire    [`USB_EP_NUM-1:0]                       csr_ep_tx_ctrl_tx_start;
wire    [`USB_EP0_TX_CTRL_TX_LEN_W*`USB_EP_NUM-1:0]   csr_ep_tx_ctrl_tx_len;
wire    [`USB_EP_NUM-1:0]                       csr_ep_rx_ctrl_rx_accept;
wire    [`USB_EP_NUM-1:0]                       csr_ep_sts_tx_err;
wire    [`USB_EP_NUM-1:0]                       csr_ep_sts_tx_busy;
wire    [`USB_EP_NUM-1:0]                       csr_ep_sts_rx_err;
wire    [`USB_EP_NUM-1:0]                       csr_ep_sts_rx_setup;
wire    [`USB_EP_NUM-1:0]                       csr_ep_sts_rx_ready;
wire    [`USB_EP0_STS_RX_COUNT_W*`USB_EP_NUM-1:0] csr_ep_sts_rx_count;

wire    [`USB_EP_NUM-1:0]                       ep_tx_ctrl_tx_start;
wire    [`USB_EP0_TX_CTRL_TX_LEN_W*`USB_EP_NUM-1:0]   ep_tx_ctrl_tx_len;
wire    [`USB_EP_NUM-1:0]                       ep_rx_ctrl_rx_accept;
wire    [`USB_EP_NUM-1:0]                       ep_sts_tx_err;
wire    [`USB_EP_NUM-1:0]                       ep_sts_tx_busy;
wire    [`USB_EP_NUM-1:0]                       ep_sts_rx_err;
wire    [`USB_EP_NUM-1:0]                       ep_sts_rx_setup;
wire    [`USB_EP_NUM-1:0]                       ep_sts_rx_ready;
wire    [`USB_EP0_STS_RX_COUNT_W*`USB_EP_NUM-1:0] ep_sts_rx_count;
////// CSR<-->MEM
wire    [`USB_EP_NUM-1:0]                       csr_ep_rx_ctrl_rx_flush;
wire    [`USB_EP_NUM-1:0]                       csr_ep_data_wt_req;
wire    [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  csr_ep_rx_data;
wire    [`USB_EP_NUM-1:0]                       csr_ep_tx_ctrl_tx_flush;
wire    [`USB_EP_NUM-1:0]                       csr_ep_data_rd_req;
wire    [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  csr_ep_tx_data;

wire    [`USB_EP_NUM-1:0]                       ep_rx_ctrl_rx_flush;
wire    [`USB_EP_NUM-1:0]                       ep_data_wt_req;
wire    [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  ep_rx_data;
wire    [`USB_EP_NUM-1:0]                       ep_tx_ctrl_tx_flush;
wire    [`USB_EP_NUM-1:0]                       ep_data_rd_req;
wire    [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  ep_tx_data;

////// CSR<-->SYNC
wire                                            csr_utmi_dmpulldown;
wire                                            csr_utmi_dppulldown;
wire                                            csr_utmi_termselect;
wire    [1:0]                                   csr_utmi_xcvrselect;
wire    [1:0]                                   csr_utmi_op_mode;
wire    [1:0]                                   csr_utmi_linestate;

////// EPU<-->CORE
wire    [`USB_EP_NUM-1:0]                       core_sie_rx_space;
wire    [`USB_EP_NUM-1:0]                       core_sie_rx_valid;
wire    [`USB_EP_NUM-1:0]                       core_sie_rx_setup;
wire                                            core_sie_rx_strb;
wire    [  7:0]                                 core_sie_rx_data;
wire                                            core_sie_rx_last;
wire                                            core_sie_rx_crc_err;
wire    [`USB_EP_NUM-1:0]                       core_sie_tx_ready;
wire    [`USB_EP_NUM-1:0]                       core_sie_tx_valid;
wire    [`USB_EP_NUM-1:0]                       core_sie_tx_strb;
wire    [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  core_sie_tx_data;
wire    [`USB_EP_NUM-1:0]                       core_sie_tx_last;
wire    [`USB_EP_NUM-1:0]                       core_sie_tx_accept;
////// EPU<-->MEM
wire    [`USB_EP_NUM-1:0]                       mem_ep_data_wt_req;
wire    [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  mem_ep_rx_data;
wire    [`USB_EP_NUM-1:0]                       mem_ep_rx_full;
wire    [`USB_EP_NUM-1:0]                       mem_ep_data_rd_req;
wire    [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  mem_ep_tx_data;
wire    [`USB_EP_NUM-1:0]                       mem_ep_tx_empty;

//-----------------------------------------------------------------
// BIU
//-----------------------------------------------------------------
usbf_biu u_usbf_biu(
    .hclk_i                             (hclk_i),
    .hrstn_i                            (hrstn_i),

    `ifdef USB_ITF_AHB
    ////// AHB slave interface
    .hsel_i                             (hsel_i),
    .hwrite_i                           (hwrite_i),
    .htrans_i                           (htrans_i),
    .hburst_i                           (hburst_i),
    .hwdata_i                           (hwdata_i),
    .haddr_i                            (haddr_i),
    .hsize_i                            (hsize_i),
    .hready_i                           (hready_i),
    .hready_o                           (hready_o),
    .hresp_o                            (hresp_o),
    .hrdata_o                           (hrdata_o),
    `endif

    `ifdef USB_ITF_ICB
    ////// ICB slave interface
    .icb_cmd_valid_i                    (icb_cmd_valid_i),
    .icb_cmd_ready_o                    (icb_cmd_ready_o),
    .icb_cmd_addr_i                     (icb_cmd_addr_i ),
    .icb_cmd_read_i                     (icb_cmd_read_i ),
    .icb_cmd_wdata_i                    (icb_cmd_wdata_i),
    .icb_rsp_valid_o                    (icb_rsp_valid_o),
    .icb_rsp_ready_i                    (icb_rsp_ready_i),
    .icb_rsp_rdata_o                    (icb_rsp_rdata_o),
    `endif

    ////// CSR interface
    .wt_en_o                            (wt_en),      
    .rd_en_o                            (rd_en),
    .enable_o                           (enable),
    .addr_o                             (addr ),
    .wdata_o                            (wdata),
    .rdata_i                            (rdata),
    .wt_ready_i                         (wt_ready),
    .rd_ready_i                         (rd_ready)
);

//-----------------------------------------------------------------
// CSR
//-----------------------------------------------------------------
usbf_csr u_usbf_csr(
    .hclk_i                             (hclk_i),                                         
    .rstn_i                             (hrstn_i),                                     
 
    ////// BIU interface 
    .wt_en_i                            (wt_en),                                 
    .rd_en_i                            (rd_en),     
    .enable_i                           (enable),                            
    .addr_i                             (addr ),                                 
    .wdata_i                            (wdata),                                 
    .rdata_o                            (rdata),         

    .wt_ready_o                         (wt_ready),
    .rd_ready_o                         (rd_ready),                     
 
    ////// Device core interface                                                             
    .func_ctrl_hs_chirp_en_o            (csr_func_ctrl_hs_chirp_en ),                                                                          
    .func_addr_dev_addr_o               (csr_func_addr_dev_addr),                                                                            
    .ep_cfg_stall_ep_o                  (csr_ep_cfg_stall_ep),
    .ep_cfg_iso_o                       (csr_ep_cfg_iso),                                                                             
    .func_stat_frame_i                  (csr_func_stat_frame),  
    .rst_intr_set_i                     (csr_rst_intr_set),
    .sof_intr_set_i                     (csr_sof_intr_set), 
    .ep_rx_ready_intr_set_i             (csr_ep_rx_ready_intr_set),     
    .ep_tx_complete_intr_set_i          (csr_ep_tx_complete_intr_set),                                                    
 
    ////// EPU(endpoint) interface                                                       
    .ep_tx_ctrl_tx_start_o              (csr_ep_tx_ctrl_tx_start),                                             
    .ep_tx_ctrl_tx_len_o                (csr_ep_tx_ctrl_tx_len),                                                
    .ep_rx_ctrl_rx_accept_o             (csr_ep_rx_ctrl_rx_accept),          
    .ep_sts_tx_err_i                    (csr_ep_sts_tx_err),                                             
    .ep_sts_tx_busy_i                   (csr_ep_sts_tx_busy),                                         
    .ep_sts_rx_err_i                    (csr_ep_sts_rx_err),                                              
    .ep_sts_rx_setup_i                  (csr_ep_sts_rx_setup),                                                         
    .ep_sts_rx_ready_i                  (csr_ep_sts_rx_ready),                                                          
    .ep_sts_rx_count_i                  (csr_ep_sts_rx_count),                                                         
 
    ////// MEM(memory) interface 
        // RX 
    .ep_rx_ctrl_rx_flush_o              (csr_ep_rx_ctrl_rx_flush),                                                                            
    .ep_data_rd_req_o                   (csr_ep_data_rd_req),                                                
    .ep_rx_data_i                       (csr_ep_rx_data),                                      
        // TX 
    .ep_tx_ctrl_tx_flush_o              (csr_ep_tx_ctrl_tx_flush),   
    .ep_data_wt_req_o                   (csr_ep_data_wt_req),                                                                                      
    .ep_tx_data_o                       (csr_ep_tx_data),                                             
      
    ////// Device interface 
    .func_ctrl_phy_dmpulldown_o         (csr_utmi_dmpulldown),                                                                         
    .func_ctrl_phy_dppulldown_o         (csr_utmi_dppulldown),                                                                         
    .func_ctrl_phy_termselect_o         (csr_utmi_termselect),                                                                         
    .func_ctrl_phy_xcvrselect_o         (csr_utmi_xcvrselect),                                                                         
    .func_ctrl_phy_opmode_o             (csr_utmi_op_mode),                                                                                                                                                        
    .func_stat_linestate_i              (csr_utmi_linestate),  

    // interrupt req
    .intr_o                             (intr_o),
    .mem_wt_ready_i                     (mem_wt_ready),
    .mem_rd_ready_i                     (mem_rd_ready)                                                            

);
//-----------------------------------------------------------------
// SYNC
//-----------------------------------------------------------------
usbf_sync u_usbf_sync(
    .phy_clk_i                          (phy_clk_i),
    .hclk_i                             (hclk_i),
    .rstn_i                             (hrstn_i),

    // connect to CSR
    .func_ctrl_hs_chirp_en_i            (csr_func_ctrl_hs_chirp_en ), 
    .func_addr_dev_addr_i               (csr_func_addr_dev_addr),     
    .ep_cfg_stall_ep_i                  (csr_ep_cfg_stall_ep),
    .ep_cfg_iso_i                       (csr_ep_cfg_iso),             
    .func_stat_frame_o                  (csr_func_stat_frame),  
    .rst_intr_set_o                     (csr_rst_intr_set),
    .sof_intr_set_o                     (csr_sof_intr_set), 
    .ep_rx_ready_intr_set_o             (csr_ep_rx_ready_intr_set),   
    .ep_tx_complete_intr_set_o          (csr_ep_tx_complete_intr_set),

    .ep_tx_ctrl_tx_start_i              (csr_ep_tx_ctrl_tx_start), 
    .ep_tx_ctrl_tx_len_i                (csr_ep_tx_ctrl_tx_len),   
    .ep_rx_ctrl_rx_accept_i             (csr_ep_rx_ctrl_rx_accept),
    .ep_sts_tx_err_o                    (csr_ep_sts_tx_err),       
    .ep_sts_tx_busy_o                   (csr_ep_sts_tx_busy),      
    .ep_sts_rx_err_o                    (csr_ep_sts_rx_err),       
    .ep_sts_rx_setup_o                  (csr_ep_sts_rx_setup),     
    .ep_sts_rx_ready_o                  (csr_ep_sts_rx_ready),     
    .ep_sts_rx_count_o                  (csr_ep_sts_rx_count),     

    .ep_rx_ctrl_rx_flush_i              (csr_ep_rx_ctrl_rx_flush),
    .ep_data_rd_req_i                   (csr_ep_data_rd_req),     
    .ep_rx_data_o                       (csr_ep_rx_data),         
    .ep_tx_ctrl_tx_flush_i              (csr_ep_tx_ctrl_tx_flush), 
    .ep_data_wt_req_i                   (csr_ep_data_wt_req),      
    .ep_tx_data_i                       (csr_ep_tx_data),          

    .func_ctrl_phy_dmpulldown_i         (csr_utmi_dmpulldown),
    .func_ctrl_phy_dppulldown_i         (csr_utmi_dppulldown),
    .func_ctrl_phy_termselect_i         (csr_utmi_termselect),
    .func_ctrl_phy_xcvrselect_i         (csr_utmi_xcvrselect),
    .func_ctrl_phy_opmode_i             (csr_utmi_op_mode),   
    .func_stat_linestate_o              (csr_utmi_linestate), 

    // connect to phy domain modules
    .sh2pl_func_ctrl_hs_chirp_en_o      (func_ctrl_hs_chirp_en),
    .sh2pb_func_addr_dev_addr_o         (func_addr_dev_addr),
    .sh2pl_ep_cfg_stall_ep_o            (ep_cfg_stall_ep),
    .sh2pl_ep_cfg_iso_o                 (ep_cfg_iso),
    .p2hb_func_stat_frame_i             (func_stat_frame),
    .p2ht_rst_intr_set_i                (rst_intr_set),
    .p2ht_sof_intr_set_i                (sof_intr_set),
    .p2ht_ep_rx_ready_intr_set_i        (ep_rx_ready_intr_set),
    .p2ht_ep_tx_complete_intr_set_i     (ep_tx_complete_intr_set),
    
    .sh2pt_ep_tx_ctrl_tx_start_o        (ep_tx_ctrl_tx_start),
    .sh2pb_ep_tx_ctrl_tx_len_o          (ep_tx_ctrl_tx_len),
    .sh2pt_ep_rx_ctrl_rx_accept_o       (ep_rx_ctrl_rx_accept),
    .p2hl_ep_sts_tx_err_i               (ep_sts_tx_err),
    .p2hl_ep_sts_tx_busy_i              (ep_sts_tx_busy),
    .p2hl_ep_sts_rx_err_i               (ep_sts_rx_err),
    .p2hl_ep_sts_rx_setup_i             (ep_sts_rx_setup),
    .p2hl_ep_sts_rx_ready_i             (ep_sts_rx_ready),
    .p2hb_ep_sts_rx_count_i             (ep_sts_rx_count),
    
    .sh2pt_ep_rx_ctrl_rx_flush_o        (ep_rx_ctrl_rx_flush),
    .sh2pt_ep_data_rd_req_o             (ep_data_rd_req),
    .p2hb_ep_rx_data_i                  (ep_rx_data),
    .sh2pt_ep_tx_ctrl_tx_flush_o        (ep_tx_ctrl_tx_flush),
    .sh2pt_ep_data_wt_req_o             (ep_data_wt_req),
    .sh2pb_ep_tx_data_o                 (ep_tx_data),
    
    .sh2pl_func_ctrl_phy_dmpulldown_o   (utmi_dmpulldown_o),
    .sh2pl_func_ctrl_phy_dppulldown_o   (utmi_dppulldown_o),
    .sh2pl_func_ctrl_phy_termselect_o   (utmi_termselect_o),
    .sh2pb_func_ctrl_phy_xcvrselect_o   (utmi_xcvrselect_o),
    .sh2pb_func_ctrl_phy_opmode_o       (utmi_op_mode_o),
    .p2hb_func_stat_linestate_i         (utmi_linestate_i),

    .mem_wt_ready_o                     (mem_wt_ready),
    .mem_rd_ready_o                     (mem_rd_ready)
);

//-----------------------------------------------------------------
// EPU
//-----------------------------------------------------------------
usbf_epu u_usbf_epu(
    .phy_clk_i                          (phy_clk_i),   
    .rstn_i                             (hrstn_i),

    //////  CORE interface
        //  RX SIE
    .core_sie_rx_space_o                (core_sie_rx_space),         
    .core_sie_rx_valid_i                (core_sie_rx_valid),         
    .core_sie_rx_setup_i                (core_sie_rx_setup),         
            //  SIE shared
    .core_sie_rx_strb_i                 (core_sie_rx_strb),         
    .core_sie_rx_data_i                 (core_sie_rx_data),         
    .core_sie_rx_last_i                 (core_sie_rx_last),         
    .core_sie_rx_crc_err_i              (core_sie_rx_crc_err),                      
        //  TX SIE
    .core_sie_tx_ready_o                (core_sie_tx_ready),                    
    .core_sie_tx_valid_o                (core_sie_tx_valid),                  
    .core_sie_tx_strb_o                 (core_sie_tx_strb),                 
    .core_sie_tx_data_o                 (core_sie_tx_data),                 
    .core_sie_tx_last_o                 (core_sie_tx_last),                 
    .core_sie_tx_accept_i               (core_sie_tx_accept),     
 
    //////  MEM interface
        //  RX FIFO (Write)
    .mem_ep_data_wt_req_o               (mem_ep_data_wt_req),        
    .mem_ep_rx_data_o                   (mem_ep_rx_data),    
    .mem_ep_rx_full_i                   (mem_ep_rx_full),    
        //  TX FIFO (Read)
    .mem_ep_data_rd_req_o               (mem_ep_data_rd_req),                        
    .mem_ep_tx_data_i                   (mem_ep_tx_data),                    
    .mem_ep_tx_empty_i                  (mem_ep_tx_empty),                    

    //////  CSR interface
        //  RX Reg
    .csr_ep_sts_rx_count_o              (ep_sts_rx_count),                                 
    .csr_ep_sts_rx_ready_o              (ep_sts_rx_ready),                                 
    .csr_ep_sts_rx_err_o                (ep_sts_rx_err),                             
    .csr_ep_sts_rx_setup_o              (ep_sts_rx_setup),                                 
    .csr_ep_sts_rx_ack_i                (ep_rx_ctrl_rx_accept),                             
        //  TX Reg
    .csr_ep_tx_ctrl_tx_flush_i          (ep_tx_ctrl_tx_flush),                                    
    .csr_ep_tx_ctrl_tx_length_i         (ep_tx_ctrl_tx_len),                                
    .csr_ep_tx_ctrl_tx_start_i          (ep_tx_ctrl_tx_start),                                
    .csr_ep_sts_tx_err_o                (ep_sts_tx_err),                        
    .csr_ep_sts_tx_busy_o               (ep_sts_tx_busy)                           
);

//-----------------------------------------------------------------
// MEM
//-----------------------------------------------------------------
usbf_mem u_usbf_mem(
    .phy_clk_i                          (phy_clk_i),               
    .rstn_i                             (hrstn_i),                                   

    ////// CSR interface
    //// RX-FIFO Read
    .csr_ep_rx_ctrl_rx_flush_i          (ep_rx_ctrl_rx_flush),                                                
    .csr_ep_data_rd_req_i               (ep_data_rd_req),                                           
    .csr_ep_rx_data_o                   (ep_rx_data),                                       
    //// TX-FIFO Write
    .csr_ep_tx_ctrl_tx_flush_i          (ep_tx_ctrl_tx_flush),                                       
    .csr_ep_data_wt_req_i               (ep_data_wt_req),                                   
    .csr_ep_tx_data_i                   (ep_tx_data),                               

    ////// EPU interface 
    //// RX-FIFO Write 
    .epu_ep_data_wt_req_i               (mem_ep_data_wt_req),                                       
    .epu_ep_rx_full_o                   (mem_ep_rx_full),                                   
    .epu_ep_rx_data_i                   (mem_ep_rx_data),                                   
    //// TX-FIFO Read
    .epu_ep_data_rd_req_i               (mem_ep_data_rd_req),                                                        
    .epu_ep_tx_empty_o                  (mem_ep_tx_empty),                                                   
    .epu_ep_tx_data_o                   (mem_ep_tx_data)                                                 
     
);

//-----------------------------------------------------------------
// CORE
//-----------------------------------------------------------------
usbf_core u_usbf_core
(
    .clk_i                              (phy_clk_i),   
    .rstn_i                             (hrstn_i),   

    // UTMI interface
    /////////////////////////////////////
    .utmi_data_o                        (utmi_data_out_o),                                               
    .utmi_data_i                        (utmi_data_in_i),                                           
    .utmi_txvalid_o                     (utmi_txvalid_o),                                           
    .utmi_txready_i                     (utmi_txready_i),                                           
    .utmi_rxvalid_i                     (utmi_rxvalid_i),                                           
    .utmi_rxactive_i                    (utmi_rxactive_i),                                               
    .utmi_rxerror_i                     (utmi_rxerror_i),                                           
    .utmi_linestate_i                   (utmi_linestate_i),                                               

    // EPU interface
    /////////////////////////////////////
    // Rx SIE Interface (shared)
    .rx_strb_o                          (core_sie_rx_strb),                                  
    .rx_data_o                          (core_sie_rx_data),                                  
    .rx_last_o                          (core_sie_rx_last),                                  
    .rx_crc_err_o                       (core_sie_rx_crc_err),                                                             
    // EP Rx SIE Interface 
    .ep_rx_setup_o                      (core_sie_rx_setup),               
    .ep_rx_valid_o                      (core_sie_rx_valid),               
    .ep_rx_space_i                      (core_sie_rx_space),               
    // EP0 Tx SIE Interface 
    .ep_tx_ready_i                      (core_sie_tx_ready),               
    .ep_tx_data_valid_i                 (core_sie_tx_valid),                       
    .ep_tx_data_strb_i                  (core_sie_tx_strb),                   
    .ep_tx_data_i                       (core_sie_tx_data),               
    .ep_tx_data_last_i                  (core_sie_tx_last),                   
    .ep_tx_data_accept_o                (core_sie_tx_accept),    

    // CSR interface
    /////////////////////////////////////
    .func_ctrl_hs_chirp_en_i            (func_ctrl_hs_chirp_en),             
    .func_addr_dev_addr_i               (func_addr_dev_addr),
    .ep_stall_i                         (ep_cfg_stall_ep), 
    .ep_iso_i                           (ep_cfg_iso),                                                                                             
    .func_stat_frame_o                  (func_stat_frame),
    .rst_intr_set_o                     (rst_intr_set),
    .sof_intr_set_o                     (sof_intr_set),        
    .ep_rx_ready_intr_set_o             (ep_rx_ready_intr_set),    
    .ep_tx_complete_intr_set_o          (ep_tx_complete_intr_set),        

    // Others
    /////////////////////////////////////
    // scaledown mode select
    .usb_scaledown_mode_i               (usb_scaledown_mode_i)  
    
);

endmodule
