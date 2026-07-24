`include "defines.v"

module myCPU (
    input  wire           cpu_clk,
    input  wire           cpu_rst,
    input  wire[31:0]    irom_data,
    output wire[31:0]    irom_addr,
    //interface to ram
    output wire[31:0]    perip_addr,            
    output wire          perip_wen,             
    output wire[1:0]     perip_mask,          
    output wire[31:0]    perip_wdata,           
    input  wire[31:0]    perip_rdata
);

    //pc to rom
    wire[31:0] pc_reg_pc_o;
    

    //if to if_id
    wire[31:0] if_inst_addr_o;
    wire[31:0] if_inst_o;


    //if_id to id
    wire[31:0] if_id_inst_addr_o;
    wire[31:0] if_id_inst_o; 

    //id to regs
    wire[4:0] id_rs1_addr_o;
    wire[4:0] id_rs2_addr_o;

    //id to id_Ex
    wire[31:0] id_inst_o;
    wire[31:0] id_inst_addr_o;
    wire[31:0] id_op1_o;
    wire[31:0] id_op2_o;
    wire [4:0] id_rd_addr_o;
    wire       id_reg_wen;
    wire[31:0] id_base_addr_o;
    wire[31:0] id_addr_offset_o;
    wire[5:0]  id_alu_op_o   ;
    wire id_is_mdu_o, id_is_system_o, id_illegal_o;
    wire[2:0] id_mdu_op_o;
    wire[3:0] id_system_op_o;
    wire[11:0] id_csr_addr_o;
    wire[4:0] id_csr_zimm_o;
    wire       id_is_branch_o;
    wire       id_is_jump_o  ;
    wire       id_is_load_o  ;
    wire       id_is_store_o ;
    wire[2:0]  id_mem_width_o;

    //regs to id
    wire[31:0] regs_reg1_rdata_o;
    wire[31:0] regs_reg2_rdata_o;

    //id_ex to ex
    wire[31:0] id_ex_inst_o;
    wire[31:0] id_ex_inst_addr_o;
    wire[4:0]  id_ex_rs1_addr_o;
    wire[4:0]  id_ex_rs2_addr_o;
    wire[31:0] id_ex_op1_o;
    wire[31:0] id_ex_op2_o;
    wire[4:0]  id_ex_rd_addr_o;
    wire       id_ex_reg_wen;
    wire[31:0] id_ex_base_addr_o;
    wire[31:0] id_ex_addr_offset_o;
    wire       id_ex_mem_rd_req_o;
    wire[31:0] id_ex_mem_rd_addr_o;
    wire[5:0]  id_ex_alu_op_o;
    wire id_ex_is_mdu_o, id_ex_is_system_o, id_ex_illegal_o;
    wire[2:0] id_ex_mdu_op_o;
    wire[3:0] id_ex_system_op_o;
    wire[11:0] id_ex_csr_addr_o;
    wire[4:0] id_ex_csr_zimm_o;
    wire       id_ex_is_branch_o;
    wire       id_ex_is_jump_o  ;
    wire       id_ex_is_load_o  ;
    wire       id_ex_is_store_o ;
    wire[2:0]  id_ex_mem_width_o;

    //ex to ctrl
    wire[31:0]      ex_jump_addr_o;
    wire            ex_jump_en_o; // ????
    wire            ex_hold_flag_o;
    wire            mdu_stall;

    //crtl to pc_reg
    wire[31:0]      ctrl_jump_addr_o;
    wire            ctrl_jump_en_o;
    
    wire PC_stall;
    wire IF_ID_stall;
    
    //ctrl to if_id
    wire            ctrl_hold_flag_o;

    //bp
    wire bpu_wait;
    wire prdt_taken;
    wire[31:0] prdt_pc_addr;

    // === ??????? EX ??? BPU ???? ===
    wire        ex_is_bxx_to_bpu;
    wire [31:0] ex_pc_to_bpu;
    wire        ex_real_taken_to_bpu;

    pc_reg pc_reg_inst (
        .clk        (cpu_clk                ),
        .rst        (cpu_rst                ),
        .jump_addr_i(ctrl_jump_addr_o       ),
        .jump_en    (ctrl_jump_en_o         ),
        .stall      (PC_stall | mdu_stall    ),
        .pc_o       (pc_reg_pc_o            ),
        .bpu_wait       (bpu_wait),
        .prdt_taken     (prdt_taken),
        .prdt_pc_addr   (prdt_pc_addr)
    );

    ifetch ifetch_inst (
        .pc_addr_i       (pc_reg_pc_o       ), //from pc
        .rom_inst_i      (irom_data         ), // from rom
        .if2rom_addr_o   (irom_addr         ), // to rom
        .inst_addr_o     (if_inst_addr_o    ),
        .inst_o          (if_inst_o         )
    );

    //bp: if_id to id_ex
    wire if_id_prdt_taken_o;
    wire[31:0] if_id_prdt_pc_addr;
    // A data/MDU stall holds the current IF/ID instruction.  A BPU wait is
    // different: PC must stay on the unresolved JALR while the older ID
    // producer is allowed to advance, so IF/ID receives a bubble instead.
    wire frontend_stall = IF_ID_stall | mdu_stall;

    if_id if_id_inst (
        .clk            (cpu_clk                ),
        .rst            (cpu_rst                ),
        .hold_flag_i    (ctrl_hold_flag_o       ),
        .inst_i         (if_inst_o              ),
        .inst_addr_i    (if_inst_addr_o         ),
        .inst_addr_o    (if_id_inst_addr_o      ),
        .inst_o         (if_id_inst_o           ),
        .stall          (frontend_stall),
        .prdt_taken_i   (prdt_taken             ),
        .prdt_pc_addr_i (prdt_pc_addr           ),
        .prdt_taken_o   (if_id_prdt_taken_o     ),
        .prdt_pc_addr   (if_id_prdt_pc_addr     ),
        .ex_jump_en_i   (ex_jump_en_o | bpu_wait)
    );
    
        //id to data hazard
    wire ID_RS1_tag;
    wire ID_RS2_tag;
    assign ID_RS1_tag = (id_rs1_addr_o == 5'b0) ? 1'b0 : 1'b1;
    assign ID_RS2_tag = (id_rs2_addr_o == 5'b0) ? 1'b0 : 1'b1;
    wire datahazard_sel;
    id id_inst (
        .inst_i         (if_id_inst_o       ),
        .inst_addr_i    (if_id_inst_addr_o  ),
        .rs1_addr_o     (id_rs1_addr_o      ),
        .rs2_addr_o     (id_rs2_addr_o      ),
        .rs1_data_i     (regs_reg1_rdata_o  ),
        .rs2_data_i     (regs_reg2_rdata_o  ),
        .datahazard_sel (datahazard_sel     ),
        .inst_o         (id_inst_o          ),
        .op1_o          (id_op1_o           ),
        .op2_o          (id_op2_o           ),
        .rd_addr_o      (id_rd_addr_o       ),
        .reg_wen_o      (id_reg_wen         ),
        .base_addr_o    (id_base_addr_o     ),
        .addr_offset_o  (id_addr_offset_o   ),
        .alu_op_o       (id_alu_op_o        ),
        .is_mdu_o       (id_is_mdu_o        ),
        .mdu_op_o       (id_mdu_op_o        ),
        .is_system_o    (id_is_system_o     ),
        .system_op_o    (id_system_op_o     ),
        .csr_addr_o     (id_csr_addr_o      ),
        .csr_zimm_o     (id_csr_zimm_o      ),
        .illegal_o      (id_illegal_o       ),
        .is_branch_o    (id_is_branch_o     ),
        .is_jump_o      (id_is_jump_o       ),
        .is_load_o      (id_is_load_o       ),
        .is_store_o     (id_is_store_o      ),
        .mem_width_o    (id_mem_width_o     )
    );
    //wb to regs
    wire        wb_reg_wen_o;
    wire[4:0]   wb_rd_addr_o;
    wire[31:0]  wb_rd_data_o;

    //bp
    wire  bpu2rf_rs1_ena;
    wire[4:0]  bpu2rf_rs1idx ;
    wire[31:0]  rf2bpu_rs1 ;   

    regs regs_inst(
        .clk            (cpu_clk                ),
        .rst            (cpu_rst                ),
        .reg1_raddr_i   (id_rs1_addr_o          ),
        .reg2_raddr_i   (id_rs2_addr_o          ),
        .reg1_rdata_o   (regs_reg1_rdata_o      ),
        .reg2_rdata_o   (regs_reg2_rdata_o      ),
        .reg_waddr_i    (wb_rd_addr_o           ),
        .reg_wdata_i    (wb_rd_data_o           ),
        .reg_wen        (wb_reg_wen_o           ),
        .bpu2rf_rs1_ena (bpu2rf_rs1_ena),
        .bpu2rf_rs1idx  (bpu2rf_rs1idx),
        .rf2bpu_rs1     (rf2bpu_rs1)
    );
    
    wire forward1;
    wire forward2;
    wire[31:0] forward_rD1;
    wire[31:0] forward_rD2;
    wire ID_EX_nop;
    //id_ex to ex
    wire id_ex_prdt_taken_o;
    wire[31:0] id_ex_prdt_pc_addr_o;

    id_ex id_ex_inst (
        .clk            (cpu_clk                ),
        .rst            (cpu_rst                ),
        .inst_i         (id_inst_o              ),
        .inst_addr_i    (if_id_inst_addr_o      ),
        .rs1_addr_i     (id_rs1_addr_o          ),
        .rs2_addr_i     (id_rs2_addr_o          ),
        .op1_i          (id_op1_o               ),
        .op2_i          (id_op2_o               ),
        .rd_addr_i      (id_rd_addr_o           ),
        .reg_wen_i      (id_reg_wen             ), 
        .base_addr_i    (id_base_addr_o         ),
        .addr_offset_i  (id_addr_offset_o       ),
        .datahazard_sel (datahazard_sel         ),
        .nop_from_hazard(ID_EX_nop              ),
        .hold_flag_i    (ctrl_hold_flag_o       ),
        .stall_i        (mdu_stall              ),
        .forward1       (forward1               ),
        .forward2       (forward2               ),
        .forward_rD1    (forward_rD1            ),
        .forward_rD2    (forward_rD2            ),
        .alu_op_i       (id_alu_op_o            ), 
        .is_mdu_i       (id_is_mdu_o            ),
        .mdu_op_i       (id_mdu_op_o            ),
        .is_system_i    (id_is_system_o         ),
        .system_op_i    (id_system_op_o         ),
        .csr_addr_i     (id_csr_addr_o          ),
        .csr_zimm_i     (id_csr_zimm_o          ),
        .illegal_i      (id_illegal_o           ),
        .is_branch_i    (id_is_branch_o         ), 
        .is_jump_i      (id_is_jump_o           ), 
        .is_load_i      (id_is_load_o           ), 
        .is_store_i     (id_is_store_o          ), 
        .mem_width_i    (id_mem_width_o         ), 
        .inst_o         (id_ex_inst_o           ),
        .inst_addr_o    (id_ex_inst_addr_o      ),
        .rs1_addr_o     (id_ex_rs1_addr_o       ),
        .rs2_addr_o     (id_ex_rs2_addr_o       ),
        .op1_o          (id_ex_op1_o            ),
        .op2_o          (id_ex_op2_o            ),
        .rd_addr_o      (id_ex_rd_addr_o        ),
        .reg_wen_o      (id_ex_reg_wen          ),
        .base_addr_o    (id_ex_base_addr_o      ),
        .addr_offset_o  (id_ex_addr_offset_o    ),
        .alu_op_o       (id_ex_alu_op_o         ), 
        .is_mdu_o       (id_ex_is_mdu_o         ),
        .mdu_op_o       (id_ex_mdu_op_o         ),
        .is_system_o    (id_ex_is_system_o      ),
        .system_op_o    (id_ex_system_op_o      ),
        .csr_addr_o     (id_ex_csr_addr_o       ),
        .csr_zimm_o     (id_ex_csr_zimm_o       ),
        .illegal_o      (id_ex_illegal_o        ),
        .is_branch_o    (id_ex_is_branch_o      ), 
        .is_jump_o      (id_ex_is_jump_o        ), 
        .is_load_o      (id_ex_is_load_o        ), 
        .is_store_o     (id_ex_is_store_o       ), 
        .mem_width_o    (id_ex_mem_width_o      ),
        .prdt_taken_i   (if_id_prdt_taken_o     ),
        .prdt_pc_addr_i (if_id_prdt_pc_addr     ),
        .prdt_taken_o   (id_ex_prdt_taken_o     ),
        .prdt_pc_addr_o (id_ex_prdt_pc_addr_o   ),
        .ex_jump_en_i   (ex_jump_en_o           ) 
    );
    
    //ex to ex_mem
    wire       ex_reg_wen;
    wire       ex_mem_rd_req_o;
    wire[31:0] ex_mem_rd_addr_o;
    //ex to ex_mem1
    wire       ex_reg_wen_o;
    wire[4:0]  ex_rd_addr_o;
    wire[31:0] ex_rd_data_o;
    wire[1:0]  ex_mem_mask_o;
    wire[31:0] ex_mem_wr_data_o;
    wire[2:0]  ex_sel;

    //mem1 to mem1_wb
    wire        mem1_reg_wen_o;
    wire[4:0]   mem1_rd_addr_o;
    wire[31:0]  mem1_rd_data_o;
    wire[1:0]   mem1_mem_mask_o;
    wire        mem1_is_load_o;

    wire id_ex_is_jalr = id_ex_is_jump_o && (id_ex_inst_o[6:0] == `INST_JALR);
    wire mem_load_forward_rs1_raw = mem1_is_load_o && mem1_reg_wen_o &&
                                (mem1_rd_addr_o != 5'b0) &&
                                (id_ex_rs1_addr_o == mem1_rd_addr_o);
    wire mem_load_forward_rs2_raw = mem1_is_load_o && mem1_reg_wen_o &&
                                (mem1_rd_addr_o != 5'b0) &&
                                (id_ex_rs2_addr_o == mem1_rd_addr_o);
    wire mem_load_forward_rs1 = mem_load_forward_rs1_raw &&
                                !(id_ex_is_branch_o || id_ex_is_jalr);
    wire mem_load_forward_rs2 = mem_load_forward_rs2_raw &&
                                !id_ex_is_branch_o;
    wire mem_load_forward_base = mem_load_forward_rs1_raw &&
                                 (id_ex_is_load_o || id_ex_is_store_o);
    wire[31:0] ex_op1_i = mem_load_forward_rs1 ? mem1_rd_data_o : id_ex_op1_o;
    wire[31:0] ex_op2_i = mem_load_forward_rs2 ? mem1_rd_data_o : id_ex_op2_o;
    wire[31:0] ex_base_addr_i = mem_load_forward_base ? mem1_rd_data_o : id_ex_base_addr_o;

    ex ex_inst (
        .clk             (cpu_clk                ),
        .rst             (cpu_rst                ),
        .inst_i          (id_ex_inst_o           ),
        .inst_addr_i     (id_ex_inst_addr_o      ),
        .op1_i           (ex_op1_i               ),      
        .op2_i           (ex_op2_i               ),
        .rd_addr_i       (id_ex_rd_addr_o        ),
        .reg_wen_i       (id_ex_reg_wen          ),
        .base_addr_i     (ex_base_addr_i         ),
        .addr_offset_i   (id_ex_addr_offset_o    ),
        .alu_op_i        (id_ex_alu_op_o         ),
        .is_mdu_i        (id_ex_is_mdu_o         ),
        .mdu_op_i        (id_ex_mdu_op_o         ),
        .is_system_i     (id_ex_is_system_o      ),
        .system_op_i     (id_ex_system_op_o      ),
        .csr_addr_i      (id_ex_csr_addr_o       ),
        .csr_zimm_i      (id_ex_csr_zimm_o       ),
        .illegal_i       (id_ex_illegal_o        ),
        .is_branch_i     (id_ex_is_branch_o      ),
        .is_load_i       (id_ex_is_load_o        ),
        .is_store_i      (id_ex_is_store_o       ),
        .is_jump_i       (id_ex_is_jump_o        ),
        .mem_width_i     (id_ex_mem_width_o      ),
        .rd_data_o       (ex_rd_data_o           ),
        .rd_addr_o       (ex_rd_addr_o           ),
        .rd_wen_o        (ex_reg_wen_o           ),
        .real_jump_addr_o     (ex_jump_addr_o           ),
        .real_jump_en_o        (ex_jump_en_o             ),
        .mdu_stall_o           (mdu_stall                ),
        .mem_rd_req      (ex_mem_rd_req_o        ),
        .mem_rd_addr    (ex_mem_rd_addr_o        ),
        .mem_wr_data_o  (ex_mem_wr_data_o        ),  
        .mem_mask       (ex_mem_mask_o           ),
        .sel            (ex_sel                  ),
        .prdt_taken_i   (id_ex_prdt_taken_o      ),
        .prdt_pc_addr_i (id_ex_prdt_pc_addr_o    ),

        // === ?????? ===
        .ex_is_bxx_o     (ex_is_bxx_to_bpu),
        .ex_pc_o         (ex_pc_to_bpu),
        .ex_real_taken_o (ex_real_taken_to_bpu)
    );
    
        //ex_mem1 to mem1
    wire        ex_mem1_mem_rd_req_o;
    wire[31:0]  ex_mem1_mem_rd_addr_o;
    wire        ex_mem1_reg_wen_o;
    wire[4:0]   ex_mem1_rd_addr_o;
    wire[31:0]  ex_mem1_rd_data_o;
    wire[2:0]   ex_mem1_reg_wr_sel_o;
    wire[31:0]  ex_mem1_mem_Wr_data_o;
    wire[1:0]   ex_mem1_mem_mask_o;
    wire        ex_mem1_is_load;

    ex_mem1 ex_mem1_inst (
        .clk                (cpu_clk                ),
        .rst                (cpu_rst                ),
        .mem_rd_req_i       (ex_mem_rd_req_o        ),
        .mem_rd_addr_i      (ex_mem_rd_addr_o        ),
        .reg_wen_i          (ex_reg_wen_o            ),
        .rd_addr_i          (ex_rd_addr_o            ),
        .rd_data_i          (ex_rd_data_o            ),
        .reg_wr_sel_i       (ex_sel                  ),
        .mem_wr_data_i      (ex_mem_wr_data_o        ),
        .mem_mask_i         (ex_mem_mask_o           ),
        .mem_rd_req_o       (ex_mem1_mem_rd_req_o    ),
        .mem_rd_addr_o      (ex_mem1_mem_rd_addr_o  ),
        .reg_wen_o          (ex_mem1_reg_wen_o       ),
        .rd_addr_o          (ex_mem1_rd_addr_o       ),
        .rd_data_o          (ex_mem1_rd_data_o       ),
        .reg_wr_sel_o       (ex_mem1_reg_wr_sel_o    ),
        .mem_wr_data_o      (ex_mem1_mem_Wr_data_o  ),
        .mem_mask_o         (ex_mem1_mem_mask_o      )
    );

    assign ex_mem1_is_load = (ex_mem1_mem_rd_req_o == 1'b0) && (ex_mem1_mem_rd_addr_o != 32'b0);

    mem1 mem1_inst (
        .clk                 (cpu_clk              ),
        .rst                 (cpu_rst              ),
        .mem_rd_req_i        (ex_mem1_mem_rd_req_o  ),
        .mem_rd_addr_i       (ex_mem1_mem_rd_addr_o ),
        .mem_wr_data_i       (ex_mem1_mem_Wr_data_o ),
        .mem_mask_i          (ex_mem1_mem_mask_o    ),
        .reg_wen_i           (ex_mem1_reg_wen_o      ),
        .rd_addr_i           (ex_mem1_rd_addr_o      ),
        .rd_data_i           (ex_mem1_rd_data_o      ),
        .sel                 (ex_mem1_reg_wr_sel_o  ),
        .mem_rd_data_i       (perip_rdata            ),
        .mem_rd_req_o        (perip_wen              ),
        .mem_rd_addr_o       (perip_addr             ),
        .mem_wr_data_o       (perip_wdata            ),
        .mem_mask_o          (perip_mask             ),
        .reg_wen_o           (mem1_reg_wen_o         ),
        .rd_addr_o           (mem1_rd_addr_o         ),
        .rd_data_o           (mem1_rd_data_o         ),
        .is_load_o           (mem1_is_load_o         )
    );

    //mem1_wb to wb
    wire        mem1_wb_reg_wen_o;
    wire[4:0]   mem1_wb_rd_addr_o;
    wire[31:0]  mem1_wb_rd_data_o;
    wire[1:0]   mem1_wb_mask_o;

    mem1_wb mem1_wb_inst (
        .clk             (cpu_clk                ),
        .rst             (cpu_rst                ),
        .hold_flag_i     (ctrl_hold_flag_o       ),
        .reg_wen_i       (mem1_reg_wen_o         ),
        .rd_addr_i       (mem1_rd_addr_o         ),
        .rd_data_i       (mem1_rd_data_o         ),
        .reg_wen_o       (mem1_wb_reg_wen_o      ),
        .rd_addr_o       (mem1_wb_rd_addr_o      ),
        .rd_data_o       (mem1_wb_rd_data_o      )
    );



    wb wb_inst (
        .reg_wen_i       (mem1_wb_reg_wen_o ),
        .rd_addr_i       (mem1_wb_rd_addr_o ),
        .rd_data_i       (mem1_wb_rd_data_o ),
        .reg_wen_o       (wb_reg_wen_o      ),
        .rd_addr_o       (wb_rd_addr_o      ),
        .rd_data_o       (wb_rd_data_o      )
    );

    ctrl ctrl_inst(
        .jump_addr_i   (ex_jump_addr_o           ),
        .jump_en_i     (ex_jump_en_o             ),
        .jump_addr_o   (ctrl_jump_addr_o         ),
        .jump_en_o     (ctrl_jump_en_o           ),
        .hold_flag_o   (ctrl_hold_flag_o         )
    );
    

    Data_Hazard_unit Data_Hazard_unit_inst(
        .ID_rs1         (ID_RS1_tag             ),
        .ID_rs2         (ID_RS2_tag             ),
        .ID_rs1_addr    (id_rs1_addr_o          ),
        .ID_rs2_addr    (id_rs2_addr_o          ),
        .EX_wr_tag      (ex_reg_wen_o            ),
        .MEM1_wr_tag    (ex_mem1_reg_wen_o       ),
        .MEM_wr_tag     (mem1_reg_wen_o          ),
        .WB_wr_tag      (wb_reg_wen_o            ),
        .EX_wr_addr     (ex_rd_addr_o            ),
        .MEM1_wr_addr   (ex_mem1_rd_addr_o       ),
        .MEM_wr_addr    (mem1_rd_addr_o          ),
        .WB_wr_addr     (wb_rd_addr_o            ),
        .EX_wr_data     (ex_rd_data_o            ),
        .MEM1_wr_data   (ex_mem1_rd_data_o       ),
        .MEM_wr_data    (mem1_rd_data_o          ),
        .WB_wr_data     (wb_rd_data_o            ),
        .rf_sel         (ex_sel                  ),
        .ID_is_branch   (id_is_branch_o          ),
        .ID_is_jump     (id_is_jump_o            ),
        .EX_is_load     (id_ex_is_load_o         ),
        .MEM1_is_load   (ex_mem1_is_load         ),
        .MEM_is_load    (mem1_is_load_o          ),
        .forward1        (forward1                ),
        .forward2        (forward2                ),
        .forward_rD1    (forward_rD1             ),
        .forward_rD2    (forward_rD2             ),
        .PC_stall       (PC_stall                ),
        .IF_ID_stall    (IF_ID_stall             ),
        .ID_EX_nop      (ID_EX_nop               )
    );

    bpu bpu_inst(
        .clk             (cpu_clk),
        .rst             (cpu_rst),
        .pc              (if_inst_addr_o),
        .inst            (if_inst_o),

        .ex_is_branch_i  (ex_is_bxx_to_bpu),
        .ex_pc_i         (ex_pc_to_bpu),
        .ex_real_taken_i (ex_real_taken_to_bpu),

        .ID_wr_tag      (id_reg_wen),
        .EX_wr_tag      (ex_reg_wen_o),
        .MEM1_wr_tag    (ex_mem1_reg_wen_o),
        .MEM_wr_tag     (mem1_reg_wen_o),
        .WB_wr_tag      (wb_reg_wen_o),
        .ID_wr_addr     (id_rd_addr_o),
        .EX_wr_addr     (ex_rd_addr_o),
        .MEM1_wr_addr   (ex_mem1_rd_addr_o),
        .MEM_wr_addr    (mem1_rd_addr_o),
        .WB_wr_addr     (wb_rd_addr_o),
        .EX_wr_data     (ex_rd_data_o),
        .MEM1_wr_data   (ex_mem1_rd_data_o),
        .MEM_wr_data    (mem1_rd_data_o),
        .WB_wr_data     (wb_rd_data_o),
        .rf_sel         (ex_sel),
        .MEM1_is_load   (ex_mem1_is_load),
        .MEM_is_load    (mem1_is_load_o),
        .bpu_wait       (bpu_wait),
        .prdt_taken     (prdt_taken),
        .prdt_pc_addr   (prdt_pc_addr),
        .bpu2rf_rs1_ena (bpu2rf_rs1_ena),
        .bpu2rf_rs1idx  (bpu2rf_rs1idx),
        .rf2bpu_rs1     (rf2bpu_rs1)
    );

endmodule

