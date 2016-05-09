CC = riscv64-unknown-elf-as
OBJCOPY = riscv64-unknown-elf-objcopy

INT_ALU_SRC = int_alu.S
INT_ALU_OBJ = int_alu.out

int_alu: $(INT_ALU_SRC)
	$(CC) $(INT_ALU_SRC) -o $(INT_ALU_OBJ)
	$(OBJCOPY) $(INT_ALU_OBJ) -O verilog ../test.dat
