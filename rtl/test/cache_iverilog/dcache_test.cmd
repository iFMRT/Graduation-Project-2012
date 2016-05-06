iverilog -s dcache_test -o dcache_test.out -I include dcache_test.v dcache_ctrl.v l2_cache_ctrl.v cache_ram.v mem.v
vvp dcache_test.out