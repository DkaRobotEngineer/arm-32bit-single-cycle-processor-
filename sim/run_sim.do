# ==============================================================================
# ModelSim DO script for ARM 32-bit Single-Cycle Processor Simulation
# ==============================================================================
cd D:/arm_single_cycle/sim
vlib work
vmap work work

# Compile all RTL modules in src
vlog -sv ../src/adder.sv
vlog -sv ../src/mux2.sv
vlog -sv ../src/flopr.sv
vlog -sv ../src/flopenr.sv
vlog -sv ../src/shifter.sv
vlog -sv ../src/alu.sv
vlog -sv ../src/regfile.sv
vlog -sv ../src/extend.sv
vlog -sv ../src/condcheck.sv
vlog -sv ../src/condlogic.sv
vlog -sv ../src/pclogic.sv
vlog -sv ../src/aludec.sv
vlog -sv ../src/maindec.sv
vlog -sv ../src/decode.sv
vlog -sv ../src/controller.sv
vlog -sv ../src/datapath.sv
vlog -sv ../src/arm.sv
vlog -sv ../src/imem.sv
vlog -sv ../src/dmem.sv
vlog -sv ../src/top.sv
vlog -sv testbench.sv

# Launch simulation with full visibility
vsim -voptargs="+acc" work.testbench

# Configure wave window
add wave -noupdate -divider {System Signals}
add wave -noupdate -format Logic /testbench/clk
add wave -noupdate -format Logic /testbench/reset
add wave -noupdate -divider {Instruction Fetch & PC}
add wave -noupdate -radix hexadecimal /testbench/dut/arm_core/pc
add wave -noupdate -radix hexadecimal /testbench/dut/arm_core/instr
add wave -noupdate -divider {Control Signals}
add wave -noupdate -format Logic /testbench/dut/arm_core/c/regwrite
add wave -noupdate -format Logic /testbench/dut/arm_core/c/memwrite
add wave -noupdate -format Logic /testbench/dut/arm_core/c/pcsrc
add wave -noupdate -radix binary /testbench/dut/arm_core/c/alucontrol
add wave -noupdate -radix binary /testbench/dut/arm_core/c/aluflags
add wave -noupdate -divider {Datapath & Shifter}
add wave -noupdate -radix hexadecimal /testbench/dut/arm_core/dp/rd1
add wave -noupdate -radix hexadecimal /testbench/dut/arm_core/dp/rd2
add wave -noupdate -radix hexadecimal /testbench/dut/arm_core/dp/shifted_rd2
add wave -noupdate -radix hexadecimal /testbench/dut/arm_core/dp/srcb
add wave -noupdate -radix hexadecimal /testbench/dut/arm_core/dp/aluresult
add wave -noupdate -divider {Memory Interface}
add wave -noupdate -radix decimal /testbench/dataadr
add wave -noupdate -radix decimal /testbench/writedata

# Run test
run -all
