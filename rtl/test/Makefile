# BUS_IF_OBJS specifies which files to compile as part of bus_if testbench
BUS_IF_OBJS = bus_if/bus_if_test.v ../cpu/bus_if.v

# IF_REG_OBJS specifies which files to compile as part of mem reg testbench
IF_REG_OBJS = if_stage/if_reg_test.v ../cpu/if_reg.v

# IF_STAGE_OBJS specifies which files to compile as part of mem stage testbench
IF_STAGE_OBJS = if_stage/if_stage_test.v ../cpu/if_stage.v $(BUS_IF_OBJS) $(IF_REG_OBJS)

# MEM_REG_OBJS specifies which files to compile as part of mem reg testbench
MEM_REG_OBJS = mem_reg_test.v ../cpu/mem_reg.v

# MEM_CTRL_OBJS specifies which files to compile as part of mem ctrl testbench
MEM_CTRL_OBJS = mem_ctrl_test.v ../cpu/mem_ctrl.v

# MEM_STAGE_OBJS specifies which files to compile as part of mem stage testbench
MEM_STAGE_OBJS = mem_stage_test.v ../cpu/mem_stage.v ../cpu/bus_if.v  ../cpu/mem_ctrl.v / ../cpu/mem_reg.v

# GPIO_OBJS specifies which files to compile as part of GPIO testbench
GPIO_OBJS = gpio_test.v ../io/gpio.v

# UNITS_OBJS specifies which files to combine a CPU
UNITS_OBJS = ../cpu/if_stage.v ../cpu/if_reg.v ../cpu/bus_if.v      \
						../cpu/id_stage.v ../cpu/id_reg.v ../cpu/decoder.v               \
						../cpu/ex_stage.v ../cpu/ex_reg.v ../cpu/alu.v  ../cpu/cmp.v     \
						../cpu/mem_stage.v ../cpu/mem_reg.v ../cpu/mem_ctrl.v            \
						../cpu/ctrl.v                                                    \
						../cpu/spm.v ../cpu/dpram_sim.v ../cpu/gpr.v ../cpu/csr.v

CPU_OBJS =  cpu_test.v $(UNITS_OBJS)
CPU_TOP_ALU_OBJS =  cpu_top/cpu_top_alu_test.v ../cpu/cpu_top.v $(UNITS_OBJS)

# CC specifies which compiler we're using
CC = iverilog

# INCLUDE_PATHS specifies the additional include paths we'll need
INCLUDE_PATHS = -I ../include

BUS_IF_OBJ_NAME    = bus_if.out
IF_REG_OBJ_NAME    = if_reg.out
IF_STAGE_OBJ_NAME  = if_stage.out
MEM_REG_OBJ_NAME   = mem_reg.out
MEM_CTRL_OBJ_NAME  = mem_ctrl.out
MEM_STAGE_OBJ_NAME = mem_stage.out

GPIO_OBJ_NAME      = gpio.out

CPU_OBJ_NAME       = cpu.out
CPU_TOP_ALU_OBJ_NAME   = cpu_top/cpu_alu_top.out

bus_if : $(BUS_IF_OBJS)
	$(CC) $(INCLUDE_PATHS) $(BUS_IF_OBJS)  -o $(BUS_IF_OBJ_NAME) -s bus_if_test
	vvp $(BUS_IF_OBJ_NAME)

if_reg : $(IF_REG_OBJS)
	$(CC) $(INCLUDE_PATHS) $(IF_REG_OBJS)  -o $(IF_REG_OBJ_NAME) -s if_reg_test
	vvp $(IF_REG_OBJ_NAME)

if_stage : $(IF_STAGE_OBJS)
	$(CC) $(INCLUDE_PATHS) $(IF_STAGE_OBJS)  -o $(IF_STAGE_OBJ_NAME) -s if_stage_test
	vvp $(IF_STAGE_OBJ_NAME)

mem_reg : $(MEM_REG_OBJS)
	$(CC) $(INCLUDE_PATHS) $(MEM_REG_OBJS)  -o $(MEM_REG_OBJ_NAME) -s mem_reg_test
	vvp $(MEM_REG_OBJ_NAME)

mem_ctrl : $(MEM_CTRL_OBJS)
	$(CC) $(INCLUDE_PATHS) $(MEM_CTRL_OBJS)  -o $(MEM_CTRL_OBJ_NAME) -s mem_ctrl_test
	vvp $(MEM_CTRL_OBJ_NAME)

mem_stage : $(MEM_STAGE_OBJS)
	$(CC) $(INCLUDE_PATHS) $(MEM_STAGE_OBJS)  -o $(MEM_STAGE_OBJ_NAME) -s mem_stage_test
	vvp $(MEM_STAGE_OBJ_NAME)

gpio : $(GPIO_OBJS)
	$(CC) $(INCLUDE_PATHS) $(GPIO_OBJS)  -o $(GPIO_OBJ_NAME) -s gpio_test
	vvp $(GPIO_OBJ_NAME)

cpu : $(CPU_OBJS)
	$(CC) $(INCLUDE_PATHS) $(CPU_OBJS)  -o $(CPU_OBJ_NAME) -s cpu_test
	vvp $(CPU_OBJ_NAME)

cpu_top_alu : $(CPU_TOP_ALU_OBJS)
	$(CC) $(INCLUDE_PATHS) $(CPU_TOP_ALU_OBJS)  -o $(CPU_TOP_ALU_OBJ_NAME) -s cpu_top_test
	vvp $(CPU_TOP_ALU_OBJ_NAME)

# Testcase Generator
TCGEN = ../../utils/tbgen/tcgen.py

# Testcase Template
TC_TEMPLATE = template/testcase.v

# Component directory
IF_DIR = if_stage
ID_DIR = id_stage

# IF Stage ALU Testcase
IF_TC_ALU = if_stage/if_stage.alu.yaml

# ID Stage ALU Testcase
ID_TC_ALU = id_stage/id_stage.alu.yaml

testcase_if_alu : $(IF_TC_ALU)
	$(TCGEN) $(IF_TC_ALU) -t $(TC_TEMPLATE) -o $(IF_DIR)/testcase_alu.v

testcase_id_alu : $(ID_TC_ALU)
	$(TCGEN) $(ID_TC_ALU) -t $(TC_TEMPLATE) -o $(ID_DIR)/testcase_alu.v
