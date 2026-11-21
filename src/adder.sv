// ============================================================================
// Module: adder.sv
// Description: Bộ cộng tham số hóa (Parameterized Adder)
// ============================================================================
module adder #(parameter WIDTH = 32) (
    input  logic [WIDTH-1:0] a, b,
    output logic [WIDTH-1:0] y
);
    assign y = a + b;
endmodule
