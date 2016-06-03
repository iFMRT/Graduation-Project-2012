CC = riscv64-unknown-elf-as
OBJCOPY = riscv64-unknown-elf-objcopy
LD = riscv64-unknown-elf-ld

CSR_LD = csr.ld
CSR_ELF = csr.elf

ALU_SRC = alu.S
CSR_SRC = csr.S
J_B_HAZARD_SRC = j_b_hazard.S
J_B_NO_HAZARD_SRC = j_b_no_hazard.S
HCU_SRC = hcu_test.s
SORT_SRC = sort.s

ALU_OBJ = alu.o
CSR_OBJ = csr.o
J_B_HAZARD_OBJ = j_b_hazard.out
J_B_NO_HAZARD_OBJ = j_b_no_hazard.out
HCU_OBJ = hcu_test.o
SORT_OBJ = sort.o

alu: $(ALU_SRC)
	$(CC) -m32 $(ALU_SRC) -o $(ALU_OBJ)
	$(OBJCOPY) $(ALU_OBJ) -O verilog ../test.dat

csr: $(CSR_SRC)
	$(CC) $(CSR_SRC) -o $(CSR_OBJ)
	$(LD) --script $(CSR_LD) $(CSR_OBJ) -o $(CSR_ELF)
	$(OBJCOPY) -O verilog $(CSR_ELF) ../test.dat

j_b_hazard: $(J_B_HAZARD_SRC)
	$(CC) -m32 $(J_B_HAZARD_SRC) -o $(J_B_HAZARD_OBJ)
	$(OBJCOPY) $(J_B_HAZARD_OBJ) -O verilog ../test.dat

j_b_no_hazard: $(J_B_NO_HAZARD_SRC)
	$(CC) -m32 $(J_B_NO_HAZARD_SRC) -o $(J_B_NO_HAZARD_OBJ)
	$(OBJCOPY) $(J_B_NO_HAZARD_OBJ) -O verilog ../test.dat

hcu: $(HCU_SRC)
	$(CC) -m32 $(HCU_SRC) -o $(HCU_OBJ)
	$(OBJCOPY) $(HCU_OBJ) -O verilog ../test.dat

sort: $(SORT_SRC)
	$(CC) -m32 $(SORT_SRC) -o $(SORT_OBJ)
	$(OBJCOPY) $(SORT_OBJ) -O verilog ../test.dat
