# 	Test CSRRx and CSRRxI instructions.

.section .initial, "xa"
  addi x1, zero, 4    # x1 = 4
  add  x2, x1, zero   # x2 = 4
  addi x3, x2, 8      # x3 = 12
  sub  x4, x3, x1     # x4 = 8
  csrrs x5, mepc, x4  # x5 = 4
  csrrc x6, mepc, x3  # x6 = 
  csrrw x0, mepc, x5  # x0 = 0
  csrrsi x7, mepc, 31 # x7 = 4
  csrrci x8, mepc, 10 # x8 = 0x1f
  csrrwi x0, mepc, 0  # x0 = 0x15

.section .exception, "xa"
  csrr x7, mcause
  csrr x8, mepc
  addi x8, x8, 4
  csrw mepc, x8
  eret

