// ============================================================================
// Module: imem.sv
// Description: Bo nho lenh (Instruction Memory ROM) 64 tu x 32-bit
//              Cung cap san chuong trinh test ARM va ho tro nap them tu memfile.dat
// ============================================================================
module imem (
    input  logic [31:0] a,
    output logic [31:0] rd
);

    logic [31:0] RAM [63:0];

    initial begin
        // Khoi tao mac dinh toan bo bo nho bang 0
        for (int i = 0; i < 64; i++) begin
            RAM[i] = 32'd0;
        end

        // Nap san chuong trinh hop ngu kiem thu phong truong hop khong tim thay file ngoai
        RAM[0]  = 32'he0400000; // 0x00: SUB R0, R0, R0
        RAM[1]  = 32'he2802005; // 0x04: ADD R2, R0, #5
        RAM[2]  = 32'he280300c; // 0x08: ADD R3, R0, #12
        RAM[3]  = 32'he2437009; // 0x0C: SUB R7, R3, #9
        RAM[4]  = 32'he1874002; // 0x10: ORR R4, R7, R2
        RAM[5]  = 32'he0035004; // 0x14: AND R5, R3, R4
        RAM[6]  = 32'he0855004; // 0x18: ADD R5, R5, R4
        RAM[7]  = 32'he0806102; // 0x1C: ADD R6, R0, R2, LSL #2
        RAM[8]  = 32'he08060a3; // 0x20: ADD R6, R0, R3, LSR #1
        RAM[9]  = 32'he0558002; // 0x24: SUBS R8, R5, R2
        RAM[10] = 32'h0a000006; // 0x28: BEQ end_fail (0x48)
        RAM[11] = 32'he2588006; // 0x2C: SUBS R8, R8, #6
        RAM[12] = 32'h0a000000; // 0x30: BEQ pass_lbl (0x38)
        RAM[13] = 32'hea000003; // 0x34: B end_fail (0x48)
        RAM[14] = 32'he5804054; // 0x38: STR R4, [R0, #84]
        RAM[15] = 32'he5909054; // 0x3C: LDR R9, [R0, #84]
        RAM[16] = 32'he5809058; // 0x40: STR R9, [R0, #88]
        RAM[17] = 32'heafffffe; // 0x44: B 0x44 (loop)
        RAM[18] = 32'he2801063; // 0x48: ADD R1, R0, #99
        RAM[19] = 32'he5801054; // 0x4C: STR R1, [R0, #84]
        RAM[20] = 32'heafffffe; // 0x50: B 0x50 (loop)

        // Nap ghi de neu co file memfile.dat tai thu muc chay mo phong
        $readmemh("memfile.dat", RAM);
    end

    // Doc to hop (Word-aligned address a[7:2])
    assign rd = RAM[a[7:2]];

endmodule
