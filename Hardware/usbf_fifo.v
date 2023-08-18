//=================================================================
//
// FIFO
//
// Version: V1.0
// Created by Ultra-Embedded.com 
// http://github.com/ultraembedded/cores
// 
// Version: V2.0
// Modified by Zeba-Xie @github:
// .Added conditional compilation option(REGS or GENERIC_RAM or 
// XILINX FPGA SPRAM)
//
//=================================================================

`include "usbf_cfg_defs.v"

module usbf_fifo
(
    // Inputs
     input           clk_i
    ,input           rstn_i
    ,input  [  7:0]  data_i
    ,input           push_i
    ,input           pop_i
    ,input           flush_i

    // Outputs
    ,output          full_o
    ,output          empty_o
    ,output [  7:0]  data_o
);

parameter WIDTH   = 8;
parameter DEPTH   = 4;
parameter ADDR_W  = 2;

//-----------------------------------------------------------------
// Local Params
//-----------------------------------------------------------------
localparam COUNT_W = ADDR_W + 1;

//-----------------------------------------------------------------
// USB_REG_FIFO
//-----------------------------------------------------------------
`ifdef USB_REG_FIFO

    //-----------------------------------------------------------------
    // Registers
    //-----------------------------------------------------------------
    reg [WIDTH-1:0]         ram [DEPTH-1:0];
    reg [ADDR_W-1:0]        rd_ptr;
    reg [ADDR_W-1:0]        wr_ptr;
    reg [COUNT_W-1:0]       count;

    //-----------------------------------------------------------------
    // Sequential
    //-----------------------------------------------------------------
    always @ (posedge clk_i or negedge rstn_i)
    if (!rstn_i)
    begin
        count   <= {(COUNT_W) {1'b0}};
        rd_ptr  <= {(ADDR_W) {1'b0}};
        wr_ptr  <= {(ADDR_W) {1'b0}};
    end
    else
    begin

        if (flush_i)
        begin
            count   <= {(COUNT_W) {1'b0}};
            rd_ptr  <= {(ADDR_W) {1'b0}};
            wr_ptr  <= {(ADDR_W) {1'b0}};
        end

        // Push
        if (push_i & ~full_o)
        begin
            ram[wr_ptr] <= data_i;
            wr_ptr      <= wr_ptr + 1;
        end

        // Pop
        if (pop_i & ~empty_o) 
        begin
            rd_ptr      <= rd_ptr + 1;
        end

        // Count up
        if ((push_i & ~full_o) & ~(pop_i & ~empty_o))
        begin
            count <= count + 1;
        end
        // Count down
        else if (~(push_i & ~full_o) & (pop_i & ~empty_o))
        begin
            count <= count - 1;
        end
    end

    //-------------------------------------------------------------------
    // Combinatorial
    //-------------------------------------------------------------------
    /* verilator lint_off WIDTH */
    assign full_o    = (count == DEPTH);
    assign empty_o   = (count == 0);
    /* verilator lint_on WIDTH */

    assign data_o    = ram[rd_ptr];


//-----------------------------------------------------------------
// FPGA or GENERIC_MEM
//-----------------------------------------------------------------
`else
    //-----------------------------------------------------------------
    // Registers
    //-----------------------------------------------------------------
    reg [ADDR_W-1:0]        rd_ptr;
    reg [ADDR_W-1:0]        wr_ptr;
    reg [COUNT_W-1:0]       count;

    //-----------------------------------------------------------------
    // Sequential
    //-----------------------------------------------------------------
    always @ (posedge clk_i or negedge rstn_i)
    if (!rstn_i)
    begin
        count   <= {(COUNT_W) {1'b0}};
        rd_ptr  <= {(ADDR_W) {1'b0}};
        wr_ptr  <= {(ADDR_W) {1'b0}};
    end
    else
    begin

        if (flush_i)
        begin
            count   <= {(COUNT_W) {1'b0}};
            rd_ptr  <= {(ADDR_W) {1'b0}};
            wr_ptr  <= {(ADDR_W) {1'b0}};
        end

        // Push
        if (push_i & ~full_o)
        begin
            wr_ptr      <= wr_ptr + 1;
        end

        // Pop
        if (pop_i & ~empty_o)
        begin
            rd_ptr      <= rd_ptr + 1;
        end

        // Count up
        if ((push_i & ~full_o) & ~(pop_i & ~empty_o))
        begin
            count <= count + 1;
        end
        // Count down
        else if (~(push_i & ~full_o) & (pop_i & ~empty_o))
        begin
            count <= count - 1;
        end
    end

    //-------------------------------------------------------------------
    // Combinatorial
    //-------------------------------------------------------------------
    /* verilator lint_off WIDTH */
    assign full_o    = (count == DEPTH);
    assign empty_o   = (count == 0);
    /* verilator lint_on WIDTH */


    //-------------------------------------------------------------------
    // Combinatorial
    //-------------------------------------------------------------------
    wire cs;
    wire gwe;
    wire [ADDR_W-1:0] addr;
    wire [WIDTH-1:0]  wdata;
    wire [WIDTH-1:0]  rdata;

    // assign cs           = push_i | pop_i ;
    assign cs           = 1'b1;
    assign gwe          = (push_i & ~full_o) ? 1'b1 : 1'b0;
    assign addr         = (push_i & ~full_o) ? wr_ptr : rd_ptr;
    assign wdata        = data_i;
    assign data_o       = rdata;

    `ifdef GENERIC_MEM

        GENERIC_RAM #( .addr_bits(ADDR_W), .data_bits(WIDTH), .we_size(WIDTH) ) u_ram (
            .clk       (  clk_i           ),
            .ls_i      (  1'b0            ), //light sleep
            .cs_i      (  cs              ),
            .addr_i    (  addr            ),
            .gwe_i     (  gwe             ),
            .we_i      (  1'b1            ),
            .wd_i      (  wdata           ),
            .rd_o      (  rdata           )
        );
    `elsif FPGA

        xpm_memory_spram #(
            .ADDR_WIDTH_A       ( ADDR_W                 ), // DECIMAL
            .AUTO_SLEEP_TIME    ( 0                      ), // DECIMAL
            .BYTE_WRITE_WIDTH_A ( WIDTH                  ), // DECIMAL
            .ECC_MODE           ( "no_ecc"               ), // String
            .MEMORY_INIT_FILE   ( "none"                 ), // String
            .MEMORY_INIT_PARAM  ( "0"                    ), // String
            .MEMORY_OPTIMIZATION( "true"                 ), // String
            .MEMORY_PRIMITIVE   ( "auto"                 ), // String
            .MEMORY_SIZE        ( WIDTH*(2**ADDR_W)      ), // DECIMAL
            .MESSAGE_CONTROL    ( 0                      ), // DECIMAL
            .READ_DATA_WIDTH_A  ( WIDTH                  ), // DECIMAL
            .READ_LATENCY_A     ( 1                      ), // DECIMAL
            .READ_RESET_VALUE_A ( "0"                    ), // String
            .RST_MODE_A         ( "SYNC"                 ), // String
            .USE_MEM_INIT       ( 1                      ), // DECIMAL
            .WAKEUP_TIME        ( "disable_sleep"        ), // String
            .WRITE_DATA_WIDTH_A ( WIDTH                  ), // DECIMAL
            .WRITE_MODE_A       ( "read_first"           )  // String
        )
        u_ram (
            .dbiterra       (            ) ,
            .douta          ( rdata      ) ,
            .sbiterra       (            ) ,
            .addra          ( addr       ) ,
            .clka           ( clk_i      ) ,
            .dina           ( wdata      ) ,
            .ena            ( cs         ) ,
            .injectdbiterra ( 1'b0       ) ,
            .injectsbiterra ( 1'b0       ) ,
            .regcea         ( 1'b1       ) ,
            .rsta           ( 1'b0       ) ,
            .sleep          ( 1'b0       ) ,
            .wea            ( gwe        )
        );

    `endif


`endif

endmodule

