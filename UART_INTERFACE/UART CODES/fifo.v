module fifo #(parameter DEPTH = 8)(
    input            clk, rst,
    input            wr_en, rd_en,
    input      [7:0] din,
    output reg [7:0] dout,
    output           full, empty
);
    reg [7:0] mem [0:DEPTH-1];
    reg [2:0] wr_ptr, rd_ptr;
    reg [3:0] count;
 
    assign full  = (count == DEPTH);
    assign empty = (count == 0);
 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0; rd_ptr <= 0; count <= 0; dout <= 0;
        end else begin
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr      <= wr_ptr + 1;
            end
            if (rd_en && !empty) begin
                dout   <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1;
            end
            // FIX: single count update to avoid NBA double-assign bug
            case ({wr_en && !full, rd_en && !empty})
                2'b10:   count <= count + 1;   // write only
                2'b01:   count <= count - 1;   // read only
                default: count <= count;        // both or neither
            endcase
        end
    end
endmodule
