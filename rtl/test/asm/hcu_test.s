########################################
#
# filename: hcu_test.s
# date: 2016-05-31 17:11:57
# author: besky
#
#########################################

addi x1, zero, 1      # x1(hart_id) = 01
addi x2, zero, 128    # x2(pc) = 128
# hs   x3, x1  , x2     # start hart
# hkc                   # kill current hart

