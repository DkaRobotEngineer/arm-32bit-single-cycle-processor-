// ============================================================================
// Module: pclogic.sv
// Description: Khối logic xác định xem PC có bị thay đổi (PCS) hay không
//              PCS = 1 nếu là lệnh Branch hoặc nếu đích ghi (Rd) là R15 và có ghi thanh ghi.
// ============================================================================
module pclogic (
    input  logic [3:0] rd,
    input  logic       branch,
    input  logic       regw,
    output logic       pcs
);

    assign pcs = ((rd == 4'b1111) & regw) | branch;

endmodule
