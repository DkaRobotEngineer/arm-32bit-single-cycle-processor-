// ============================================================================
// Module: aludec.sv
// Description: Khối giải mã ALU (ALU Decoder)
//              Xác định mã điều khiển ALUControl và các tín hiệu FlagW, NoWrite
// ============================================================================
module aludec (
    input  logic       aluop,
    input  logic [4:1] funct4_1, // Trường mã lệnh thao tác (cmd)
    input  logic       funct0,   // Bit S (Set condition flags)
    output logic [1:0] alucontrol,
    output logic [1:0] flagw,
    output logic       nowrite   // 1 cho lệnh so sánh (CMP) - không ghi thanh ghi
);

    always_comb begin
        if (~aluop) begin
            // Các lệnh không phải Data-processing (LDR, STR, B) dùng ALU để cộng địa chỉ
            alucontrol = 2'b00; // ADD
            flagw      = 2'b00;
            nowrite    = 1'b0;
        end else begin
            case (funct4_1)
                4'b0100: begin // ADD / ADDS
                    alucontrol = 2'b00;
                    flagw      = {funct0, funct0}; // Cập nhật NZCV nếu S=1
                    nowrite    = 1'b0;
                end
                4'b0010: begin // SUB / SUBS
                    alucontrol = 2'b01;
                    flagw      = {funct0, funct0}; // Cập nhật NZCV nếu S=1
                    nowrite    = 1'b0;
                end
                4'b0000: begin // AND / ANDS
                    alucontrol = 2'b10;
                    flagw      = {funct0, 1'b0};   // Chỉ cập nhật NZ nếu S=1
                    nowrite    = 1'b0;
                end
                4'b1100: begin // ORR / ORRS
                    alucontrol = 2'b11;
                    flagw      = {funct0, 1'b0};   // Chỉ cập nhật NZ nếu S=1
                    nowrite    = 1'b0;
                end
                4'b1010: begin // CMP (So sánh không ghi kết quả)
                    alucontrol = 2'b01;            // Thực hiện phép trừ A - B
                    flagw      = 2'b11;            // Luôn cập nhật đầy đủ NZCV
                    nowrite    = 1'b1;            // Không ghi thanh ghi đích
                end
                default: begin
                    alucontrol = 2'b00;
                    flagw      = 2'b00;
                    nowrite    = 1'b0;
                end
            endcase
        end
    end

endmodule
