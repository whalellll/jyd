`include "defines.v"

module csr_unit(
    input  wire        clk,
    input  wire        rst,
    input  wire        valid,
    input  wire [3:0]  op,
    input  wire [11:0] addr,
    input  wire [31:0] rs1_value,
    input  wire [4:0]  zimm,
    input  wire [31:0] pc,
    input  wire        decoded_illegal,
    output reg  [31:0] read_value,
    output wire        redirect,
    output wire [31:0] redirect_pc,
    output wire        illegal_csr
);
    reg [31:0] mstatus;
    reg [31:0] mtvec;
    reg [31:0] mscratch;
    reg [31:0] mepc;
    reg [31:0] mcause;

    wire csr_instruction = valid && ((op == `SYS_CSRRW) ||
                                     (op == `SYS_CSRRS) ||
                                     (op == `SYS_CSRRC) ||
                                     (op == `SYS_CSRRWI) ||
                                     (op == `SYS_CSRRSI) ||
                                     (op == `SYS_CSRRCI));
    wire csr_known = (addr == `CSR_MSTATUS) || (addr == `CSR_MTVEC) ||
                     (addr == `CSR_MSCRATCH) || (addr == `CSR_MEPC) ||
                     (addr == `CSR_MCAUSE);
    assign illegal_csr = csr_instruction && !csr_known;
    wire take_illegal = decoded_illegal || illegal_csr;
    wire take_ecall = valid && (op == `SYS_ECALL);
    wire take_mret = valid && (op == `SYS_MRET);
    assign redirect = take_illegal || take_ecall || take_mret;
    assign redirect_pc = take_mret ? (mepc & 32'hffff_fffe) :
                         (mtvec & 32'hffff_fffc);

    reg [31:0] csr_write_value;
    reg        csr_write_enable;
    always @(*) begin
        case (addr)
            `CSR_MSTATUS:  read_value = mstatus;
            `CSR_MTVEC:    read_value = mtvec;
            `CSR_MSCRATCH: read_value = mscratch;
            `CSR_MEPC:     read_value = mepc;
            `CSR_MCAUSE:   read_value = mcause;
            default:       read_value = 0;
        endcase
        csr_write_value = read_value;
        csr_write_enable = 1'b0;
        case (op)
            `SYS_CSRRW: begin csr_write_value = rs1_value; csr_write_enable = 1'b1; end
            `SYS_CSRRS: begin csr_write_value = read_value | rs1_value;
                                   csr_write_enable = (rs1_value != 0); end
            `SYS_CSRRC: begin csr_write_value = read_value & ~rs1_value;
                                   csr_write_enable = (rs1_value != 0); end
            `SYS_CSRRWI: begin csr_write_value = {27'b0, zimm}; csr_write_enable = 1'b1; end
            `SYS_CSRRSI: begin csr_write_value = read_value | {27'b0, zimm};
                                    csr_write_enable = (zimm != 0); end
            `SYS_CSRRCI: begin csr_write_value = read_value & ~{27'b0, zimm};
                                    csr_write_enable = (zimm != 0); end
            default: begin end
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            mstatus  <= 0;
            mtvec    <= 0;
            mscratch <= 0;
            mepc     <= 0;
            mcause   <= 0;
        end else if (take_illegal) begin
            mepc <= pc;
            mcause <= 32'd2;
            mstatus[7] <= mstatus[3];
            mstatus[3] <= 1'b0;
        end else if (take_ecall) begin
            mepc <= pc;
            mcause <= 32'd11;
            mstatus[7] <= mstatus[3];
            mstatus[3] <= 1'b0;
        end else if (take_mret) begin
            mstatus[3] <= mstatus[7];
            mstatus[7] <= 1'b1;
        end else if (csr_instruction && csr_known && csr_write_enable) begin
            case (addr)
                `CSR_MSTATUS:  mstatus  <= csr_write_value;
                `CSR_MTVEC:    mtvec    <= csr_write_value;
                `CSR_MSCRATCH: mscratch <= csr_write_value;
                `CSR_MEPC:     mepc     <= csr_write_value;
                `CSR_MCAUSE:   mcause   <= csr_write_value;
                default: begin end
            endcase
        end
    end
endmodule
