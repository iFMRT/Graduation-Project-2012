 # Integer Computational Instructions(19)
 # ADDI, SLTI, SLTIU, XORI, ORI,  ANDI, SLLI, SRLI. SRAI
 # LUI,  AUIPC
 # ADD,  SUB,  SLL,   SLT,  SLTU, XOR,  SRL,  SRA,  OR,  AND

  addi  x1, zero, 4   # x1 = 4
  slti  x2, zero, -2  # x2 = 0
  sltiu x3, zero, -2  # x3 = 1
  xori  x4, x1, 5     # x4 = 1
  ori   x5, x2, -6    # x5 = -6 0xfffffffa
  andi  x6, x3, 7     # x6 = 1
  slli  x7, x4, 3     # x7 = 8
  srli  x8, x5, 2     # x8 = 0x3ffffffe
  srai  x9, x5, 2     # x9 = -2 0xfffffffe

  lui   x12, 20       # x12 = 0x14000
  auipc x13, 20       # x13 = 0x14028

  add   x10, x1,  x2  # x10 = 4
  sub   x11, x6,  x7  # x11 = -7 0xfffffff9
  sll   x20, x10, x1  # x20 = 64
  slt   x21, x4,  x5  # x21 = 0
  sltu  x22, x4,  x5  # x22 = 1
  xor   x23, x7,  x8  # x23 = 0x3ffffff6
  srl   x24, x5,  x3  # x24 = 0x7ffffffd
  sra   x14, x5,  x3  # x14 = -3 0xfffffffd
  or    x15, x8,  x9  # x15 = 0xfffffffe
  and   x16, x10, x11 # x16 = 0

  nop
  nop
  nop
  nop
