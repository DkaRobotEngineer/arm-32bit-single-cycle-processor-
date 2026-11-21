// ============================================================================
// Module: shifter.sv
// Description: Khối Barrel Shifter 32-bit mở rộng cho vi xử lý ARM
//              Hỗ trợ 4 chế độ dịch: LSL, LSR, ASR, ROR
// Inputs:
//   - a: Toán hạng cần dịch (32-bit từ RD2)
//   - shamt: Số bit cần dịch (5-bit từ Instr[11:7], giá trị 0-31)
//   - shtype: Loại phép dịch (2-bit từ Instr[6:5])
//       00: LSL (Logical Shift Left)
//       01: LSR (Logical Shift Right)
//       10: ASR (Arithmetic Shift Right - giữ dấu)
//       11: ROR (Rotate Right - xoay phải)
// Outputs:
//   - y: Kết quả sau khi dịch (32-bit)
// ============================================================================
module shifter (
    input  logic [31:0] a,
    input  logic [4:0]  shamt,
    input  logic [1:0]  shtype,
    output logic [31:0] y
);

    always_comb begin
        case (shtype)
            2'b00: y = a << shamt;                           // LSL: Dịch trái logic
            2'b01: y = a >> shamt;                           // LSR: Dịch phải logic (chèn 0)
            2'b10: y = $signed(a) >>> shamt;                 // ASR: Dịch phải số học (bảo toàn bit dấu)
            2'b11: y = (shamt == 5'd0) ? a :                 // ROR: Xoay vòng phải
                       ((a >> shamt) | (a << (32 - shamt)));
            default: y = a;
        endcase
    end

endmodule
