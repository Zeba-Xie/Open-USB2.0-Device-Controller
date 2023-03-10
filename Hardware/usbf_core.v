//=================================================================
//
// Device core, including RX and TX SIE
//
// Version: V1.0
// Created by Ultra-Embedded.com 
// http://github.com/ultraembedded/cores
// 
// Version: V2.0
// Modified by Zeba-Xie @github:
// .Added usb_scaledown_mode
// .Moved intr to CSR 
// .Simplified interface
// .Change reset singnal form high active to low active
// .The number of endpoints can be configured
//
//=================================================================
`include "usbf_cfg_defs.v"
module usbf_core
(
 
     input                                  clk_i
    ,input                                  rstn_i

    // UTMI interface
    /////////////////////////////////////
    ,output [  7:0]                         utmi_data_o
    ,input  [  7:0]                         utmi_data_i
    ,output                                 utmi_txvalid_o
    ,input                                  utmi_txready_i
    ,input                                  utmi_rxvalid_i
    ,input                                  utmi_rxactive_i
    ,input                                  utmi_rxerror_i
    ,input  [  1:0]                         utmi_linestate_i

    // EPU interface
    /////////////////////////////////////
    // Rx SIE Interface (shared)
    ,output                                 rx_strb_o
    ,output [  7:0]                         rx_data_o
    ,output                                 rx_last_o
    ,output                                 rx_crc_err_o
    // EP Rx SIE Interface
    ,output [`USB_EP_NUM-1:0]               ep_rx_setup_o
    ,output [`USB_EP_NUM-1:0]               ep_rx_valid_o
    ,input  [`USB_EP_NUM-1:0]               ep_rx_space_i
    // EP Tx SIE Interface
    ,input  [`USB_EP_NUM-1:0]               ep_tx_ready_i
    ,input  [`USB_EP_NUM-1:0]               ep_tx_data_valid_i
    ,input  [`USB_EP_NUM-1:0]               ep_tx_data_strb_i
    ,input  [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  ep_tx_data_i
    ,input  [`USB_EP_NUM-1:0]               ep_tx_data_last_i
    ,output [`USB_EP_NUM-1:0]               ep_tx_data_accept_o
    
    // CSR interface
    /////////////////////////////////////
    // chirp enable
    ,input                                  func_ctrl_hs_chirp_en_i
    // device address
    ,input  [  6:0]                         func_addr_dev_addr_i
    // EP config
    ,input  [`USB_EP_NUM-1:0]               ep_stall_i
    ,input  [`USB_EP_NUM-1:0]               ep_iso_i
    // status frame output
    ,output [ 10:0]                         func_stat_frame_o
    // intr set pulse
    ,output                                 rst_intr_set_o
    ,output                                 sof_intr_set_o 
    ,output [`USB_EP_NUM-1:0]               ep_rx_ready_intr_set_o
    ,output [`USB_EP_NUM-1:0]               ep_tx_complete_intr_set_o
     
    // Others
    /////////////////////////////////////
    // scaledown mode select
    ,input  [  1:0]                         usb_scaledown_mode_i

);

//-----------------------------------------------------------------
// Defines:
//-----------------------------------------------------------------
`include "usbf_protocol_defs.v"

`define USB_RESET_CNT_W     17 // TODO: 15

localparam STATE_W                       = 3;
localparam STATE_RX_IDLE                 = 3'd0;
localparam STATE_RX_DATA                 = 3'd1;
localparam STATE_RX_DATA_READY           = 3'd2;
localparam STATE_RX_DATA_IGNORE          = 3'd3;
localparam STATE_TX_DATA                 = 3'd4;
localparam STATE_TX_DATA_COMPLETE        = 3'd5;
localparam STATE_TX_HANDSHAKE            = 3'd6;
localparam STATE_TX_CHIRP                = 3'd7;
reg [STATE_W-1:0] state_q;

//-----------------------------------------------------------------
// Reset detection
//-----------------------------------------------------------------
reg usb_rst_w;

reg [`USB_RESET_CNT_W-1:0] se0_cnt_q;

always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    se0_cnt_q <= `USB_RESET_CNT_W'b0;
else if (utmi_linestate_i == 2'b0)
begin
    if (!usb_rst_w)
        se0_cnt_q <= se0_cnt_q + `USB_RESET_CNT_W'd1;
    else
        se0_cnt_q <= `USB_RESET_CNT_W'b0;
end    
else
    se0_cnt_q <= `USB_RESET_CNT_W'b0;

// wire usb_rst_w = se0_cnt_q[`USB_RESET_CNT_W-1];

always @ *
begin
    usb_rst_w    = 1'b0;
    case (usb_scaledown_mode_i)
    4'd0:
    begin
        usb_rst_w = se0_cnt_q[`USB_RESET_CNT_W-1];
    end
    4'd1:
    begin
        usb_rst_w = se0_cnt_q[`USB_RESET_CNT_W-2];
    end
    4'd2:
    begin
        usb_rst_w = se0_cnt_q[`USB_RESET_CNT_W-3];
    end
    4'd3:
    begin
        usb_rst_w = se0_cnt_q[`USB_RESET_CNT_W-5];
    end
    default:
        usb_rst_w    = 1'b0;
    endcase
end


//-----------------------------------------------------------------
// Wire / Regs
//-----------------------------------------------------------------
`define USB_FRAME_W    11
wire [`USB_FRAME_W-1:0] frame_num_w;

wire                    frame_valid_w;

`define USB_DEV_W      7
wire [`USB_DEV_W-1:0]   token_dev_w;

wire [`USB_EP_NUM-1:0]  token_ep_w;

`define USB_PID_W      8
wire [`USB_PID_W-1:0]   token_pid_w;

wire                    token_valid_w;

wire                    rx_data_valid_w;
wire                    rx_data_complete_w;

wire                    rx_handshake_w;

reg                     tx_data_valid_r;
reg                     tx_data_strb_r;
reg  [7:0]              tx_data_r;
reg                     tx_data_last_r;
wire                    tx_data_accept_w;

reg                     tx_valid_q;
reg [7:0]               tx_pid_q;
wire                    tx_accept_w;

reg                     rx_space_q;
reg                     rx_space_r;
reg                     tx_ready_r;
reg                     ep_data_bit_r;

reg                     ep_stall_r;
reg                     ep_iso_r;

reg                     rx_enable_q;
reg                     rx_setup_q;

reg [`USB_EP_NUM-1:0]   ep_data_bit_q;

wire                    status_stage_w;

reg [`USB_DEV_W-1:0]    current_addr_q;

//-----------------------------------------------------------------
// SIE - TX
//-----------------------------------------------------------------
usbf_sie_tx
u_sie_tx
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    
    .enable_i(~usb_rst_w),
    .chirp_i(func_ctrl_hs_chirp_en_i),

    // UTMI Interface
    .utmi_data_o(utmi_data_o),
    .utmi_txvalid_o(utmi_txvalid_o),
    .utmi_txready_i(utmi_txready_i),

    // Request
    .tx_valid_i(tx_valid_q),
    .tx_pid_i(tx_pid_q),
    .tx_accept_o(tx_accept_w),

    // Data
    .data_valid_i(tx_data_valid_r),
    .data_strb_i(tx_data_strb_r),
    .data_i(tx_data_r),
    .data_last_i(tx_data_last_r),
    .data_accept_o(tx_data_accept_w)
);

genvar i;
integer j;
// MUX for tx ep select
generate //{
    always @(*)begin
        tx_data_valid_r = 1'b0;
        tx_data_strb_r  = 1'b0;
        tx_data_r       = 8'b0;
        tx_data_last_r  = 1'b0;
        for(j=0; j<`USB_EP_NUM; j=j+1) begin //{
            if (token_ep_w == j) begin
                tx_data_valid_r = ep_tx_data_valid_i[j];
                tx_data_strb_r  = ep_tx_data_strb_i[j];
                tx_data_r       = ep_tx_data_i[j*`USB_EP0_DATA_DATA_W +:  `USB_EP0_DATA_DATA_W];
                tx_data_last_r  = ep_tx_data_last_i[j];
            end
        end //}
    end
endgenerate //}

generate //{
    for(i=0; i<`USB_EP_NUM; i=i+1) begin
        assign ep_tx_data_accept_o[i] = (tx_data_accept_w & (token_ep_w == i));
    end
endgenerate //}

generate //{
    always @(*)begin
        rx_space_r    =  1'b0;
        tx_ready_r    =  1'b0;
        ep_data_bit_r =  1'b0;
        ep_stall_r    =  1'b0;
        ep_iso_r      =  1'b0;

        for(j=0; j<`USB_EP_NUM; j=j+1) begin //{
            if (token_ep_w ==j) begin
                rx_space_r    = ep_rx_space_i[j];
                tx_ready_r    = ep_tx_ready_i[j];
                ep_data_bit_r = ep_data_bit_q[j] | status_stage_w;
                ep_stall_r    = ep_stall_i[j];
                ep_iso_r      = ep_iso_i[j];
            end
        end //}
    end
endgenerate //}

always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    rx_space_q <= 1'b0;
else if (state_q == STATE_RX_IDLE)
    rx_space_q <= rx_space_r;

//-----------------------------------------------------------------
// SIE - RX
//-----------------------------------------------------------------
usbf_sie_rx
u_sie_rx
(
    .clk_i(clk_i),
    .rstn_i(rstn_i),
    
    .enable_i(~usb_rst_w && ~func_ctrl_hs_chirp_en_i),

    // UTMI Interface
    .utmi_data_i(utmi_data_i),
    .utmi_rxvalid_i(utmi_rxvalid_i),
    .utmi_rxactive_i(utmi_rxactive_i),

    .current_addr_i(current_addr_q),

    .pid_o(token_pid_w),

    .frame_valid_o(frame_valid_w),
    .frame_number_o(func_stat_frame_o),

    .token_valid_o(token_valid_w),
    .token_addr_o(token_dev_w),
    .token_ep_o(token_ep_w),
    .token_crc_err_o(),

    .handshake_valid_o(rx_handshake_w),

    .data_valid_o(rx_data_valid_w),
    .data_strb_o(rx_strb_o),
    .data_o(rx_data_o),
    .data_last_o(rx_last_o),

    .data_complete_o(rx_data_complete_w),
    .data_crc_err_o(rx_crc_err_o)
);

generate //{
    for(i=0; i<`USB_EP_NUM; i=i+1) begin //{
        assign ep_rx_setup_o[i] = rx_setup_q & (token_ep_w == i);
        assign ep_rx_valid_o[i] = rx_enable_q & rx_data_valid_w & (token_ep_w == i);
    end //}
endgenerate //}

//-----------------------------------------------------------------
// Next state
//-----------------------------------------------------------------
reg [STATE_W-1:0] next_state_r;

always @ *
begin
    next_state_r = state_q;

    //-----------------------------------------
    // State Machine
    //-----------------------------------------
    case (state_q)

    //-----------------------------------------
    // IDLE
    //-----------------------------------------
    STATE_RX_IDLE :
    begin
        // Token received (OUT, IN, SETUP, PING)
        if (token_valid_w)
        begin
            //-------------------------------
            // IN transfer (device -> host)
            //-------------------------------
            if (token_pid_w == `PID_IN)
            begin
                // Stalled endpoint?
                if (ep_stall_r)
                    next_state_r  = STATE_TX_HANDSHAKE;
                // Some data to TX?
                else if (tx_ready_r)
                    next_state_r  = STATE_TX_DATA;
                // No data to TX
                else
                    next_state_r  = STATE_TX_HANDSHAKE;
            end
            //-------------------------------
            // PING transfer (device -> host)
            //-------------------------------
            else if (token_pid_w == `PID_PING)
            begin
                next_state_r  = STATE_TX_HANDSHAKE;
            end
            //-------------------------------
            // OUT transfer (host -> device)
            //-------------------------------
            else if (token_pid_w == `PID_OUT)
            begin
                // Stalled endpoint?
                if (ep_stall_r)
                    next_state_r  = STATE_RX_DATA_IGNORE;
                // Some space to rx
                else if (rx_space_r)
                    next_state_r  = STATE_RX_DATA;
                // No rx space, ignore receive
                else
                    next_state_r  = STATE_RX_DATA_IGNORE;
            end
            //-------------------------------
            // SETUP transfer (host -> device)
            //-------------------------------
            else if (token_pid_w == `PID_SETUP)
            begin
                // Some space to rx
                if (rx_space_r)
                    next_state_r  = STATE_RX_DATA;
                // No rx space, ignore receive
                else
                    next_state_r  = STATE_RX_DATA_IGNORE;
            end
        end
        else if (func_ctrl_hs_chirp_en_i)
            next_state_r  = STATE_TX_CHIRP;
    end

    //-----------------------------------------
    // RX_DATA
    //-----------------------------------------
    STATE_RX_DATA :
    begin
        // TODO: Exit data state handling?

        // TODO: Sort out ISO data bit handling
        // Check for expected DATAx PID
        if ((token_pid_w == `PID_DATA0 &&  ep_data_bit_r && !ep_iso_r) ||
            (token_pid_w == `PID_DATA1 && !ep_data_bit_r && !ep_iso_r))
            next_state_r  = STATE_RX_DATA_IGNORE;
        // Receive complete
        else if (rx_data_valid_w && rx_last_o)
            next_state_r  = STATE_RX_DATA_READY;
    end
    //-----------------------------------------
    // RX_DATA_IGNORE
    //-----------------------------------------
    STATE_RX_DATA_IGNORE :
    begin
        // Receive complete
        if (rx_data_valid_w && rx_last_o)
            next_state_r  = STATE_RX_DATA_READY;
    end
    //-----------------------------------------
    // RX_DATA_READY
    //-----------------------------------------
    STATE_RX_DATA_READY :
    begin
        if (rx_data_complete_w)
        begin
            // No response on CRC16 error
            if (rx_crc_err_o)
                next_state_r  = STATE_RX_IDLE;
            // ISO endpoint, no response?
            else if (ep_iso_r)
                next_state_r  = STATE_RX_IDLE;
            else
                next_state_r  = STATE_TX_HANDSHAKE;
        end
    end
    //-----------------------------------------
    // TX_DATA
    //-----------------------------------------
    STATE_TX_DATA :
    begin
        if (!tx_valid_q || tx_accept_w)
            if (tx_data_valid_r && tx_data_last_r && tx_data_accept_w)
                next_state_r  = STATE_TX_DATA_COMPLETE;
    end
    //-----------------------------------------
    // TX_HANDSHAKE
    //-----------------------------------------
    STATE_TX_DATA_COMPLETE :
    begin
        next_state_r  = STATE_RX_IDLE;
    end
    //-----------------------------------------
    // TX_HANDSHAKE
    //-----------------------------------------
    STATE_TX_HANDSHAKE :
    begin
        if (tx_accept_w)
            next_state_r  = STATE_RX_IDLE;
    end
    //-----------------------------------------
    // TX_CHIRP
    //-----------------------------------------
    STATE_TX_CHIRP :
    begin
        if (!func_ctrl_hs_chirp_en_i)
            next_state_r  = STATE_RX_IDLE;
    end

    default :
       ;

    endcase

    //-----------------------------------------
    // USB Bus Reset (HOST->DEVICE)
    //----------------------------------------- 
    if (usb_rst_w && !func_ctrl_hs_chirp_en_i)
        next_state_r  = STATE_RX_IDLE;
end

// Update state
always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    state_q   <= STATE_RX_IDLE;
else
    state_q   <= next_state_r;

//-----------------------------------------------------------------
// Response
//-----------------------------------------------------------------
reg         tx_valid_r;
reg [7:0]   tx_pid_r;

always @ *
begin
    tx_valid_r = 1'b0;
    tx_pid_r   = 8'b0;

    case (state_q)
    //-----------------------------------------
    // IDLE
    //-----------------------------------------
    STATE_RX_IDLE :
    begin
        // Token received (OUT, IN, SETUP, PING)
        if (token_valid_w)
        begin
            //-------------------------------
            // IN transfer (device -> host)
            //-------------------------------
            if (token_pid_w == `PID_IN)
            begin
                // Stalled endpoint?
                if (ep_stall_r)
                begin
                    tx_valid_r = 1'b1;
                    tx_pid_r   = `PID_STALL;
                end
                // Some data to TX?
                else if (tx_ready_r)
                begin
                    tx_valid_r = 1'b1;
                    // TODO: Handle MDATA for ISOs
                    tx_pid_r   = ep_data_bit_r ? `PID_DATA1 : `PID_DATA0;
                end
                // No data to TX
                else
                begin
                    tx_valid_r = 1'b1;
                    tx_pid_r   = `PID_NAK;
                end
            end
            //-------------------------------
            // PING transfer (device -> host)
            //-------------------------------
            else if (token_pid_w == `PID_PING)
            begin
                // Stalled endpoint?
                if (ep_stall_r)
                begin
                    tx_valid_r = 1'b1;
                    tx_pid_r   = `PID_STALL;
                end
                // Data ready to RX
                else if (rx_space_r)
                begin
                    tx_valid_r = 1'b1;
                    tx_pid_r   = `PID_ACK;
                end
                // No data to TX
                else
                begin
                    tx_valid_r = 1'b1;
                    tx_pid_r   = `PID_NAK;
                end
            end
        end
    end

    //-----------------------------------------
    // RX_DATA_READY
    //-----------------------------------------
    STATE_RX_DATA_READY :
    begin
       // Receive complete
       if (rx_data_complete_w)
       begin
            // No response on CRC16 error
            if (rx_crc_err_o)
                ;
            // ISO endpoint, no response?
            else if (ep_iso_r)
                ;
            // Send STALL?
            else if (ep_stall_r)
            begin
                tx_valid_r = 1'b1;
                tx_pid_r   = `PID_STALL;
            end
            // DATAx bit mismatch
            else if ( (token_pid_w == `PID_DATA0 && ep_data_bit_r) ||
                      (token_pid_w == `PID_DATA1 && !ep_data_bit_r) )
            begin
                // Ack transfer to resync
                tx_valid_r = 1'b1;
                tx_pid_r   = `PID_ACK;
            end
            // Send NAK
            else if (!rx_space_q)
            begin
                tx_valid_r = 1'b1;
                tx_pid_r   = `PID_NAK;
            end
            // TODO: USB 2.0, no more buffer space, return NYET
            else
            begin
                tx_valid_r = 1'b1;
                tx_pid_r   = `PID_ACK;
            end
       end
    end

    //-----------------------------------------
    // TX_CHIRP
    //-----------------------------------------
    STATE_TX_CHIRP :
    begin
        tx_valid_r = 1'b1;
        tx_pid_r   = 8'b0;
    end

    default :
       ;

    endcase
end

always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    tx_valid_q <= 1'b0;
else if (!tx_valid_q || tx_accept_w)
    tx_valid_q <= tx_valid_r;

always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    tx_pid_q <= 8'b0;
else if (!tx_valid_q || tx_accept_w)
    tx_pid_q <= tx_pid_r;

//-----------------------------------------------------------------
// Receive enable
//-----------------------------------------------------------------
always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    rx_enable_q <= 1'b0;
else if (usb_rst_w ||func_ctrl_hs_chirp_en_i)
    rx_enable_q <= 1'b0;
else
    rx_enable_q <= (state_q == STATE_RX_DATA);

//-----------------------------------------------------------------
// Receive SETUP: Pulse on SETUP packet receive
//-----------------------------------------------------------------
always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    rx_setup_q <= 1'b0;
else if (usb_rst_w ||func_ctrl_hs_chirp_en_i)
    rx_setup_q <= 1'b0;
else if ((state_q == STATE_RX_IDLE) && token_valid_w && (token_pid_w == `PID_SETUP) && (token_ep_w == 4'd0))
    rx_setup_q <= 1'b1;
else
    rx_setup_q <= 1'b0;

//-----------------------------------------------------------------
// Set Address
//-----------------------------------------------------------------
reg addr_update_pending_q;

wire ep0_tx_zlp_w = ep_tx_data_valid_i[0] && (ep_tx_data_strb_i[0] == 1'b0) && 
                    ep_tx_data_last_i[0] && ep_tx_data_accept_o[0];

always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    addr_update_pending_q   <= 1'b0;
else if (ep0_tx_zlp_w || usb_rst_w)
    addr_update_pending_q   <= 1'b0;
// TODO: Use write strobe
else if (func_addr_dev_addr_i != current_addr_q)
    addr_update_pending_q   <= 1'b1;

always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    current_addr_q  <= `USB_DEV_W'b0;
else if (usb_rst_w)
    current_addr_q  <= `USB_DEV_W'b0;
else if (ep0_tx_zlp_w && addr_update_pending_q)
    current_addr_q  <= func_addr_dev_addr_i;

//-----------------------------------------------------------------
// SETUP request tracking
//-----------------------------------------------------------------
reg ep0_dir_in_q;
reg ep0_dir_out_q;

always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    ep0_dir_in_q <= 1'b0;
else if (usb_rst_w ||func_ctrl_hs_chirp_en_i)
    ep0_dir_in_q <= 1'b0;
else if ((state_q == STATE_RX_IDLE) && token_valid_w && (token_pid_w == `PID_SETUP) && (token_ep_w == 4'd0))
    ep0_dir_in_q <= 1'b0;
else if ((state_q == STATE_RX_IDLE) && token_valid_w && (token_pid_w == `PID_IN) && (token_ep_w == 4'd0))
    ep0_dir_in_q <= 1'b1;

always @ (posedge clk_i or negedge rstn_i)
if (!rstn_i)
    ep0_dir_out_q <= 1'b0;
else if (usb_rst_w ||func_ctrl_hs_chirp_en_i)
    ep0_dir_out_q <= 1'b0;
else if ((state_q == STATE_RX_IDLE) && token_valid_w && (token_pid_w == `PID_SETUP) && (token_ep_w == 4'd0))
    ep0_dir_out_q <= 1'b0;
else if ((state_q == STATE_RX_IDLE) && token_valid_w && (token_pid_w == `PID_OUT) && (token_ep_w == 4'd0))
    ep0_dir_out_q <= 1'b1;

assign status_stage_w = ep0_dir_in_q && ep0_dir_out_q && (token_ep_w == 4'd0);

//-----------------------------------------------------------------
// Endpoint data bit toggle
//-----------------------------------------------------------------
reg new_data_bit_r;
always @ *
begin
    new_data_bit_r = ep_data_bit_r;

    case (state_q)
    //-----------------------------------------
    // RX_DATA_READY
    //-----------------------------------------
    STATE_RX_DATA_READY :
    begin
       // Receive complete
       if (rx_data_complete_w)
       begin
            // No toggle on CRC16 error
            if (rx_crc_err_o)
                ;
            // ISO endpoint, no response?
            else if (ep_iso_r)
                ; // TODO: HS handling
            // STALL?
            else if (ep_stall_r)
                ;
            // DATAx bit mismatch
            else if ( (token_pid_w == `PID_DATA0 && ep_data_bit_r) ||
                      (token_pid_w == `PID_DATA1 && !ep_data_bit_r) )
                ;
            // NAKd
            else if (!rx_space_q)
                ;
            // Data accepted - toggle data bit
            else
                new_data_bit_r = !ep_data_bit_r;
       end
    end
    //-----------------------------------------
    // RX_IDLE
    //-----------------------------------------
    STATE_RX_IDLE :
    begin
        // Token received (OUT, IN, SETUP, PING)
        if (token_valid_w)
        begin
            // SETUP packets always start with DATA0
            if (token_pid_w == `PID_SETUP)
                new_data_bit_r = 1'b0;
        end
        // ACK received
        else if (rx_handshake_w && token_pid_w == `PID_ACK)
        begin
            new_data_bit_r = !ep_data_bit_r;
        end
    end
    default:
        ;
    endcase
end

generate //{
    for(i=0; i<`USB_EP_NUM; i=i+1) begin
        always @ (posedge clk_i or negedge rstn_i) begin
            if (!rstn_i)
                ep_data_bit_q[i] <= 1'b0;
            else if (usb_rst_w)
                ep_data_bit_q[i] <= 1'b0;
            else if (token_ep_w == i)
                ep_data_bit_q[i] <= new_data_bit_r;
        end
    end
endgenerate //}

//-----------------------------------------------------------------
// Interrupts set pulse
//-----------------------------------------------------------------
assign rst_intr_set_o = usb_rst_w;
assign sof_intr_set_o = frame_valid_w;

generate //{
    for(i=0; i<`USB_EP_NUM; i=i+1) begin //{
        // TODO: the data type of i
        assign ep_rx_ready_intr_set_o[i] = (state_q == STATE_RX_DATA_READY) && rx_space_q && (token_ep_w == i);
        assign ep_tx_complete_intr_set_o[i] = (state_q == STATE_TX_DATA_COMPLETE) && (token_ep_w == i);
    end //}
endgenerate //}


//-------------------------------------------------------------------
// Debug
//-------------------------------------------------------------------
`ifdef verilator
/* verilator lint_off WIDTH */
reg [79:0] dbg_state;

always @ *
begin
    dbg_state = "-";

    case (state_q)
    STATE_RX_IDLE: dbg_state = "IDLE";
    STATE_RX_DATA: dbg_state = "RX_DATA";
    STATE_RX_DATA_READY: dbg_state = "RX_DATA_READY";
    STATE_RX_DATA_IGNORE: dbg_state = "RX_IGNORE";
    STATE_TX_DATA: dbg_state = "TX_DATA";
    STATE_TX_DATA_COMPLETE: dbg_state = "TX_DATA_COMPLETE";
    STATE_TX_HANDSHAKE: dbg_state = "TX_HANDSHAKE";
    STATE_TX_CHIRP: dbg_state = "CHIRP";
    endcase
end

reg [79:0] dbg_pid;
reg [7:0]  dbg_pid_r;
always @ *
begin
    dbg_pid = "-";

    if (tx_valid_q && tx_accept_w)
        dbg_pid_r = tx_pid_q;
    else if (token_valid_w || rx_handshake_w || rx_data_valid_w)
        dbg_pid_r = token_pid_w;
    else
        dbg_pid_r = 8'b0;

    case (dbg_pid_r)
    // Token
    `PID_OUT:
        dbg_pid = "OUT";
    `PID_IN:
        dbg_pid = "IN";
    `PID_SOF:
        dbg_pid = "SOF";
    `PID_SETUP:
        dbg_pid = "SETUP";
    `PID_PING:
        dbg_pid = "PING";
    // Data
    `PID_DATA0:
        dbg_pid = "DATA0";
    `PID_DATA1:
        dbg_pid = "DATA1";
    `PID_DATA2:
        dbg_pid = "DATA2";
    `PID_MDATA:
        dbg_pid = "MDATA";
    // Handshake
    `PID_ACK:
        dbg_pid = "ACK";
    `PID_NAK:
        dbg_pid = "NAK";
    `PID_STALL:
        dbg_pid = "STALL";
    `PID_NYET:
        dbg_pid = "NYET";
    // Special
    `PID_PRE:
        dbg_pid = "PRE/ERR";
    `PID_SPLIT:
        dbg_pid = "SPLIT";
    default:
        ;
    endcase
end
/* verilator lint_on WIDTH */
`endif


endmodule

