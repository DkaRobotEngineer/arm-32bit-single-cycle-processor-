// ============================================================================
// Module: flopenr.sv
// Description: D-Flip-Flop tham số hóa có tín hiệu Enable và Reset bất đồng bộ
// ============================================================================
module flopenr #(parameter WIDTH = 32) (
    input  logic             clk, reset,
    input  logic             en,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset)   q <= '0;
        else if (en) q <= d;
    end
endmodule
