//=================================================================
// 
// usbf synchronizer module
//
// Version: V1.0
// Created by Zeba-Xie @github
//
// hclk -> phyclk
// sh2pt : toggle
// sh2pl : level
// sh2pd : direct
// sh2pb : bus

// phyclk -> hclk
// sp2ht
// sp2hl
// sp2hd
// sp2hb
//=================================================================

`include "usbf_cfg_defs.v"

module usbf_sync(
	 input                                          phy_clk_i
	,input                                          hclk_i
    ,input                                          rstn_i

	//-------------------------------hclk domain, connect to CSR
    ////// Device core interface
    ,input                                         	func_ctrl_hs_chirp_en_i
    ,input [ `USB_FUNC_ADDR_DEV_ADDR_W-1:0]        	func_addr_dev_addr_i
    ,input [`USB_EP_NUM-1:0]                       	ep_cfg_stall_ep_i
    ,input [`USB_EP_NUM-1:0]                       	ep_cfg_iso_i
    ,output  [`USB_FUNC_STAT_FRAME_W-1:0]           func_stat_frame_o
    ,output                                         rst_intr_set_o
    ,output                                         sof_intr_set_o
    ,output  [`USB_EP_NUM-1:0]                      ep_rx_ready_intr_set_o
    ,output  [`USB_EP_NUM-1:0]                      ep_tx_complete_intr_set_o

    ////// EPU(endpoint) interface
    ,input [`USB_EP_NUM-1:0]                       	ep_tx_ctrl_tx_start_i
    ,input [`USB_EP0_TX_CTRL_TX_LEN_W*`USB_EP_NUM-1:0]  ep_tx_ctrl_tx_len_i     
    ,input [`USB_EP_NUM-1:0]                       	ep_rx_ctrl_rx_accept_i        
    
    ,output  [`USB_EP_NUM-1:0]                      ep_sts_tx_err_o
    ,output  [`USB_EP_NUM-1:0]                      ep_sts_tx_busy_o
    ,output  [`USB_EP_NUM-1:0]                      ep_sts_rx_err_o
    ,output  [`USB_EP_NUM-1:0]                      ep_sts_rx_setup_o
    ,output  [`USB_EP_NUM-1:0]                      ep_sts_rx_ready_o 
    ,output  [`USB_EP0_STS_RX_COUNT_W*`USB_EP_NUM-1:0] ep_sts_rx_count_o

    ////// MEM(memory) interface
        // RX
    ,input [`USB_EP_NUM-1:0]                       	ep_rx_ctrl_rx_flush_i      
    ,input [`USB_EP_NUM-1:0]                       	ep_data_rd_req_i   
    ,output  [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0] ep_rx_data_o 
        // TX
    ,input [`USB_EP_NUM-1:0]                       	ep_tx_ctrl_tx_flush_i
    ,input [`USB_EP_NUM-1:0]                       	ep_data_wt_req_i
    ,input [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  	ep_tx_data_i
    
    ////// Device interface
    ,input                                         	func_ctrl_phy_dmpulldown_i
    ,input                                         	func_ctrl_phy_dppulldown_i
    ,input                                         	func_ctrl_phy_termselect_i
    ,input [1:0]                                   	func_ctrl_phy_xcvrselect_i
    ,input [1:0]                                   	func_ctrl_phy_opmode_i
    ,output  [1:0]                                  func_stat_linestate_o

	//-------------------------------phy domain, connect to phy domain modules
	////// Device core interface
    ,output                                         sh2pl_func_ctrl_hs_chirp_en_o
    ,output [ `USB_FUNC_ADDR_DEV_ADDR_W-1:0]        sh2pb_func_addr_dev_addr_o 
    ,output [`USB_EP_NUM-1:0]                       sh2pl_ep_cfg_stall_ep_o // TODO
    ,output [`USB_EP_NUM-1:0]                       sh2pl_ep_cfg_iso_o
    
    ,input  [`USB_FUNC_STAT_FRAME_W-1:0]            p2hb_func_stat_frame_i 
    ,input                                          p2ht_rst_intr_set_i
    ,input                                          p2ht_sof_intr_set_i
    ,input  [`USB_EP_NUM-1:0]                       p2ht_ep_rx_ready_intr_set_i
    ,input  [`USB_EP_NUM-1:0]                       p2ht_ep_tx_complete_intr_set_i

    ////// EPU(endpoint) interface
    ,output [`USB_EP_NUM-1:0]                       sh2pt_ep_tx_ctrl_tx_start_o
    ,output [`USB_EP0_TX_CTRL_TX_LEN_W*`USB_EP_NUM-1:0]   sh2pb_ep_tx_ctrl_tx_len_o     
    ,output [`USB_EP_NUM-1:0]                       sh2pt_ep_rx_ctrl_rx_accept_o        
    
    ,input  [`USB_EP_NUM-1:0]                       p2hl_ep_sts_tx_err_i
    ,input  [`USB_EP_NUM-1:0]                       p2hl_ep_sts_tx_busy_i
    ,input  [`USB_EP_NUM-1:0]                       p2hl_ep_sts_rx_err_i 
    ,input  [`USB_EP_NUM-1:0]                       p2hl_ep_sts_rx_setup_i
    ,input  [`USB_EP_NUM-1:0]                       p2hl_ep_sts_rx_ready_i 
    ,input  [`USB_EP0_STS_RX_COUNT_W*`USB_EP_NUM-1:0] p2hb_ep_sts_rx_count_i

    ////// MEM(memory) interface
        // RX
    ,output [`USB_EP_NUM-1:0]                       sh2pt_ep_rx_ctrl_rx_flush_o      
    ,output [`USB_EP_NUM-1:0]                       sh2pt_ep_data_rd_req_o   
    ,input  [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  p2hb_ep_rx_data_i 
        // TX
    ,output [`USB_EP_NUM-1:0]                       sh2pt_ep_tx_ctrl_tx_flush_o
    ,output [`USB_EP_NUM-1:0]                       sh2pt_ep_data_wt_req_o
    ,output [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  sh2pb_ep_tx_data_o
    
    ////// Device interface
    ,output                                         sh2pl_func_ctrl_phy_dmpulldown_o
    ,output                                         sh2pl_func_ctrl_phy_dppulldown_o
    ,output                                         sh2pl_func_ctrl_phy_termselect_o
    ,output [1:0]                                   sh2pb_func_ctrl_phy_xcvrselect_o
    ,output [1:0]                                   sh2pb_func_ctrl_phy_opmode_o
    ,input  [1:0]                                   p2hb_func_stat_linestate_i

    `ifdef USB_ITF_ICB
    ,output					                        mem_wt_ready_o // MEM fifos are in PHY clock domain
	,output					                        mem_rd_ready_o // so writing/reading data to fifo needs waiting CDC
    `endif

);

//-----------------------------------------------------------------
// Device core interface
//-----------------------------------------------------------------
// ======== hclk -> phyclk

set_level_sync #(2, 1) func_ctrl_hs_chirp_en_sync(
	.clk_d(phy_clk_i),
	.rst_n(rstn_i),
	.din(func_ctrl_hs_chirp_en_i),
	.dout(sh2pl_func_ctrl_hs_chirp_en_o)
);

set_level_sync #(2, `USB_EP_NUM) ep_cfg_stall_ep_sync(
	.clk_d(phy_clk_i),
	.rst_n(rstn_i),
	.din(ep_cfg_stall_ep_i),
	.dout(sh2pl_ep_cfg_stall_ep_o)
);

set_level_sync #(2,`USB_EP_NUM) ep_cfg_iso_sync(
	.clk_d(phy_clk_i),
	.rst_n(rstn_i),
	.din(ep_cfg_iso_i),
	.dout(sh2pl_ep_cfg_iso_o)
);

bus_sync #(`USB_FUNC_ADDR_DEV_ADDR_W) func_addr_dev_addr_sync(
    .clk_s(hclk_i),
    .clk_d(phy_clk_i),
    .rstn(rstn_i),
    .din(func_addr_dev_addr_i),
    .dout(sh2pb_func_addr_dev_addr_o)
);

// ======== phyclk -> hclk
bus_sync #(`USB_FUNC_STAT_FRAME_W) func_stat_frame_sync(
    .clk_s(phy_clk_i),
    .clk_d(hclk_i),
    .rstn(rstn_i),
    .din(p2hb_func_stat_frame_i),
    .dout(func_stat_frame_o)
);

set_pulse_sync #(1) rst_intr_set_sync(
    .clk_s(phy_clk_i),
    .clk_d(hclk_i),
    .rstn(rstn_i),
    .din(p2ht_rst_intr_set_i),
    .dout(rst_intr_set_o)
);

set_pulse_sync #(1) sof_intr_set_sync(
    .clk_s(phy_clk_i),
    .clk_d(hclk_i),
    .rstn(rstn_i),
    .din(p2ht_sof_intr_set_i),
    .dout(sof_intr_set_o)
);

set_pulse_sync #(`USB_EP_NUM) ep_rx_ready_intr_set_sync(
    .clk_s(phy_clk_i),
    .clk_d(hclk_i),
    .rstn(rstn_i),
    .din(p2ht_ep_rx_ready_intr_set_i),
    .dout(ep_rx_ready_intr_set_o)
);

set_pulse_sync #(`USB_EP_NUM) ep_tx_complete_intr_set_sync(
    .clk_s(phy_clk_i),
    .clk_d(hclk_i),
    .rstn(rstn_i),
    .din(p2ht_ep_tx_complete_intr_set_i),
    .dout(ep_tx_complete_intr_set_o)
);

//-----------------------------------------------------------------
// EPU(endpoint) interface
//-----------------------------------------------------------------
// ======== hclk -> phyclk
set_pulse_sync #(`USB_EP_NUM) ep_tx_ctrl_tx_star_sync(
    .clk_s(hclk_i),
    .clk_d(phy_clk_i),
    .rstn(rstn_i),
    .din(ep_tx_ctrl_tx_start_i),
    .dout(sh2pt_ep_tx_ctrl_tx_start_o)
);
set_pulse_sync #(`USB_EP_NUM) ep_rx_ctrl_rx_accept_sync(
    .clk_s(hclk_i),
    .clk_d(phy_clk_i),
    .rstn(rstn_i),
    .din(ep_rx_ctrl_rx_accept_i),
    .dout(sh2pt_ep_rx_ctrl_rx_accept_o)
);
// bus_sync #(`USB_EP0_TX_CTRL_TX_LEN_W*`USB_EP_NUM) ep_tx_ctrl_tx_len_sync(
//     .clk_s(hclk_i),
//     .clk_d(phy_clk_i),
//     .rstn(rstn_i),
//     .din(ep_tx_ctrl_tx_len_i),
//     .dout(sh2pb_ep_tx_ctrl_tx_len_o)
// );
assign sh2pb_ep_tx_ctrl_tx_len_o = ep_tx_ctrl_tx_len_i;

// ======== phyclk -> hclk
wire [`USB_EP_NUM*5+`USB_EP0_STS_RX_COUNT_W*`USB_EP_NUM-1:0] ep_sts_in, s_ep_sts_out;
bus_sync #(`USB_EP_NUM*5+`USB_EP0_STS_RX_COUNT_W*`USB_EP_NUM) ep_sts_sync(
    .clk_s(phy_clk_i),
    .clk_d(hclk_i),
    .rstn(rstn_i),
    .din(ep_sts_in),
    .dout(s_ep_sts_out)
);
assign ep_sts_in = {p2hl_ep_sts_tx_err_i,
                    p2hl_ep_sts_tx_busy_i,
                    p2hl_ep_sts_rx_err_i,
                    p2hl_ep_sts_rx_setup_i,
                    p2hl_ep_sts_rx_ready_i,
                    p2hb_ep_sts_rx_count_i
                    };

assign {ep_sts_tx_err_o,
        ep_sts_tx_busy_o,
        ep_sts_rx_err_o,
        ep_sts_rx_setup_o,
        ep_sts_rx_ready_o,
        ep_sts_rx_count_o} = s_ep_sts_out;

//-----------------------------------------------------------------
// MEM(memory) interface
//-----------------------------------------------------------------
// ======== hclk -> phyclk
set_pulse_sync #(`USB_EP_NUM) ep_rx_ctrl_rx_flush_sync(
    .clk_s(hclk_i),
    .clk_d(phy_clk_i),
    .rstn(rstn_i),
    .din(ep_rx_ctrl_rx_flush_i),
    .dout(sh2pt_ep_rx_ctrl_rx_flush_o)
);
set_pulse_sync #(`USB_EP_NUM) ep_data_rd_req_sync(
    .clk_s(hclk_i),
    .clk_d(phy_clk_i),
    .rstn(rstn_i),
    .din(ep_data_rd_req_i),
    .dout(sh2pt_ep_data_rd_req_o)
);
set_pulse_sync #(`USB_EP_NUM) ep_tx_ctrl_tx_flush_sync(
    .clk_s(hclk_i),
    .clk_d(phy_clk_i),
    .rstn(rstn_i),
    .din(ep_tx_ctrl_tx_flush_i),
    .dout(sh2pt_ep_tx_ctrl_tx_flush_o)
);
set_pulse_sync #(`USB_EP_NUM) ep_data_wt_req_sync(
    .clk_s(hclk_i),
    .clk_d(phy_clk_i),
    .rstn(rstn_i),
    .din(ep_data_wt_req_i),
    .dout(sh2pt_ep_data_wt_req_o)
);
// bus_sync #(`USB_EP0_DATA_DATA_W*`USB_EP_NUM) ep_tx_data_sync(
//     .clk_s(hclk_i),
//     .clk_d(phy_clk_i),
//     .rstn(rstn_i),
//     .din(ep_tx_data_i),
//     .dout(sh2pb_ep_tx_data_o)
// );

assign sh2pb_ep_tx_data_o = ep_tx_data_i;

// ======== phyclk -> hclk
// actual rx_data valid in sh2pt_ep_data_rd_req_o clk
// so, register rx_data
wire [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0] actual_rx_data_r;
wire actual_rx_data_ena = |sh2pt_ep_data_rd_req_o;
wire [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0] actual_rx_data_next = p2hb_ep_rx_data_i;
usbf_gnrl_dfflrd #(`USB_EP0_DATA_DATA_W*`USB_EP_NUM, {`USB_EP0_DATA_DATA_W*`USB_EP_NUM{1'b0}}) 
                actual_rx_data_difflrd(
                    actual_rx_data_ena,actual_rx_data_next,
                    actual_rx_data_r,
                    phy_clk_i,rstn_i
                );

// bus_sync #(`USB_EP0_DATA_DATA_W*`USB_EP_NUM) ep_rx_data_sync(
//     .clk_s(phy_clk_i),
//     .clk_d(hclk_i),
//     .rstn(rstn_i),
//     .din(p2hb_ep_rx_data_i),
//     .dout(ep_rx_data_o)
// );
assign ep_rx_data_o = actual_rx_data_r;

// mem_wt_ready and mem rd ready pulse generate
`ifdef USB_ITF_ICB

// sync sh2pt_ep_data_rd_req_o from phy to H clock
wire [`USB_EP_NUM-1:0] mem_rd_ready;
set_pulse_sync #(`USB_EP_NUM) sh2pt_ep_data_rd_req_sync(
    .clk_s(phy_clk_i),
    .clk_d(hclk_i),
    .rstn(rstn_i),
    .din(sh2pt_ep_data_rd_req_o),
    .dout(mem_rd_ready)
);
assign mem_rd_ready_o = |mem_rd_ready;

wire [`USB_EP_NUM-1:0] mem_wt_ready;
set_pulse_sync #(`USB_EP_NUM) sh2pt_ep_data_wt_req_sync(
    .clk_s(phy_clk_i),
    .clk_d(hclk_i),
    .rstn(rstn_i),
    .din(sh2pt_ep_data_wt_req_o),
    .dout(mem_wt_ready)
);
assign mem_wt_ready_o = |mem_wt_ready;


`endif

//-----------------------------------------------------------------
// Device interface
//-----------------------------------------------------------------
// ======== hclk -> phyclk
wire [3+4-1:0] func_ctrl_in, func_ctrl_out;
assign func_ctrl_in = {func_ctrl_phy_dmpulldown_i,
                        func_ctrl_phy_dppulldown_i,
                        func_ctrl_phy_termselect_i,
                        func_ctrl_phy_xcvrselect_i,
                        func_ctrl_phy_opmode_i};
assign {sh2pl_func_ctrl_phy_dmpulldown_o,
        sh2pl_func_ctrl_phy_dppulldown_o,
        sh2pl_func_ctrl_phy_termselect_o,
        sh2pb_func_ctrl_phy_xcvrselect_o,
        sh2pb_func_ctrl_phy_opmode_o} = func_ctrl_out;
bus_sync #(7) func_ctrl_sync(
    .clk_s(hclk_i),
    .clk_d(phy_clk_i),
    .rstn(rstn_i),
    .din(func_ctrl_in),
    .dout(func_ctrl_out)
);
// ======== phyclk -> hclk
bus_sync #(2) func_stat_linestate_sync(
    .clk_s(phy_clk_i),
    .clk_d(hclk_i),
    .rstn(rstn_i),
    .din(p2hb_func_stat_linestate_i),
    .dout(func_stat_linestate_o)
);

endmodule