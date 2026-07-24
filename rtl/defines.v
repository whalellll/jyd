// I type inst
`define INST_TYPE_I 7'b0010011
`define INST_ADDI   3'b000
`define INST_SLTI   3'b010
`define INST_SLTIU  3'b011
`define INST_XORI   3'b100
`define INST_ORI    3'b110
`define INST_ANDI   3'b111
`define INST_SLLI   3'b001
`define INST_SRI    3'b101

// L type inst
`define INST_TYPE_L 7'b0000011
`define INST_LB     3'b000
`define INST_LH     3'b001
`define INST_LW     3'b010
`define INST_LBU    3'b100
`define INST_LHU    3'b101

// S type inst
`define INST_TYPE_S 7'b0100011
`define INST_SB     3'b000
`define INST_SH     3'b001
`define INST_SW     3'b010

// R and M type inst
`define INST_TYPE_R_M 7'b0110011
// R type inst
`define INST_ADD_SUB 3'b000
`define INST_SLL    3'b001
`define INST_SLT    3'b010
`define INST_SLTU   3'b011
`define INST_XOR    3'b100
`define INST_z     3'b101
`define INST_OR     3'b110
`define INST_AND    3'b111
// M type inst
`define INST_MUL    3'b000
`define INST_MULH   3'b001
`define INST_MULHSU 3'b010
`define INST_MULHU  3'b011
`define INST_DIV    3'b100
`define INST_DIVU   3'b101
`define INST_REM    3'b110
`define INST_REMU   3'b111

// J type inst
`define INST_JAL    7'b1101111
`define INST_JALR   7'b1100111

`define INST_LUI    7'b0110111
`define INST_AUIPC  7'b0010111
`define INST_NOP    32'h00000013
`define INST_NOP_OP 7'b0000001
`define INST_MRET   32'h30200073
`define INST_RET    32'h00008067

`define INST_FENCE  7'b0001111
`define INST_ECALL  32'h73
`define INST_EBREAK 32'h00100073

// J type inst
`define INST_TYPE_B 7'b1100011
`define INST_BEQ    3'b000
`define INST_BNE    3'b001
`define INST_BLT    3'b100
`define INST_BGE    3'b101
`define INST_BLTU   3'b110
`define INST_BGEU   3'b111
`define ALU_ADD     6'd0
`define ALU_SUB     6'd1
`define ALU_SLL     6'd2
`define ALU_SLT     6'd3
`define ALU_SLTU    6'd4
`define ALU_XOR     6'd5
`define ALU_SRL     6'd6
`define ALU_SRA     6'd7
`define ALU_OR      6'd8
`define ALU_AND     6'd9
`define ALU_LUI     6'd10

// Competition-added Zbkx instruction
`define ALU_XPERM4  6'd48

// RV32M operation codes (funct3-compatible)
`define MDU_MUL     3'b000
`define MDU_MULH    3'b001
`define MDU_MULHSU  3'b010
`define MDU_MULHU   3'b011
`define MDU_DIV     3'b100
`define MDU_DIVU    3'b101
`define MDU_REM     3'b110
`define MDU_REMU    3'b111

// Zicsr / privileged operation codes
`define SYS_NONE    4'd0
`define SYS_CSRRW   4'd1
`define SYS_CSRRS   4'd2
`define SYS_CSRRC   4'd3
`define SYS_CSRRWI  4'd5
`define SYS_CSRRSI  4'd6
`define SYS_CSRRCI  4'd7
`define SYS_ECALL   4'd8
`define SYS_MRET    4'd9

`define CSR_MSTATUS  12'h300
`define CSR_MTVEC    12'h305
`define CSR_MSCRATCH 12'h340
`define CSR_MEPC     12'h341
`define CSR_MCAUSE   12'h342


