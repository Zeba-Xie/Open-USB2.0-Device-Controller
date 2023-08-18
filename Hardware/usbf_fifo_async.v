//=================================================================
//
// Async FIFO
// 
// Version: V1.0
// Created by Zeba-Xie @github
//
// usbf_fifo_async_DEBUG:
//     If define: Mask empty for debug
//
// Param OUT_REG: 
//     0 : Direct data output
//     1 : Output after data register
//=================================================================

// `define usbf_fifo_async_DEBUG

module usbf_fifo_async #(
    parameter WIDTH   = 8,
    parameter DEPTH   = 4,
    parameter OUT_REG = 1
)(
    input                               rst_n,
    input                               w_clk,
    input                               r_clk,
    input                               w_en,
    input                               r_en,
    input                               w_flush,
    input                               r_flush,
    input      [WIDTH-1:0]              din,

    output reg [WIDTH-1:0]              dout,
    output reg                          valid,
    output                              empty_w,
    output reg                          empty,
    output                              full_w,
    output reg                          full
);

localparam ADDR_W  = $clog2(DEPTH);

//----------------------------------------------
// regs
//----------------------------------------------
reg [WIDTH-1:0] ram [DEPTH-1:0];

//----------------------------------------------
// wires
//----------------------------------------------
wire [ADDR_W-1:0]   w_addr;
wire [ADDR_W-1:0]   r_addr;


//----------------------------------------------
// write data to fifo
//----------------------------------------------
always @(posedge w_clk) begin
    if(w_en && !full)
        ram[w_addr] <= din;
end

generate
if (OUT_REG==1) begin
    //----------------------------------------------
    // read data from fifo
    //----------------------------------------------
    always @(posedge r_clk or negedge rst_n) begin
        if(!rst_n)
            dout <= 'd0;
        else if(r_flush)
            dout <= 'd0;
        `ifndef usbf_fifo_async_DEBUG
        else if(r_en && !empty)
        `else
        else if(r_en) //DEBUG
        `endif
            dout <= ram[r_addr];
        // else 
            // dout <= 'd0;
    end

    //----------------------------------------------
    // read data valid
    //----------------------------------------------
    always @(posedge r_clk or negedge rst_n) begin
        if(!rst_n)
            valid <= 1'd0;
        else if(r_flush)
            valid <= 1'd0;
        `ifndef usbf_fifo_async_DEBUG
        else if(r_en && !empty)
        `else
        else if(r_en) //DEBUG
        `endif
            valid <= 1'd1;
        else 
            valid <= 1'd0;
    end
end
else begin
    always@(*)begin
        dout = ram[r_addr];
        valid = (r_en && !empty);
    end
end
endgenerate

//----------------------------------------------
// write address pointer
//----------------------------------------------
reg  [ADDR_W:0]     w_addr_ptr;

wire [ADDR_W:0]     w_addr_ptr_next;

always @(posedge w_clk or negedge rst_n) begin
    if(!rst_n)
        w_addr_ptr <= 'd0;
    else if(w_flush)
        w_addr_ptr <= 'd0;
    else 
        w_addr_ptr <= w_addr_ptr_next;

end

assign w_addr_ptr_next = (w_en && !full) ? (w_addr_ptr + 1) : (w_addr_ptr);

//----------------------------------------------
// read address pointer
//----------------------------------------------
reg   [ADDR_W:0]     r_addr_ptr;

wire  [ADDR_W:0]     r_addr_ptr_next;

always @(posedge r_clk or negedge rst_n) begin
    if(!rst_n)
        r_addr_ptr <= 'd0;
    else if(r_flush)
        r_addr_ptr <= 'd0;
    else 
        r_addr_ptr <= r_addr_ptr_next;

end

`ifndef usbf_fifo_async_DEBUG
assign r_addr_ptr_next = (r_en && !empty) ? (r_addr_ptr + 1) : (r_addr_ptr);
`else
assign r_addr_ptr_next = (r_en) ? (r_addr_ptr + 1) : (r_addr_ptr); //DEBUG
`endif

//----------------------------------------------
// address pointer 2 gray
//----------------------------------------------
wire [ADDR_W:0]      w_addr_ptr_gray_next;
wire [ADDR_W:0]      r_addr_ptr_gray_next;

reg  [ADDR_W:0]      w_addr_ptr_gray;
reg  [ADDR_W:0]      r_addr_ptr_gray;

assign w_addr_ptr_gray_next = (w_addr_ptr_next >> 1) ^ w_addr_ptr_next;
assign r_addr_ptr_gray_next = (r_addr_ptr_next >> 1) ^ r_addr_ptr_next;

always @(posedge w_clk or negedge rst_n) begin
    if(!rst_n)
        w_addr_ptr_gray <= 'd0;
    else if(w_flush)
        w_addr_ptr_gray <= 'd0;
    else 
        w_addr_ptr_gray <= w_addr_ptr_gray_next;
end

always @(posedge r_clk or negedge rst_n) begin
    if(!rst_n)
        r_addr_ptr_gray <= 'd0;
    else if(r_flush)
        r_addr_ptr_gray <= 'd0;
    else 
        r_addr_ptr_gray <= r_addr_ptr_gray_next;
end

//----------------------------------------------
// sync w_addr_ptr_gray to read clk
//----------------------------------------------
reg [ADDR_W:0]      w_addr_ptr_gray_d1;
reg [ADDR_W:0]      w_addr_ptr_gray_d2;

always @(posedge r_clk or negedge rst_n) begin
    if(!rst_n)
        {w_addr_ptr_gray_d2, w_addr_ptr_gray_d1} <= 'd0;
    else if(r_flush)
        {w_addr_ptr_gray_d2, w_addr_ptr_gray_d1} <= 'd0;
    else 
        {w_addr_ptr_gray_d2, w_addr_ptr_gray_d1} <= {w_addr_ptr_gray_d1, w_addr_ptr_gray};
end

//----------------------------------------------
// sync r_addr_ptr_gray to write clk
//----------------------------------------------
reg [ADDR_W:0]      r_addr_ptr_gray_d1;
reg [ADDR_W:0]      r_addr_ptr_gray_d2;

always @(posedge w_clk or negedge rst_n) begin
    if(!rst_n)
        {r_addr_ptr_gray_d2, r_addr_ptr_gray_d1} <= 'd0;
    else if(w_flush)
        {r_addr_ptr_gray_d2, r_addr_ptr_gray_d1} <= 'd0;
    else 
        {r_addr_ptr_gray_d2, r_addr_ptr_gray_d1} <= {r_addr_ptr_gray_d1, r_addr_ptr_gray};
end

//----------------------------------------------
// fifo address 
//----------------------------------------------
assign w_addr = w_addr_ptr[ADDR_W-1:0];
assign r_addr = r_addr_ptr[ADDR_W-1:0];

//----------------------------------------------
// full and empty
//----------------------------------------------
assign full_w = {~r_addr_ptr_gray_d2[ADDR_W-:2],r_addr_ptr_gray_d2[ADDR_W-2:0]} == w_addr_ptr_gray_next;
assign empty_w = w_addr_ptr_gray_d2 == r_addr_ptr_gray_next;

always @(posedge w_clk or negedge rst_n) begin
    if(!rst_n)
        full <= 'd0;
    else if(w_flush)
        full <= 'd0;
    else 
        full <= full_w;
end

always @(posedge r_clk or negedge rst_n) begin
    if(!rst_n)
        empty <= 'd1;
    else if(r_flush)
        empty <= 'd1;
    else 
        empty <= empty_w;
end

endmodule
