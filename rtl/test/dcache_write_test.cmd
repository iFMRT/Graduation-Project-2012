iverilog -s dcache_write_test -o dcache_write_test.out -I include dcache_write_test.v dcache_ctrl.v l2_cache_ctrl.v cache_ram.v
vvp dcache_write_test.out