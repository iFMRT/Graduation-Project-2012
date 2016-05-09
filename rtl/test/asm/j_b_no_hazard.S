// test Jump & Branch & Load & Store format instruction without data hazard 

addi t0,zero,1025  // t0 = 1025
addi t1,zero,1025  // t1 = 1025
beq  t0,t1,8       // if t0 = t1, jump to insn(sb   t0,t1,1024)

addi t1,t0,4       // t1 = t0 + 4
jal  zero,16       // jump to insn(sw   t2,t0,1028)

sb   t0,1024(t1)   // t0[7:0]  --> [t1 + 1024]   1    --> [2049]
sh   t1,1028(t0)   // t1[15:0] --> [t0 + 1028]   1025 --> [2053]
addi t2,zero,14    // t2 = 14
add  t3,t0,t1      // t3 = t0 + t1 = 2050   
add  t4,t0,t1      // t4 = t0 + t1 = 2050 
lb   t2,1024(t1)   // [t1 + 1024] --> t2 = 1
lh   t3,1028(t0)   // [t0 + 1028] --> t3 = 1025
sw   t0,1024(t1)   // t0 --> [t1 + 1024]         1025 --> [2049]
addi s1,zero,5     // s1 = 5
addi t1,zero,32    // t1 = 32
add  t4,t0,t2      // t4 = t0 + t2 = 1026  
add  t2,t0,zero    // t2 = t0 = 1025

lbu  t1,1028(t0)   // [t0 + 1028] --> t1 = 1
lhu  t4,1028(t0)   // [t0 + 1028] --> t4 = 1025

