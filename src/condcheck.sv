// ============================================================================
// Module: condcheck.sv
// Description: Giải mã toàn bộ 14 mã điều kiện thực thi (Condition Execution) của ARM
// Inputs:
//   - cond: Trường mã điều kiện 4-bit (Instr[31:28])
//   - flags: 4 cờ trạng thái hiện thời {N, Z, C, V}
// Output:
//   - condex: 1 nếu thỏa mãn điều kiện thực thi, 0 nếu bỏ qua lệnh
// ============================================================================
module condcheck (
    input  logic [3:0] cond,
    input  logic [3:0] flags, // {N, Z, C, V}
    output logic       condex
);

    logic neg, zero, carry, overflow, ge;

    assign {neg, zero, carry, overflow} = flags;
    assign ge = (neg == overflow);

    always_comb begin
        case (cond)
            4'b0000: condex = zero;                     // EQ: Bằng nhau (Zero set)
            4'b0001: condex = ~zero;                    // NE: Khác nhau (Zero clear)
            4'b0010: condex = carry;                    // CS / HS: Cờ nhớ bật (Unsigned Higher or Same)
            4'b0011: condex = ~carry;                   // CC / LO: Cờ nhớ tắt (Unsigned Lower)
            4'b0100: condex = neg;                      // MI: Âm (Negative set)
            4'b0101: condex = ~neg;                     // PL: Dương hoặc 0 (Negative clear)
            4'b0110: condex = overflow;                 // VS: Tràn (Overflow set)
            4'b0111: condex = ~overflow;                // VC: Không tràn (Overflow clear)
            4'b1000: condex = carry & ~zero;            // HI: Lớn hơn không dấu (Unsigned Higher)
            4'b1001: condex = ~carry | zero;            // LS: Nhỏ hơn hoặc bằng không dấu
            4'b1010: condex = ge;                       // GE: Lớn hơn hoặc bằng có dấu
            4'b1011: condex = ~ge;                      // LT: Nhỏ hơn có dấu
            4'b1100: condex = ~zero & ge;               // GT: Lớn hơn có dấu
            4'b1101: condex = zero | ~ge;               // LE: Nhỏ hơn hoặc bằng có dấu
            4'b1110: condex = 1'b1;                     // AL: Luôn luôn thực thi (Always)
            default: condex = 1'b0;                     // 4'b1111: Dự phòng / không xác định
        endcase
    end

endmodule
