module uart_top (
    input            clk,
    input            rst,
    input            wr_en,
    input      [7:0] data_in,
    output     [7:0] data_out,
    output           tx,
    output           irq
);
    wire        tick;
    wire        tx_fifo_rd_en;
    wire [7:0]  tx_fifo_dout;
    wire        tx_fifo_full;
    wire        tx_fifo_empty;
    wire [7:0]  rx_data;
    wire        rx_valid;
    wire        rx_fifo_empty;
 
    baud_gen bg (
        .clk  (clk),
        .rst  (rst),
        .tick (tick)
    );
 
    sync_fifo tx_fifo (
        .clk   (clk),
        .rst   (rst),
        .wr_en (wr_en),
        .rd_en (tx_fifo_rd_en),
        .din   (data_in),
        .dout  (tx_fifo_dout),
        .full  (tx_fifo_full),
        .empty (tx_fifo_empty)
    );
 
    uart_tx txu (
        .clk        (clk),
        .rst        (rst),
        .tick       (tick),
        .fifo_dout  (tx_fifo_dout),
        .fifo_empty (tx_fifo_empty),
        .fifo_rd_en (tx_fifo_rd_en),
        .tx         (tx),
        .busy       ()
    );
 
    uart_rx rxu (
        .clk   (clk),
        .rst   (rst),
        .tick  (tick),
        .rx    (tx),        // loopback
        .data  (rx_data),
        .valid (rx_valid)
    );
 
    sync_fifo rx_fifo (
        .clk   (clk),
        .rst   (rst),
        .wr_en (rx_valid),
        .rd_en (1'b0),
        .din   (rx_data),
        .dout  (),
        .full  (),
        .empty (rx_fifo_empty)
    );
 
    reg [7:0] data_out_r;
    always @(posedge clk or posedge rst) begin
        if (rst)           data_out_r <= 8'h00;
        else if (rx_valid) data_out_r <= rx_data;
    end
    assign data_out = data_out_r;
 
    interrupt_ctrl ic (
        .rx_ready (rx_valid),
        .tx_empty (tx_fifo_empty),
        .irq      (irq)
    );
 
endmodule
