`include "defines.v"

module id(
    input wire[31:0] inst_i,
    input wire[31:0] inst_addr_i,
    output reg[4:0]  rs1_addr_o,
    output reg[4:0]  rs2_addr_o,
    input wire[31:0] rs1_data_i,
    input wire[31:0] rs2_data_i,
    output reg       datahazard_sel,
    output reg[31:0] inst_o,
    output reg[31:0] op1_o,
    output reg[31:0] op2_o,
    output reg[4:0]  rd_addr_o,
    output reg       reg_wen_o,
    output reg[31:0] base_addr_o,
    output reg[31:0] addr_offset_o,
    output reg[5:0]  alu_op_o,
    output reg       is_mdu_o,
    output reg[2:0]  mdu_op_o,
    output reg       is_system_o,
    output reg[3:0]  system_op_o,
    output reg[11:0] csr_addr_o,
    output reg[4:0]  csr_zimm_o,
    output reg       illegal_o,
    output reg       is_branch_o,
    output reg       is_jump_o,
    output reg       is_load_o,
    output reg       is_store_o,
    output reg[2:0]  mem_width_o
);

    wire[6:0] opcode;
    wire[4:0] rd;
    wire[2:0] func3;
    wire[4:0] rs1;
    wire[11:0] imm;
    wire[6:0] func7;
    wire[4:0] rs2;
    wire[4:0] shamt;

    assign opcode = inst_i[6:0];
    assign rd = inst_i[11:7];
    assign func3 = inst_i[14:12];
    assign rs1 = inst_i[19:15];
    assign rs2 = inst_i[24:20];
    assign imm = inst_i[31:20];
    assign func7 = inst_i[31:25];
    assign shamt = inst_i[24:20];

    wire is_R_type = (opcode == `INST_TYPE_R_M);
    wire is_I_type = (opcode == `INST_TYPE_I);
    wire is_L_type = (opcode == `INST_TYPE_L);
    wire is_S_type = (opcode == `INST_TYPE_S);
    wire is_B_type = (opcode == `INST_TYPE_B);
    wire is_JAL    = (opcode == `INST_JAL);
    wire is_JALR   = ((opcode == `INST_JALR) && (func3 == 3'b000));
    wire is_LUI    = (opcode == `INST_LUI);
    wire is_AUIPC  = (opcode == `INST_AUIPC);
    wire is_SYSTEM = (opcode == 7'b1110011);

    task decode_imm_op;
        input [5:0] alu_op;
        begin
            rs1_addr_o = rs1;
            op1_o = rs1_data_i;
            op2_o = {27'b0, shamt};
            rd_addr_o = rd;
            reg_wen_o = 1'b1;
            alu_op_o = alu_op;
        end
    endtask

    task decode_reg_op;
        input [5:0] alu_op;
        begin
            rs1_addr_o = rs1;
            rs2_addr_o = rs2;
            op1_o = rs1_data_i;
            op2_o = rs2_data_i;
            rd_addr_o = rd;
            reg_wen_o = 1'b1;
            alu_op_o = alu_op;
        end
    endtask

    always @(*) begin
        inst_o = inst_i;
        datahazard_sel = 1'b0;
        is_branch_o = 1'b0;
        is_jump_o = 1'b0;
        is_load_o = 1'b0;
        is_store_o = 1'b0;
        reg_wen_o = 1'b0;
        mem_width_o = func3;
        
        rs1_addr_o = 5'b0;
        rs2_addr_o = 5'b0;
        op1_o = 32'b0;
        op2_o = 32'b0;
        rd_addr_o = 5'b0;
        base_addr_o = 32'b0;
        addr_offset_o = 32'b0;
        alu_op_o = 6'b0;
        is_mdu_o = 1'b0;
        mdu_op_o = 3'b0;
        is_system_o = 1'b0;
        system_op_o = `SYS_NONE;
        csr_addr_o = inst_i[31:20];
        csr_zimm_o = inst_i[19:15];
        illegal_o = 1'b0;

        // I-type
        if (is_I_type) begin
            rs1_addr_o = rs1;
            op1_o = rs1_data_i;
            rd_addr_o = rd;
            reg_wen_o = 1'b1;
            
            case(func3)
                3'b000: begin // ADDI
                    op2_o = {{20{imm[11]}}, imm};
                    alu_op_o = `ALU_ADD;
                end
                3'b010: begin // SLTI
                    op2_o = {{20{imm[11]}}, imm};
                    alu_op_o = `ALU_SLT;
                end
                3'b011: begin // SLTIU
                    op2_o = {{20{imm[11]}}, imm};
                    alu_op_o = `ALU_SLTU;
                end
                3'b100: begin // XORI
                    op2_o = {{20{imm[11]}}, imm};
                    alu_op_o = `ALU_XOR;
                end
                3'b110: begin // ORI
                    op2_o = {{20{imm[11]}}, imm};
                    alu_op_o = `ALU_OR;
                end
                3'b111: begin // ANDI
                    op2_o = {{20{imm[11]}}, imm};
                    alu_op_o = `ALU_AND;
                end
                3'b001: begin // SLLI
                    if (func7 == 7'b0000000) begin
                        decode_imm_op(`ALU_SLL);
                    end else begin reg_wen_o = 1'b0; illegal_o = 1'b1; end
                end
                3'b101: begin // SRLI/SRAI
                    if ((func7 == 7'b0000000) || (func7 == 7'b0100000)) begin
                        decode_imm_op(func7[5] ? `ALU_SRA : `ALU_SRL);
                    end else begin reg_wen_o = 1'b0; illegal_o = 1'b1; end
                end
                default: begin reg_wen_o = 1'b0; illegal_o = 1'b1; end
            endcase
        end
        // R-type
        else if (is_R_type && (func7 == 7'b0000001)) begin
            rs1_addr_o = rs1;
            rs2_addr_o = rs2;
            op1_o = rs1_data_i;
            op2_o = rs2_data_i;
            rd_addr_o = rd;
            reg_wen_o = 1'b1;
            is_mdu_o = 1'b1;
            mdu_op_o = func3;
        end
        else if (is_R_type) begin
            if ((func7 == 7'h14) && (func3 == 3'b010)) begin
                decode_reg_op(`ALU_XPERM4);
            end else if ((func7 == 7'b0000000) ||
                         ((func7 == 7'b0100000) &&
                          ((func3 == 3'b000) || (func3 == 3'b101)))) begin
                case(func3)
                    3'b000: decode_reg_op(func7[5] ? `ALU_SUB : `ALU_ADD);
                    3'b001: decode_reg_op(`ALU_SLL);
                    3'b010: decode_reg_op(`ALU_SLT);
                    3'b011: decode_reg_op(`ALU_SLTU);
                    3'b100: decode_reg_op(`ALU_XOR);
                    3'b101: decode_reg_op(func7[5] ? `ALU_SRA : `ALU_SRL);
                    3'b110: decode_reg_op(`ALU_OR);
                    3'b111: decode_reg_op(`ALU_AND);
                endcase
            end else begin
                illegal_o = 1'b1;
            end
        end
        // B-type
        else if (is_B_type) begin
            is_branch_o = 1'b1;
            rs1_addr_o = rs1;
            rs2_addr_o = rs2;
            op1_o = rs1_data_i;
            op2_o = rs2_data_i;
            base_addr_o = inst_addr_i;
            addr_offset_o = {{19{inst_i[31]}}, inst_i[31], inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0};
            if (!((func3 == 3'b000) || (func3 == 3'b001) ||
                  (func3 == 3'b100) || (func3 == 3'b101) ||
                  (func3 == 3'b110) || (func3 == 3'b111))) begin
                is_branch_o = 1'b0;
                illegal_o = 1'b1;
            end
        end
        // JAL
        else if (is_JAL) begin
            is_jump_o = 1'b1;
            reg_wen_o = 1'b1;
            op1_o = inst_addr_i;
            op2_o = 32'h4;
            rd_addr_o = rd;
            base_addr_o = inst_addr_i;
            addr_offset_o = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
            alu_op_o = `ALU_ADD;
        end
        // LUI
        else if (is_LUI) begin
            reg_wen_o = 1'b1;
            op1_o = {inst_i[31:12], 12'b0};
            rd_addr_o = rd;
            alu_op_o = `ALU_LUI;
        end
        // AUIPC
        else if (is_AUIPC) begin
            reg_wen_o = 1'b1;
            op1_o = inst_addr_i;
            op2_o = {inst_i[31:12], 12'b0};
            rd_addr_o = rd;
            alu_op_o = `ALU_ADD;
        end
        // JALR
        else if (is_JALR) begin
            is_jump_o = 1'b1;
            datahazard_sel = 1'b1;
            reg_wen_o = 1'b1;
            rs1_addr_o = rs1;
            op1_o = inst_addr_i;
            op2_o = 32'h4;
            rd_addr_o = rd;
            base_addr_o = rs1_data_i;
            addr_offset_o = {{20{imm[11]}}, imm};
            alu_op_o = `ALU_ADD;
        end
        // Load
        else if (is_L_type) begin
            is_load_o = 1'b1;
            datahazard_sel = 1'b1;
            reg_wen_o = 1'b1;
            rs1_addr_o = rs1;
            rd_addr_o = rd;
            base_addr_o = rs1_data_i;
            addr_offset_o = {{20{imm[11]}}, imm};
            if (!((func3 == `INST_LB) || (func3 == `INST_LH) ||
                  (func3 == `INST_LW) || (func3 == `INST_LBU) ||
                  (func3 == `INST_LHU))) begin
                is_load_o = 1'b0; reg_wen_o = 1'b0; illegal_o = 1'b1;
            end
        end
        // Store
        else if (is_S_type) begin
            is_store_o = 1'b1;
            datahazard_sel = 1'b1;
            rs1_addr_o = rs1;
            rs2_addr_o = rs2;
            op2_o = rs2_data_i;
            base_addr_o = rs1_data_i;
            addr_offset_o = {{20{inst_i[31]}}, inst_i[31:25], inst_i[11:7]};
            if (!((func3 == `INST_SB) || (func3 == `INST_SH) ||
                  (func3 == `INST_SW))) begin
                is_store_o = 1'b0; illegal_o = 1'b1;
            end
        end

        else if ((opcode == `INST_FENCE) &&
                 ((func3 == 3'b000) || (func3 == 3'b001))) begin
            // Keep all default control outputs deasserted.
        end
        else if (inst_i == `INST_EBREAK) begin
            // Competition-profile policy: treat EBREAK as a no-side-effect NOP.
            // In particular, do not raise illegal-instruction or trap redirect.
        end
        else if (is_SYSTEM) begin
            is_system_o = 1'b1;
            if (inst_i == `INST_ECALL) begin
                system_op_o = `SYS_ECALL;
            end else if (inst_i == `INST_MRET) begin
                system_op_o = `SYS_MRET;
            end else begin
                case (func3)
                    3'b001, 3'b010, 3'b011: begin
                        system_op_o = {1'b0, func3};
                        rs1_addr_o = rs1;
                        op1_o = rs1_data_i;
                        rd_addr_o = rd;
                        reg_wen_o = 1'b1;
                    end
                    3'b101, 3'b110, 3'b111: begin
                        system_op_o = {1'b0, func3};
                        rd_addr_o = rd;
                        reg_wen_o = 1'b1;
                    end
                    default: begin
                        is_system_o = 1'b0;
                        illegal_o = 1'b1;
                    end
                endcase
            end
        end
        else if (inst_i != `INST_NOP) begin
            illegal_o = 1'b1;
        end
    end
endmodule


