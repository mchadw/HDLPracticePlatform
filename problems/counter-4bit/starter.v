module counter_4bit (
    input  wire       clk,
    input  wire       rst,
    output reg  [3:0] q
);
    // TODO: synchronous reset to 0; otherwise increment on each rising clk
    always @(posedge clk) begin
        q <= 4'b0000;
    end
endmodule
