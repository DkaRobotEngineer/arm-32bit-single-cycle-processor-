// ============================================================================
// Module: controller.sv
// Description: Bộ điều khiển trung tâm (Control Unit) cho Single-Cycle ARM
//              Bao gồm Decode (giải mã lệnh) và CondLogic (xử lý cờ và điều kiện)
// ============================================================================
module controller (
    input  logic        clk, reset,
    input  logic [31:12] instr,
    input  logic [3:0]  aluflags,
    output logic [1:0]  regsrc,
    output logic        regwrite,
    output logic [1:0]  immsrc,
    output logic        alusrc,
    output logic [1:0]  alucontrol,
    output logic        memwrite,
    output logic        memtoreg,
    output logic        pcsrc
);

    logic [1:0] flagw;
    logic       pcs, regw, memw;

    // Khối giải mã lệnh
    decode dec (
        .op         (instr[27:26]),
        .funct      (instr[25:20]),
        .rd         (instr[15:12]),
        .flagw      (flagw),
        .pcs        (pcs),
        .regw       (regw),
        .memw       (memw),
        .memtoreg   (memtoreg),
        .alusrc     (alusrc),
        .immsrc     (immsrc),
        .regsrc     (regsrc),
        .alucontrol (alucontrol)
    );

    // Khối logic điều kiện và cờ trạng thái
    condlogic cl (
        .clk        (clk),
        .reset      (reset),
        .cond       (instr[31:28]),
        .aluflags   (aluflags),
        .flagw      (flagw),
        .pcs        (pcs),
        .regw       (regw),
        .memw       (memw),
        .pcsrc      (pcsrc),
        .regwrite   (regwrite),
        .memwrite   (memwrite)
    );

endmodule
