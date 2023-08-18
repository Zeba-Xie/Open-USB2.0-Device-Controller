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
// 
// Version: V2.0
// Modified in 2023.8.5
// Use async FIFO
//=================================================================

`include "usbf_cfg_defs.v"

module usbf_mem(
      input                                         phy_clk_i
    , input                                         hclk_i
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
    wire rx_fifo_w_flush[0:`USB_EP_NUM-1];
    wire tx_fifo_r_flush[0:`USB_EP_NUM-1];

    for(i=0; i<`USB_EP_NUM; i=i+1)begin
        ////// flush sync
        pulse_sync r_flush_pulse_sync(
            .clk_s(hclk_i),
            .clk_d(phy_clk_i),
            .rst_n(rstn_i),
            .din(csr_ep_rx_ctrl_rx_flush_i[i]),
            .dout(rx_fifo_w_flush[i])
        );
        
        ////// RX FIFO
        usbf_fifo_async
        #(
            .WIDTH(8),
            .DEPTH(64),
            .OUT_REG(1)
        )
        u_fifo_rx
        (
            .rst_n(rstn_i),
            .w_clk(phy_clk_i), 
            .r_clk(hclk_i),
            
            // CSR read
            .r_flush(csr_ep_rx_ctrl_rx_flush_i[i]),
            .r_en(csr_ep_data_rd_req_i[i]),
            .dout(csr_ep_rx_data_o[i*`USB_EP0_DATA_DATA_W +: `USB_EP0_DATA_DATA_W]),
            .valid(),

            // EPU write
            .w_flush(rx_fifo_w_flush[i]),
            .w_en(epu_ep_data_wt_req_i[i]),
            .din(epu_ep_rx_data_i[i*`USB_EP0_DATA_DATA_W +: `USB_EP0_DATA_DATA_W]),

            .full_w(epu_ep_rx_full_o[i]),
            .empty_w()
        );

        ////// flush sync
        pulse_sync w_flush_pulse_sync(
            .clk_s(hclk_i),
            .clk_d(phy_clk_i),
            .rst_n(rstn_i),
            .din(csr_ep_tx_ctrl_tx_flush_i[i]),
            .dout(tx_fifo_r_flush[i])
        );

        ////// TX FIFO
        usbf_fifo_async
        #(
            .WIDTH(8),
            .DEPTH(64),
            .OUT_REG(0)
        )
        u_fifo_tx
        (
            .rst_n(rstn_i),
            .w_clk(hclk_i), 
            .r_clk(phy_clk_i),

            // CSR write
            .w_flush(csr_ep_tx_ctrl_tx_flush_i[i]),
            .w_en(csr_ep_data_wt_req_i[i]),            
            .din(csr_ep_tx_data_i[i*`USB_EP0_DATA_DATA_W +: `USB_EP0_DATA_DATA_W]),

            // EPU read
            .r_flush(tx_fifo_r_flush[i]),
            .r_en(epu_ep_data_rd_req_i[i]),
            .dout(epu_ep_tx_data_o[i*`USB_EP0_DATA_DATA_W +: `USB_EP0_DATA_DATA_W]),
            .valid(),

            .empty_w(epu_ep_tx_empty_o[i]),
            .full_w()
        );
    end
    
endgenerate

endmodule