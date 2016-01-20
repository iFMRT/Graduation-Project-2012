# BUS_IF_OBJS specifies which files to compile as part of bus_if testbench
BUS_IF_OBJS = bus_if_test.v ../cpu/bus_if.v

# MEM_REG_OBJS specifies which files to compile as part of mem reg testbench
MEM_REG_OBJS = mem_reg_test.v ../cpu/mem_reg.v

# MEM_CTRL_OBJS specifies which files to compile as part of mem ctrl testbench
MEM_CTRL_OBJS = mem_ctrl_test.v ../cpu/mem_ctrl.v

# MEM_STAGE_OBJS specifies which files to compile as part of mem stage testbench
MEM_STAGE_OBJS = mem_stage_test.v ../cpu/mem_stage.v ../cpu/bus_if.v   ../cpu/mem_ctrl.v / ../cpu/mem_reg.v

# CPU_OBJS specifies which files to compile as part of mem stage testbench
CPU_OBJS = cpu_test.v ../cpu/if_stage.v ../cpu/if_reg.v ../cpu/bus_if.v ../cpu/spm.v     \
					  ../cpu/dpram_sim.v ../cpu/gpr.v ../cpu/id_stage.v ../cpu/id_reg.v  \
					  ../cpu/decoder.v ../cpu/ex_stage.v ../cpu/ex_reg.v ../cpu/alu.v    \
					  ../cpu/cmp.v ../cpu/mem_stage.v ../cpu/mem_reg.v ../cpu/mem_ctrl.v \
					  ../cpu/ctrl.v

# CC specifies which compiler we're using
CC = iverilog

# INCLUDE_PATHS specifies the additional include paths we'll need
INCLUDE_PATHS = -I ../include

BUS_IF_OBJ_NAME    = bus_if.out
MEM_REG_OBJ_NAME   = mem_reg.out
MEM_CTRL_OBJ_NAME  = mem_ctrl.out
MEM_STAGE_OBJ_NAME = mem_stage.out
CPU_OBJ_NAME 	   = cpu.out

bus_if : $(BUS_IF_OBJS)
	$(CC) $(INCLUDE_PATHS) $(BUS_IF_OBJS)  -o $(BUS_IF_OBJ_NAME) -s bus_if_test
	vvp $(BUS_IF_OBJ_NAME)

mem_reg : $(MEM_REG_OBJS)
	$(CC) $(INCLUDE_PATHS) $(MEM_REG_OBJS)  -o $(MEM_REG_OBJ_NAME) -s mem_reg_test
	vvp $(MEM_REG_OBJ_NAME)

mem_ctrl : $(MEM_CTRL_OBJS)
	$(CC) $(INCLUDE_PATHS) $(MEM_CTRL_OBJS)  -o $(MEM_CTRL_OBJ_NAME) -s mem_ctrl_test
	vvp $(MEM_CTRL_OBJ_NAME)

mem_stage : $(MEM_STAGE_OBJS)
	$(CC) $(INCLUDE_PATHS) $(MEM_STAGE_OBJS)  -o $(MEM_STAGE_OBJ_NAME) -s mem_stage_test
	vvp $(MEM_STAGE_OBJ_NAME)

cpu : $(CPU_OBJS)
	$(CC) $(INCLUDE_PATHS) $(CPU_OBJS)  -o $(CPU_OBJ_NAME) -s cpu_test
	vvp $(CPU_OBJ_NAME)