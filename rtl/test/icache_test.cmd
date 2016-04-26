iverilog -s icache_test -o icache_test.out -I include icache_test.v icache_ctrl.v l2_cache_ctrl.v cache_ram.v clk_2.v clk_4.v mem.v
vvp icache_test.out