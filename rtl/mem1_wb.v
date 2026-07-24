`include "defines.v"

module mem1_wb(
    input wire          clk,          
    input wire          rst,         
    input wire          hold_flag_i,  
    input wire          reg_wen_i,   
    input wire [4:0]    rd_addr_i,  
    input wire [31:0]   rd_data_i, 
    output wire         reg_wen_o,  
    output wire [4:0]   rd_addr_o,  
    output wire [31:0]  rd_data_o  
);
    dff_set #(1)  dff1(clk, rst, 1'b0, 1'b0,  reg_wen_i, reg_wen_o);
    dff_set #(5)  dff2(clk, rst, 1'b0, 5'b0,  rd_addr_i, rd_addr_o);
    dff_set #(32) dff3(clk, rst, 1'b0, 32'b0, rd_data_i, rd_data_o);

endmodule