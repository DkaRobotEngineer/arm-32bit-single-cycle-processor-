// ============================================================================
// Module: decode.sv
// Description: Khối giải mã tổ hợp bao gồm Main Decoder, ALU Decoder và PC Logic
// ============================================================================
module decode (
    input  logic [1:0] op,
    input  logic [5:0] funct,
    input  logic [3:0] rd,
    output logic [1:0] flagw,
    output logic       pcs,
    output logic       regw,
    output logic       memw,
    output logic       memtoreg,
    output logic       alusrc,
    output logic [1:0] immsrc,
    output logic [1:0] regsrc,
    output logic [1:0] alucontrol
);

    logic branch, aluop, regw_main, nowrite;

    // Khối giải mã chính
    maindec md (
        .op       (op),
        .funct5   (funct[5]),
        .funct0   (funct[0]),
        .branch   (branch),
        .memtoreg (memtoreg),
        .memw     (memw),
        .alusrc   (alusrc),
        .immsrc   (immsrc),
        .regw     (regw_main),
        .regsrc   (regsrc),
        .aluop    (aluop)
    );

    // Khối giải mã ALU
    aludec ad (
        .aluop      (aluop),
        .funct4_1   (funct[4:1]),
        .funct0     (funct[0]),
        .alucontrol (alucontrol),
        .flagw      (flagw),
        .nowrite    (nowrite)
    );

    // Nếu lệnh là CMP (nowrite = 1) thì cấm ghi vào thanh ghi
    assign regw = regw_main & ~nowrite;

    // Khối xác định cập nhật Program Counter (PC)
    pclogic pcl (
        .rd     (rd),
        .branch (branch),
        .regw   (regw),
        .pcs    (pcs)
    );

endmodule
