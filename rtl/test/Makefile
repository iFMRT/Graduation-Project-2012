# MEM_STAGE_OBJS specifies which files to compile as part of mem stage testbench
MEM_REG_OBJS = mem_reg_test.v ../cpu/mem_reg.v

# MEM_STAGE_OBJS specifies which files to compile as part of mem stage testbench
MEM_CTRL_OBJS = mem_ctrl_test.v ../cpu/mem_ctrl.v

# MEM_STAGE_OBJS specifies which files to compile as part of mem stage testbench
MEM_STAGE_OBJS = mem_stage_test.v ../cpu/mem_stage.v ../cpu/bus_if.v   ../cpu/mem_ctrl.v / ../cpu/mem_reg.v

# CC specifies which compiler we're using
CC = iverilog

# INCLUDE_PATHS specifies the additional include paths we'll need
INCLUDE_PATHS = -I ../include

MEM_REG_OBJ_NAME  = mem_reg.out
MEM_CTRL_OBJ_NAME  = mem_ctrl.out
MEM_STAGE_OBJ_NAME = mem_stage.out

mem_reg : $(MEM_REG_OBJS)
	$(CC) $(MEM_REG_OBJS) $(INCLUDE_PATHS) -o $(MEM_REG_OBJ_NAME) -s mem_reg_test
	vvp $(MEM_REG_OBJ_NAME)

mem_ctrl : $(MEM_CTRL_OBJS)
	$(CC) $(MEM_CTRL_OBJS) $(INCLUDE_PATHS) -o $(MEM_CTRL_OBJ_NAME) -s mem_ctrl_test
	vvp $(MEM_CTRL_OBJ_NAME)

mem_stage : $(MEM_STAGE_OBJS)
	$(CC) $(MEM_STAGE_OBJS) $(INCLUDE_PATHS) -o $(MEM_STAGE_OBJ_NAME) -s mem_stage_test
	vvp $(MEM_STAGE_OBJ_NAME)
