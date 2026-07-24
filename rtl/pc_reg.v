module pc_reg (
    input wire       clk,
    input wire       rst,
    input wire[31:0] jump_addr_i,
    input wire       jump_en,
    input wire       stall,
    output reg[31:0] pc_o,
    //bp
    input wire       bpu_wait           ,
    input wire       prdt_taken         ,
    input wire[31:0] prdt_pc_addr
);
    always @(posedge clk) begin
        if(rst == 1'b1)
            pc_o <= 32'h80000000;
        else if(jump_en)
            pc_o <= jump_addr_i;
        else if(bpu_wait  | stall)
            pc_o <= pc_o;
        else if (prdt_taken)
            pc_o <= prdt_pc_addr;
        else
            pc_o <= pc_o + 3'd4;        
    end
endmodule
