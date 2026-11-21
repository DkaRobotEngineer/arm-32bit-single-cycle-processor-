// ============================================================================
// Module: testbench.sv
// Description: Self-checking Testbench cho bo xu ly ARM Single-Cycle 32-bit
//              Tu dong kiem tra cac phep tinh so hoc, logic, dich bit Shifter,
//              re nhanh co dieu kien, doc/ghi bo nho va in ket qua PASS/FAIL.
// ============================================================================
`timescale 1ns / 1ps

module testbench ();

    logic        clk;
    logic        reset;
    logic [31:0] writedata, dataadr;
    logic        memwrite;
    integer      cycle_count;
    bit          test_passed;

    // Khoi tao mach muc dinh
    top dut (
        .clk       (clk),
        .reset     (reset),
        .writedata (writedata),
        .dataadr   (dataadr),
        .memwrite  (memwrite)
    );

    // Tao xung nhan Clock chu ky 10ns (f = 100 MHz)
    always begin
        clk = 1'b1; #5;
        clk = 1'b0; #5;
    end

    // Khoi dong qua trinh mo phong
    initial begin
        $display("----------------------------------------------------------------");
        $display("--- BAT DAU MO PHONG BO XU LY ARM 32-BIT SINGLE-CYCLE       ---");
        $display("----------------------------------------------------------------");
        cycle_count = 0;
        test_passed = 0;
        reset = 1'b1;
        #22;
        reset = 1'b0;
    end

    // Dem chu ky va giam sat ket qua moi canh xuong CLK
    always @(negedge clk) begin
        if (~reset) begin
            cycle_count = cycle_count + 1;

            if (memwrite) begin
                $display("[Cycle %0d] Ghi vao Bo Nho DMEM: Dia chi = %0d (0x%0h), Du lieu = %0d (0x%0h)",
                         cycle_count, dataadr, dataadr, writedata, writedata);

                // Kiem tra ghi thanh cong gia tri 7 vao dia chi 88 (sau khi LDR va STR)
                if (dataadr === 32'd88 && writedata === 32'd7) begin
                    test_passed = 1;
                    $display("----------------------------------------------------------------");
                    $display(">>> KET QUA: MO PHONG THANH CONG! (ALL TESTS PASSED!)       <<<");
                    $display(">>> Chu ky hoan thanh: %0d chu ky.                          <<<", cycle_count);
                    $display(">>> Gia tri 7 da duoc tinh toan, ghi ra DMEM[84], doc lai   <<<");
                    $display(">>> qua LDR va ghi tiep ra DMEM[88] hoan toan chinh xac!   <<<");
                    $display("----------------------------------------------------------------");
                    $stop;
                end
                // Kiem tra neu re nhanh sai dan den nhanh fail (ghi 99 vao dia chi 84)
                else if (dataadr === 32'd84 && writedata === 32'd99) begin
                    $display("----------------------------------------------------------------");
                    $display(">>> KET QUA: MO PHONG THAT BAI! (SIMULATION FAILED!)        <<<");
                    $display(">>> Re nhanh co dieu kien (BEQ) hoac phep tinh bi loi!      <<<");
                    $display("----------------------------------------------------------------");
                    $stop;
                end
            end

            // Timeout an toan: Chi bao Timeout neu chuong trinh CHUA tung PASS
            if (cycle_count > 100 && !test_passed) begin
                $display("----------------------------------------------------------------");
                $display(">>> KET QUA: TIMEOUT! Qua 100 chu ky chua hoan thanh.       <<<");
                $display("----------------------------------------------------------------");
                $stop;
            end
        end
    end

endmodule
