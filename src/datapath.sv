// ============================================================================
// Module: datapath.sv
// Description: Đường truyền dữ liệu (Datapath) 32-bit cho Single-Cycle ARM
//              Đã tích hợp khối Barrel Shifter mở rộng ở ngõ ra RD2
// ============================================================================
module datapath (
    input  logic        clk, reset,
    input  logic [1:0]  regsrc,
    input  logic        regwrite,
    input  logic [1:0]  immsrc,
    input  logic        alusrc,
    input  logic [1:0]  alucontrol,
    input  logic        memtoreg,
    input  logic        pcsrc,
    input  logic [31:0] instr,
    input  logic [31:0] readdata,
    output logic [31:0] pc,
    output logic [31:0] aluresult,
    output logic [31:0] writedata,
    output logic [3:0]  aluflags
);

    logic [31:0] pcnext, pcplus4, pcplus8;
    logic [31:0] extimm, rd1, rd2, shifted_rd2, srcb, result;
    logic [3:0]  ra1, ra2;

    // --- 1. Khối cập nhật con trỏ lệnh PC ---
    // Chọn PC tiếp theo: PC+4 (tuần tự) hoặc Result (nhảy B hoặc ghi trực tiếp R15)
    mux2 #(32) pcmux (
        .d0 (pcplus4),
        .d1 (result),
        .s  (pcsrc),
        .y  (pcnext)
    );

    flopr #(32) pcreg (
        .clk   (clk),
        .reset (reset),
        .d     (pcnext),
        .q     (pc)
    );

    adder #(32) pcadd4 (
        .a (pc),
        .b (32'd4),
        .y (pcplus4)
    );

    adder #(32) pcadd8 (
        .a (pcplus4),
        .b (32'd4),
        .y (pcplus8)
    );

    // --- 2. Khối tệp thanh ghi (Register File) ---
    // Mux chọn địa chỉ đọc cổng 1: Rn (Instr[19:16]) hoặc R15 (4'b1111 cho lệnh B)
    mux2 #(4) ra1mux (
        .d0 (instr[19:16]),
        .d1 (4'b1111),
        .s  (regsrc[0]),
        .y  (ra1)
    );

    // Mux chọn địa chỉ đọc cổng 2: Rm (Instr[3:0]) hoặc Rd (Instr[15:12] cho lệnh STR)
    mux2 #(4) ra2mux (
        .d0 (instr[3:0]),
        .d1 (instr[15:12]),
        .s  (regsrc[1]),
        .y  (ra2)
    );

    regfile rf (
        .clk   (clk),
        .reset (reset),
        .we3   (regwrite),
        .ra1   (ra1),
        .ra2   (ra2),
        .wa3   (instr[15:12]),
        .wd3   (result),
        .r15   (pcplus8),
        .rd1   (rd1),
        .rd2   (rd2)
    );

    // Dữ liệu ghi ra bộ nhớ Data Memory là RD2 nguyên bản (trước khi dịch)
    assign writedata = rd2;

    // --- 3. Khối mở rộng Barrel Shifter ---
    // Dịch toán hạng RD2 theo số bit Instr[11:7] và kiểu dịch Instr[6:5]
    shifter sh (
        .a      (rd2),
        .shamt  (instr[11:7]),
        .shtype (instr[6:5]),
        .y      (shifted_rd2)
    );

    // --- 4. Khối mở rộng hằng số tức thời (Extend Unit) ---
    extend ext (
        .instr  (instr[23:0]),
        .immsrc (immsrc),
        .extimm (extimm)
    );

    // Mux chọn toán hạng B cho ALU: giá trị dịch (shifted_rd2) hoặc hằng số tức thời (extimm)
    mux2 #(32) srcbmux (
        .d0 (shifted_rd2),
        .d1 (extimm),
        .s  (alusrc),
        .y  (srcb)
    );

    // --- 5. Khối số học & logic (ALU) ---
    alu alu_inst (
        .a          (rd1),
        .b          (srcb),
        .alucontrol (alucontrol),
        .result     (aluresult),
        .flags      (aluflags)
    );

    // --- 6. Mux chọn kết quả ghi ngược về thanh ghi (Writeback) ---
    // Chọn giữa kết quả tính toán ALU và dữ liệu nạp từ bộ nhớ RAM
    mux2 #(32) resmux (
        .d0 (aluresult),
        .d1 (readdata),
        .s  (memtoreg),
        .y  (result)
    );

endmodule
