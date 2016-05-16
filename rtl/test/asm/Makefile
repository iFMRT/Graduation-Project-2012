CC = riscv64-unknown-elf-as
OBJCOPY = riscv64-unknown-elf-objcopy
LD = riscv64-unknown-elf-ld

CSR_LD = csr.ld
CSR_ELF = csr.elf

ALU_SRC = alu.S
CSR_SRC = csr.S

ALU_OBJ = alu.o
CSR_OBJ = csr.o

alu: $(ALU_SRC)
	$(CC) -m32 $(ALU_SRC) -o $(ALU_OBJ)
	$(OBJCOPY) $(ALU_OBJ) -O verilog ../test.dat

csr: $(CSR_SRC)
	$(CC) $(CSR_SRC) -o $(CSR_OBJ)
	$(LD) --script $(CSR_LD) $(CSR_OBJ) -o $(CSR_ELF)
	$(OBJCOPY) -O verilog $(CSR_ELF) ../test.dat