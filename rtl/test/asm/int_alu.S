 # Integer Computational Instructions(19)
 # ADDI, SLTI, SLTIU, XORI, ORI,  ANDI, SLLI, SRLI. SRAI
 # LUI,  AUIPC
 # ADD,  SUB,  SLL,   SLT,  SLTU, XOR,  SRL,  SRA,  OR,  AND

  addi  s1, zero, 4
  slti  s2, zero, -2
	sltiu s3, zero, -2
	xori  s4, s1, 5
	ori   s5, s2, -6
	andi  s6, s3, 7
	slli  s7, s4, 3
	srli  s8, s5, 2
	srai  s9, s5, 2

	lui   a1, 20
	auipc a3, 20

	add   s10, s1,  s2
  sub   s11, s6,  s7
	sll   t0,  s10, s11
  slt   t1,  s4,  s3
  sltu  t2,  s4,  s1
  xor   t3,  s7,  s8
  srl   t4,  s5,  s2
  sra   a4,  s5,  s2
  or    a5,  s8,  s9
  and   a6,  a0,  a1

	nop
	nop
	nop
	nop
