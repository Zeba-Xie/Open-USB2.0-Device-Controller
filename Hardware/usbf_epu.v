//=================================================================
// 
// Endpoint unit module, including multipile sie-eps.
//
// Version: V1.0
// Created by Zeba-Xie @github
//
// |      |--RX SIE-->|     |--wt-->|  RX-FIFO  |
// | CORE |           | EPU |       |    MEM    |   
// |      |--TX SIE<--|     |--rd<--|  TX-FIFO  |
//                    |-----|
//                       ^
//                       |
//                       v
//                    | CSR |
//
//=================================================================

`include "usbf_cfg_defs.v"

module usbf_epu(
      input                                         phy_clk_i        
    , input                                         rstn_i

    //////  CORE interface
        //  RX SIE
    ,output [`USB_EP_NUM-1:0]                       core_sie_rx_space_o
    , input [`USB_EP_NUM-1:0]                       core_sie_rx_valid_i
    , input [`USB_EP_NUM-1:0]                       core_sie_rx_setup_i
            //  SIE shared
    , input                                         core_sie_rx_strb_i
    , input [  7:0]                                 core_sie_rx_data_i
    , input                                         core_sie_rx_last_i
    , input                                         core_sie_rx_crc_err_i 
        //  TX SIE
    ,output [`USB_EP_NUM-1:0]                       core_sie_tx_ready_o    
    ,output [`USB_EP_NUM-1:0]                       core_sie_tx_valid_o  
    ,output [`USB_EP_NUM-1:0]                       core_sie_tx_strb_o  
    ,output [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  core_sie_tx_data_o  
    ,output [`USB_EP_NUM-1:0]                       core_sie_tx_last_o  
    , input [`USB_EP_NUM-1:0]                       core_sie_tx_accept_i

    //////  MEM interface
        //  RX FIFO (Write)
    ,output [`USB_EP_NUM-1:0]                       mem_ep_data_wt_req_o
    ,output [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  mem_ep_rx_data_o 
    , input [`USB_EP_NUM-1:0]                       mem_ep_rx_full_i 
        //  TX FIFO (Read)
    ,output [`USB_EP_NUM-1:0]                       mem_ep_data_rd_req_o
    , input [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  mem_ep_tx_data_i
    , input [`USB_EP_NUM-1:0]                       mem_ep_tx_empty_i 

    //////  CSR interface
        //  RX Reg
    ,output [`USB_EP0_STS_RX_COUNT_W*`USB_EP_NUM-1:0]  csr_ep_sts_rx_count_o
    ,output [`USB_EP_NUM-1:0]                       csr_ep_sts_rx_ready_o
    ,output [`USB_EP_NUM-1:0]                       csr_ep_sts_rx_err_o
    ,output [`USB_EP_NUM-1:0]                       csr_ep_sts_rx_setup_o
    , input [`USB_EP_NUM-1:0]                       csr_ep_sts_rx_ack_i
        //  TX Reg
    , input [`USB_EP_NUM-1:0]                       csr_ep_tx_ctrl_tx_flush_i
    , input [`USB_EP0_TX_CTRL_TX_LEN_W*`USB_EP_NUM-1:0] csr_ep_tx_ctrl_tx_length_i
    , input [`USB_EP_NUM-1:0]                       csr_ep_tx_ctrl_tx_start_i
    ,output [`USB_EP_NUM-1:0]                       csr_ep_sts_tx_err_o
    ,output [`USB_EP_NUM-1:0]                       csr_ep_sts_tx_busy_o
);

genvar i;
generate
    for(i=0; i<`USB_EP_NUM; i=i+1)begin
        usbf_sie_ep u_ep
        (
        .clk_i(phy_clk_i), 
        .rstn_i(rstn_i),   

        // Rx SIE Interface
        .rx_space_o(core_sie_rx_space_o[i]),
        .rx_valid_i(core_sie_rx_valid_i[i]),
        .rx_setup_i(core_sie_rx_setup_i[i]),

        .rx_strb_i(core_sie_rx_strb_i),
        .rx_data_i(core_sie_rx_data_i),
        .rx_last_i(core_sie_rx_last_i),
        .rx_crc_err_i(core_sie_rx_crc_err_i),

        // Tx SIE Interface
        .tx_ready_o(core_sie_tx_ready_o[i]),
        .tx_data_valid_o(core_sie_tx_valid_o[i]),
        .tx_data_strb_o(core_sie_tx_strb_o[i]),
        .tx_data_o(core_sie_tx_data_o[i*`USB_EP0_DATA_DATA_W +: `USB_EP0_DATA_DATA_W]),
        .tx_data_last_o(core_sie_tx_last_o[i]),
        .tx_data_accept_i(core_sie_tx_accept_i[i]),

        // Rx FIFO Interface
        .rx_push_o(mem_ep_data_wt_req_o[i]),
        .rx_data_o(mem_ep_rx_data_o[i*`USB_EP0_DATA_DATA_W +: `USB_EP0_DATA_DATA_W]),
        .rx_full_i(mem_ep_rx_full_i[i]),

        // Tx FIFO Interface
        .tx_pop_o(mem_ep_data_rd_req_o[i]),
        .tx_data_i(mem_ep_tx_data_i[i*`USB_EP0_DATA_DATA_W +: `USB_EP0_DATA_DATA_W]),
        .tx_empty_i(mem_ep_tx_empty_i[i]),

        // Rx Register Interface
        .rx_length_o(csr_ep_sts_rx_count_o[i*`USB_EP0_STS_RX_COUNT_W +: `USB_EP0_STS_RX_COUNT_W]),
        .rx_ready_o(csr_ep_sts_rx_ready_o[i]),
        .rx_err_o(csr_ep_sts_rx_err_o[i]),
        .rx_setup_o(csr_ep_sts_rx_setup_o[i]),
        .rx_ack_i(csr_ep_sts_rx_ack_i[i]),

        // Tx Register Interface
        .tx_flush_i(csr_ep_tx_ctrl_tx_flush_i[i]),
        .tx_length_i(csr_ep_tx_ctrl_tx_length_i[i*`USB_EP0_TX_CTRL_TX_LEN_W +: `USB_EP0_TX_CTRL_TX_LEN_W]),
        .tx_start_i(csr_ep_tx_ctrl_tx_start_i[i]),
        .tx_busy_o(csr_ep_sts_tx_busy_o[i]),
        .tx_err_o(csr_ep_sts_tx_err_o[i])
        );
    end
    

endgenerate




endmodule
