module interrupt_ctrl (
    input  rx_ready,
    input  tx_empty,
    output reg irq
);
    always @(*) irq = rx_ready | tx_empty;
endmodule