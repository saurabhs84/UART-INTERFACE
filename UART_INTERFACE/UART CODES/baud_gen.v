module baud_gen (
    input  clk,
    input  rst,
    output reg tick
);
    reg [3:0] count;
 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count <= 4'd0;
            tick  <= 1'b0;
        end else if (count == 4'd15) begin
            count <= 4'd0;
            tick  <= 1'b1;
        end else begin
            count <= count + 4'd1;
            tick  <= 1'b0;
        end
    end
endmodule
