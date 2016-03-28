iverilog -s icache_if_test -o icache_if_test.out -I include icache_if_test.v if_stage.v l2_cache_ctrl.v cache_ram.v ctrl.v
vvp icache_if_test.out