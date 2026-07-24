`include "defines.v"

module ex(
    input  wire       clk,
    input  wire       rst,
    input  wire[31:0] inst_i,
    input  wire[31:0] inst_addr_i,
    input  wire[31:0] op1_i,
    input  wire[31:0] op2_i,
    input  wire[4:0]  rd_addr_i,
    input  wire       reg_wen_i,
    input wire[31:0]  base_addr_i,
    input wire[31:0]  addr_offset_i,
    input wire[5:0]   alu_op_i,
    input wire        is_mdu_i,
    input wire[2:0]   mdu_op_i,
    input wire        is_system_i,
    input wire[3:0]   system_op_i,
    input wire[11:0]  csr_addr_i,
    input wire[4:0]   csr_zimm_i,
    input wire        illegal_i,
    input wire        is_branch_i,
    input wire        is_load_i,
    input wire        is_store_i,
    input wire        is_jump_i,
    input wire[2:0]   mem_width_i,   
    output reg[31:0]  rd_data_o,
    output wire[4:0]  rd_addr_o,
    output wire       rd_wen_o,
    output wire[31:0] real_jump_addr_o,
    output wire       real_jump_en_o,
    output wire       mdu_stall_o,
    
    output reg        mem_rd_req, 
    output reg[31:0]  mem_rd_addr,
    output reg[31:0]  mem_wr_data_o,
    output reg[1:0]   mem_mask,
    output reg[2:0]   sel,

    input wire        prdt_taken_i,
    input wire[31:0] prdt_pc_addr_i,

    output wire        ex_is_bxx_o,    
    output wire [31:0] ex_pc_o,         
    output wire        ex_real_taken_o  
);
    reg[31:0]  jump_addr_o;
    reg        jump_en_o;  
    function [31:0] xperm4_32;
        input [31:0] a;
        input [31:0] b;
        integer j;
        reg [3:0] idx;
        begin
            xperm4_32 = 32'd0;
            for (j = 0; j < 8; j = j + 1) begin
                idx = b[j*4 +: 4];
                xperm4_32[j*4 +: 4] = (idx < 4'd8) ? ((a >> ({3'd0, idx} << 2)) & 4'hf) : 4'd0;
            end
        end
    endfunction

    wire [31:0] mdu_result;
    wire [31:0] csr_read_value;
    wire system_redirect;
    wire [31:0] system_redirect_pc;
    wire illegal_csr;
    wire mdu_busy;
    wire mdu_done;
    wire mdu_start = is_mdu_i && !mdu_busy && !mdu_done;
    assign mdu_stall_o = is_mdu_i && !mdu_done;
    mdu mdu_inst(
        .clk(clk), .rst(rst), .start(mdu_start), .op(mdu_op_i),
        .src1(op1_i), .src2(op2_i), .result(mdu_result),
        .busy(mdu_busy), .done(mdu_done)
    );
    csr_unit csr_inst(
        .clk(clk), .rst(rst), .valid(is_system_i), .op(system_op_i),
        .addr(csr_addr_i), .rs1_value(op1_i), .zimm(csr_zimm_i),
        .pc(inst_addr_i), .decoded_illegal(illegal_i),
        .read_value(csr_read_value), .redirect(system_redirect),
        .redirect_pc(system_redirect_pc), .illegal_csr(illegal_csr)
    );

    wire is_any_jump = is_branch_i | is_jump_i;

    assign ex_is_bxx_o     = is_branch_i;
    assign ex_pc_o         = inst_addr_i;
    assign ex_real_taken_o = (is_branch_i) ? jump_en_o : 1'b0;

    wire branch_target_miss = is_any_jump && jump_en_o && prdt_taken_i &&
                              (jump_addr_o != prdt_pc_addr_i);
    wire branch_redirect = is_any_jump &&
                           ((jump_en_o != prdt_taken_i) || branch_target_miss);
    assign real_jump_en_o = system_redirect | branch_redirect;

    assign  real_jump_addr_o = system_redirect ? system_redirect_pc :
                               (!branch_redirect) ? 32'b0 :
                               jump_en_o ? jump_addr_o : (inst_addr_i + 4);

    assign  rd_wen_o  = reg_wen_i & ~illegal_i & ~illegal_csr &
                        (!is_mdu_i || mdu_done);
    assign  rd_addr_o = rd_addr_i;

    always @(*) begin
        if (is_mdu_i)
            rd_data_o = mdu_result;
        else if (is_system_i)
            rd_data_o = csr_read_value;
        else case(alu_op_i)
            `ALU_ADD:  rd_data_o = op1_i + op2_i;
            `ALU_SUB:  rd_data_o = op1_i - op2_i;
            `ALU_SLL:  rd_data_o = op1_i << op2_i[4:0];
            `ALU_SLT:  rd_data_o = {31'b0, ($signed(op1_i) < $signed(op2_i))};
            `ALU_SLTU: rd_data_o = {31'b0, (op1_i < op2_i)};
            `ALU_XOR:  rd_data_o = op1_i ^ op2_i;
            `ALU_SRL:  rd_data_o = op1_i >> op2_i[4:0];
            `ALU_SRA:  rd_data_o = $signed(op1_i) >>> op2_i[4:0];
            `ALU_OR:   rd_data_o = op1_i | op2_i;
            `ALU_AND:  rd_data_o = op1_i & op2_i;
            `ALU_LUI:  rd_data_o = op1_i;
            `ALU_XPERM4: rd_data_o = xperm4_32(op1_i, op2_i);
            default:   rd_data_o = 32'b0;
        endcase
    end

    always @(*) begin
        jump_en_o = 1'b0;
        jump_addr_o = 32'b0;
        mem_rd_req = 1'b0;
        mem_rd_addr = 32'b0;
        mem_wr_data_o = 32'b0;
        mem_mask = 2'b0;
        sel = 3'b000;

        if (is_branch_i) begin
            case(mem_width_i) 
                3'b000: jump_en_o = (op1_i == op2_i);      // beq
                3'b001: jump_en_o = (op1_i != op2_i);      // bne
                3'b100: jump_en_o = ($signed(op1_i) < $signed(op2_i));  // blt
                3'b101: jump_en_o = !($signed(op1_i) < $signed(op2_i)); // bge
                3'b110: jump_en_o = (op1_i < op2_i);        // bltu
                3'b111: jump_en_o = !(op1_i < op2_i);       // bgeu
                default: jump_en_o = 1'b0;
            endcase
            jump_addr_o = base_addr_i + addr_offset_i;
        end else if (is_jump_i) begin
            jump_en_o = 1'b1;
            jump_addr_o = (inst_i[6:0] == `INST_JALR) ?
                          ((base_addr_i + addr_offset_i) & 32'hffff_fffe) :
                          (base_addr_i + addr_offset_i);
        end else if (is_load_i) begin
            mem_rd_addr   = base_addr_i + addr_offset_i;
            mem_mask      = mem_width_i[1:0];
            sel           = mem_width_i;
        end else if (is_store_i) begin
            mem_rd_addr   = base_addr_i + addr_offset_i;
            mem_rd_req    = 1'b1;
            mem_wr_data_o = op2_i;
            mem_mask      = mem_width_i[1:0];
        end
    end

endmodule

