`timescale 1ns / 1ps

module uart_top (
    input rst,
    input [7:0] data_in,
    input wr_en, clk, rdy_clr,
    output rdy, busy,
    output [7:0] data_out
);

wire rx_clk_en;
wire tx_clk_en;
wire tx_line;

baud_rate_generator bg (clk, rst, tx_clk_en, rx_clk_en);

transmitter tx (
    clk, wr_en, rst, tx_clk_en,
    data_in, tx_line, busy
);

uart_receiver rx (
    clk, rst, tx_line, rdy_clr,
    rx_clk_en, rdy, data_out
);

endmodule
