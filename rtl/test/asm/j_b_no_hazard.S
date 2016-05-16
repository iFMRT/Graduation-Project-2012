// test Jump & Branch & Load & Store format instruction without data hazard 

addi x26,x0,1025     // x26 = 1025
addi x27,x0,1025     // x27 = 1025
beq  x26,x27,8       // if x26 = x27, jump to insn(sb   x26,x27,1024)

addi x27,x26,4       // x27 = x26 + 4
jal  x0,16           // jump to insn(sw   x28,x26,1028)

sb   x26,1024(x27)   // x26[7:0]  --> [x27 + 1024]   1    --> [2049]
sh   x27,1028(x26)   // x27[15:0] --> [x26 + 1028]   1025 --> [2053]
addi x28,x0,14       // x28 = 14
add  x29,x26,x27     // x29 = x26 + x27 = 2050   
add  x30,x26,x27     // x30 = x26 + x27 = 2050 
lb   x28,1024(x27)   // [x27 + 1024] --> x28 = 1
lh   x29,1028(x26)   // [x26 + 1028] --> x29 = 1025
sw   x26,1024(x27)   // x26 --> [x27 + 1024]         1025 --> [2049]
addi x3,x0,5         // x3 = 5
addi x27,x0,32       // x27 = 32
add  x30,x26,x28     // x30 = x26 + x28 = 1026  
add  x28,x26,x0      // x28 = x26 = 1025

lbu  x27,1028(x26)   // [x26 + 1028] --> x27 = 1
lhu  x30,1028(x26)   // [x26 + 1028] --> x30 = 1025

