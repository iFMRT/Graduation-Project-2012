iverilog -s icache_test -o icache_test.out -I ../../include icache_test.v icache_ctrl.v L2_cache_ctrl.v icache_ram.v
vvp icache_test.out