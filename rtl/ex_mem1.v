`include "defines.v"

module ex_mem1(
    input   wire            clk,
    input   wire            rst,
    input   wire            mem_rd_req_i,
    input   wire[31:0]      mem_rd_addr_i,
    input   wire            reg_wen_i,
    input   wire[4:0]       rd_addr_i,
    input   wire[31:0]      rd_data_i,
    input   wire[2:0]       reg_wr_sel_i,
    input   wire[31:0]      mem_wr_data_i,
    input   wire[1:0]       mem_mask_i,
    output  wire            mem_rd_req_o,
    output  wire[31:0]      mem_rd_addr_o,
    output  wire            reg_wen_o,
    output  wire[4:0]       rd_addr_o,
    output  wire[31:0]      rd_data_o,
    output  wire[2:0]       reg_wr_sel_o,
    output  wire[31:0]      mem_wr_data_o,
    output  wire[1:0]       mem_mask_o
);
    dff_set #(1)  dff1(clk, rst, 1'b0 ,1'b0,mem_rd_req_i,mem_rd_req_o);
    dff_set #(32) dff2(clk, rst, 1'b0 ,32'b0,mem_rd_addr_i,mem_rd_addr_o);
    dff_set #(1)  dff3(clk, rst, 1'b0 ,1'b0,reg_wen_i,reg_wen_o);
    dff_set #(5)  dff4(clk, rst, 1'b0 ,5'b0,rd_addr_i,rd_addr_o);
    dff_set #(32) dff5(clk, rst, 1'b0 ,32'b0,rd_data_i,rd_data_o);
    dff_set #(3)  dff6(clk, rst, 1'b0 ,3'b0,reg_wr_sel_i,reg_wr_sel_o);
    dff_set #(32) dff7(clk, rst, 1'b0 ,32'b0,mem_wr_data_i,mem_wr_data_o);
    dff_set #(2)  dff8(clk, rst, 1'b0 ,2'b0,mem_mask_i,mem_mask_o);
endmodule