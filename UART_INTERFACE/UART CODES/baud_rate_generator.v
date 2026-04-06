`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07.04.2026 02:06:53
// Design Name: 
// Module Name: baud_rate_generator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module baud_rate_generator (
    input clk, reset,
    output tx_enb, rx_enb
);

reg [12:0] tx_counter;
reg [9:0] rx_counter;

always @(posedge clk or posedge reset) begin
    if (reset)
        tx_counter <= 0;
    else if (tx_counter == 5208)
        tx_counter <= 0;
    else
        tx_counter <= tx_counter + 1;
end

always @(posedge clk or posedge reset) begin
    if (reset)
        rx_counter <= 0;
    else if (rx_counter == 325)
        rx_counter <= 0;
    else
        rx_counter <= rx_counter + 1;
end

assign tx_enb = (tx_counter == 0);
assign rx_enb = (rx_counter == 0);

endmodule
