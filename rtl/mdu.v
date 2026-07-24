`include "defines.v"

module mdu(
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire [2:0]  op,
    input  wire [31:0] src1,
    input  wire [31:0] src2,
    output reg  [31:0] result,
    output reg         busy,
    output reg         done
);
    reg [2:0]  op_q;
    reg [5:0]  count;
    reg [31:0] src1_q;
    reg [31:0] src2_q;
    reg [31:0] divisor_q;
    reg [31:0] dividend_q;
    reg [31:0] quotient_q;
    reg [32:0] remainder_q;
    reg        quotient_neg;
    reg        remainder_neg;
    reg        quick_finish;

    wire signed [63:0] product_ss =
        $signed({{32{src1_q[31]}}, src1_q}) *
        $signed({{32{src2_q[31]}}, src2_q});
    wire [63:0] product_uu = {32'b0, src1_q} * {32'b0, src2_q};
    wire signed [64:0] product_su =
        $signed({{33{src1_q[31]}}, src1_q}) * $signed({33'b0, src2_q});

    wire is_divrem = (op == `MDU_DIV)  || (op == `MDU_DIVU) ||
                     (op == `MDU_REM)  || (op == `MDU_REMU);
    wire signed_op = (op == `MDU_DIV) || (op == `MDU_REM);
    wire [31:0] abs_src1 = (signed_op && src1[31]) ? (~src1 + 1'b1) : src1;
    wire [31:0] abs_src2 = (signed_op && src2[31]) ? (~src2 + 1'b1) : src2;

    wire [32:0] shifted_remainder = {remainder_q[31:0], dividend_q[31]};
    wire subtract_ok = shifted_remainder >= {1'b0, divisor_q};
    wire [32:0] next_remainder = subtract_ok ?
        (shifted_remainder - {1'b0, divisor_q}) : shifted_remainder;
    wire [31:0] next_quotient = {quotient_q[30:0], subtract_ok};
    wire [31:0] signed_quotient = quotient_neg ?
        (~next_quotient + 1'b1) : next_quotient;
    wire [31:0] signed_remainder = remainder_neg ?
        (~next_remainder[31:0] + 1'b1) : next_remainder[31:0];

    always @(posedge clk) begin
        if (rst) begin
            result        <= 0;
            busy          <= 0;
            done          <= 0;
            op_q          <= 0;
            count         <= 0;
            src1_q        <= 0;
            src2_q        <= 0;
            divisor_q     <= 0;
            dividend_q    <= 0;
            quotient_q    <= 0;
            remainder_q   <= 0;
            quotient_neg  <= 0;
            remainder_neg <= 0;
            quick_finish  <= 0;
        end else begin
            done <= 1'b0;
            if (start && !busy) begin
                busy         <= 1'b1;
                quick_finish <= 1'b1;
                op_q         <= op;
                count        <= 0;
                src1_q       <= src1;
                src2_q       <= src2;

                case (op)
                    `MDU_MUL,
                    `MDU_MULH,
                    `MDU_MULHSU,
                    `MDU_MULHU: begin
                    end
                    default: begin
                        if (is_divrem && (src2 == 0)) begin
                            result <= ((op == `MDU_DIV) || (op == `MDU_DIVU)) ?
                                      32'hffff_ffff : src1;
                        end else if (((op == `MDU_DIV) || (op == `MDU_REM)) &&
                                     (src1 == 32'h8000_0000) &&
                                     (src2 == 32'hffff_ffff)) begin
                            result <= (op == `MDU_DIV) ? 32'h8000_0000 : 0;
                        end else begin
                            quick_finish  <= 1'b0;
                            divisor_q     <= abs_src2;
                            dividend_q    <= abs_src1;
                            quotient_q    <= 0;
                            remainder_q   <= 0;
                            quotient_neg  <= signed_op && (src1[31] ^ src2[31]);
                            remainder_neg <= signed_op && src1[31];
                        end
                    end
                endcase
            end else if (busy) begin
                if (quick_finish) begin
                    case (op_q)
                        `MDU_MUL:    result <= product_ss[31:0];
                        `MDU_MULH:   result <= product_ss[63:32];
                        `MDU_MULHSU: result <= product_su[63:32];
                        `MDU_MULHU:  result <= product_uu[63:32];
                        default: begin
                        end
                    endcase
                    busy <= 1'b0;
                    done <= 1'b1;
                end else begin
                    remainder_q <= next_remainder;
                    dividend_q  <= {dividend_q[30:0], 1'b0};
                    quotient_q  <= next_quotient;
                    if (count == 6'd31) begin
                        if ((op_q == `MDU_DIV) || (op_q == `MDU_DIVU))
                            result <= signed_quotient;
                        else
                            result <= signed_remainder;
                        busy <= 1'b0;
                        done <= 1'b1;
                    end else begin
                        count <= count + 1'b1;
                    end
                end
            end
        end
    end
endmodule
