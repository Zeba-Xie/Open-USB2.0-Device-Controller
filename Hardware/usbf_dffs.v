//=================================================================
//
// There are some diffs
// 
// Version: V1.0
// Created by Zeba-Xie @github
//
//=================================================================

//=================================================================
//
// Description:
//  Verilog module usbf_gnrl DFF with Load-enable and Reset
//  Default reset value is 1
//
//=================================================================

module usbf_gnrl_dfflrs # (
  parameter DW = 32
) (

  input               lden, 
  input      [DW-1:0] dnxt,
  output     [DW-1:0] qout,

  input               clk,
  input               rst_n
);

reg [DW-1:0] qout_r;

always @(posedge clk or negedge rst_n)
begin : DFFLRS_PROC
  if (rst_n == 1'b0)
    qout_r <= {DW{1'b1}};
  else if (lden == 1'b1)
    qout_r <= dnxt;
end

assign qout = qout_r;

// `ifndef FPGA_SOURCE//{
// `ifndef DISABLE_SV_ASSERTION//{
// //synopsys translate_off
// usbf_gnrl_xchecker # (
//   .DW(1)
// ) usbf_gnrl_xchecker(
//   .i_dat(lden),
//   .clk  (clk)
// );
// //synopsys translate_on
// `endif//}
// `endif//}
    

endmodule
//=================================================================
//
// Description:
//  Verilog module usbf_gnrl DFF with Load-enable and Reset
//  Default reset value is 0
//
//=================================================================

module usbf_gnrl_dfflr # (
  parameter DW = 32
) (

  input               lden, 
  input      [DW-1:0] dnxt,
  output     [DW-1:0] qout,

  input               clk,
  input               rst_n
);

reg [DW-1:0] qout_r;

always @(posedge clk or negedge rst_n)
begin : DFFLR_PROC
  if (rst_n == 1'b0)
    qout_r <= {DW{1'b0}};
  else if (lden == 1'b1)
    qout_r <= dnxt;
end

assign qout = qout_r;

// `ifndef FPGA_SOURCE//{
// `ifndef DISABLE_SV_ASSERTION//{
// //synopsys translate_off
// usbf_gnrl_xchecker # (
//   .DW(1)
// ) usbf_gnrl_xchecker(
//   .i_dat(lden),
//   .clk  (clk)
// );
// //synopsys translate_on
// `endif//}
// `endif//}
    

endmodule
//=================================================================
//
// Description:
//  Verilog module usbf_gnrl DFF with Load-enable, no reset 
//
//=================================================================

module usbf_gnrl_dffl # (
  parameter DW = 32
) (

  input               lden, 
  input      [DW-1:0] dnxt,
  output     [DW-1:0] qout,

  input               clk 
);

reg [DW-1:0] qout_r;

always @(posedge clk)
begin : DFFL_PROC
  if (lden == 1'b1)
    qout_r <= dnxt;
end

assign qout = qout_r;

// `ifndef FPGA_SOURCE//{
// `ifndef DISABLE_SV_ASSERTION//{
// //synopsys translate_off
// usbf_gnrl_xchecker # (
//   .DW(1)
// ) usbf_gnrl_xchecker(
//   .i_dat(lden),
//   .clk  (clk)
// );
// //synopsys translate_on
// `endif//}
// `endif//}
    

endmodule
//=================================================================
//
// Description:
//  Verilog module usbf_gnrl DFF with Reset, no load-enable
//  Default reset value is 1
//
//=================================================================

module usbf_gnrl_dffrs # (
  parameter DW = 32
) (

  input      [DW-1:0] dnxt,
  output     [DW-1:0] qout,

  input               clk,
  input               rst_n
);

reg [DW-1:0] qout_r;

always @(posedge clk or negedge rst_n)
begin : DFFRS_PROC
  if (rst_n == 1'b0)
    qout_r <= {DW{1'b1}};
  else                  
    qout_r <= dnxt;
end

assign qout = qout_r;

endmodule
//=================================================================
//
// Description:
//  Verilog module usbf_gnrl DFF with Reset, no load-enable
//  Default reset value is 0
//
//=================================================================

module usbf_gnrl_dffr # (
  parameter DW = 32
) (

  input      [DW-1:0] dnxt,
  output     [DW-1:0] qout,

  input               clk,
  input               rst_n
);

reg [DW-1:0] qout_r;

always @(posedge clk or negedge rst_n)
begin : DFFR_PROC
  if (rst_n == 1'b0)
    qout_r <= {DW{1'b0}};
  else                  
    qout_r <= dnxt;
end

assign qout = qout_r;

endmodule


//=================================================================
//
// Description:
//  Verilog module usbf_gnrl DFF with Load-enable and Reset
//  Default reset value is set by parameter
//
//=================================================================

module usbf_gnrl_dfflrd # (
  parameter DW = 32,
  parameter RESET_VAL = {DW{1'b0}}
) (

  input               lden, 
  input      [DW-1:0] dnxt,
  output     [DW-1:0] qout,

  input               clk,
  input               rst_n
);

reg [DW-1:0] qout_r;

always @(posedge clk or negedge rst_n)
begin : DFFLRS_PROC
  if (rst_n == 1'b0)
    qout_r <= RESET_VAL;
  else if (lden == 1'b1)
    qout_r <= dnxt;
end

assign qout = qout_r;

// `ifndef FPGA_SOURCE//{
// `ifndef DISABLE_SV_ASSERTION//{
// //synopsys translate_off
// usbf_gnrl_xchecker # (
//   .DW(1)
// ) usbf_gnrl_xchecker(
//   .i_dat(lden),
//   .clk  (clk)
// );
// //synopsys translate_on
// `endif//}
// `endif//}
    

endmodule