// ------------------------------------------------------------
module uart_rx (
    input            clk,
    input            rst,
    input            tick,
    input            rx,
    output reg [7:0] data,
    output reg       valid
);
    localparam IDLE  = 2'd0,
               START = 2'd1,
               DATA  = 2'd2,
               STOP  = 2'd3;
 
    reg [1:0] state;
    reg [3:0] tick_cnt;
    reg [2:0] bit_cnt;
    reg [7:0] shift_reg;
 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            valid     <= 1'b0;
            tick_cnt  <= 4'd0;
            bit_cnt   <= 3'd0;
            shift_reg <= 8'd0;
            data      <= 8'd0;
        end else begin
            valid <= 1'b0;
 
            case (state)
                // ---- Detect falling edge (start bit) ----
                IDLE: begin
                    tick_cnt <= 4'd0;
                    bit_cnt  <= 3'd0;
                    if (rx == 1'b0)
                        state <= START;
                end
 
                // ---- Wait to mid-start-bit (8 ticks) then validate ----
                START: begin
                    if (tick) begin
                        if (tick_cnt == 4'd7) begin
                            tick_cnt <= 4'd0;
                            if (rx == 1'b0)
                                state <= DATA;
                            else
                                state <= IDLE;
                        end else
                            tick_cnt <= tick_cnt + 4'd1;
                    end
                end
 
                // ---- Sample 8 data bits at mid-bit (tick 15) ----
                // FIX: shift LEFT so LSB-first bits assemble correctly
                // D0 received first -> lands at shift_reg[0]
                // D7 received last  -> lands at shift_reg[7]
                DATA: begin
                    if (tick) begin
                        if (tick_cnt == 4'd15) begin
                            tick_cnt  <= 4'd0;
                            // Shift left: new bit goes to LSB,
                            // previous bits move up
                            // After 8 bits: shift_reg = {D7,D6,...,D1,D0}
                            shift_reg <= {shift_reg[6:0], rx};
 
                            if (bit_cnt == 3'd7) begin
                                // All 8 bits received
                                data    <= {shift_reg[6:0], rx};
                                bit_cnt <= 3'd0;
                                state   <= STOP;
                            end else
                                bit_cnt <= bit_cnt + 3'd1;
                        end else
                            tick_cnt <= tick_cnt + 4'd1;
                    end
                end
 
                // ---- Validate stop bit ----
                STOP: begin
                    if (tick) begin
                        if (tick_cnt == 4'd15) begin
                            tick_cnt <= 4'd0;
                            valid    <= (rx == 1'b1);
                            state    <= IDLE;
                        end else
                            tick_cnt <= tick_cnt + 4'd1;
                    end
                end
 
                default: state <= IDLE;
            endcase
        end
    end
endmodule
