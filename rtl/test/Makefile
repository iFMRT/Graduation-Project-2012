# V_CC specifies which compiler we're using
V_CC = iverilog

# INCLUDE_PATHS specifies the additional include paths we'll need
INCLUDE_PATHS = -I ../include

BUS_IF_OBJS    = bus_if/bus_if_test.v ../cpu/bus_if.v

IF_REG_OBJS    = if_stage/if_reg_test.v ../cpu/if_reg.v
IF_STAGE_OBJS  = if_stage/if_stage_test.v ../cpu/if_stage.v $(BUS_IF_OBJS) $(IF_REG_OBJS)

MEM_REG_OBJS   = mem_reg_test.v ../cpu/mem_reg.v
MEM_CTRL_OBJS  = mem_ctrl_test.v ../cpu/mem_ctrl.v
MEM_STAGE_OBJS = mem_stage_test.v ../cpu/mem_stage.v ../cpu/bus_if.v  ../cpu/mem_ctrl.v / ../cpu/mem_reg.v

GPIO_OBJS = gpio_test.v ../io/gpio.v

UNITS_OBJS = ../cpu/if_stage.v ../cpu/if_reg.v ../cpu/bus_if.v               \
						../cpu/id_stage.v ../cpu/id_reg.v ../cpu/decoder.v               \
						../cpu/ex_stage.v ../cpu/ex_reg.v ../cpu/alu.v  ../cpu/cmp.v     \
						../cpu/mem_stage.v ../cpu/mem_reg.v ../cpu/mem_ctrl.v            \
						../cpu/ctrl.v                                                    \
						../cpu/spm.v ../cpu/dpram_sim.v ../cpu/gpr.v ../cpu/csr.v

CPU_TOP_SRC  = ../cpu/cpu_top.v
CPU_TOP_OBJS =  cpu_top/cpu_top_test.v $(CPU_TOP_SRC) $(UNITS_OBJS)

BUS_IF_OBJ_NAME    = build/bus_if.out

IF_REG_OBJ_NAME    = build/if_reg.out
IF_STAGE_OBJ_NAME  = build/if_stage.out

MEM_REG_OBJ_NAME   = build/mem_reg.out
MEM_CTRL_OBJ_NAME  = build/mem_ctrl.out
MEM_STAGE_OBJ_NAME = build/mem_stage.out

GPIO_OBJ_NAME      = build/gpio.out

CPU_TOP_OBJ_NAME   = build/cpu_top.out

bus_if : $(BUS_IF_OBJS)
	$(V_CC) $(INCLUDE_PATHS) $(BUS_IF_OBJS)  -o $(BUS_IF_OBJ_NAME) -s bus_if_test
	vvp $(BUS_IF_OBJ_NAME)

if_reg : $(IF_REG_OBJS)
	$(V_CC) $(INCLUDE_PATHS) $(IF_REG_OBJS)  -o $(IF_REG_OBJ_NAME) -s if_reg_test
	vvp $(IF_REG_OBJ_NAME)

if_stage : $(IF_STAGE_OBJS)
	$(V_CC) $(INCLUDE_PATHS) $(IF_STAGE_OBJS)  -o $(IF_STAGE_OBJ_NAME) -s if_stage_test
	vvp $(IF_STAGE_OBJ_NAME)

mem_reg : $(MEM_REG_OBJS)
	$(V_CC) $(INCLUDE_PATHS) $(MEM_REG_OBJS)  -o $(MEM_REG_OBJ_NAME) -s mem_reg_test
	vvp $(MEM_REG_OBJ_NAME)

mem_ctrl : $(MEM_CTRL_OBJS)
	$(V_CC) $(INCLUDE_PATHS) $(MEM_CTRL_OBJS)  -o $(MEM_CTRL_OBJ_NAME) -s mem_ctrl_test
	vvp $(MEM_CTRL_OBJ_NAME)

mem_stage : $(MEM_STAGE_OBJS)
	$(V_CC) $(INCLUDE_PATHS) $(MEM_STAGE_OBJS)  -o $(MEM_STAGE_OBJ_NAME) -s mem_stage_test
	vvp $(MEM_STAGE_OBJ_NAME)

gpio : $(GPIO_OBJS)
	$(V_CC) $(INCLUDE_PATHS) $(GPIO_OBJS)  -o $(GPIO_OBJ_NAME) -s gpio_test
	vvp $(GPIO_OBJ_NAME)

cpu_top: $(CPU_TOP_OBJS)
	$(V_CC) $(INCLUDE_PATHS) $(CPU_TOP_OBJS)  -o $(CPU_TOP_OBJ_NAME) -s cpu_top_test
	vvp $(CPU_TOP_OBJ_NAME)

# Testbench Generator
TBGEN = ../../utils/tbgen/tbgen.py

# Testbench Template
TB_SEQ_TEMPLATE_OUTPUT = template/sequential_logic_output.v
TB_SEQ_TEMPLATE_INOUT  = template/sequential_logic_inout.v

# IF Stage ALU Testbench yaml file
IF_TB_ALU   = if_stage/if_stage.yaml
# ID Stage ALU Testbench
ID_TB_ALU   = id_stage/id_stage.yaml
# CPU Top ALU Testbench
CPU_TOP_TB_ALU = cpu_top/cpu_top.alu.yaml
# CPU Top CSR Testbench
CPU_TOP_TB_CSR = cpu_top/cpu_top.csr.yaml
# CPU Top CTRL and MEM Testbench
CPU_TOP_TB_CTRL_MEM_HAZARD = cpu_top/cpu_top.ctrl_mem_hazard.yaml

# Generate yaml template file
yaml_cpu_top_alu : $(CPU_TOP_TB_ALU)
	$(TBGEN) $(CPU_TOP_SRC) -g $(CPU_TOP_TB_ALU)

yaml_cpu_top_csr : $(CPU_TOP_TB_CSR)
	$(TBGEN) $(CPU_TOP_SRC) -g $(CPU_TOP_TB_CSR)

yaml_cpu_top_ctrl_mem_hazard : $(CPU_TOP_TB_CTRL_MEM)
	$(TBGEN) $(CPU_TOP_SRC) -g $(CPU_TOP_TB_CTRL_MEM_HAZARD)

# Generate testcase
tb_cpu_top_alu : $(CPU_TOP_TB_ALU)
	$(TBGEN) $(CPU_TOP_SRC) -y $(CPU_TOP_TB_ALU) -t $(TB_SEQ_TEMPLATE_OUTPUT) -o cpu_top/cpu_top_test.v

tb_cpu_top_csr : $(CPU_TOP_TB_CSR)
	$(TBGEN) $(CPU_TOP_SRC) -y $(CPU_TOP_TB_CSR) -t $(TB_SEQ_TEMPLATE_OUTPUT) -o cpu_top/cpu_top_test.v

tb_cpu_top_ctrl_mem_hazard : $(CPU_TOP_TB_CTRL_MEM)
	$(TBGEN) $(CPU_TOP_SRC) -y $(CPU_TOP_TB_CTRL_MEM_HAZARD) -t $(TB_SEQ_TEMPLATE_OUTPUT) -o cpu_top/cpu_top_test.v

# ASM Compilation
CC      = riscv64-unknown-elf-as
OBJCOPY = riscv64-unknown-elf-objcopy
LD      = riscv64-unknown-elf-ld

CSR_LD  = asm/csr.ld
CSR_ELF = build/csr.elf

ALU_SRC             = asm/alu.S
CSR_SRC             = asm/csr.S
CTRL_MEM_SRC        = asm/ctrl_mem.S
CTRL_MEM_HAZARD_SRC = asm/ctrl_mem_hazard.S

ALU_OBJ             = build/alu.o
CSR_OBJ             = build/csr.o
CTRL_MEM_OBJ        = build/ctrl_mem.o
CTRL_MEM_HAZARD_OBJ = build/ctrl_mem_hazard.o

alu: $(ALU_SRC)
	$(CC) -m32 $(ALU_SRC) -o $(ALU_OBJ)
	$(OBJCOPY) $(ALU_OBJ) -O verilog test.dat

csr: $(CSR_SRC)
	$(CC) $(CSR_SRC) -o $(CSR_OBJ)
	$(LD) --script $(CSR_LD) $(CSR_OBJ) -o $(CSR_ELF)
	$(OBJCOPY) -O verilog $(CSR_ELF) test.dat

ctrl_mem: $(CTRL_MEM_SRC)
	$(CC) -m32 $(CTRL_MEM_SRC) -o $(CTRL_MEM_OBJ)
	$(OBJCOPY) $(CTRL_MEM_OBJ) -O verilog test.dat

ctrl_mem_hazard: $(CTRL_MEM_HAZARD_SRC)
	$(CC) -m32 $(CTRL_MEM_HAZARD_SRC) -o $(CTRL_MEM_HAZARD_OBJ)
	$(OBJCOPY) $(CTRL_MEM_HAZARD_OBJ) -O verilog test.dat

