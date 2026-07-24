module id_ex(
    input  wire             clk             ,
    input  wire             rst             ,
    input  wire[31:0]       inst_i          ,
    input  wire[31:0]       inst_addr_i     ,
    input  wire[4:0]        rs1_addr_i      ,
    input  wire[4:0]        rs2_addr_i      ,
    input  wire[31:0]       op1_i           ,
    input  wire[31:0]       op2_i           ,
    input  wire[4:0]        rd_addr_i       ,
    input  wire             reg_wen_i       ,
    input  wire[31:0]       base_addr_i     ,
    input  wire[31:0]       addr_offset_i   ,
    input  wire             datahazard_sel  ,
    input  wire             nop_from_hazard ,
    input  wire             hold_flag_i     ,
    input  wire             stall_i         ,
    input  wire             forward1        ,
    input  wire             forward2        ,
    input  wire[31:0]       forward_rD1     ,
    input  wire[31:0]       forward_rD2     ,
    input  wire[5:0]        alu_op_i        ,
    input  wire             is_mdu_i        ,
    input  wire[2:0]        mdu_op_i        ,
    input  wire             is_system_i     ,
    input  wire[3:0]        system_op_i     ,
    input  wire[11:0]       csr_addr_i      ,
    input  wire[4:0]        csr_zimm_i      ,
    input  wire             illegal_i       ,
    input  wire             is_branch_i     ,
    input  wire             is_jump_i       ,
    input  wire             is_load_i       ,
    input  wire             is_store_i      ,
    input  wire[2:0]        mem_width_i     ,
    
    output wire[31:0]       inst_o          ,
    output wire[31:0]       inst_addr_o     ,
    output wire[4:0]        rs1_addr_o      ,
    output wire[4:0]        rs2_addr_o      ,
    output reg[31:0]        op1_o           ,
    output reg[31:0]        op2_o           ,
    output wire[4:0]        rd_addr_o       ,  
    output wire             reg_wen_o       ,
    output reg[31:0]        base_addr_o     ,
    output wire[31:0]       addr_offset_o   ,
    output wire[5:0]        alu_op_o        ,
    output wire             is_mdu_o        ,
    output wire[2:0]        mdu_op_o        ,
    output wire             is_system_o     ,
    output wire[3:0]        system_op_o     ,
    output wire[11:0]       csr_addr_o      ,
    output wire[4:0]        csr_zimm_o      ,
    output wire             illegal_o       ,
    output wire             is_branch_o     ,
    output wire             is_jump_o       ,
    output wire             is_load_o       ,
    output wire             is_store_o      ,
    output wire[2:0]        mem_width_o     ,
    
    // bp ??
    input wire              prdt_taken_i    ,
    input wire[31:0]        prdt_pc_addr_i  ,  
    output wire             prdt_taken_o    ,
    output wire[31:0]       prdt_pc_addr_o  ,

    input wire              ex_jump_en_i
);

    wire flush_real = (hold_flag_i || nop_from_hazard || ex_jump_en_i)
                   && !stall_i;

    dff_set #(32) dff1(clk, rst, flush_real, 32'h0000_0013, stall_i ? inst_o : inst_i, inst_o);
    dff_set #(5)  dff2(clk, rst, flush_real, 5'b0,          stall_i ? rd_addr_o : rd_addr_i, rd_addr_o);
    dff_set #(1)  dff3(clk, rst, flush_real, 1'b0,          stall_i ? reg_wen_o : reg_wen_i, reg_wen_o);
    dff_set #(32) dff4(clk, rst, flush_real, 32'b0,         stall_i ? addr_offset_o : addr_offset_i, addr_offset_o);
    dff_set #(6)  dff5(clk, rst, flush_real, 6'b0,          stall_i ? alu_op_o : alu_op_i, alu_op_o);
    dff_set #(1)  dff_mdu0(clk, rst, flush_real, 1'b0,      stall_i ? is_mdu_o : is_mdu_i, is_mdu_o);
    dff_set #(3)  dff_mdu1(clk, rst, flush_real, 3'b0,      stall_i ? mdu_op_o : mdu_op_i, mdu_op_o);
    dff_set #(1)  dff_sys0(clk, rst, flush_real, 1'b0,      stall_i ? is_system_o : is_system_i, is_system_o);
    dff_set #(4)  dff_sys1(clk, rst, flush_real, `SYS_NONE, stall_i ? system_op_o : system_op_i, system_op_o);
    dff_set #(12) dff_sys2(clk, rst, flush_real, 12'b0,     stall_i ? csr_addr_o : csr_addr_i, csr_addr_o);
    dff_set #(5)  dff_sys3(clk, rst, flush_real, 5'b0,      stall_i ? csr_zimm_o : csr_zimm_i, csr_zimm_o);
    dff_set #(1)  dff_ill(clk, rst, flush_real, 1'b0,       stall_i ? illegal_o : illegal_i, illegal_o);
    dff_set #(1)  dff6(clk, rst, flush_real, 1'b0,          stall_i ? is_branch_o : is_branch_i, is_branch_o);
    dff_set #(1)  dff7(clk, rst, flush_real, 1'b0,          stall_i ? is_jump_o : is_jump_i, is_jump_o);
    dff_set #(1)  dff8(clk, rst, flush_real, 1'b0,          stall_i ? is_load_o : is_load_i, is_load_o);
    dff_set #(1)  dff9(clk, rst, flush_real, 1'b0,          stall_i ? is_store_o : is_store_i, is_store_o);
    dff_set #(3)  dffa(clk, rst, flush_real, 3'b0,          stall_i ? mem_width_o : mem_width_i, mem_width_o);
    dff_set #(5)  dffb(clk, rst, flush_real, 5'b0,          stall_i ? rs1_addr_o : rs1_addr_i, rs1_addr_o);
    dff_set #(5)  dffc(clk, rst, flush_real, 5'b0,          stall_i ? rs2_addr_o : rs2_addr_i, rs2_addr_o);
    dff_set #(1)  dff11(clk, rst, flush_real, 1'b0,         stall_i ? prdt_taken_o : prdt_taken_i, prdt_taken_o);
    dff_set #(32) dff12(clk, rst, flush_real, 32'b0,        stall_i ? prdt_pc_addr_o : prdt_pc_addr_i, prdt_pc_addr_o);
    dff_set #(32) dff13(clk, rst, flush_real, 32'b0,        stall_i ? inst_addr_o : inst_addr_i, inst_addr_o);

    always@(posedge clk) begin
        if(rst) begin
            op1_o <= 32'b0;
        end
        else if(stall_i) begin
            op1_o <= op1_o;
        end
        else if(forward1 && (!datahazard_sel)) begin
            op1_o <= forward_rD1;
        end
        else if(flush_real) begin 
            op1_o <= 32'b0;
        end
        else begin
            op1_o <= op1_i;
        end
    end
    
    always@(posedge clk) begin
        if(rst) begin
            base_addr_o <= 32'b0;
        end
        else if(stall_i) begin
            base_addr_o <= base_addr_o;
        end
        else if(forward1 && datahazard_sel) begin
            base_addr_o <= forward_rD1;
        end
        else if(flush_real) begin 
            base_addr_o <= 32'b0;
        end
        else begin
            base_addr_o <= base_addr_i;
        end
    end

    always@(posedge clk) begin
        if(rst) begin
            op2_o <= 32'b0;
        end
        else if(stall_i) begin
            op2_o <= op2_o;
        end
        else if(forward2) begin
            op2_o <= forward_rD2;
        end
        else if(flush_real) begin 
            op2_o <= 32'b0;
        end
        else begin
            op2_o <= op2_i;
        end
    end
endmodule

