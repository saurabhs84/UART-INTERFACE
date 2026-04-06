`timescale 1ns/1ps

module uart_tb;

reg clk, rst;
reg [7:0] data_in;
reg wr_en;
wire rdy;
reg rdy_clr;
wire [7:0] dout;
wire busy;

// DUT
uart_top dut (
    .rst(rst),
    .data_in(data_in),
    .wr_en(wr_en),
    .clk(clk),
    .rdy_clr(rdy_clr),
    .rdy(rdy),
    .busy(busy),
    .data_out(dout)
);

// Clock generation (100 MHz)
always #5 clk = ~clk;

// ---------------- INITIAL ----------------
initial begin
    clk = 0;
    rst = 0;
    data_in = 0;
    wr_en = 0;
    rdy_clr = 0;
end

// ---------------- TASK: SEND BYTE ----------------
task send_byte(input [7:0] din);
begin
    @(negedge clk);
    data_in = din;
    wr_en = 1;
    @(negedge clk);
    wr_en = 0;

    $display("[%0t ns] SENT DATA = %h", $time, din);
end
endtask

// ---------------- TASK: CLEAR READY ----------------
task clear_ready;
begin
    @(negedge clk);
    rdy_clr = 1;
    @(negedge clk);
    rdy_clr = 0;
end
endtask

// ---------------- TASK: CHECK OUTPUT ----------------
task check_data(input [7:0] expected);
begin
    wait(rdy);
    #1; // small delay for stability

    if (dout == expected)
        $display("[%0t ns] ✅ PASS : Expected = %h, Received = %h", $time, expected, dout);
    else
        $display("[%0t ns] ❌ FAIL : Expected = %h, Received = %h", $time, expected, dout);

    clear_ready();
end
endtask

// ---------------- MAIN TEST ----------------
initial begin
    $display("=======================================");
    $display(" UART TESTBENCH STARTED ");
    $display("=======================================");

    // Reset
    @(negedge clk);
    rst = 1;
    @(negedge clk);
    rst = 0;

    $display("[%0t ns] Reset Done", $time);

    // ---------------- TEST CASE 1 ----------------
    $display("\n--- TEST CASE 1: Send 0x41 ('A') ---");
    send_byte(8'h41);
    wait(!busy);
    check_data(8'h41);

    // ---------------- TEST CASE 2 ----------------
    $display("\n--- TEST CASE 2: Send 0x55 ---");
    send_byte(8'h55);
    wait(!busy);
    check_data(8'h55);

    // ---------------- TEST CASE 3 ----------------
    $display("\n--- TEST CASE 3: Send 0xAA ---");
    send_byte(8'hAA);
    wait(!busy);
    check_data(8'hAA);

    // ---------------- TEST CASE 4 ----------------
    $display("\n--- TEST CASE 4: Send 0xFF ---");
    send_byte(8'hFF);
    wait(!busy);
    check_data(8'hFF);

    // ---------------- TEST CASE 5 ----------------
    $display("\n--- TEST CASE 5: Send 0x00 ---");
    send_byte(8'h00);
    wait(!busy);
    check_data(8'h00);

    // End Simulation
    $display("\n=======================================");
    $display(" ALL TEST CASES COMPLETED ");
    $display("=======================================");

    #2000000; // 2 ms simulation time
    $finish;
end

endmodule