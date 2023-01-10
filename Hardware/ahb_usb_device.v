//=================================================================
// 
// USB device with AHB slave interface and ULPI PHY interface
//
// Version：V1.0
// Created by Zeba-Xie @github
// 
//=================================================================
module ahb_usb_device(
     input              hclk_i
    ,input              hrstn_i
    ,input              hsel_i
    ,input              hwrite_i
    ,input  [1:0]       htrans_i
    ,input  [2:0]       hburst_i
    ,input  [31:0]      hwdata_i
    ,input  [31:0]      haddr_i
    ,input  [2:0]       hsize_i
    ,input              hready_i

    ,input              ulpi_clk60_i
    ,input  [7:0]       ulpi_data_i
    ,input              ulpi_dir_i
    ,input              ulpi_nxt_i

    ,input  [1:0]       usb_scaledown_mode 

    ,output             hready_o
    ,output [1:0]       hresp_o
    ,output [31:0]      hrdata_o

    ,output [7:0]       ulpi_data_o
    ,output [7:0]       ulpi_data_out_en_o
    ,output             ulpi_stp_o

    ,output             intr_o
);


// wire
wire    [7:0]       utmi_data_in    ;   
wire                utmi_txready    ;    
wire                utmi_rxvalid    ;  
wire                utmi_rxactive   ;   
wire                utmi_rxerror    ;  
wire    [1:0]       utmi_linestate  ; 
wire    [7:0]       utmi_data_out   ;        
wire                utmi_txvalid    ;        
wire    [1:0]       utmi_op_mode    ;    
wire    [1:0]       utmi_xcvrselect ;          
wire                utmi_termselect ;          
wire                utmi_dppulldown ;    
wire                utmi_dmpulldown ;          
         
usbf_device u_usbf_device(
    .hclk_i                 (hclk_i             ),         
    .phy_clk_i              (ulpi_clk60_i       ),  
    .hrstn_i                (hrstn_i            ),    
    .hsel_i                 (hsel_i             ),
    .hwrite_i               (hwrite_i           ),
    .htrans_i               (htrans_i           ),
    .hburst_i               (hburst_i           ),
    .hwdata_i               (hwdata_i           ),    
    .haddr_i                (haddr_i            ),    
    .hsize_i                (hsize_i            ),    
    .hready_i               (hready_i           ),    

    .utmi_data_in_i         (utmi_data_in       ),   
    .utmi_txready_i         (utmi_txready       ),   
    .utmi_rxvalid_i         (utmi_rxvalid       ),       
    .utmi_rxactive_i        (utmi_rxactive      ),       
    .utmi_rxerror_i         (utmi_rxerror       ),   
    .utmi_linestate_i       (utmi_linestate     ),

    .usb_scaledown_mode_i   (usb_scaledown_mode ),

    .hready_o               (hready_o           ),   
    .hresp_o                (hresp_o            ),   
    .hrdata_o               (hrdata_o           ),       

    .intr_o                 (intr_o             ),       

    .utmi_data_out_o        (utmi_data_out      ),       
    .utmi_txvalid_o         (utmi_txvalid       ),   
    .utmi_op_mode_o         (utmi_op_mode       ),   
    .utmi_xcvrselect_o      (utmi_xcvrselect    ),
    .utmi_termselect_o      (utmi_termselect    ),
    .utmi_dppulldown_o      (utmi_dppulldown    ),
    .utmi_dmpulldown_o      (utmi_dmpulldown    )
);


usbf_ulpi_wrapper u_usbf_ulpi_wrapper(
    .ulpi_clk60_i           (ulpi_clk60_i       ),      
    .ulpi_rstn_i            (hrstn_i           ),  
    .ulpi_data_out_i        (ulpi_data_i        ),      
    .ulpi_dir_i             (ulpi_dir_i         ),  
    .ulpi_nxt_i             (ulpi_nxt_i         ),  

    .utmi_data_out_i        (utmi_data_out      ),      
    .utmi_txvalid_i         (utmi_txvalid       ),      
    .utmi_op_mode_i         (utmi_op_mode       ),  
    .utmi_xcvrselect_i      (utmi_xcvrselect    ),
    .utmi_termselect_i      (utmi_termselect    ),
    .utmi_dppulldown_i      (utmi_dppulldown    ),
    .utmi_dmpulldown_i      (utmi_dmpulldown    ),
     
    .ulpi_data_in_o         (ulpi_data_o        ),     
    .ulpi_stp_o             (ulpi_stp_o         ), 
    .ulpi_data_out_en_o     (ulpi_data_out_en_o ),   
    
    .utmi_data_in_o         (utmi_data_in       ), 
    .utmi_txready_o         (utmi_txready       ),     
    .utmi_rxvalid_o         (utmi_rxvalid       ),     
    .utmi_rxactive_o        (utmi_rxactive      ),     
    .utmi_rxerror_o         (utmi_rxerror       ),     
    .utmi_linestate_o       (utmi_linestate     )
);      


endmodule
