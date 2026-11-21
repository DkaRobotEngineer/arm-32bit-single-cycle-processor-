// ============================================================================
// Module: arm.sv
// Description: Lõi vi xử lý ARM 32-bit đơn chu kỳ (ARM Single-Cycle Core)
//              Kết hợp Control Unit (controller) và Datapath (datapath)
// ============================================================================
module arm (
    input  logic        clk, reset,
    output logic [31:0] pc,
    input  logic [31:0] instr,
    output logic        memwrite,
    output logic [31:0] aluresult, writedata,
    input  logic [31:0] readdata
);

    logic [1:0] regsrc, immsrc, alucontrol;
    logic       regwrite, alusrc, memtoreg, pcsrc;
    logic [3:0] aluflags;

    // Khối điều khiển trung tâm
    controller c (
        .clk        (clk),
        .reset      (reset),
        .instr      (instr[31:12]),
        .aluflags   (aluflags),
        .regsrc     (regsrc),
        .regwrite   (regwrite),
        .immsrc     (immsrc),
        .alusrc     (alusrc),
        .alucontrol (alucontrol),
        .memwrite   (memwrite),
        .memtoreg   (memtoreg),
        .pcsrc      (pcsrc)
    );

    // Khối đường truyền dữ liệu
    datapath dp (
        .clk        (clk),
        .reset      (reset),
        .regsrc     (regsrc),
        .regwrite   (regwrite),
        .immsrc     (immsrc),
        .alusrc     (alusrc),
        .alucontrol (alucontrol),
        .memtoreg   (memtoreg),
        .pcsrc      (pcsrc),
        .instr      (instr),
        .readdata   (readdata),
        .pc         (pc),
        .aluresult  (aluresult),
        .writedata  (writedata),
        .aluflags   (aluflags)
    );

endmodule
