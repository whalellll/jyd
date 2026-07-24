`include "defines.v"

module wb(
    input  wire           reg_wen_i,
    input  wire[4:0]      rd_addr_i,
    input  wire[31:0]     rd_data_i,
    output reg            reg_wen_o,
    output reg[4:0]       rd_addr_o,
    output reg[31:0]      rd_data_o
);
    always @(*) begin
    if (rd_addr_i == 5'b0) begin
        rd_addr_o = 5'b0;
        rd_data_o = 32'b0;
        reg_wen_o = 1'b0;
    end
    else begin
        rd_addr_o = rd_addr_i;
        rd_data_o = rd_data_i;
        reg_wen_o = reg_wen_i;
    end
    end
endmodule