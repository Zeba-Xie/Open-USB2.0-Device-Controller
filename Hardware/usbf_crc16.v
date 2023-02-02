//=================================================================
//
// CRC-16
//
// Version: V1.0
// Created by Ultra-Embedded.com 
// http://github.com/ultraembedded/cores
//
//=================================================================
module usbf_crc16
(
    // Inputs
     input  [ 15:0]  crc_in_i
    ,input  [  7:0]  din_i

    // Outputs
    ,output [ 15:0]  crc_out_o
);



//-----------------------------------------------------------------
// Logic
//-----------------------------------------------------------------
assign crc_out_o[15] =    din_i[0] ^ din_i[1] ^ din_i[2] ^ din_i[3] ^ din_i[4] ^ din_i[5] ^ din_i[6] ^ din_i[7] ^ 
                        crc_in_i[7] ^ crc_in_i[6] ^ crc_in_i[5] ^ crc_in_i[4] ^ crc_in_i[3] ^ crc_in_i[2] ^ crc_in_i[1] ^ crc_in_i[0];
assign crc_out_o[14] =    din_i[0] ^ din_i[1] ^ din_i[2] ^ din_i[3] ^ din_i[4] ^ din_i[5] ^ din_i[6] ^
                        crc_in_i[6] ^ crc_in_i[5] ^ crc_in_i[4] ^ crc_in_i[3] ^ crc_in_i[2] ^ crc_in_i[1] ^ crc_in_i[0];
assign crc_out_o[13] =    din_i[6] ^ din_i[7] ^ 
                        crc_in_i[7] ^ crc_in_i[6];
assign crc_out_o[12] =    din_i[5] ^ din_i[6] ^ 
                        crc_in_i[6] ^ crc_in_i[5];
assign crc_out_o[11] =    din_i[4] ^ din_i[5] ^ 
                        crc_in_i[5] ^ crc_in_i[4];
assign crc_out_o[10] =    din_i[3] ^ din_i[4] ^ 
                        crc_in_i[4] ^ crc_in_i[3];
assign crc_out_o[9] =     din_i[2] ^ din_i[3] ^ 
                        crc_in_i[3] ^ crc_in_i[2];
assign crc_out_o[8] =     din_i[1] ^ din_i[2] ^ 
                        crc_in_i[2] ^ crc_in_i[1];
assign crc_out_o[7] =     din_i[0] ^ din_i[1] ^ 
                        crc_in_i[15] ^ crc_in_i[1] ^ crc_in_i[0];
assign crc_out_o[6] =     din_i[0] ^ 
                        crc_in_i[14] ^ crc_in_i[0];
assign crc_out_o[5] =     crc_in_i[13];
assign crc_out_o[4] =     crc_in_i[12];
assign crc_out_o[3] =     crc_in_i[11];
assign crc_out_o[2] =     crc_in_i[10];
assign crc_out_o[1] =     crc_in_i[9];
assign crc_out_o[0] =     din_i[0] ^ din_i[1] ^ din_i[2] ^ din_i[3] ^ din_i[4] ^ din_i[5] ^ din_i[6] ^ din_i[7] ^
                        crc_in_i[8] ^ crc_in_i[7] ^ crc_in_i[6] ^ crc_in_i[5] ^ crc_in_i[4] ^ crc_in_i[3] ^ crc_in_i[2] ^ crc_in_i[1] ^ crc_in_i[0];


endmodule

