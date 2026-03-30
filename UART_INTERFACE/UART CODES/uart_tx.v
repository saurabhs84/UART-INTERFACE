module uart_tx (
    input            clk,
    input            rst,
    input            tick,
    input      [7:0] fifo_dout,
    input            fifo_empty,
    output reg       fifo_rd_en,
    output reg       tx,
    output           busy
);
    localparam IDLE = 2'd0,
               LOAD = 2'd1,
               SEND = 2'd2;
 
    reg [1:0]  state;
    reg [8:0]  shift_reg;   // 9 bits: D0..D7 + STOP
    reg [3:0]  bit_cnt;     // counts ticks in SEND (0..15 per bit)
    reg [3:0]  bit_num;     // which bit we are on (0..8)
 
    assign busy = (state != IDLE);
 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state      <= IDLE;
            tx         <= 1'b1;
            fifo_rd_en <= 1'b0;
            shift_reg  <= 9'h1FF;
            bit_cnt    <= 4'd0;
            bit_num    <= 4'd0;
        end else begin
            fifo_rd_en <= 1'b0;
 
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    if (!fifo_empty) begin
                        fifo_rd_en <= 1'b1;
                        state      <= LOAD;
                    end
                end
 
                LOAD: begin
                    // fifo_dout now stable
                    // Load data bits + stop bit into shift reg
                    // shift_reg[0] = D0 (LSB first), shift_reg[8] = STOP
                    shift_reg <= {1'b1, fifo_dout};  // [8]=STOP, [7:0]=D7..D0
                    tx        <= 1'b0;               // drive start bit
                    bit_cnt   <= 4'd0;
                    bit_num   <= 4'd0;
                    state     <= SEND;
                end
 
                SEND: begin
                    if (tick) begin
                        if (bit_cnt == 4'd15) begin
                            bit_cnt <= 4'd0;
                            // Output current bit from shift reg LSB
                            tx        <= shift_reg[0];
                            shift_reg <= {1'b1, shift_reg[8:1]};  // shift right
                            if (bit_num == 4'd8) begin
                                // Just sent stop bit
                                state <= IDLE;
                                tx    <= 1'b1;
                            end else begin
                                bit_num <= bit_num + 4'd1;
                            end
                        end else begin
                            bit_cnt <= bit_cnt + 4'd1;
                        end
                    end
                end
 
                default: state <= IDLE;
            endcase
        end
    end
endmodule
