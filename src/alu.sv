// ============================================================================
// Module: alu.sv
// Description: Khối số học & logic (ALU) 32-bit theo chuẩn ARM Architecture
// Chức năng:
//   - alucontrol = 00: ADD (Cộng: a + b)
//   - alucontrol = 01: SUB (Trừ: a - b = a + ~b + 1)
//   - alucontrol = 10: AND (Và logic: a & b)
//   - alucontrol = 11: ORR (Hoặc logic: a | b)
// Cờ trạng thái (flags):
//   - flags[3] = N (Negative: bit dấu của kết quả)
//   - flags[2] = Z (Zero: kết quả bằng 0)
//   - flags[1] = C (Carry: cờ nhớ khi cộng / mượn khi trừ - Cout của bộ cộng)
//   - flags[0] = V (oVerflow: tràn số có dấu)
// ============================================================================
module alu (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic [1:0]  alucontrol,
    output logic [31:0] result,
    output logic [3:0]  flags // {N, Z, C, V}
);

    logic [31:0] condinvb;
    logic [32:0] sum;
    logic        neg, zero, carry, overflow;

    // Đảo b nếu là phép trừ (alucontrol[0] == 1)
    assign condinvb = alucontrol[0] ? ~b : b;
    // Bộ cộng 33-bit để bắt chính xác Carry-out (bit thứ 32)
    assign sum      = {1'b0, a} + {1'b0, condinvb} + {32'b0, alucontrol[0]};

    // Chọn kết quả phép toán
    always_comb begin
        case (alucontrol)
            2'b00: result = sum[31:0]; // ADD
            2'b01: result = sum[31:0]; // SUB
            2'b10: result = a & b;     // AND
            2'b11: result = a | b;     // ORR
            default: result = 32'bx;
        endcase
    end

    // Tính toán 4 cờ trạng thái theo chuẩn ARM
    assign neg      = result[31];
    assign zero     = (result == 32'b0);
    // Cờ Carry: chỉ tính cho phép ADD/SUB (~alucontrol[1])
    assign carry    = ~alucontrol[1] & sum[32];
    // Cờ Overflow: tràn khi cộng 2 số cùng dấu ra trái dấu, hoặc trừ 2 số trái dấu ra kết quả sai dấu
    assign overflow = ~alucontrol[1] & ~(a[31] ^ b[31] ^ alucontrol[0]) & (a[31] ^ sum[31]);

    assign flags = {neg, zero, carry, overflow};

endmodule
