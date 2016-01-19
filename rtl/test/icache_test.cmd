iverilog -s icache_test -o icache_test.out -I ../../include icache_test.v icache.v L2_icache.v icache_ram.v
vvp icache_test.out