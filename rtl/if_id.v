`include "defines.v"
module if_id(
    input wire clk,
    input wire rst,
    input wire hold_flag_i,
    input wire[31:0] inst_i,
    input wire[31:0] inst_addr_i,
    output reg[31:0] inst_addr_o,
    output reg[31:0] inst_o,
    input  wire stall,
    
    input wire       prdt_taken_i   ,
    input wire[31:0] prdt_pc_addr_i ,
    output reg       prdt_taken_o   ,
    output reg[31:0] prdt_pc_addr   ,

    input wire       ex_jump_en_i     
);
    wire rom_flag;

  
    assign rom_flag = (rst | hold_flag_i | ex_jump_en_i) ? 1'b0 : 1'b1;

    always @(posedge clk) begin
        if(!rom_flag) begin
            inst_o      <= `INST_NOP;
            inst_addr_o <= 32'b0;
            prdt_taken_o<= 1'b0;
            prdt_pc_addr<= 32'b0;
        end
        else if(stall) begin
            inst_o      <= inst_o;
            inst_addr_o <= inst_addr_o;
            prdt_taken_o<= prdt_taken_o;
            prdt_pc_addr<= prdt_pc_addr;
        end
        else begin
            inst_o      <= inst_i;
            inst_addr_o <= inst_addr_i;
            prdt_taken_o<= prdt_taken_i;
            prdt_pc_addr<= prdt_pc_addr_i;
        end
    end
endmodule
