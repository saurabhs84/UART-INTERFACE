`timescale 1ns / 1ps

module uart_receiver (
    input clk, rst, rx, rdy_clr, clk_en,
    output reg rdy,
    output reg [7:0] data_out
);

parameter start_state = 2'b00;
parameter data_state  = 2'b01;
parameter stop_state  = 2'b10;

reg [1:0] state;
reg [3:0] sample;
reg [2:0] index;
reg [7:0] temp;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= start_state;
        sample <= 0;
        index <= 0;
        rdy <= 0;
        data_out <= 0;
    end else begin

        if (rdy_clr)
            rdy <= 0;

        if (clk_en) begin
            case(state)

            start_state: begin
                if (rx == 0) begin
                    sample <= sample + 1;
                    if (sample == 7) begin
                        sample <= 0;
                        state <= data_state;
                        index <= 0;
                    end
                end else begin
                    sample <= 0;
                end
            end

            data_state: begin
                sample <= sample + 1;
                if (sample == 8) begin
                    temp[index] <= rx;
                end
                if (sample == 15) begin
                    sample <= 0;
                    if (index == 7)
                        state <= stop_state;
                    else
                        index <= index + 1;
                end
            end

            stop_state: begin
                sample <= sample + 1;
                if (sample == 15) begin
                    data_out <= temp;
                    rdy <= 1;
                    state <= start_state;
                    sample <= 0;
                end
            end

            endcase
        end
    end
end

endmodule
