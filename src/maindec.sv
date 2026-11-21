// ============================================================================
// Module: maindec.sv
// Description: Khối giải mã chính (Main Decoder)
//              Giải mã các trường Op, Funct[5], Funct[0] thành các tín hiệu điều khiển datapath
// ============================================================================
module maindec (
    input  logic [1:0] op,
    input  logic       funct5, // Bit I
    input  logic       funct0, // Bit S (cho DP) hoặc L (cho LDR/STR)
    output logic       branch,
    output logic       memtoreg,
    output logic       memw,
    output logic       alusrc,
    output logic [1:0] immsrc,
    output logic       regw,
    output logic [1:0] regsrc,
    output logic       aluop
);

    logic [9:0] controls;

    assign {branch, memtoreg, memw, alusrc, immsrc, regw, regsrc, aluop} = controls;

    always_comb begin
        case (op)
            // 00: Data-processing
            2'b00: begin
                if (funct5)
                    // DP Immediate (ADD, SUB, AND, ORR với toán hạng tức thời)
                    controls = 10'b0_0_0_1_00_1_00_1;
                else
                    // DP Register (ADD, SUB, AND, ORR với toán hạng thanh ghi)
                    controls = 10'b0_0_0_0_00_1_00_1;
            end

            // 01: Memory (LDR, STR)
            2'b01: begin
                if (funct0)
                    // LDR: Nạp từ bộ nhớ vào thanh ghi
                    controls = 10'b0_1_0_1_01_1_00_0;
                else
                    // STR: Lưu từ thanh ghi ra bộ nhớ
                    controls = 10'b0_0_1_1_01_0_10_0;
            end

            // 10: Branch (B)
            2'b10: begin
                controls = 10'b1_0_0_1_10_0_01_0;
            end

            // Mặc định cho các opcode chưa hỗ trợ
            default: begin
                controls = 10'b0_0_0_0_00_0_00_0;
            end
        endcase
    end

endmodule
