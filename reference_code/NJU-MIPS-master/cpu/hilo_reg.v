`include "macro.v"
module hilo_reg(
    input wire clk,
    input wire rst,
    input wire we,
    input wire[`REGBUS] hi_i,
    input wire[`REGBUS] lo_i,
    output reg[`REGBUS] hi_o,
    output reg[`REGBUS] lo_o
);
    always @(posedge clk) begin
        if (rst==`RSTENABLE) begin
            hi_o <= `ZEROWORD;
            lo_o <= `ZEROWORD;
        end else if ((we==`WRITEENABLE)) begin
            hi_o <= hi_i;
            lo_o <= lo_i;
        end
    end
endmodule
