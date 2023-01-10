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
	input           phy_clk_i

	////// AHB slave interface
	,input          hclk_i
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
	// sh2p: sync form hclk to phy clk
	,output         sh2pt_wt_en_o
	,output         sh2pt_rd_en_o
	,output			sh2pd_enable_o
	,output [31:0]  sh2pd_addr_o
	,output [31:0]  sh2pd_wdata_o
	,input  [31:0]  sp2hd_rdata_i

);

//-----------------------------------------------------------------
// write and read enable
//-----------------------------------------------------------------
wire wt_en = hsel_i & hready_i & hwrite_i & (htrans_i == 2'b10 | htrans_i == 2'b11);
wire rd_en = hsel_i & hready_i & !hwrite_i & (htrans_i == 2'b10 | htrans_i == 2'b11);

//-----------------------------------------------------------------
// sync wt_en and rd_en to phy clk
//-----------------------------------------------------------------
wire [1:0] h2pt_bus = {wt_en, rd_en};
wire [1:0] sh2pt_bus;
usbf_sync #(2) sync_h2p(
    .clk_s (hclk_i),
    .clk_d (phy_clk_i),
    .rstn  (hrstn_i),
    .din   (h2pt_bus),
    .dout  (sh2pt_bus)
);

wire sh2pt_wt_en;
wire sh2pt_rd_en;
assign {sh2pt_wt_en, sh2pt_rd_en} = sh2pt_bus;

wire sh2pt_wt_en_r;
wire sh2pt_wt_en_next = sh2pt_wt_en;
usbf_gnrl_dffr #(1) sh2pt_wt_en_diffr(
	sh2pt_wt_en_next, sh2pt_wt_en_r,
	phy_clk_i,hrstn_i
);

wire sh2pt_rd_en_r;
wire sh2pt_rd_en_next = sh2pt_rd_en;
usbf_gnrl_dffr #(1) sh2pt_rd_en_diffr(
	sh2pt_rd_en_next, sh2pt_rd_en_r,
	phy_clk_i,hrstn_i
);

//-----------------------------------------------------------------
// sync sh2pt_wt_en_r and sh2pt_rd_en_r to hclk
//-----------------------------------------------------------------
wire [1:0] p2ht_bus = {sh2pt_wt_en_r, sh2pt_rd_en_r};
wire [1:0] sp2ht_bus;
usbf_sync #(2) sync_p2h(
    .clk_s (phy_clk_i),
    .clk_d (hclk_i),
    .rstn  (hrstn_i),
    .din   (p2ht_bus),
    .dout  (sp2ht_bus)
);

wire sp2ht_wt_en_r;
wire sp2ht_rd_en_r;
assign {sp2ht_wt_en_r, sp2ht_rd_en_r} = sp2ht_bus;

//-----------------------------------------------------------------
// write and read ready (finished form CSR)
// **HCLK**
//-----------------------------------------------------------------
wire wt_ready_r; // default 1
wire wt_ready_set = sp2ht_wt_en_r; // write finished
wire wt_ready_clr = wt_en; // start write
wire wt_ready_ena  = wt_ready_set | wt_ready_clr;
wire wt_ready_next = wt_ready_set | (~wt_ready_clr);
usbf_gnrl_dfflrd #(1, 1'b1) 
		wt_ready_difflrd(
			wt_ready_ena,wt_ready_next,
			wt_ready_r,
			hclk_i,hrstn_i
		);

wire rd_ready_r; // default 1
wire rd_ready_set = sp2ht_rd_en_r; // read finished
wire rd_ready_clr = rd_en; // start read
wire rd_ready_ena  = rd_ready_set | rd_ready_clr;
wire rd_ready_next = rd_ready_set | (~rd_ready_clr);
usbf_gnrl_dfflrd #(1, 1'b1) 
		rd_ready_difflrd(
			rd_ready_ena,rd_ready_next,
			rd_ready_r,
			hclk_i,hrstn_i
		);

//-----------------------------------------------------------------
// hready and hresp
//-----------------------------------------------------------------
assign hready_o = wt_ready_r & rd_ready_r;
assign hresp_o = 2'b0;

//-----------------------------------------------------------------
// data and addr
//-----------------------------------------------------------------
assign sh2pd_addr_o = haddr_i;
assign sh2pd_wdata_o = hwdata_i;
assign hrdata_o = sp2hd_rdata_i;

//-----------------------------------------------------------------
// sh2pt_wt_en_o and sh2pt_rd_en_o
//-----------------------------------------------------------------
assign sh2pt_wt_en_o = sh2pt_wt_en;
assign sh2pt_rd_en_o = sh2pt_rd_en;

//-----------------------------------------------------------------
// sh2pd_enable_o 
//-----------------------------------------------------------------
assign sh2pd_enable_o = hsel_i;

endmodule