iverilog -s dcache_mem_test -o dcache_mem_test.out -I include dcache_mem_test.v l2_cache_ctrl.v cache_ram.v ctrl.v mem_stage.v mem_ctrl.v mem_reg.v dcache_ctrl.v mem.v
vvp dcache_mem_test.out