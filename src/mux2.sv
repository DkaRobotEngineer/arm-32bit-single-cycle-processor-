// ============================================================================
// Module: mux2.sv
// Description: Bộ dồn kênh 2 sang 1 tham số hóa (Parameterized 2-to-1 Multiplexer)
// ============================================================================
module mux2 #(parameter WIDTH = 32) (
    input  logic [WIDTH-1:0] d0, d1,
    input  logic             s,
    output logic [WIDTH-1:0] y
);
    assign y = s ? d1 : d0;
endmodule
