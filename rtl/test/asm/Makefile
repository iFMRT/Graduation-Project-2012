CC = riscv64-unknown-elf-as
OBJCOPY = riscv64-unknown-elf-objcopy

INT_ALU_SRC = int_alu.S
INT_ALU_OBJ = int_alu.out

int_alu: $(INT_ALU_SRC)
	$(CC) -m32 $(INT_ALU_SRC) -o $(INT_ALU_OBJ)
	$(OBJCOPY) $(INT_ALU_OBJ) -O verilog ../test.dat

J_B_HAZARD_SRC = j_b_hazard.S
J_B_HAZARD_OBJ = j_b_hazard.out

j_b_hazard: $(J_B_HAZARD_SRC)
	$(CC) -m32 $(J_B_HAZARD_SRC) -o $(J_B_HAZARD_OBJ)
	$(OBJCOPY) $(J_B_HAZARD_OBJ) -O verilog ../test.dat

J_B_NO_HAZARD_SRC = j_b_no_hazard.S
J_B_NO_HAZARD_OBJ = j_b_no_hazard.out

j_b_no_hazard: $(J_B_NO_HAZARD_SRC)
	$(CC) -m32 $(J_B_NO_HAZARD_SRC) -o $(J_B_NO_HAZARD_OBJ)
	$(OBJCOPY) $(J_B_NO_HAZARD_OBJ) -O verilog ../test.dat