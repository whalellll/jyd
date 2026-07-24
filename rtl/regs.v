module regs(
    input wire clk,
    input wire rst,

    input wire[4:0] reg1_raddr_i,
    input wire[4:0] reg2_raddr_i,

    output reg[31:0] reg1_rdata_o,
    output reg[31:0] reg2_rdata_o,

    input wire[4:0] reg_waddr_i,
    input wire[31:0]reg_wdata_i,
    input           reg_wen,
    //bp
    input wire       bpu2rf_rs1_ena,
    input wire[4:0]  bpu2rf_rs1idx ,
    output reg[31:0] rf2bpu_rs1     
);
    reg[31:0] regs[0:31];
    integer i;
    always @(*) begin
        if(rst == 1'b1)
            reg1_rdata_o <= 32'b0;
        else if(reg1_raddr_i == 5'b0)
            reg1_rdata_o <= 32'b0;
        else if(reg_wen && reg1_raddr_i == reg_waddr_i)
            reg1_rdata_o <= reg_wdata_i;
        else
            reg1_rdata_o <= regs[reg1_raddr_i];
    end

    always @(*) begin
        if(rst == 1'b1)
            reg2_rdata_o <= 32'b0;
        else if(reg2_raddr_i == 5'b0)
            reg2_rdata_o <= 32'b0;
        else if(reg_wen && reg2_raddr_i == reg_waddr_i)
            reg2_rdata_o <= reg_wdata_i;
        else
            reg2_rdata_o <= regs[reg2_raddr_i];
    end

    always @(posedge clk)begin
        if(rst == 1'b1) begin
            for(i = 0; i <= 31; i = i + 1) begin
                regs[i] <= 32'b0;
            end
        end
        else if(reg_wen && reg_waddr_i != 5'b0) begin
            regs[reg_waddr_i] <= reg_wdata_i;
        end
    end

    //bp
    always @(*) begin
        if(rst == 1'b1)
            rf2bpu_rs1 <= 32'b0;
        else if(bpu2rf_rs1idx == 5'b0)
            rf2bpu_rs1 <= 32'b0;
        else if(bpu2rf_rs1_ena)
            rf2bpu_rs1 <= regs[bpu2rf_rs1idx];
        else 
            rf2bpu_rs1 <= 32'b0;
    end
endmodule