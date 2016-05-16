# test Jump & Branch & Load & Store format instruction with data hazard

addi x26,x0,1025     # x26 = 1025
addi x27,x0,2        # x27 = 2

beq  x26,x27,jump1   # if x26 = x27, jump to insn(sb x26,x1024(x27))
addi x27,x26,4       # x27 = x26+4 = 1029  (x26 data hazard)
jal  x0,jump2        # jump to insn (sw   x28,x26,1028)
jump1:
sb   x26,1024(x27)   # x26 --> [x27 + 1024]
sh   x27,1027(x26)   # x27 --> [x26 + 1027]
lb   x28,1024(x27)   # [x27 + 1024] byte --> x28
lh   x29,1027(x26)   # [x26 + 1027] half_word --> x29
jump2:
sw   x26,1027(x26)   # x26 --> [x26 + 1027] = 1025 --> [2052]
lbu  x27,1027(x26)   # [x26 + 1027] --> x27 = 1     (load hazard)
lhu  x30,1027(x26)   # [x26 + 1027] --> x30 = 1025  (load hazard)
add  x29,x26,x27     # x29 = x26 + x27 = 1026     (x27 data hazard)
addi x28,x0,14       # x28 = 14

add  x30,x26,x28     # x30 = x26 + x28 = 1039     (x28 data hazard)
add  x27,x27,x29     # x27 = x27 + x29 = 1027     (x29 data hazard)
bne  x27,x30,branch1 # if x26 != x30,jump to insn(add  x27,x27,x29)

lw   x27,1027(x26)   # [x26 + 1027] --> x27
blt  x29,x28,branch2 # if x29 < x28, jump to insn(add  x27,x27,x29)
branch1:
add  x27,x27,x29     # x27 = x27 + x29 = 2053
bge  x29,x28,branch3 # if x29 > x28, jump to insn(bltu x29,x28,8)
branch2:
add  x27,x27,x29     # x27 = x27 + x29
add  x27,x27,x29     # x27 = x27 + x29
branch3:
bltu x29,x28,branch4 # if x29 < x28, jump to insn(add  x30,x26,x28)
bgeu x29,x28,branch5 # if x29 > x28, jump to insn(add  x27,x27,x29)
add  x30,x26,x28     # x30 = x26 + x28
branch4:
add  x30,x26,x28     # x30 = x26 + x28
branch5:
add  x27,x27,x29     # x27 = x27 + x29 = 3079
