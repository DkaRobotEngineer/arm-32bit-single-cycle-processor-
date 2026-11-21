// ============================================================================
// Module: extend.sv
// Description: Khối mở rộng hằng số tức thời (Extend Unit) 24-bit -> 32-bit
// Các chế độ:
//   - immsrc = 00: Lệnh Data-processing Immediate (mở rộng zero 8-bit Instr[7:0])
//   - immsrc = 01: Lệnh Memory LDR/STR (mở rộng zero 12-bit Instr[11:0])
//   - immsrc = 10: Lệnh Branch B (mở rộng có dấu 24-bit Instr[23:0] và dịch trái 2 bit)
// ============================================================================
module extend (
    input  logic [23:0] instr,
    input  logic [1:0]  immsrc,
    output logic [31:0] extimm
);

    always_comb begin
        case (immsrc)
            2'b00:   extimm = {24'b0, instr[7:0]};
            2'b01:   extimm = {20'b0, instr[11:0]};
            2'b10:   extimm = {{6{instr[23]}}, instr[23:0], 2'b00};
            default: extimm = 32'bx;
        endcase
    end

endmodule
