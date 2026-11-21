# Assembler script to generate memfile.dat for ARM Single-Cycle Processor
# Instructions:
# 0x00: SUB R0, R0, R0             -> R0 = 0
# 0x04: ADD R2, R0, #5             -> R2 = 5
# 0x08: ADD R3, R0, #12            -> R3 = 12
# 0x0C: SUB R7, R3, #9             -> R7 = 12 - 9 = 3
# 0x10: ORR R4, R7, R2             -> R4 = 3 | 5 = 7
# 0x14: AND R5, R3, R4             -> R5 = 12 & 7 = 4
# 0x18: ADD R5, R5, R4             -> R5 = 4 + 7 = 11
# 0x1C: ADD R6, R0, R2, LSL #2     -> R6 = 0 + (5 << 2) = 20 (Test Shifter LSL)
# 0x20: ADD R6, R0, R3, LSR #1     -> R6 = 0 + (12 >> 1) = 6 (Test Shifter LSR)
# 0x24: SUBS R8, R5, R2            -> R8 = 11 - 5 = 6 (Z=0)
# 0x28: BEQ end_fail (target 0x48) -> not taken since Z=0
# 0x2C: SUBS R8, R8, #6            -> R8 = 6 - 6 = 0 (Z=1)
# 0x30: BEQ pass_lbl (target 0x38) -> taken since Z=1
# 0x34: B end_fail (target 0x48)   -> should be skipped
# 0x38 (pass_lbl):
#       STR R4, [R0, #84]          -> Store 7 into Mem[84]
# 0x3C: LDR R9, [R0, #84]          -> Load Mem[84] into R9 (R9 = 7)
# 0x40: STR R9, [R0, #88]          -> Store 7 into Mem[88]
# 0x44: B end_success (0x44)       -> Infinite loop
# 0x48 (end_fail):
#       ADD R1, R0, #99            -> R1 = 99
# 0x4C: STR R1, [R0, #84]          -> Store 99 into Mem[84] (Indicates failure)
# 0x50: B end_fail (0x50)          -> Infinite loop

def encode_dp_imm(cond, cmd, s, rn, rd, imm8):
    # Cond: 4, 00: 2, I=1: 1, cmd: 4, S: 1, Rn: 4, Rd: 4, rot=0: 4, imm8: 8
    val = (cond << 28) | (0 << 26) | (1 << 25) | (cmd << 21) | (s << 20) | (rn << 16) | (rd << 12) | imm8
    return val

def encode_dp_reg(cond, cmd, s, rn, rd, shamt5, shtype, rm):
    # Cond: 4, 00: 2, I=0: 1, cmd: 4, S: 1, Rn: 4, Rd: 4, shamt5: 5, shtype: 2, 0: 1, rm: 4
    val = (cond << 28) | (0 << 26) | (0 << 25) | (cmd << 21) | (s << 20) | (rn << 16) | (rd << 12) | (shamt5 << 7) | (shtype << 5) | rm
    return val

def encode_mem(cond, l, rn, rd, imm12):
    # Cond: 4, 01: 2, I=0: 1, P=1, U=1, B=0, W=0: 4, L: 1, Rn: 4, Rd: 4, imm12: 12
    # P=1, U=1, B=0, W=0 -> 1100 in bits 24..21 -> 0b1100 = 12
    val = (cond << 28) | (1 << 26) | (0 << 25) | (1 << 24) | (1 << 23) | (0 << 22) | (0 << 21) | (l << 20) | (rn << 16) | (rd << 12) | imm12
    return val

def encode_branch(cond, cur_pc, target_pc):
    # BTA = target_pc
    # offset = (target_pc - (cur_pc + 8)) >> 2
    offset = (target_pc - (cur_pc + 8)) >> 2
    offset24 = offset & 0x00FFFFFF
    val = (cond << 28) | (2 << 26) | (5 << 24) | offset24 # 5 << 24 is 1010 in bits 27..24 -> Op=10, 1L=10
    return val

COND_AL = 0xE # 1110
COND_EQ = 0x0 # 0000

CMD_AND = 0x0
CMD_SUB = 0x2
CMD_ADD = 0x4
CMD_ORR = 0xC

instructions = []

# 0x00: SUB R0, R0, R0
instructions.append((0x00, encode_dp_reg(COND_AL, CMD_SUB, 0, 0, 0, 0, 0, 0), "SUB R0, R0, R0"))
# 0x04: ADD R2, R0, #5
instructions.append((0x04, encode_dp_imm(COND_AL, CMD_ADD, 0, 0, 2, 5), "ADD R2, R0, #5"))
# 0x08: ADD R3, R0, #12
instructions.append((0x08, encode_dp_imm(COND_AL, CMD_ADD, 0, 0, 3, 12), "ADD R3, R0, #12"))
# 0x0C: SUB R7, R3, #9
instructions.append((0x0C, encode_dp_imm(COND_AL, CMD_SUB, 0, 3, 7, 9), "SUB R7, R3, #9"))
# 0x10: ORR R4, R7, R2
instructions.append((0x10, encode_dp_reg(COND_AL, CMD_ORR, 0, 7, 4, 0, 0, 2), "ORR R4, R7, R2"))
# 0x14: AND R5, R3, R4
instructions.append((0x14, encode_dp_reg(COND_AL, CMD_AND, 0, 3, 5, 0, 0, 4), "AND R5, R3, R4"))
# 0x18: ADD R5, R5, R4
instructions.append((0x18, encode_dp_reg(COND_AL, CMD_ADD, 0, 5, 5, 0, 0, 4), "ADD R5, R5, R4"))
# 0x1C: ADD R6, R0, R2, LSL #2
instructions.append((0x1C, encode_dp_reg(COND_AL, CMD_ADD, 0, 0, 6, 2, 0, 2), "ADD R6, R0, R2, LSL #2"))
# 0x20: ADD R6, R0, R3, LSR #1
instructions.append((0x20, encode_dp_reg(COND_AL, CMD_ADD, 0, 0, 6, 1, 1, 3), "ADD R6, R0, R3, LSR #1"))
# 0x24: SUBS R8, R5, R2
instructions.append((0x24, encode_dp_reg(COND_AL, CMD_SUB, 1, 5, 8, 0, 0, 2), "SUBS R8, R5, R2"))
# 0x28: BEQ end_fail (target 0x48)
instructions.append((0x28, encode_branch(COND_EQ, 0x28, 0x48), "BEQ end_fail"))
# 0x2C: SUBS R8, R8, #6
instructions.append((0x2C, encode_dp_imm(COND_AL, CMD_SUB, 1, 8, 8, 6), "SUBS R8, R8, #6"))
# 0x30: BEQ pass_lbl (target 0x38)
instructions.append((0x30, encode_branch(COND_EQ, 0x30, 0x38), "BEQ pass_lbl"))
# 0x34: B end_fail (target 0x48)
instructions.append((0x34, encode_branch(COND_AL, 0x34, 0x48), "B end_fail"))
# 0x38: STR R4, [R0, #84]
instructions.append((0x38, encode_mem(COND_AL, 0, 0, 4, 84), "STR R4, [R0, #84]"))
# 0x3C: LDR R9, [R0, #84]
instructions.append((0x3C, encode_mem(COND_AL, 1, 0, 9, 84), "LDR R9, [R0, #84]"))
# 0x40: STR R9, [R0, #88]
instructions.append((0x40, encode_mem(COND_AL, 0, 0, 9, 88), "STR R9, [R0, #88]"))
# 0x44: B 0x44 (infinite loop)
instructions.append((0x44, encode_branch(COND_AL, 0x44, 0x44), "B 0x44 (loop)"))
# 0x48: ADD R1, R0, #99
instructions.append((0x48, encode_dp_imm(COND_AL, CMD_ADD, 0, 0, 1, 99), "ADD R1, R0, #99"))
# 0x4C: STR R1, [R0, #84]
instructions.append((0x4C, encode_mem(COND_AL, 0, 0, 1, 84), "STR R1, [R0, #84]"))
# 0x50: B 0x50
instructions.append((0x50, encode_branch(COND_AL, 0x50, 0x50), "B 0x50 (loop)"))

lines = []
for pc, code, asm in instructions:
    hex_str = f"{code:08x}"
    lines.append(f"{hex_str} // 0x{pc:02x}: {asm}")

output_path = r"C:\Users\nguye\.gemini\antigravity\scratch\arm_single_cycle\sim\memfile.dat"
with open(output_path, "w") as f:
    for line in lines:
        f.write(line + "\n")

# Also copy to root and quartus dirs for ModelSim / Quartus easy loading
with open(r"C:\Users\nguye\.gemini\antigravity\scratch\arm_single_cycle\memfile.dat", "w") as f:
    for line in lines:
        f.write(line + "\n")

print(f"Generated {len(lines)} instructions into {output_path}")
