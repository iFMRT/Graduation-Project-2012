/**
 * filename: hart_ctrl.h
 * author  : besky
 * time    : 2016-05-17 23:19:28
 */

`ifndef __HMU_HEADER__
    `define __HMU_HEADER__			         // Include Guard
	
    `define HART_NUM_W               4
    `define HART_NUM_B               3:0
    `define HART_STATE_W             4
    `define HART_STATE_B             3:0
    `define HART_SST_W               2
    `define HART_SST_B               1:0
    `define HART_ID_W                2
    `define HART_ID_B                1:0
    `define HART_CYCLES_W            16
    `define HART_CYCLES_B            15:0
    `define HART_MAX_CYCLES          500

`endif

