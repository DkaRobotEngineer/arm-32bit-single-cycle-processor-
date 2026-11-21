// ============================================================================
// Module: top.sv
// Description: Mạch mức đỉnh (Top-level System) kết nối lõi vi xử lý ARM
//              với Bộ nhớ lệnh (imem) và Bộ nhớ dữ liệu (dmem)
// ============================================================================
module top (
    input  logic        clk, reset,
    output logic [31:0] writedata, dataadr,
    output logic        memwrite
);

    logic [31:0] pc, instr, readdata;

    // Lõi vi xử lý ARM
    arm arm_core (
        .clk       (clk),
        .reset     (reset),
        .pc        (pc),
        .instr     (instr),
        .memwrite  (memwrite),
        .aluresult (dataadr),
        .writedata (writedata),
        .readdata  (readdata)
    );

    // Bộ nhớ lệnh ROM
    imem imem_inst (
        .a  (pc),
        .rd (instr)
    );

    // Bộ nhớ dữ liệu RAM
    dmem dmem_inst (
        .clk (clk),
        .we  (memwrite),
        .a   (dataadr),
        .wd  (writedata),
        .rd  (readdata)
    );

endmodule
