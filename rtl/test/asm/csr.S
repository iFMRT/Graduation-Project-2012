# 	Test CSRRx and CSRRxI instructions.

.section .initial, "xa"
  addi x1, zero, 4    # x1 = 4
  add  x2, x1, zero   # x2 = 4
  addi x3, x2, 8      # x3 = 12
  lw   x4, 3(x1)
  csrrs x5, mepc, x3  # x5 = 4, x5 = 0x14
  csrrc x6, mepc, x3  # x6 = 0xc, x6 = 0x1c
  csrrw x0, mepc, x5  # x0 = 0,  x0 = 0x10
  csrrsi x7, mepc, 31 # x7 = 4, x7 = 0x14
  csrrci x8, mepc, 10 # x8 = 0x1f, x8 = 0x1f
  csrrwi x0, mepc, 0  # x0 = 0x15

.section .exception, "xa"
  csrr x7, mcause
  csrr x8, mepc
  addi x8, x8, 4
  csrw mepc, x8
  eret

