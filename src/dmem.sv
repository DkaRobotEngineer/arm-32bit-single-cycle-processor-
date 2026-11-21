// ============================================================================
// Module: dmem.sv
// Description: Bo nho du lieu (Data Memory RAM) 64 tu x 32-bit
//              Ghi dong bo theo canh xung nhip CLK, doc to hop (Single-Cycle)
// ============================================================================
module dmem (
    input  logic        clk, we,
    input  logic [31:0] a, wd,
    output logic [31:0] rd
);

    logic [31:0] RAM [63:0];

    initial begin
        for (int i = 0; i < 64; i++) begin
            RAM[i] = 32'd0;
        end
    end

    // Doc to hop (Word-aligned address a[7:2])
    assign rd = RAM[a[7:2]];

    // Ghi dong bo (Dung always de tuong thich voi khoi initial theo chuan SystemVerilog)
    always @(posedge clk) begin
        if (we) begin
            RAM[a[7:2]] <= wd;
        end
    end

endmodule
