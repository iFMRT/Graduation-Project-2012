        addi    x15, x0,  1       #00
        addi    x16, x0,  3       #04  排序个数
        sub     x3,  x16, x15     #08
        jal     x4,  sort         #0C      sort
        addi    x1,  x0,  1024    #10
        addi    x2,  x0,  0       #14

load:   lw      x31, 0(x1)        #18
        addi    x1,  x1,  4       #1C
        addi    x2,  x2,  1       #20
        bge     x3,  x2,  load    #24
        jal     x23, finish       #28

sort:   sub     x5,  x3,  x15     #2C      j
        jal     x6,  j1           #30      big loop
        addi    x23, x0,  0       #34
        addi    x23, x0,  0       #38
        jr      x4                #3C

j1:     addi    x13, x0,  0       #40
        jal     x8,  j2           #44     # small loop
        sub     x5,  x5,  x15     #48
        addi    x20, x5,  1       #4C
        bne     x20, x0,  j1      #50
        jr      x6                #54

j2:     sll     x7,  x13, 2       #58  i
        lw      x9,  1024(x7)     #5C
        lw      x10, 1028(x7)     #60
        bge     x9,  x10, j3      #64
        jal     x11, swap         #68

j3:     sw      x9,  1024(x7)     #6C
        sw      x10, 1028(x7)     #70
        addi    x13, x13, 1       #74
        bge     x5,  x13, j2      #78
        jr      x8                #7C

swap:   addi    x12, x9,  0       #80
        addi    x9,  x10, 0       #84
        addi    x10, x12, 0       #88
        jr      x11               #8C

finish: beq     x0,  x0,  finish  #90
        addi    x0,  x0,  0
        addi    x0,  x0,  0
