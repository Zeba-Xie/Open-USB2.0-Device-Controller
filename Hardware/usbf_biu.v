//=================================================================
// 
// Bus interface unit
// This module is used for communication between AHB/ICB and CSR module.
//
// Version: V1.0
// Created by Zeba-Xie @github
// 
//=================================================================

`include "usbf_cfg_defs.v"

module usbf_biu(
     input                      hclk_i
    ,input                      hrstn_i

    `ifdef USB_ITF_AHB
    ////// AHB slave interface
    ,input                      hsel_i
    ,input                      hwrite_i
    ,input  [1:0]               htrans_i
    ,input  [2:0]               hburst_i
    ,input  [31:0]              hwdata_i
    ,input  [31:0]              haddr_i
    ,input  [2:0]               hsize_i
    ,input                      hready_i
    ,output                     hready_o
    ,output [1:0]               hresp_o
    ,output [31:0]              hrdata_o
    `endif

    `ifdef USB_ITF_ICB
    ////// ICB slave interface
    // CMD
    ,input                      icb_cmd_valid_i
    ,output                     icb_cmd_ready_o
    ,input  [32-1:0]            icb_cmd_addr_i
    ,input                      icb_cmd_read_i
    ,input  [32-1:0]            icb_cmd_wdata_i
    // RSP
    ,output                     icb_rsp_valid_o
    ,input                      icb_rsp_ready_i
    ,output [32-1:0]            icb_rsp_rdata_o
    `endif

    ////// CSR interface
    ,output                     wt_en_o
    ,output                     rd_en_o
    ,output                     enable_o
    ,output [31:0]              addr_o
    ,output [31:0]              wdata_o
    ,input  [31:0]              rdata_i

    `ifdef USB_ITF_ICB
    ,input                      wt_ready_i // MEM fifos are in PHY clock domain
    ,input                      rd_ready_i // so writing/reading data to fifo needs waiting CDC
    `endif

);

//===================================================================================
`ifdef USB_ITF_AHB
//-----------------------------------------------------------------
// write and read enable
//-----------------------------------------------------------------
wire wt_en = hsel_i & hready_i &  hwrite_i & (htrans_i == 2'b10 | htrans_i == 2'b11);
wire rd_en = hsel_i & hready_i & !hwrite_i & (htrans_i == 2'b10 | htrans_i == 2'b11);

wire wt_en_r;
wire wt_en_next = wt_en;
usbf_gnrl_dffr #(1) wt_en_diffr(
    wt_en_next, wt_en_r,
    hclk_i,hrstn_i
);

assign wt_en_o = wt_en_r;
assign rd_en_o = rd_en;

//-----------------------------------------------------------------
// hready and hresp
//-----------------------------------------------------------------
assign hready_o = 1'b1;
assign hresp_o = 2'b0;

//-----------------------------------------------------------------
// data and addr
//-----------------------------------------------------------------
assign addr_o = haddr_i;
assign wdata_o = hwdata_i;
assign hrdata_o = rdata_i;

//-----------------------------------------------------------------
// enable_o 
//-----------------------------------------------------------------
assign enable_o = hsel_i;
`endif // USB_ITF_AHB

//===================================================================================
`ifdef USB_ITF_ICB
//-----------------------------------------------------------------
// write and read enable
//-----------------------------------------------------------------
wire icb_cmd_hsked    = icb_cmd_valid_i & icb_cmd_ready_o;
wire wt_en = icb_cmd_hsked & (~icb_cmd_read_i);
wire rd_en = icb_cmd_hsked & icb_cmd_read_i;

assign wt_en_o = wt_en;
assign rd_en_o = rd_en;

//-----------------------------------------------------------------
// handshake
//-----------------------------------------------------------------
wire wt_ready_r; // default 0
wire wt_ready_set = wt_ready_i; // write finished
wire wt_ready_clr = icb_rsp_ready_i; // RSP finished
wire wt_ready_ena  = wt_ready_set | wt_ready_clr;
wire wt_ready_next = wt_ready_set | (~wt_ready_clr);
usbf_gnrl_dfflrd #(1, 1'b0) 
    wt_ready_difflrd(
        wt_ready_ena,wt_ready_next,
        wt_ready_r,
        hclk_i,hrstn_i
    );

wire rd_ready_r; // default 0
wire rd_ready_set = rd_ready_i; // read finished
wire rd_ready_clr = icb_rsp_ready_i; // RSP finished
wire rd_ready_ena  = rd_ready_set | rd_ready_clr;
wire rd_ready_next = rd_ready_set | (~rd_ready_clr);
usbf_gnrl_dfflrd #(1, 1'b0) 
    rd_ready_difflrd(
        rd_ready_ena,rd_ready_next,
        rd_ready_r,
        hclk_i,hrstn_i
    );
assign icb_cmd_ready_o = icb_cmd_valid_i;
assign icb_rsp_valid_o = wt_ready_r | rd_ready_r;
// assign icb_rsp_valid_o = icb_rsp_ready_i;

//-----------------------------------------------------------------
// data and addr
//-----------------------------------------------------------------
wire [32-1:0] addr_r;
wire addr_ena = icb_cmd_hsked;
wire [32-1:0] addr_nxt = icb_cmd_addr_i;
usbf_gnrl_dfflrd #(32, 32'b0) 
    addr_difflrd(
        addr_ena,addr_nxt,
        addr_r,
        hclk_i,hrstn_i
    );

wire [32-1:0] wdata_r;
wire wdata_ena = wt_en;
wire [32-1:0] wdata_nxt = icb_cmd_wdata_i;
usbf_gnrl_dfflrd #(32, 32'b0) 
    wdata_difflrd(
        wdata_ena,wdata_nxt,
        wdata_r,
        hclk_i,hrstn_i
    );

assign addr_o = icb_cmd_hsked ? icb_cmd_addr_i : addr_r;
assign wdata_o = icb_cmd_hsked ? icb_cmd_wdata_i : wdata_r;
assign icb_rsp_rdata_o = rdata_i;

//-----------------------------------------------------------------
// enable_o 
//-----------------------------------------------------------------
assign enable_o = addr_o[31:12] == `USB_BASE_ADDR_31_12;
`endif // USB_ITF_ICB

endmodule