// ============================================================================
// Module: flopr.sv
// Description: D-Flip-Flop tham số hóa có Reset bất đồng bộ mức cao
// ============================================================================
module flopr #(parameter WIDTH = 32) (
    input  logic             clk, reset,
    input  logic [WIDTH-1:0] d,
    output logic [WIDTH-1:0] q
);
    always_ff @(posedge clk, posedge reset) begin
        if (reset) q <= '0;
        else       q <= d;
    end
endmodule
