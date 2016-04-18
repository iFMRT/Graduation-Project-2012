////////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com                  //
//                                                                    //
// Additional contributions by:                                       //
//                 Beyond Sky - fan-dave@163.com                      //
//                 Kippy Chen - 799182081@qq.com                      //
//                 Junhao Chang                                       //
//                                                                    //
// Design Name:    RISC-V processor core head files                   //
// Project Name:   FMRT Mini Core                                     //
// Language:       Verilog                                            //
//                                                                    //
// Description:    Defines for various constants used by the          //
//                 processor core .                                   //
//                                                                    //
////////////////////////////////////////////////////////////////////////

`ifndef _CORE_DEFINES
`define _CORE_DEFINES

////////////////////////////////////////////////
//    ___         ____          _             //
//   / _ \ _ __  / ___|___   __| | ___  ___   //
//  | | | | '_ \| |   / _ \ / _` |/ _ \/ __|  //
//  | |_| | |_) | |__| (_) | (_| |  __/\__ \  //
//   \___/| .__/ \____\___/ \__,_|\___||___/  //
//        |_|                                 //
////////////////////////////////////////////////
// NOP is addi x0, x0, 0
`define ISA_NOP         32'b0010011

`define ISA_OP_W		    7	           // OpCode's width

// I Type
`define ISA_OP_LOAD     7'b0000011   // Load Type
`define ISA_OP_ALSI		  7'b0010011   // Arithmetic Logic Shift Immediate
`define ISA_OP_JALR		  7'b1100111   // Jump And Link Register

// R Type
`define ISA_OP_ALS		  7'b0110011   // Arithmetic Logic Shift

// U Type
`define ISA_OP_LUI		  7'b0110111   // Load Upper Immediate
`define ISA_OP_AUIPC	  7'b0010111   // Add Upper Immediate to PC

// S Type
`define ISA_OP_STORE		7'b0100011   // STore

// B TYPE
// `DEFINE ISA_OP_BR		    7'b1100011   // BRANCH

// J TYPE
// `DEFINE ISA_OP_JAL		  7'b1101111   // JUMP AND LINK

/******** FUNCTION CODE 3 FIELD ********/
// `DEFINE ISA_FUNCT3_W	  3	         // FUNCT3'S WIDTH

// ISA_OP_LOAD
// `DEFINE ISA_OP_LOAD_LB	  3'b000	 // Load signed byte
`define ISA_OP_LOAD_LH	  3'b001	 // Load signed half word
`define ISA_OP_LOAD_LW	  3'b010	 // Load signed word
`define ISA_OP_LOAD_LBU	  3'b100	 // Load unsigned byte
`define ISA_OP_LOAD_LHU	  3'b101	 // Load unsigned half word

// ISA_OP_ALSI
`define ISA_OP_ALSI_ADDI  3'b000	 // Register-immediate addition
`define ISA_OP_ALSI_SLLI	3'b001	 // Shift left logical by a immediate
`define ISA_OP_ALSI_SRI	  3'b010	 // Shift right by a immediate
`define ISA_OP_ALSI_SLTI  3'b011	 // Set less than immediate
`define ISA_OP_ALSI_SLTIU 3'b100	 // Set less than unsigned immediate
`define ISA_OP_ALSI_XORI  3'b100	 // Register-immediate bitwise XOR
`define ISA_OP_ALSI_ORI	  3'b110	 // Register-immediate bitwise OR
`define ISA_OP_ALSI_ANDI  3'b111	 // Register-immediate bitwise AND

// ISA_OP_STORE
`define ISA_OP_STORE_SB	  3'b000	 // Store byte
`define ISA_OP_STORE_SH	  3'b001	 // Store half byte
`define ISA_OP_STORE_SW	  3'b010	 // Store word

// ISA_OP_ALS
`define ISA_OP_ALS_AS	    3'b000	 // Register-register addition subtrachtion
`define ISA_OP_ALS_SLL	  3'b001	 // Register-register Left Logical
`define ISA_OP_ALS_SR	    3'b010	 // Register-register shift right
`define ISA_OP_ALS_SLT	  3'b011	 // Register-register signed set less than
`define ISA_OP_ALS_SLTU	  3'b100	 // Register-register unsigned set less than
`define ISA_OP_ALS_XOR	  3'b101	 // Register-register bitwise XOR
`define ISA_OP_ALS_OR	    3'b110	 // Register-register bitwise OR
`define ISA_OP_ALS_AND	  3'b111	 // Register-register bitwise AND

// ISA_OP_BR
`define ISA_OP_BR_BEQ	    3'b000	 //Register-register branch if equal
`define ISA_OP_BR_BNE	    3'b001	 // Register-register branch if unequal
`define ISA_OP_BR_BLT	    3'b100	 // Register-register branch if less than signed
`define ISA_OP_BR_BGE	    3'b101	 // Register-register branch if greater than signed
`define ISA_OP_BR_BLTU	  3'b110	 // Register-register branch if less than unsigned
`define ISA_OP_BR_BGEU	  3'b111	 // Register-register branch if greater than unsigned

/******** FUNCTION CODE 7 FIELD ********/
`define ISA_Funct7_W	        7	         // Funct7's width

// ISA_OP_ALSI_SRI
`define ISA_OP_ALSI_SRI_SRLI	7'b0000000 // Register-immediate shift right logical
`define ISA_OP_ALSI_SRI_SRAI  7'b0100000 // Register-immediate shift right arithmetic
// ISA_OP_ALS_AS
`define ISA_OP_ALS_AS_ADD	    7'b0000000 // Register-register addition
`define ISA_OP_ALS_AS_SUB	    7'b0100000 // Register-register subtraction
// ISA_OP_ALS_SR
`define ISA_OP_ALS_SR_SRL	    7'b0000000 // Register-register shift right logical
`define ISA_OP_ALS_SR_SRA	    7'b0100000 // Register-register shift right arithmetic



`endif