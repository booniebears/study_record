`include "macro.v"
module if_id(
    input wire  clk,
    input wire  rst,
    input wire[`INSTADDRBUS] if_pc,
    input wire[`INSTBUS] if_inst,
    input wire[5:0]  stall,
    output reg[`INSTADDRBUS] id_pc,
    output reg[`INSTBUS] id_inst
);

    always @(posedge clk) begin
        if (rst==`RSTENABLE) begin
            id_pc <= `ZEROWORD;
            id_inst <= `ZEROWORD;
        end else if (stall[1] == `STOP && stall[2] == `NOSTOP) begin
            id_pc <= `ZEROWORD;
            id_inst <= `ZEROWORD;
        end else if (stall[1] == `NOSTOP) begin
            id_pc <= if_pc;
            id_inst <= if_inst;
        end
    end

endmodule
