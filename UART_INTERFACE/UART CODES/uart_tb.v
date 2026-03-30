`timescale 1ns/1ps
module uart_tb;
 
    reg clk = 1'b0;
    always #5 clk = ~clk;   // 100 MHz
 
    reg        rst;
    reg        wr_en;
    reg  [7:0] data_in;
    wire [7:0] data_out;
    wire       tx;
    wire       irq;
 
    // Scoreboard
    reg  [7:0] sent_q [0:4];
    reg  [2:0] sent_idx;
    reg  [2:0] recv_idx;
    integer    pass_cnt;
    integer    fail_cnt;
 
    uart_top uut (
        .clk      (clk),
        .rst      (rst),
        .wr_en    (wr_en),
        .data_in  (data_in),
        .data_out (data_out),
        .tx       (tx),
        .irq      (irq)
    );
 
    // $monitor ? fires on ANY signal change
    initial begin
        $display("==================================================");
        $display("   UART LOOPBACK SIMULATION");
        $display("   Clock: 100MHz | Frame: 8-N-1 | 16x oversample");
        $display("   1 frame = 10 bits x 16 ticks x 10ns = 1600ns");
        $display("==================================================");
        $monitor("[MON] %0t ps | tx=%b irq=%b data_out=8'h%02h",
                 $time, tx, irq, data_out);
    end
 
    // Send task ? ONE byte per call, waits between bytes
    // Inter-frame gap: wait 20 ticks (320ns) after wr_en deasserts
    // so TX finishes current frame before next byte is queued
    task send;
        input [7:0] byte_val;
        integer i;
        begin
            @(posedge clk); #1;
            wr_en   = 1'b1;
            data_in = byte_val;
            @(posedge clk); #1;
            wr_en   = 1'b0;
            data_in = 8'h00;
 
            sent_q[sent_idx] = byte_val;
            sent_idx         = sent_idx + 3'd1;
 
            $display("[TX ] Byte #%0d sent     -> 8'h%02h  (%0d decimal)",
                     sent_idx, byte_val, byte_val);
 
            // Wait for this byte to be fully transmitted + received
            // 1 frame = 1600ns = 160 clock cycles, add margin -> 200 cycles
            repeat(200) @(posedge clk);
        end
    endtask
 
    // RX monitor
    always @(posedge clk) begin
        if (uut.rxu.valid) begin
            $display("--------------------------------------------------");
            $display("[RX ] Byte #%0d received -> 8'h%02h  (%0d decimal)",
                     recv_idx + 1, uut.rxu.data, uut.rxu.data);
            $display("      Expected           -> 8'h%02h  (%0d decimal)",
                     sent_q[recv_idx], sent_q[recv_idx]);
            $display("      data_out port      -> 8'h%02h", data_out);
 
            if (uut.rxu.data === sent_q[recv_idx]) begin
                $display("      CHECK              -> PASS");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("      CHECK              -> FAIL  *** MISMATCH ***");
                $display("      Expected bits: %08b", sent_q[recv_idx]);
                $display("      Got bits:      %08b", uut.rxu.data);
                fail_cnt = fail_cnt + 1;
            end
            $display("--------------------------------------------------");
            recv_idx = recv_idx + 3'd1;
        end
    end
 
    // Stimulus
    initial begin
        sent_idx = 3'd0;
        recv_idx = 3'd0;
        pass_cnt = 0;
        fail_cnt = 0;
 
        rst     = 1'b1;
        wr_en   = 1'b0;
        data_in = 8'h00;
        $display("[RST] Reset asserted at t=%0t ps", $time);
        repeat(10) @(posedge clk);
        rst = 1'b0;
        repeat(2) @(posedge clk);
        $display("[RST] Reset released  at t=%0t ps", $time);
        $display("--------------------------------------------------");
 
        // Send bytes ONE AT A TIME with inter-frame gap
        send(8'h3C);   //  60 dec
        send(8'hA5);   // 165 dec
        send(8'h5A);   //  90 dec
        send(8'hFF);   // 255 dec
        send(8'h81);   // 129 dec
 
        // Extra wait after last byte
        repeat(50) @(posedge clk);
 
        // Summary
        $display("==================================================");
        $display("  SIMULATION SUMMARY");
        $display("  Bytes sent     : %0d", sent_idx);
        $display("  Bytes received : %0d", recv_idx);
        $display("  PASS           : %0d", pass_cnt);
        $display("  FAIL           : %0d", fail_cnt);
        $display("--------------------------------------------------");
        if (pass_cnt == 5 && fail_cnt == 0)
            $display("  RESULT  :  ALL 5 BYTES PASSED  (LOOPBACK OK)");
        else
            $display("  RESULT  :  ERRORS DETECTED");
        $display("==================================================");
        $finish;
    end
 
endmodule
