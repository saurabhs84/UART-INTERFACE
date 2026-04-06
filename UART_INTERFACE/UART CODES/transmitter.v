`timescale 1ns / 1ps

module transmitter (
    input clk, wr_enb, rst, enb,
    input [7:0] data_in,
    output reg tx,
    output busy
);

parameter idle_state = 2'b00;
parameter start_state = 2'b01;
parameter data_state  = 2'b10;
parameter stop_state  = 2'b11;

reg [7:0] data;
reg [2:0] index;
reg [1:0] state;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        state <= idle_state;
        tx <= 1'b1;
        index <= 0;
    end else begin
        case(state)

        idle_state: begin
            tx <= 1'b1;
            if (wr_enb) begin
                state <= start_state;
                data <= data_in;
                index <= 0;
            end
        end

        start_state: begin
            if (enb) begin
                tx <= 1'b0;
                state <= data_state;
            end
        end

        data_state: begin
            if (enb) begin
                tx <= data[index];
                if (index == 7)
                    state <= stop_state;
                else
                    index <= index + 1;
            end
        end

        stop_state: begin
            if (enb) begin
                tx <= 1'b1;
                state <= idle_state;
            end
        end

        endcase
    end
end

assign busy = (state != idle_state);

endmodule
