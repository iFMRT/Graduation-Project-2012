////////////////////////////////////////////////////////////////////
// Engineer:       Leway Colin - colin4124@gmail.com              //
//                                                                //
// Additional contributions by:                                   //
//                 Beyond Sky - fan-dave@163.com                  //
//                 Kippy Chen - 799182081@qq.com                  //
//                 Junhao Chang                                   //
//                                                                //
// Design Name:    RISC-V processor core head files               //
// Project Name:   FMRT Mini Core                                 //
// Language:       Verilog                                        //
//                                                                //
// Description:    Defines for various constants used by the      //
//                 processor core .                               //
//                                                                //
////////////////////////////////////////////////////////////////////

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
`define OP_NOP      32'b0010011
`define OP_W		    7	           // OpCode's width

// I Type
`define OP_LD       7'b0000011   // Load Type
`define OP_ALSI		  7'b0010011   // Arithmetic Logic Shift Immediate
`define OP_JALR		  7'b1100111   // Jump And Link Register

// R Type
`define OP_ALS		  7'b0110011   // Arithmetic Logic Shift
`define OP_HART		  7'b0001011   // Hart Control

// U Type
`define OP_LUI		  7'b0110111   // Load Upper Immediate
`define OP_AUIPC	  7'b0010111   // Add Upper Immediate to PC

// S Type
`define OP_ST		    7'b0100011   // STore

// B TYPE
`define OP_BR		    7'b1100011   // BRANCH

// J TYPE
`define OP_JAL		  7'b1101111   // JUMP AND LINK

/******** FUNCTION CODE 3 FIELD ********/
`define OP_FUNCT3_W	3	           // FUNCT3'S WIDTH

// OP_LD
`define OP_LD_LB	  3'b000	 // Load signed byte
`define OP_LD_LH	  3'b001	 // Load signed half word
`define OP_LD_LW	  3'b010	 // Load signed word
`define OP_LD_LBU	  3'b100	 // Load unsigned byte
`define OP_LD_LHU	  3'b101	 // Load unsigned half word

// OP_ALSI
`define OP_ALSI_ADDI  3'b000 // Register-immediate addition
`define OP_ALSI_SLLI	3'b001 // Shift left logical by a immediate
`define OP_ALSI_SLTI  3'b010 // Set less than immediate
`define OP_ALSI_SLTIU 3'b011 // Set less than unsigned immediate
`define OP_ALSI_XORI  3'b100 // Register-immediate bitwise XOR
`define OP_ALSI_SRI	  3'b101 // Shift right by a immediate
`define OP_ALSI_ORI	  3'b110 // Register-immediate bitwise OR
`define OP_ALSI_ANDI  3'b111 // Register-immediate bitwise AND

// OP_ST
`define OP_ST_SB	    3'b000	 // Store byte
`define OP_ST_SH	    3'b001	 // Store half byte
`define OP_ST_SW	    3'b010	 // Store word

// OP_ALS
`define OP_ALS_AS	    3'b000	 // Register-register addition subtrachtion
`define OP_ALS_SLL	  3'b001	 // Register-register Left Logical
`define OP_ALS_SLT	  3'b010	 // Register-register signed set less than
`define OP_ALS_SLTU	  3'b011	 // Register-register unsigned set less than
`define OP_ALS_XOR	  3'b100	 // Register-register bitwise XOR
`define OP_ALS_SR	    3'b101	 // Register-register shift right
`define OP_ALS_OR	    3'b110	 // Register-register bitwise OR
`define OP_ALS_AND	  3'b111	 // Register-register bitwise AND

// OP_BR
`define OP_BR_BEQ	    3'b000	 //Register-register branch if equal
`define OP_BR_BNE	    3'b001	 // Register-register branch if unequal
`define OP_BR_BLT	    3'b100	 // Register-register branch if less than signed
`define OP_BR_BGE	    3'b101	 // Register-register branch if greater than signed
`define OP_BR_BLTU	  3'b110	 // Register-register branch if less than unsigned
`define OP_BR_BGEU	  3'b111	 // Register-register branch if greater than unsigned

// OP_HART
`define OP_HART_STA    3'b000    // hart start
`define OP_HART_STAC   3'b001    // current hart start
`define OP_HART_KILL   3'b010    // hart kill
`define OP_HART_KILLC  3'b011    // current hart kill
`define OP_HART_READ   3'b100    // read hart state
`define OP_HART_READA  3'b101    // read active hart state
`define OP_HART_READI  3'b110    // read idel   hart state

/******** FUNCTION CODE 7 FIELD ********/
`define OP_Funct7_W	      7	         // Funct7's width

// OP_ALSI_SRI
`define OP_ALSI_SRI_SRLI	7'b0000000 // Register-immediate shift right logical
`define OP_ALSI_SRI_SRAI  7'b0100000 // Register-immediate shift right arithmetic
// OP_ALS_AS
`define OP_ALS_AS_ADD	    7'b0000000 // Register-register addition
`define OP_ALS_AS_SUB	    7'b0100000 // Register-register subtraction
// OP_ALS_SR
`define OP_ALS_SR_SRL	    7'b0000000 // Register-register shift right logical
`define OP_ALS_SR_SRA	    7'b0100000 // Register-register shift right arithmetic

/******** FUNCTION CODE 12 FIELD ********/
`define OP_ECALL          12'b000000000000 // environment (system) call
`define OP_ERET           12'b000100000000

`define OP_SYSTEM         7'b1110011
/******** Exception ********/
`define EXP_ENTRY_ADDR    32'h2000

`define EXP_CODE_BUS      5:0   // Exception code bus
`define EXP_CODE_W	      6     // Exception code width

`define EXP_NO_EXP	      3'h0	 // No exception
`define EXP_EXT_INT	      3'h1	 // External interrupt
`define EXP_ILLEGAL_INSN  3'h2	 // Illegal instruction
`define EXP_MISS_ALIGN    3'h3	 // MEM address miss align


//////////////////////// ////////////////////////////////////
//   ____ ____    ____            _     _                  //
//  / ___/ ___|  |  _ \ ___  __ _(_)___| |_ ___ _ __ ___   //
// | |   \___ \  | |_) / _ \/ _` | / __| __/ _ \ '__/ __|  //
// | |___ ___) | |  _ <  __/ (_| | \__ \ ||  __/ |  \__ \  //
//  \____|____/  |_| \_\___|\__, |_|___/\__\___|_|  |___/  //
//                          |___/                          //
/////////////////////////////////////////////////////////////

// CSR operations
`define CSR_OP_BUS     1:0   // CSRs operation bus
`define CSR_OP_NOP     2'b00
`define CSR_OP_WRITE   2'b01
`define CSR_OP_SET     2'b10
`define CSR_OP_CLEAR   2'b11

`define CSR_ADDR_BUS   11:0  // CSRs address bus
`define CSR_ADDR_W     12    // CSRs address bus


///////////////////////////////////////////////
//  _______  __  ____  _                     //
// | ____\ \/ / / ___|| |_ __ _  __ _  ___   //
// |  _|  \  /  \___ \| __/ _` |/ _` |/ _ \  //
// | |___ /  \   ___) | || (_| | (_| |  __/  //
// |_____/_/\_\ |____/ \__\__,_|\__, |\___|  //
//                              |___/        //
///////////////////////////////////////////////

`define EX_OUT_SEL_W      2
`define EX_OUT_SEL_BUS    1:0

`define EX_OUT_ALU        2'b00
`define EX_OUT_CMP        2'b01
`define EX_OUT_PCN        2'b10

// ALU
`define ALU_OP_NOP        4'h0
`define ALU_OP_AND        4'h1
`define ALU_OP_OR         4'h2
`define ALU_OP_XOR        4'h3
`define ALU_OP_SLL        4'h4
`define ALU_OP_SRL        4'h5
`define ALU_OP_SRA        4'h6
`define ALU_OP_ADD        4'h7
`define ALU_OP_SUB        4'h8

`define ALU_OP_W          4
`define ALU_OP_BUS        3:0

// CMP
`define CMP_OP_NOP        3'o0       // option: nop
`define CMP_OP_EQ         3'o1       // option: ==  equal
`define CMP_OP_NE         3'o2       // option: !=  not equal
`define CMP_OP_LT         3'o3       // option: <   lower than
`define CMP_OP_LTU        3'o4       // option: <u  lower than unsigned
`define CMP_OP_GE         3'o5       // option: >=  greater equal
`define CMP_OP_GEU        3'o6       // option: >=u greater equal unsigned

`define CMP_OP_W          3          // option width
`define CMP_OP_BUS        2:0        // option bus

`define CMP_TRUE          1'b1       // compare result: true
`define CMP_FALSE         1'b0       // compare result: false


///////////////////////////////////////////////
//  ____            _     _                  //
// |  _ \ ___  __ _(_)___| |_ ___ _ __ ___   //
// | |_) / _ \/ _` | / __| __/ _ \ '__/ __|  //
// |  _ <  __/ (_| | \__ \ ||  __/ |  \__ \  //
// |_| \_\___|\__, |_|___/\__\___|_|  |___/  //
//            |___/                          //
///////////////////////////////////////////////

`define REG_NUM_BUS     31:0     // Numbers of general purpose registers
`define REG_ADDR_W			5	       // Register address width
`define REG_ADDR_BUS		4:0      // Register address bus

/////////////////////////////////////////////////////
//   ____            _             _ _             //
//  / ___|___  _ __ | |_ _ __ ___ | | | ___ _ __   //
// | |   / _ \| '_ \| __| '__/ _ \| | |/ _ \ '__|  //
// | |__| (_) | | | | |_| | | (_) | | |  __/ |     //
//  \____\___/|_| |_|\__|_|  \___/|_|_|\___|_|     //
// 												                         //
/////////////////////////////////////////////////////

// Instruction various field width
`define INSN_OP				6:0
`define INSN_RS1			19:15
`define INSN_RS2			24:20
`define INSN_RD				11:7
`define INSN_F3				14:12
`define INSN_F7				31:25
`define INSN_F12      31:20
`define INSN_CSR      31:20
`define INSN_OP_BUS		6:0
`define INSN_F3_BUS		2:0
`define INSN_F7_BUS		6:0
`define INSN_F12_BUS	11:0

`define FWD_CTRL_BUS  1:0
`define FWD_CTRL_NONE 2'h0
`define FWD_CTRL_EX 	2'h1
`define FWD_CTRL_MEM 	2'h2

////////////////////////////////////////////////////////
//  __  __ _____ __  __   ____  _                     //
// |  \/  | ____|  \/  | / ___|| |_ __ _  __ _  ___   //
// | |\/| |  _| | |\/| | \___ \| __/ _` |/ _` |/ _ \  //
// | |  | | |___| |  | |  ___) | || (_| | (_| |  __/  //
// |_|  |_|_____|_|  |_| |____/ \__\__,_|\__, |\___|  //
//                                       |___/        //
////////////////////////////////////////////////////////

`define MEM_OP_BUS 		3:0 			// mem_op width

// NOP  : 0000
// STORE: 01XX
// LOAD : 1XXX
`define MEM_OP_NOP 		4'b0000
`define MEM_OP_SB			4'b0100
`define MEM_OP_SH			4'b0101
`define MEM_OP_SW			4'b0110
`define MEM_OP_LB 		4'b1000
`define MEM_OP_LH			4'b1001
`define MEM_OP_LW			4'b1010
`define MEM_OP_LBU		4'b1011
`define MEM_OP_LHU		4'b1100

`define WORD_ADDR_LOC           31:2  // Address location

`define BYTE_OFFSET_BUS         1:0   // Byte offset bus
`define BYTE_OFFSET_LOC         1:0   // Byte offset location
`define BYTE_OFFSET_WORD        2'b00 // Word offset

// byte choose
`define BYTE0 			  2'b00
`define BYTE1			    2'b01
`define BYTE2			    2'b10
`define BYTE3			    2'b11

///////////////////////////
//  ____  ____  __  __   //
// / ___||  _ \|  \/  |  //
// \___ \| |_) | |\/| |  //
//  ___) |  __/| |  | |  //
// |____/|_|   |_|  |_|  //
// 						           //
///////////////////////////


/*
 *   SPM Size:   16384 Byte (16KB)
 *	 SPM_DEPTH:  16384 (Byte Address)
 *	 SPM_ADDR_W: log2(4096) = 12
 */

`define SPM_SIZE     16384   // 16384Byte（16KB）
`define SPM_DEPTH    16384	 // SPM depth
`define SPM_ADDR_W   12	     // Address width
`define SPM_ADDR_BUS 11:0	 // Address bus
`define SPM_ADDR_LOC 11:0	 // Address location

`endif