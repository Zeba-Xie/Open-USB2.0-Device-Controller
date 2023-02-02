//=================================================================
// 
// Synchronizer modules
//
// Version: V1.0
// Created by Zeba-Xie @github
//
//=================================================================

//-----------------------------------------------------------------
//
// Pulse Synchronizer
// Synchronize the pulse signal in the source clock domain to the 
// destination clock domain.
//
// Version: V1.0
//-----------------------------------------------------------------
module pulse_sync(
	input  clk_s, // source clk
	input  clk_d, // destination clk
	input  rst_n,
	input  din,
	output dout
);
// signal pulse to level 
// **clk s**
wire s_pulse2level_r;
wire s_pulse2level_next = din ^ s_pulse2level_r;
usbf_gnrl_dffr #(1) s_pulse2level_diffr(
	s_pulse2level_next, s_pulse2level_r,
	clk_s,rst_n
);

// 3 level synchronizer
// **clk d**
wire d_sample_r;
wire d_sample_next = s_pulse2level_r;
usbf_gnrl_dffr #(1) d_sample_diffr(
	d_sample_next, d_sample_r,
	clk_d,rst_n
);

wire d_sync2_r;
wire d_sync2_next = d_sample_r;
usbf_gnrl_dffr #(1) d_sync2_diffr(
	d_sync2_next, d_sync2_r,
	clk_d,rst_n
);

wire d_sync3_r;
wire d_sync3_next = d_sync2_r;
usbf_gnrl_dffr #(1) d_sync3_diffr(
	d_sync3_next, d_sync3_r,
	clk_d,rst_n
);

// edge detection
assign dout = d_sync2_r ^ d_sync3_r;
	
endmodule

//-----------------------------------------------------------------
//
// Level Synchronizer
// Synchronize the level signal in the source clock domain to the 
// destination clock domain.
//
// Parameter STAGE must be greater than or equal to 2
//
// Version: V1.0
//
//-----------------------------------------------------------------
module level_sync#(
	parameter STAGE = 2
)(
	input  clk_d, // destination clk
	input  rst_n,
	input  din,
	output dout
);
// if (STAGE<2) begin
// 	$fatal ("\n Error: The stage of level synchronizer must be greater than or equal to 2. \n");
// end

// first smaple
wire d_sample_r;
wire d_sample_next = din;
usbf_gnrl_dffr #(1) d_sample_diffr(
	d_sample_next, d_sample_r,
	clk_d,rst_n
);

wire d_sync_r[STAGE-2:0];
wire d_sync_next[STAGE-2:0];

genvar i;
generate //{
	for(i=0; i<(STAGE-1); i=i+1) begin //{
		if(i==0)
			assign d_sync_next[i] = d_sample_r;
		else
			assign d_sync_next[i] = d_sync_r[i-1];

		usbf_gnrl_dffr #(1) d_sync_diffr(
		d_sync_next[i], d_sync_r[i],
		clk_d,rst_n
		);
	end //}
endgenerate //}

assign dout = d_sync_r[STAGE-2];
	
endmodule

//-----------------------------------------------------------------
//
// Set Level Synchronizer
// Synchronize a set level signal in the source clock domain to the 
// destination clock domain.
//
// Parameter STAGE must be greater than or equal to 2
//
// Version: V1.0
//
//-----------------------------------------------------------------
module set_level_sync #(
	parameter STAGE = 2,
	parameter DW = 1
)(
	input  clk_d, // destination clk
	input  rst_n,
	input  [DW-1:0] din,
	output [DW-1:0] dout
);
genvar i;
generate //{

    for(i=0; i<DW; i=i+1)begin: sync
        level_sync #(STAGE) u_level_sync( 
            .clk_d (clk_d),
            .rst_n (rst_n),
            .din   (din[i]), 
            .dout  (dout[i])
        );
    end
    
endgenerate //}

endmodule


//-----------------------------------------------------------------
// 
// set pulse Synchronizer
// Synchronize the a set pulse signals(Just for control singnal),
// in the source clock domain to the destination clock domain.
//
// Version: V1.0
//
//-----------------------------------------------------------------
module set_pulse_sync#(
    parameter DW = 1
)
(
     input          clk_s   // source clk
    ,input          clk_d   // destination clk
    ,input          rstn

    ,input [DW-1:0] din
    ,output[DW-1:0] dout

);

genvar i;
generate //{

    for(i=0; i<DW; i=i+1)begin: sync
        pulse_sync u_pulse_sync( 
            .clk_s (clk_s),
            .clk_d (clk_d),
            .rst_n (rstn),
            .din   (din[i]), 
            .dout  (dout[i])
        );
    end
    
endgenerate //}

endmodule


//-----------------------------------------------------------------
// 
// BUS Synchronizer
// This module synchronizes a bus signal from S clock
// domain to D clock domain.
//
// s ---> d
//
// Version: V1.0
//
//-----------------------------------------------------------------
module bus_sync#(
    parameter DW = 1
)
(
     input          clk_s   // source clk
    ,input          clk_d   // destination clk
    ,input          rstn

    ,input [DW-1:0] din
    ,output[DW-1:0] dout

);

wire s2d_tgl_r;
wire d2s_tgl_r;
wire s_s2d_tgl;
wire s_d2s_tgl;

wire data_in_en = s2d_tgl_r == s_d2s_tgl;
wire data_out_en= d2s_tgl_r != s_s2d_tgl;

// s2d_tgl_r
wire s2d_tgl_ena  = data_in_en;
wire s2d_tgl_next = ~s2d_tgl_r;
usbf_gnrl_dfflrd #(1, 1'b0) 
                s2d_tgl_difflrd(
                    s2d_tgl_ena,s2d_tgl_next,
                    s2d_tgl_r,
                    clk_s,rstn
                );

// d2s_tgl_r
wire d2s_tgl_ena  = data_out_en;
wire d2s_tgl_next = ~d2s_tgl_r;
usbf_gnrl_dfflrd #(1, 1'b0) 
                d2s_tgl_difflrd(
                    d2s_tgl_ena,d2s_tgl_next,
                    d2s_tgl_r,
                    clk_d,rstn
                );

// s_s2d_tgl
level_sync #(2) s2d_tgl_sync(
	.clk_d(clk_d),
	.rst_n(rstn),
	.din(s2d_tgl_r),
	.dout(s_s2d_tgl)
);

// s_d2s_tgl
level_sync #(2) d2s_tgl_sync(
	.clk_d(clk_s),
	.rst_n(rstn),
	.din(d2s_tgl_r),
	.dout(s_d2s_tgl)
);

// data in
wire [DW-1:0] data_in_r;
wire data_in_ena = data_in_en;
wire [DW-1:0] data_in_nxt = din;
usbf_gnrl_dfflrd #(DW, {DW{1'b0}}) 
                data_in_difflrd(
                    data_in_ena,data_in_nxt,
                    data_in_r,
                    clk_s,rstn
                );

// data out
wire data_out_ena = data_out_en;
wire [DW-1:0] data_out_nxt = data_in_r;
usbf_gnrl_dfflrd #(DW, {DW{1'b0}}) 
                data_out_difflrd(
                    data_out_ena,data_out_nxt,
                    dout,
                    clk_d,rstn
                );

endmodule