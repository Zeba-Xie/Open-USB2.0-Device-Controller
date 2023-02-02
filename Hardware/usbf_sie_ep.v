//=================================================================
//
// SIE EP
//
// Version: V1.0
// Created by Ultra-Embedded.com 
// http://github.com/ultraembedded/cores
//
//=================================================================
module usbf_sie_ep
(
    // Inputs
     input           clk_i
    ,input           rstn_i

    // Rx SIE interface
    ,output          rx_space_o
    ,input           rx_setup_i
    ,input           rx_valid_i
    ,input           rx_strb_i
    ,input  [  7:0]  rx_data_i
    ,input           rx_last_i
    ,input           rx_crc_err_i

    // Rx FIFO interface
    ,output          rx_push_o
    ,output [  7:0]  rx_data_o
    ,input           rx_full_i

    // Rx register interface 
    ,output [ 10:0]  rx_length_o
    ,output          rx_ready_o
    ,output          rx_err_o
    ,output          rx_setup_o
    ,input           rx_ack_i
    
    // Tx FIFO interface
    ,output          tx_pop_o
    ,input  [  7:0]  tx_data_i
    ,input           tx_empty_i
    
    // Tx register interface 
    ,input           tx_flush_i
    ,input  [ 10:0]  tx_length_i
    ,input           tx_start_i
    ,output          tx_busy_o
    ,output          tx_err_o
    
    // Tx SIE interface
    ,output          tx_ready_o
    ,output          tx_data_valid_o
    ,output          tx_data_strb_o
    ,output [  7:0]  tx_data_o
    ,output          tx_data_last_o
    ,input           tx_data_accept_i
);



//-----------------------------------------------------------------
// Rx
//-----------------------------------------------------------------
reg        rx_ready_q;
reg        rx_err_q;
reg [10:0] rx_len_q;
reg        rx_setup_q;

always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    rx_ready_q <= 1'b0;
else if (rx_ack_i)
    rx_ready_q <= 1'b0;
else if (rx_valid_i && rx_last_i)
    rx_ready_q <= 1'b1;

assign rx_space_o = !rx_ready_q;

always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    rx_len_q <= 11'b0;
else if (rx_ack_i)
    rx_len_q <= 11'b0;
else if (rx_valid_i && rx_strb_i)
    rx_len_q <= rx_len_q + 11'd1;

always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    rx_err_q <= 1'b0;
else if (rx_ack_i)
    rx_err_q <= 1'b0;
else if (rx_valid_i && rx_last_i && rx_crc_err_i)
    rx_err_q <= 1'b1;
else if (rx_full_i && rx_push_o)
    rx_err_q <= 1'b1;

always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    rx_setup_q <= 1'b0;
else if (rx_ack_i)
    rx_setup_q <= 1'b0;
else if (rx_setup_i)
    rx_setup_q <= 1'b1;

assign rx_length_o = rx_len_q;
assign rx_ready_o  = rx_ready_q;
assign rx_err_o    = rx_err_q;
assign rx_setup_o  = rx_setup_q;

assign rx_push_o   = rx_valid_i & rx_strb_i;
assign rx_data_o   = rx_data_i;

//-----------------------------------------------------------------
// Tx
//-----------------------------------------------------------------
reg        tx_active_q;
reg        tx_err_q;
reg        tx_zlp_q;
reg [10:0] tx_len_q;

// Tx active
always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    tx_active_q <= 1'b0;
else if (tx_flush_i)
    tx_active_q <= 1'b0;
else if (tx_start_i)
    tx_active_q <= 1'b1;
else if (tx_data_valid_o && tx_data_last_o && tx_data_accept_i)
    tx_active_q <= 1'b0;

assign tx_ready_o = tx_active_q;

// Tx zero length packet
always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    tx_zlp_q <= 1'b0;
else if (tx_flush_i)
    tx_zlp_q <= 1'b0;
else if (tx_start_i)
    tx_zlp_q <= (tx_length_i == 11'b0);

// Tx length
always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    tx_len_q <= 11'b0;
else if (tx_flush_i)
    tx_len_q <= 11'b0;
else if (tx_start_i)
    tx_len_q <= tx_length_i;
else if (tx_data_valid_o && tx_data_accept_i && !tx_zlp_q)
    tx_len_q <= tx_len_q - 11'd1;

// Tx SIE Interface
assign tx_data_valid_o = tx_active_q;
assign tx_data_strb_o  = !tx_zlp_q;
assign tx_data_last_o  = tx_zlp_q || (tx_len_q == 11'd1);
assign tx_data_o       = tx_data_i;

// Error: Buffer underrun
always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    tx_err_q <= 1'b0;
else if (tx_flush_i)
    tx_err_q <= 1'b0;
else if (tx_start_i)
    tx_err_q <= 1'b0;
else if (!tx_zlp_q && tx_empty_i && tx_data_valid_o)
    tx_err_q <= 1'b1;

// Tx Register Interface
assign tx_err_o      = tx_err_q;
assign tx_busy_o     = tx_active_q;

// Tx FIFO Interface
assign tx_pop_o      = tx_data_accept_i & tx_active_q;


endmodule

