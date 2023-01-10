
//=================================================================
//
// Definitions for USB20 protocol
//
// Version: V1.0
// Created by Ultra-Embedded.com 
// http://github.com/ultraembedded/cores
// 
// Can be added but not modified!
//
//=================================================================

// Tokens
`define PID_OUT                    8'hE1
`define PID_IN                     8'h69
`define PID_SOF                    8'hA5
`define PID_SETUP                  8'h2D

// Data
`define PID_DATA0                  8'hC3
`define PID_DATA1                  8'h4B
`define PID_DATA2                  8'h87
`define PID_MDATA                  8'h0F

// Handshake
`define PID_ACK                    8'hD2
`define PID_NAK                    8'h5A
`define PID_STALL                  8'h1E
`define PID_NYET                   8'h96

// Special
`define PID_PRE                    8'h3C
`define PID_ERR                    8'h3C
`define PID_SPLIT                  8'h78
`define PID_PING                   8'hB4

