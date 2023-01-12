//=================================================================
// 
// Bus interface unit
// This module is used for communication between AHB and CSR module.
// Since the CSR module belongs to the PHY clock domian, it needs 
// CDC.
//
// Version: V1.0
// Created by Zeba-Xie @github
// 
//=================================================================

module usbf_biu(
	////// AHB slave interface
	 input          hclk_i
	,input			hrstn_i
	,input			hsel_i
	,input			hwrite_i
	,input	[1:0]	htrans_i
	,input	[2:0]	hburst_i
	,input	[31:0]	hwdata_i
	,input	[31:0]	haddr_i
	,input  [2:0]	hsize_i
	,input			hready_i
	,output			hready_o
	,output	[1:0]	hresp_o
	,output [31:0]  hrdata_o

	////// CSR interface
	,output         wt_en_o
	,output         rd_en_o
	,output			enable_o
	,output [31:0]  addr_o
	,output [31:0]  wdata_o
	,input  [31:0]  rdata_i

);

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
assign hready_o = hready_i;
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

endmodule