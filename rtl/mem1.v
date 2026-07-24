`include "defines.v"

module mem1(
    input wire          clk,
    input wire          rst,
    input wire[2:0]     sel,
    input wire          mem_rd_req_i,
    input wire[31:0]    mem_rd_addr_i,
    input wire[31:0]    mem_wr_data_i,
    input wire[1:0]     mem_mask_i,
    input wire          reg_wen_i,
    input wire[4:0]     rd_addr_i,
    input wire[31:0]    rd_data_i,
    input wire[31:0]    mem_rd_data_i,//from ram
    output reg          mem_rd_req_o,
    output reg[31:0]    mem_rd_addr_o,
    output reg[31:0]    mem_wr_data_o,
    output reg[1:0]     mem_mask_o,
    output reg          reg_wen_o,
    output reg[4:0]     rd_addr_o,
    output reg[31:0]    rd_data_o,
    output reg          is_load_o
    
);
    reg[2:0]  sel_q;
    reg[31:0] rd_data_q;
    reg[31:0] mem_rd_data_q;

    wire is_load_i = (mem_rd_req_i == 1'b0) && (mem_rd_addr_i != 32'b0);

    always @(*) begin
        //L?????
        if (is_load_i) begin
            mem_rd_req_o  = mem_rd_req_i;
            mem_rd_addr_o = mem_rd_addr_i;
            mem_wr_data_o = 32'b0;
            mem_mask_o    = mem_mask_i;
        //S?????
        end 
        else begin
            mem_mask_o    = mem_mask_i;			
			mem_rd_req_o  = mem_rd_req_i;
			mem_rd_addr_o = mem_rd_addr_i;
			mem_wr_data_o = mem_wr_data_i;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            sel_q         <= 3'b0;
            rd_data_q     <= 32'b0;
            mem_rd_data_q <= 32'b0;
            reg_wen_o     <= 1'b0;
            rd_addr_o     <= 5'b0;
            is_load_o     <= 1'b0;
        end
        else begin
            sel_q         <= sel;
            rd_data_q     <= rd_data_i;
            mem_rd_data_q <= mem_rd_data_i;
            reg_wen_o     <= reg_wen_i;
            rd_addr_o     <= rd_addr_i;
            is_load_o     <= is_load_i;
        end
    end

    always @(*) begin
        if (is_load_o) begin
            case(sel_q)
                `INST_LW:  rd_data_o = mem_rd_data_q;
                `INST_LH:  rd_data_o = {{16{mem_rd_data_q[15]}}, mem_rd_data_q[15:0]};
                `INST_LB:  rd_data_o = {{24{mem_rd_data_q[7]}},  mem_rd_data_q[7:0]};
                `INST_LHU: rd_data_o = {16'b0, mem_rd_data_q[15:0]};
                `INST_LBU: rd_data_o = {24'b0, mem_rd_data_q[7:0]};
                default:   rd_data_o = 32'b0;
            endcase
        end
        else begin
            rd_data_o = rd_data_q;
        end
    end
endmodule

