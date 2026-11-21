// ============================================================================
// Module: regfile.sv
// Description: Tep thanh ghi ARM (ARM Register File) gom 15 thanh ghi R0-R14
//              Thanh ghi R15 (PC) la thanh ghi dac biet, khi doc tra ve PC+8
// ============================================================================
module regfile (
    input  logic        clk,
    input  logic        reset,
    input  logic        we3,
    input  logic [3:0]  ra1, ra2, wa3,
    input  logic [31:0] wd3, r15,
    output logic [31:0] rd1, rd2
);

    logic [31:0] rf [14:0];

    // Ghi dong bo theo suon duong xung nhip CLK hoac Reset ve 0
    always_ff @(posedge clk, posedge reset) begin
        if (reset) begin
            for (int i = 0; i < 15; i++) begin
                rf[i] <= 32'd0;
            end
        end else if (we3) begin
            // Chi ghi vao R0-R14; viec ghi R15 do PC logic xu ly
            if (wa3 != 4'b1111) begin
                rf[wa3] <= wd3;
            end
        end
    end

    // Doc to hop (Asynchronous read): Neu doc R15 tra ve PC+8
    assign rd1 = (ra1 == 4'b1111) ? r15 : rf[ra1];
    assign rd2 = (ra2 == 4'b1111) ? r15 : rf[ra2];

endmodule
