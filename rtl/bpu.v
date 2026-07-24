`include "defines.v"

module bpu(
  input  wire        clk,
  input  wire        rst,
  input  wire[31:0] pc,
  input  wire[31:0] inst,

  input wire        ex_is_branch_i,
  input wire [31:0] ex_pc_i,
  input wire        ex_real_taken_i,

  input wire          ID_wr_tag   ,
  input wire          EX_wr_tag   ,
  input wire          MEM1_wr_tag ,
  input wire          MEM_wr_tag    ,
  input wire          WB_wr_tag   ,
  input wire[4:0]     ID_wr_addr    ,
  input wire[4:0]     EX_wr_addr    ,
  input wire[4:0]     MEM1_wr_addr ,
  input wire[4:0]     MEM_wr_addr   ,
  input wire[4:0]     WB_wr_addr    ,
  input wire[31:0]    EX_wr_data    ,
  input wire[31:0]    MEM1_wr_data ,
  input wire[31:0]    MEM_wr_data   ,
  input wire[31:0]    WB_wr_data    ,
  input wire[2:0]     rf_sel      , 
  input wire          MEM1_is_load,
  input wire          MEM_is_load,

  output reg        bpu_wait        ,  
  output wire       prdt_taken      ,
  output wire[31:0] prdt_pc_addr    ,

  output wire       bpu2rf_rs1_ena,
  output wire[4:0]  bpu2rf_rs1idx,
  input  wire[31:0] rf2bpu_rs1
  );

  // Lightweight IF-stage control-flow predecode.  Full instruction semantics
  // are decoded separately in id.v; this block only produces prediction data.
  wire [6:0] opcode = inst[6:0];
  wire dec_jal  = (opcode == `INST_JAL);
  wire dec_jalr = (opcode == `INST_JALR);
  wire dec_bxx  = (opcode == `INST_TYPE_B);
  wire [11:0] jalr_imm = inst[31:20];
  wire [31:0] dec_bjp_imm =
      dec_bxx  ? {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0} :
      dec_jal  ? {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0} :
      dec_jalr ? {{20{jalr_imm[11]}}, jalr_imm} :
                  32'b0;
  wire [4:0] dec_jalr_rs1idx = inst[19:15];

  reg [1:0] bht [15:0];
  wire [3:0] index        = pc[5:2];
  wire [3:0] update_index = ex_pc_i[5:2];
  integer i;

  always @(posedge clk) begin
      if(rst) begin
          for(i=0; i<16; i=i+1) begin
              bht[i] <= 2'b01; 
          end
      end else if(ex_is_branch_i) begin
          case(bht[update_index])
              2'b00: bht[update_index] <= (ex_real_taken_i) ? 2'b01 : 2'b00;
              2'b01: bht[update_index] <= (ex_real_taken_i) ? 2'b10 : 2'b00;
              2'b10: bht[update_index] <= (ex_real_taken_i) ? 2'b11 : 2'b01;
              2'b11: bht[update_index] <= (ex_real_taken_i) ? 2'b11 : 2'b10;
              default: bht[update_index] <= 2'b01;
          endcase
      end
  end

  assign prdt_taken = (dec_jal | dec_jalr | (dec_bxx & bht[index][1]));  

  wire forward;
  reg [31:0] forward_rs1;
  wire forward_ID_rD  = dec_jalr && ID_wr_tag && (dec_jalr_rs1idx == ID_wr_addr) && (ID_wr_addr != 5'b0);
  wire forward_EX_rD  = dec_jalr && EX_wr_tag && (dec_jalr_rs1idx == EX_wr_addr) && (EX_wr_addr != 5'b0);
  wire forward_MEM1_rD = dec_jalr && MEM1_wr_tag && (dec_jalr_rs1idx == MEM1_wr_addr) && (MEM1_wr_addr != 5'b0);
  wire forward_MEM_rD = dec_jalr && MEM_wr_tag && (dec_jalr_rs1idx == MEM_wr_addr) && (MEM_wr_addr != 5'b0);
  wire forward_WB_rD  = dec_jalr && WB_wr_tag && (dec_jalr_rs1idx == WB_wr_addr) && (WB_wr_addr != 5'b0);
  wire load_use_hazard = forward_EX_rD && (rf_sel != 3'b000);
  assign forward = forward_EX_rD || (forward_MEM1_rD && !MEM1_is_load) ||
                   (forward_MEM_rD && !MEM_is_load) || forward_WB_rD;

  always @(*) begin
      if(forward_EX_rD)          forward_rs1 = EX_wr_data;
      else if(forward_MEM1_rD && !MEM1_is_load)
                                  forward_rs1 = MEM1_wr_data;
      else if(forward_MEM_rD && !MEM_is_load)
                                  forward_rs1 = MEM_wr_data;
      else if(forward_WB_rD)     forward_rs1 = WB_wr_data;
      else                       forward_rs1 = 32'b0;
  end

  always @(*) begin
      if(load_use_hazard | forward_ID_rD |
         (forward_MEM1_rD && MEM1_is_load) |
         (forward_MEM_rD && MEM_is_load)) bpu_wait = 1'b1;
      else                                                                  bpu_wait = 1'b0;
  end

  wire dec_jalr_rs1x0 = (dec_jalr_rs1idx == 5'd0);
  wire dec_jalr_rs1xn = ~dec_jalr_rs1x0;
  assign bpu2rf_rs1_ena = dec_jalr & (~forward) & (~forward_ID_rD) & dec_jalr_rs1xn;
  assign bpu2rf_rs1idx = dec_jalr_rs1idx;
  wire [31:0] prdt_pc_base = (dec_bxx | dec_jal) ? pc
                            : (dec_jalr & dec_jalr_rs1x0) ? 32'b0
                            : (dec_jalr & dec_jalr_rs1xn & forward) ? forward_rs1
                            : rf2bpu_rs1;
  wire [31:0] prdt_pc_sum = prdt_pc_base + dec_bjp_imm;

  // RISC-V requires JALR targets to have bit 0 cleared.  Apply the rule on
  // the final sum; masking either operand separately is not equivalent.
  assign prdt_pc_addr = dec_jalr ? (prdt_pc_sum & 32'hffff_fffe)
                                 : prdt_pc_sum;

endmodule
