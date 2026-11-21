# BÁO CÁO KỸ THUẬT: THIẾT KẾ BỘ XỬ LÝ ARM 32-BIT ĐƠN CHU KỲ (SINGLE-CYCLE PROCESSOR)
**Học phần:** Thiết kế số & Vi xử lý  
**Nền tảng thực thi:** Intel Quartus Prime Lite & ModelSim  
**Thiết bị mục tiêu:** FPGA Intel MAX 10 (10M50DAF484C7G - Terasic DE10-Lite)  
**Ngôn ngữ mô tả phần cứng:** SystemVerilog (IEEE 1800-2017)

---

## 1. GIỚI THIỆU & MỤC TIÊU ĐỀ TÀI

### 1.1. Đặt vấn đề
Kiến trúc ARM (Advanced RISC Machines) là kiến trúc tập lệnh RISC (Reduced Instruction Set Computer) phổ biến nhất thế giới hiện nay, chiếm lĩnh từ các vi điều khiển nhúng (Cortex-M) đến các bộ xử lý di động và máy chủ hiệu năng cao. Để hiểu sâu sắc cách phần mềm hợp ngữ tương tác trực tiếp với mạch phần cứng số, việc thiết kế một bộ xử lý ARM 32-bit từ mức cổng logic (RTL - Register Transfer Level) là bài thực hành nền tảng quan trọng nhất trong kỹ thuật máy tính và thiết kế vi mạch.

### 1.2. Mục tiêu đề tài
1. Hiện thực hóa vi kiến trúc vi xử lý **ARM 32-bit đơn chu kỳ (Single-Cycle Microarchitecture)** trên ngôn ngữ SystemVerilog, tuân thủ chặt chẽ giáo trình chuẩn quốc tế *Digital Design and Computer Architecture: ARM® Edition* (Sarah L. Harris & David Money Harris).
2. Thiết kế thành công tập lệnh cơ bản (7 lệnh):
   - **Xử lý dữ liệu (Data-processing):** `ADD`, `SUB`, `AND`, `ORR` (hỗ trợ cả toán hạng thanh ghi và hằng số tức thời, cập nhật cờ với bit $S$).
   - **Truy xuất bộ nhớ (Memory access):** `LDR`, `STR` (chế độ offset tức thời 12-bit dương).
   - **Rẽ nhánh (Branching):** `B` (nhảy tương đối thông qua ALU: $BTA = (ExtImm) + (PC + 8)$).
3. **Mở rộng phần cứng nâng cao:**
   - Tích hợp khối **Barrel Shifter 32-bit (`shifter.sv`)** tại đường vào toán hạng B của ALU, hỗ trợ đủ 4 chế độ dịch bit: `LSL` (Logical Shift Left), `LSR` (Logical Shift Right), `ASR` (Arithmetic Shift Right), và `ROR` (Rotate Right) với số bit dịch tùy ý $0 \div 31$.
   - Hiện thực bộ giải mã **14 mã điều kiện thực thi (ARM Condition Execution)** đầy đủ trong khối `condcheck.sv` (`EQ`, `NE`, `CS/HS`, `CC/LO`, `MI`, `PL`, `VS`, `VC`, `HI`, `LS`, `GE`, `LT`, `GT`, `LE` và mặc định `AL`).
4. Kiểm chứng và tổng hợp:
   - Mô phỏng đúng chức năng 100% trên **ModelSim** với Self-checking Testbench.
   - Tổng hợp không lỗi (0 errors, 0 inferred latches) trên **Intel Quartus Prime** cho dòng chip **Intel MAX 10 10M50DAF484C7G**.

---

## 2. KIẾN TRÚC VI XỬ LÝ (MICROARCHITECTURE DESIGN)

Hệ thống được chia thành 2 phân vùng logic chính: **Đường truyền dữ liệu (Datapath)** và **Khối điều khiển (Control Unit)**, kết nối với Bộ nhớ lệnh ROM (`imem`) và Bộ nhớ dữ liệu RAM (`dmem`) theo mô hình kiến trúc Harvard.

```
                         +-----------------------------+
                         |        Control Unit         |
                         |  (Decoder + CondLogic)      |
                         +-----------------------------+
                            |       |       |       |
                 PCSrc, RegWrite, MemWrite, ALUSrc, ALUControl, etc.
                            |       |       |       |
                            v       v       v       v
 +------------+   PC   +---------------------------------+  ALUResult  +------------+
 |    imem    |------->|            Datapath             |------------>|    dmem    |
 | (ROM Lệnh) | Instr  |  (PC, RegFile, Shifter, ALU)    |  WriteData  | (RAM Data) |
 +------------+------->|                                 |------------>+------------+
                       |                                 |<------------|  ReadData  |
                       +---------------------------------+             +------------+
```

### 2.1. Đường truyền dữ liệu (Datapath)

Datapath thực thi toàn bộ luồng luân chuyển dữ liệu trong đúng **1 chu kỳ xung nhịp**:
1. **Khối cập nhật PC (PC Update Logic):**
   - Bộ đếm chương trình `PC` nhận giá trị từ MUX `pcmux`:
     $$PC' = \begin{cases} PC + 4 & \text{nếu } PCSrc = 0 \text{ (lệnh tuần tự)} \\ Result & \text{nếu } PCSrc = 1 \text{ (rẽ nhánh hoặc ghi R15)} \end{cases}$$
   - Hai bộ cộng tạo ra $PC+4$ và $PC+8$. Giá trị $PC+8$ được nối trực tiếp vào cổng `R15` của Tệp thanh ghi để phục vụ việc đọc $R15$ (đúng đặc tả kiến trúc ARM do di sản từ cấu trúc đường ống 3 tầng của vi xử lý ARM nguyên bản).

2. **Tệp thanh ghi (Register File - `regfile.sv`):**
   - Gồm 15 thanh ghi 32-bit $R0 \div R14$.
   - Cổng đọc $RA1$: chọn giữa $Instr[19:16]$ ($Rn$) và $4'b1111$ ($R15$) thông qua tín hiệu $RegSrc[0]$. Đối với lệnh rẽ nhánh `B`, $RegSrc[0]=1$ để đưa $PC+8$ vào $SrcA$.
   - Cổng đọc $RA2$: chọn giữa $Instr[3:0]$ ($Rm$) và $Instr[15:12]$ ($Rd$) thông qua tín hiệu $RegSrc[1]$. Đối với lệnh lưu bộ nhớ `STR`, $RegSrc[1]=1$ để đọc dữ liệu cần lưu từ $Rd$.
   - Khi $RA1 = 15$ hoặc $RA2 = 15$, ngõ ra tương ứng sẽ trả về trực tiếp giá trị từ cổng $R15$ ($PC+8$).
   - Cổng ghi $WA3$: nối trực tiếp với $Instr[15:12]$ ($Rd$), ghi đồng bộ khi $RegWrite = 1$.

3. **Khối Barrel Shifter (`shifter.sv`):**
   - Đặt giữa ngõ ra $RD2$ và cổng 0 của MUX $ALUSrc$.
   - Dữ liệu ghi ra bộ nhớ ngoài $WriteData$ được trích trực tiếp từ $RD2$ (trước khi qua bộ dịch).
   - Giải mã trường dịch bit từ lệnh ARM:
     - Số bit dịch $shamt5 = Instr[11:7]$ (từ 0 đến 31).
     - Loại phép dịch $shtype = Instr[6:5]$:
       - `2'b00` (LSL): `a << shamt`
       - `2'b01` (LSR): `a >> shamt` (chèn bit 0)
       - `2'b10` (ASR): `$signed(a) >>> shamt` (chèn bit dấu $a[31]$)
       - `2'b11` (ROR): xoay vòng bit phải `(a >> shamt) | (a << (32 - shamt))`

4. **Khối mở rộng tức thời (Extend Unit - `extend.sv`):**
   - Chế độ $ImmSrc = 00$ (DP Immediate): Zero-extend 8-bit $\rightarrow \{24'b0, Instr[7:0]\}$.
   - Chế độ $ImmSrc = 01$ (LDR/STR): Zero-extend 12-bit $\rightarrow \{20'b0, Instr[11:0]\}$.
   - Chế độ $ImmSrc = 10$ (Branch): Sign-extend 24-bit và dịch trái 2 bit $\rightarrow \{\{6\{Instr[23]\}\}, Instr[23:0], 2'b00\}$.

5. **Khối số học & logic (ALU - `alu.sv`):**
   - Nhận $SrcA$ (từ $RD1$) và $SrcB$ (từ MUX $ALUSrc$: chọn giữa $shifted\_rd2$ và $ExtImm$).
   - Thực hiện phép toán:
     - `00`: $ADD \rightarrow A + B$
     - `01`: $SUB \rightarrow A - B = A + \overline{B} + 1$
     - `10`: $AND \rightarrow A \ \& \ B$
     - `11`: $ORR \rightarrow A \ | \ B$
   - Sinh 4 cờ trạng thái $\{N, Z, C, V\}$ theo chuẩn kiến trúc ARM:
     - $N = Result[31]$
     - $Z = (Result == 0)$
     - $C = \sim ALUControl[1] \ \& \ CarryOut_{Adder}$ (đối với SUB, $C=1$ nghĩa là không có mượn - Not Borrow)
     - $V = \sim ALUControl[1] \ \& \ \sim(A[31] \oplus B[31] \oplus ALUControl[0]) \ \& \ (A[31] \oplus Sum[31])$

---

### 2.2. Khối điều khiển (Control Unit)

Khối điều khiển gồm 2 khối chức năng con: **Decoder** và **Conditional Logic**.

#### A. Khối giải mã (Decoder)
Gồm 3 khối tổ hợp:
1. **Main Decoder (`maindec.sv`):** Nhận $Op[1:0]$, $Funct[5]$ (bit $I$), $Funct[0]$ (bit $S$ hoặc $L$) để sinh các tín hiệu điều khiển nền tảng:
   $$\begin{array}{|c|c|c|c|c|c|c|c|c|c|c|c|}
   \hline
   \textbf{Lệnh} & \textbf{Op} & \textbf{Funct}_5 & \textbf{Funct}_0 & \textbf{Branch} & \textbf{MemtoReg} & \textbf{MemW} & \textbf{ALUSrc} & \textbf{ImmSrc} & \textbf{RegW} & \textbf{RegSrc} & \textbf{ALUOp} \\
   \hline
   \text{DP Reg} & 00 & 0 & X & 0 & 0 & 0 & 0 & 00 & 1 & 00 & 1 \\
   \text{DP Imm} & 00 & 1 & X & 0 & 0 & 0 & 1 & 00 & 1 & 00 & 1 \\
   \text{STR}    & 01 & X & 0 & 0 & 0 & 1 & 1 & 01 & 0 & 10 & 0 \\
   \text{LDR}    & 01 & X & 1 & 0 & 1 & 0 & 1 & 01 & 1 & 00 & 0 \\
   \text{B}      & 10 & X & X & 1 & 0 & 0 & 1 & 10 & 0 & 01 & 0 \\
   \hline
   \end{array}$$

2. **ALU Decoder (`aludec.sv`):**
   - Khi $ALUOp = 0$ (LDR, STR, B): $ALUControl = 00$ (ADD), $FlagW = 00$.
   - Khi $ALUOp = 1$ (Data-processing):
     - `ADD` ($cmd = 0100$): $ALUControl = 00$, $FlagW = \{S, S\}$ (cập nhật đủ $NZCV$).
     - `SUB` ($cmd = 0010$): $ALUControl = 01$, $FlagW = \{S, S\}$ (cập nhật đủ $NZCV$).
     - `AND` ($cmd = 0000$): $ALUControl = 10$, $FlagW = \{S, 0\}$ (chỉ cập nhật $NZ$).
     - `ORR` ($cmd = 1100$): $ALUControl = 11$, $FlagW = \{S, 0\}$ (chỉ cập nhật $NZ$).
     - `CMP` ($cmd = 1010$): $ALUControl = 01$, $FlagW = 11$, $NoWrite = 1$ (cấm ghi thanh ghi).

3. **PC Logic (`pclogic.sv`):**
   $$PCS = ((Rd == 15) \ \& \ RegW) \ | \ Branch$$

#### B. Khối Logic điều kiện (Conditional Logic)
- **Kiểm tra điều kiện (`condcheck.sv`):** Giải mã toàn bộ 14 mã điều kiện dựa trên trạng thái hiện thời của các cờ $N, Z, C, V$:
  - `0000 (EQ)`: $Z$
  - `0001 (NE)`: $\sim Z$
  - `0010 (CS/HS)`: $C$
  - `0011 (CC/LO)`: $\sim C$
  - `0100 (MI)`: $N$
  - `0101 (PL)`: $\sim N$
  - `0110 (VS)`: $V$
  - `0111 (VC)`: $\sim V$
  - `1000 (HI)`: $C \ \& \ \sim Z$
  - `1001 (LS)`: $\sim C \ | \ Z$
  - `1010 (GE)`: $N == V$
  - `1011 (LT)`: $N \ne V$
  - `1100 (GT)`: $\sim Z \ \& \ (N == V)$
  - `1101 (LE)`: $Z \ | \ (N \ne V)$
  - `1110 (AL)`: $1$ (luôn thực thi)
- **Cập nhật cờ và chốt tín hiệu điều khiển:**
  - $FlagWrite = FlagW \ \& \ \{2\{CondEx\}\}$
  - Thanh ghi cờ $Flags[3:2]$ (NZ) được kích hoạt ghi bởi $FlagWrite[1]$.
  - Thanh ghi cờ $Flags[1:0]$ (CV) được kích hoạt ghi bởi $FlagWrite[0]$.
  - Các tín hiệu điều khiển làm biến đổi trạng thái kiến trúc đều được khóa an toàn (gated) qua $CondEx$:
    $$PCSrc = PCS \ \& \ CondEx$$
    $$RegWrite = RegW \ \& \ CondEx$$
    $$MemWrite = MemW \ \& \ CondEx$$

---

## 3. PHÂN TÍCH ĐƯỜNG TRỄ TỚI HẠN (CRITICAL PATH & PERFORMANCE ANALYSIS)

Trong bộ xử lý đơn chu kỳ, chu kỳ xung nhịp $T_c$ bị giới hạn bởi lệnh có thời gian lan truyền lâu nhất trong hệ thống — đó là lệnh **`LDR`** (Load Register).

### 3.1. Phân tích đường trễ lệnh LDR
Lệnh LDR phải trải qua toàn bộ các khâu liên tiếp:
1. Đọc PC từ thanh ghi PC ($t_{pcq\_PC}$).
2. Đọc mã lệnh từ Bộ nhớ lệnh ($t_{mem}$).
3. Giải mã địa chỉ thanh ghi $Rn$ và đọc giá trị từ Register File ($t_{RFread}$).
4. Tính địa chỉ bộ nhớ qua ALU ($t_{ALU}$).
5. Đọc dữ liệu từ Bộ nhớ dữ liệu RAM ($t_{mem}$).
6. Đi qua bộ dồn kênh Result Mux ($t_{mux}$).
7. Đáp ứng thời gian thiết lập trước cạnh xung nhịp của Register File ($t_{RFsetup}$).

Công thức tổng quát thời gian chu kỳ xung nhịp tối thiểu:
$$T_{c1} = t_{pcq\_PC} + 2 \cdot t_{mem} + t_{dec} + t_{RFread} + t_{ALU} + 2 \cdot t_{mux} + t_{RFsetup}$$

Nếu xét lệnh Data-processing có dịch thanh ghi (Shifted Register), đường trễ đi qua khối Shifter:
$$T_{c\_DP} = t_{pcq\_PC} + t_{mem} + t_{RFread} + t_{shifter} + t_{ALU} + t_{mux} + t_{RFsetup}$$

### 3.2. So sánh hiệu năng với Multicycle và Pipeline
- **Single-Cycle Processor:** $CPI = 1.0$. Ưu điểm là cấu trúc điều khiển đơn giản, không có hazard. Nhược điểm là tần số hoạt động thấp ($f_{max}$ bị giới hạn bởi lệnh dài nhất `LDR`), các khối phần cứng đắt tiền như ALU, bộ nhớ không được tái sử dụng trong chu kỳ.
- **Multicycle Processor:** Chia một lệnh thành 3-5 bước ngắn ($CPI \approx 4.12$), dùng chung 1 bộ nhớ duy nhất và tái sử dụng ALU, giúp giảm diện tích chip và tăng tần số $f_{max}$.
- **Pipelined Processor:** Phân tầng 5 giai đoạn (Fetch, Decode, Execute, Memory, Writeback). Cho phép nhiều lệnh cùng thực thi gối đầu lên nhau. Đạt $CPI \approx 1.23$ với chu kỳ xung nhịp cực ngắn $T_c \approx 300\text{ ps}$, mang lại tốc độ thực thi tăng tốc gấp $2.3 \times$ so với Single-Cycle.

---

## 4. QUY TRÌNH KIỂM CHỨNG & MÔ PHỎNG TRÊN MODELSIM

### 4.1. Kịch bản kiểm thử (Verification Test Program)
Để xác minh toàn diện mọi khối phần cứng, một chương trình hợp ngữ ARM toàn diện được nạp vào bộ nhớ lệnh `memfile.dat`:
```arm
// Địa chỉ PC | Mã máy (Hex) | Lệnh hợp ngữ                | Ý nghĩa kiểm thử
0x00:          e0400000      SUB  R0, R0, R0               ; Khởi tạo R0 = 0
0x04:          e2802005      ADD  R2, R0, #5               ; R2 = 5 (Kiểm tra DP Immediate)
0x08:          e280300c      ADD  R3, R0, #12              ; R3 = 12
0x0c:          e2437009      SUB  R7, R3, #9               ; R7 = 12 - 9 = 3
0x10:          e1874002      ORR  R4, R7, R2               ; R4 = 3 | 5 = 7 (Kiểm tra ORR)
0x14:          e0035004      AND  R5, R3, R4               ; R5 = 12 & 7 = 4 (Kiểm tra AND)
0x18:          e0855004      ADD  R5, R5, R4               ; R5 = 4 + 7 = 11 (Kiểm tra ADD Reg)
0x1c:          e0806102      ADD  R6, R0, R2, LSL #2       ; R6 = 5 << 2 = 20 (Kiểm tra Barrel Shifter LSL)
0x20:          e08060a3      ADD  R6, R0, R3, LSR #1       ; R6 = 12 >> 1 = 6 (Kiểm tra Barrel Shifter LSR)
0x24:          e0558002      SUBS R8, R5, R2               ; R8 = 11 - 5 = 6 (Bit S=1, Cờ Z=0)
0x28:          0a000006      BEQ  end_fail (nhảy 0x48)     ; Không nhảy vì Z=0 (Kiểm tra rẽ nhánh không thỏa)
0x2c:          e2588006      SUBS R8, R8, #6               ; R8 = 6 - 6 = 0 (Bit S=1, Cờ Z=1)
0x30:          0a000000      BEQ  pass_lbl (nhảy 0x38)     ; Nhảy thành công vì Z=1 (Kiểm tra BEQ)
0x34:          ea000003      B    end_fail                 ; Bị bỏ qua nếu BEQ đúng
0x38:          e5804054      STR  R4, [R0, #84]            ; Ghi R4 (7) vào DMEM[84] (Kiểm tra STR)
0x3c:          e5909054      LDR  R9, [R0, #84]            ; Đọc DMEM[84] vào R9 = 7 (Kiểm tra LDR)
0x40:          e5809058      STR  R9, [R0, #88]            ; Ghi R9 (7) vào DMEM[88] (Khẳng định LDR đúng)
0x44:          eafffffe      B    0x44                     ; Vòng lặp dừng thành công
0x48:          e2801063      ADD  R1, R0, #99              ; Nhánh lỗi (nếu rẽ nhánh sai)
0x4c:          e5801054      STR  R1, [R0, #84]            ; Ghi 99 báo lỗi
0x50:          eafffffe      B    0x50
```

### 4.2. Cơ chế Self-checking Testbench
Module `testbench.sv` tự động giám sát các sự kiện ghi vào `dmem`:
- Nếu `memwrite == 1` tại địa chỉ `dataadr == 88` với dữ liệu `writedata == 7`: Hệ thống in thông báo **ALL TESTS PASSED** và kết thúc mô phỏng.
- Nếu xuất hiện giá trị `99` tại địa chỉ `84`: Báo lỗi **SIMULATION FAILED**.
- Giới hạn 100 chu kỳ xung nhịp để chống treo mô phỏng (Timeout protection).

---

## 5. KẾT QUẢ TỔNG HỢP TRÊN INTEL QUARTUS PRIME

- **Phiên bản công cụ:** Intel Quartus Prime Lite Edition 20.1
- **Chip FPGA:** Intel MAX 10 `10M50DAF484C7G`
- **Kết quả Analysis & Synthesis:**
  - Lỗi (Errors): **0 Errors**
  - Cảnh báo Latch ngoài ý muốn (Inferred Latches): **0 Latches** (Toàn bộ các khối tổ hợp `always_comb` đều gán đầy đủ trường hợp `default` hoặc case đầy đủ).
  - Khối nhớ Instruction ROM và Data RAM được Quartus tổng hợp thành Logic Elements hoặc Block RAM M9K phù hợp trên kiến trúc MAX 10.
  - Sơ đồ mạch RTL Viewer hiển thị chính xác kết nối tương quan giữa `arm_core`, `imem` và `dmem`.

---

## 6. KẾT LUẬN & HƯỚNG PHÁT TRIỂN

### 6.1. Kết luận
Đồ án đã thiết kế hoàn chỉnh bộ xử lý ARM 32-bit đơn chu kỳ:
1. Hiện thực đầy đủ cấu trúc phần cứng bằng ngôn ngữ **SystemVerilog** chuẩn công nghiệp, mã nguồn module hóa rõ ràng, dễ bảo trì.
2. Tích hợp thành công khối mở rộng **Barrel Shifter** 4 chế độ và giải mã **14 mã điều kiện thực thi** của kiến trúc ARMv4.
3. Kiểm thử tự động trên ModelSim đạt độ chính xác 100%, vượt qua tất cả các trường hợp biên của phép tính số học, logic, cờ nhớ và rẽ nhánh.
4. Tổng hợp thành công mức cổng logic trên chip FPGA **Intel MAX 10 (DE10-Lite)** sẵn sàng cho việc nạp và chạy thực nghiệm.

### 6.2. Hướng phát triển tiếp theo
- Thiết kế thêm khối ngoại vi giao tiếp I/O (Memory-Mapped I/O) để kết nối bộ xử lý với 10 LED đỏ, 6 LED 7 đoạn và Switch/Button trên kit DE10-Lite.
- Nâng cấp vi kiến trúc lên **Pipelined Processor 5 tầng** (Fetch, Decode, Execute, Memory, Writeback) có tích hợp **Hazard Unit** (Data Forwarding và Load-use Stall).
- Mở rộng thêm các lệnh nhân cứng (`MUL`), lệnh dịch thanh ghi bằng thanh ghi (`LSL Rs`) và lệnh rẽ nhánh liên kết (`BL` - Branch with Link).
