# BUS_IF_OBJS specifies which files to compile as part of bus_if testbench
BUS_IF_OBJS = bus_if_test.v ../cpu/bus_if.v

# MEM_REG_OBJS specifies which files to compile as part of mem reg testbench
MEM_REG_OBJS = mem_reg_test.v ../cpu/mem_reg.v

# MEM_CTRL_OBJS specifies which files to compile as part of mem ctrl testbench
MEM_CTRL_OBJS = mem_ctrl_test.v ../cpu/mem_ctrl.v

# MEM_STAGE_OBJS specifies which files to compile as part of mem stage testbench
MEM_STAGE_OBJS = mem_stage_test.v ../cpu/mem_stage.v ../cpu/bus_if.v   ../cpu/mem_ctrl.v / ../cpu/mem_reg.v

# MEM_STAGE_OBJS specifies which files to compile as part of mem stage testbench
MEM_TMP_OBJS = mem_tmp_test.v  ../cpu/mem_tmp.v  ../cpu/mem_ctrl.v ../cpu/bus_if.v

# CC specifies which compiler we're using
CC = iverilog

# INCLUDE_PATHS specifies the additional include paths we'll need
INCLUDE_PATHS = -I ../include

BUS_IF_OBJ_NAME    = bus_if.out
MEM_REG_OBJ_NAME   = mem_reg.out
MEM_CTRL_OBJ_NAME  = mem_ctrl.out
MEM_STAGE_OBJ_NAME = mem_stage.out
MEM_TMP_OBJ_NAME = mem_tmp.out

bus_if : $(BUS_IF_OBJS)
	$(CC) $(BUS_IF_OBJS) $(INCLUDE_PATHS) -o $(BUS_IF_OBJ_NAME) -s bus_if_test
	vvp $(BUS_IF_OBJ_NAME)

mem_reg : $(MEM_REG_OBJS)
	$(CC) $(MEM_REG_OBJS) $(INCLUDE_PATHS) -o $(MEM_REG_OBJ_NAME) -s mem_reg_test
	vvp $(MEM_REG_OBJ_NAME)

mem_ctrl : $(MEM_CTRL_OBJS)
	$(CC) $(MEM_CTRL_OBJS) $(INCLUDE_PATHS) -o $(MEM_CTRL_OBJ_NAME) -s mem_ctrl_test
	vvp $(MEM_CTRL_OBJ_NAME)

mem_stage : $(MEM_STAGE_OBJS)
	$(CC) $(MEM_STAGE_OBJS) $(INCLUDE_PATHS) -o $(MEM_STAGE_OBJ_NAME) -s mem_stage_test
	vvp $(MEM_STAGE_OBJ_NAME)

mem_tmp : $(MEM_TMP_OBJS)
	$(CC) $(MEM_TMP_OBJS) $(INCLUDE_PATHS) -o $(MEM_TMP_OBJ_NAME) -s mem_tmp_test
	vvp $(MEM_TMP_OBJ_NAME)


