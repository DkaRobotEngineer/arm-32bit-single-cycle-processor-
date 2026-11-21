// ============================================================================
// Module: condlogic.sv
// Description: Khối logic điều kiện (Conditional Logic)
//              Lưu trữ cờ trạng thái NZCV trong thanh ghi cờ và chặn (gate)
//              các tín hiệu ghi nếu lệnh không thỏa mãn điều kiện thực thi.
// ============================================================================
module condlogic (
    input  logic       clk, reset,
    input  logic [3:0] cond,
    input  logic [3:0] aluflags,
    input  logic [1:0] flagw,
    input  logic       pcs, regw, memw,
    output logic       pcsrc, regwrite, memwrite
);

    logic [1:0] flagwrite;
    logic [3:0] flags;
    logic       condex;

    // Kiểm tra điều kiện thực thi
    condcheck cc (
        .cond   (cond),
        .flags  (flags),
        .condex (condex)
    );

    // Cờ trạng thái chỉ được cập nhật khi lệnh thỏa điều kiện thực thi
    assign flagwrite = flagw & {2{condex}};

    // Thanh ghi lưu cờ N, Z (flags[3:2]) - cập nhật bởi cả ADD, SUB, AND, ORR
    flopenr #(2) flagreg1 (
        .clk   (clk),
        .reset (reset),
        .en    (flagwrite[1]),
        .d     (aluflags[3:2]),
        .q     (flags[3:2])
    );

    // Thanh ghi lưu cờ C, V (flags[1:0]) - chỉ cập nhật bởi ADD, SUB
    flopenr #(2) flagreg0 (
        .clk   (clk),
        .reset (reset),
        .en    (flagwrite[0]),
        .d     (aluflags[1:0]),
        .q     (flags[1:0])
    );

    // Chặn các tác động ghi trạng thái hệ thống nếu không thỏa điều kiện
    assign pcsrc    = pcs & condex;
    assign regwrite = regw & condex;
    assign memwrite = memw & condex;

endmodule
