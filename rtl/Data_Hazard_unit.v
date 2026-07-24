`include "defines.v"

module Data_Hazard_unit(
    input wire          ID_rs1,
    input wire          ID_rs2,
    input wire[4:0]     ID_rs1_addr,
    input wire[4:0]     ID_rs2_addr,
    input wire          EX_wr_tag,
    input wire          MEM1_wr_tag,
    input wire          MEM_wr_tag,
    input wire          WB_wr_tag,
    input wire[4:0]     EX_wr_addr,
    input wire[4:0]     MEM1_wr_addr,
    input wire[4:0]     MEM_wr_addr,
    input wire[4:0]     WB_wr_addr,
    input wire[31:0]    EX_wr_data,
    input wire[31:0]    MEM1_wr_data,
    input wire[31:0]    MEM_wr_data,
    input wire[31:0]    WB_wr_data,
    input wire[2:0]     rf_sel, // from EX
    input wire          ID_is_branch,
    input wire          ID_is_jump,
    input wire          EX_is_load,
    input wire          MEM1_is_load,
    input wire          MEM_is_load,
    output wire         forward1,
    output wire         forward2,
    output reg [31:0]   forward_rD1,
    output reg [31:0]   forward_rD2,
    output reg          PC_stall,
    output reg          IF_ID_stall,
    output reg          ID_EX_nop
);
    wire forward_EX_rD1  = ID_rs1 && EX_wr_tag && (ID_rs1_addr == EX_wr_addr) && (EX_wr_addr != 5'b0);
    wire forward_EX_rD2  = ID_rs2 && EX_wr_tag && (ID_rs2_addr == EX_wr_addr) && (EX_wr_addr != 5'b0);

    wire forward_MEM1_rD1 = ID_rs1 && MEM1_wr_tag && (ID_rs1_addr == MEM1_wr_addr) && (MEM1_wr_addr != 5'b0);
    wire forward_MEM1_rD2 = ID_rs2 && MEM1_wr_tag && (ID_rs2_addr == MEM1_wr_addr) && (MEM1_wr_addr != 5'b0);

    wire forward_MEM_rD1 = ID_rs1 && MEM_wr_tag && (ID_rs1_addr == MEM_wr_addr) && (MEM_wr_addr != 5'b0);
    wire forward_MEM_rD2 = ID_rs2 && MEM_wr_tag && (ID_rs2_addr == MEM_wr_addr) && (MEM_wr_addr != 5'b0);
    
    wire forward_WB_rD1  = ID_rs1 && WB_wr_tag && (ID_rs1_addr == WB_wr_addr) && (WB_wr_addr != 5'b0);
    wire forward_WB_rD2  = ID_rs2 && WB_wr_tag && (ID_rs2_addr == WB_wr_addr) && (WB_wr_addr != 5'b0);

    wire ex_load_hazard   = (forward_EX_rD1 || forward_EX_rD2) && EX_is_load;
    wire mem_load_redirect_hazard =
        (ID_is_branch || ID_is_jump) &&
        (((forward_MEM1_rD1 || forward_MEM1_rD2) && MEM1_is_load) ||
         ((forward_MEM_rD1 || forward_MEM_rD2) && MEM_is_load));
    wire data_hazard      = ex_load_hazard || mem_load_redirect_hazard;

    assign forward1 = forward_EX_rD1 || (forward_MEM1_rD1 && !MEM1_is_load) || forward_MEM_rD1 || forward_WB_rD1;
    assign forward2 = forward_EX_rD2 || (forward_MEM1_rD2 && !MEM1_is_load) || forward_MEM_rD2 || forward_WB_rD2;

    always @(*) begin
        if(forward_EX_rD1)          begin forward_rD1 = EX_wr_data  ;   end
        else if(forward_MEM1_rD1 && !MEM1_is_load)
                                    begin forward_rD1 = MEM1_wr_data;   end
        else if(forward_MEM_rD1)
                                    begin forward_rD1 = MEM_wr_data ;   end
        else if(forward_WB_rD1)     begin forward_rD1 = WB_wr_data  ;   end
        else                        begin forward_rD1 = 32'b0       ;   end
    end

    always @(*) begin
        if(forward_EX_rD2)          begin forward_rD2 = EX_wr_data  ;   end
        else if(forward_MEM1_rD2 && !MEM1_is_load)
                                    begin forward_rD2 = MEM1_wr_data;   end
        else if(forward_MEM_rD2)
                                    begin forward_rD2 = MEM_wr_data ;   end
        else if(forward_WB_rD2)     begin forward_rD2 = WB_wr_data  ;   end
        else                        begin forward_rD2 = 32'b0       ;   end
    end

    always @(*) begin
        if(data_hazard) begin
            PC_stall    = 1'b1;
            IF_ID_stall = 1'b1;
            ID_EX_nop   = 1'b1;
        end
        else begin
            PC_stall    = 1'b0;
            IF_ID_stall = 1'b0;
            ID_EX_nop   = 1'b0;
        end
    end
endmodule
