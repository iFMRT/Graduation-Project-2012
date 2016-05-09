// test Jump & Branch & Load & Store format instruction with data hazard 

addi t0,zero,1025  // t0 = 1025
addi t1,zero,2     // t1 = 2
beq  t0,t1,8       // if t0 = t1, jump to insn(sb   t0,t1,1024)

addi t1,t0,4       // t1 = 1029 (t0 data hazard)
jal  zero,16       // jump to insn(sw   t2,t0,1028)

sb   t0,1024(t1)   // t0 --> [t1 + 1024] 
sh   t1,1028(t0)   // t1 --> [t0 + 1028]
lb   t2,1024(t1)   // [t1 + 1024] byte --> t2  
lh   t3,1028(t0)   // [t0 + 1028] half_word --> t3  

sw   t0,1028(t0)   // t0 --> [t0 + 1028] = 1025 --> [2053]
lbu  t1,1028(t0)   // [t0 + 1028] --> t1 = 1
lhu  t4,1028(t0)   // [t0 + 1028] --> t4 = 1
add  t3,t0,t1      // t3 = t0 + t1 = 1026  (t1 data hazard)
addi t2,zero,14    // t2 = 14

add  t4,t0,t2      // t4 = t0 + t2 = 1039  (t2 data hazard)
add  t0,t1,t3      // t0 = t1 + t3 = 1027  (t3 data hazard)