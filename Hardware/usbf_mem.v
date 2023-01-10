//=================================================================
//
// Memory module, including multipile RX and TX FIFOs for EPU 
//
// Version: V1.0
// Created by Zeba-Xie @github
//
//     |--wt-->|RX-FIFO|-->rd--|
// EPU |       |       |       | CSR
//     |--rd<--|TX-FIFO|<--wt--|
// 
// TODO: FIFOs can be configured to different size for different EP
//=================================================================

`include "usbf_cfg_defs.v"

module usbf_mem(
      input                                         phy_clk_i
    , input                                         rstn_i

    ////// CSR interface
    //// RX-FIFO Read
    , input [`USB_EP_NUM-1:0]                       csr_ep_rx_ctrl_rx_flush_i 
    , input [`USB_EP_NUM-1:0]                       csr_ep_data_rd_req_i
    ,output [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  csr_ep_rx_data_o
    //// TX-FIFO Write
    , input [`USB_EP_NUM-1:0]                       csr_ep_tx_ctrl_tx_flush_i
    , input [`USB_EP_NUM-1:0]                       csr_ep_data_wt_req_i 
    , input [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  csr_ep_tx_data_i

    ////// EPU interface 
    //// RX-FIFO Write 
    , input [`USB_EP_NUM-1:0]                       epu_ep_data_wt_req_i 
    ,output [`USB_EP_NUM-1:0]                       epu_ep_rx_full_o
    , input [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  epu_ep_rx_data_i
    //// TX-FIFO Read
    , input [`USB_EP_NUM-1:0]                       epu_ep_data_rd_req_i 
    ,output [`USB_EP_NUM-1:0]                       epu_ep_tx_empty_o
    ,output [`USB_EP0_DATA_DATA_W*`USB_EP_NUM-1:0]  epu_ep_tx_data_o
     
);

genvar i;
generate
    for(i=0; i<`USB_EP_NUM; i=i+1)begin
        ////// RX FIFO
        usbf_fifo
        #(
            .WIDTH(8),
            .DEPTH(64),
            .ADDR_W(6)
        )
        u_fifo_rx
        (
            .clk_i(phy_clk_i), 
            .rstn_i(rstn_i),
            
            // CSR read
            .flush_i(csr_ep_rx_ctrl_rx_flush_i[i]),
            .pop_i(csr_ep_data_rd_req_i[i]),
            .data_o(csr_ep_rx_data_o[i*`USB_EP0_DATA_DATA_W +: `USB_EP0_DATA_DATA_W]),

            // EPU write
            .push_i(epu_ep_data_wt_req_i[i]),
            .full_o(epu_ep_rx_full_o[i]),
            .data_i(epu_ep_rx_data_i[i*`USB_EP0_DATA_DATA_W +: `USB_EP0_DATA_DATA_W]),

            .empty_o()
        );

        ////// TX FIFO
        usbf_fifo
        #(
            .WIDTH(8),
            .DEPTH(64),
            .ADDR_W(6)
        )
        u_fifo_tx
        (
            .clk_i(phy_clk_i), 
            .rstn_i(rstn_i),

            // CSR write
            .flush_i(csr_ep_tx_ctrl_tx_flush_i[i]),
            .push_i(csr_ep_data_wt_req_i[i]),            
            .data_i(csr_ep_tx_data_i[i*`USB_EP0_DATA_DATA_W +: `USB_EP0_DATA_DATA_W]),

            // EPU read
            .pop_i(epu_ep_data_rd_req_i[i]),
            .empty_o(epu_ep_tx_empty_o[i]),
            .data_o(epu_ep_tx_data_o[i*`USB_EP0_DATA_DATA_W +: `USB_EP0_DATA_DATA_W]),

            .full_o()
            
        );
    end
    
endgenerate

endmodule