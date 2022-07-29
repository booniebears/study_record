`include "macro.v"
module regfile(
    input wire clk,
    input wire rst,

    input wire we,
    input wire[`REGADDRBUS] waddr,
    input wire[`REGBUS] wdata,

    input wire re1,
    input wire[`REGADDRBUS] raddr1,
    output reg[`REGBUS] rdata1,

    input wire re2,
    input wire[`REGADDRBUS] raddr2,
    output reg[`REGBUS] rdata2
);

    reg[`REGBUS] regs[0:`REGNUM-1];

    always @(posedge clk) begin
        if (rst == `RSTDISABLE) begin
            if ((we==`WRITEENABLE) && (waddr!=`REGNUMLOG2'h0)) begin 
                regs[waddr] <= wdata;
            end
        end 
    end 

    always @(*) begin
        if (rst == `RSTENABLE) begin
            rdata1 <= `ZEROWORD;
        end else if (raddr1 == `REGNUMLOG2'h0) begin 
            rdata1 <= `ZEROWORD;
        end else if ((raddr1==waddr)&&(we == `WRITEENABLE)&&(re1==`READENABLE))begin
            rdata1 <= wdata;
        end else if (re1 == `READENABLE) begin 
            rdata1 <= regs[raddr1];
        end else begin
            rdata1 <= `ZEROWORD;
        end
    end

    always @(*) begin
        if (rst == `RSTENABLE) begin
            rdata2 <= `ZEROWORD;
        end else if (raddr2 == `REGNUMLOG2'h0) begin 
            rdata2 <= `ZEROWORD;
        end else if ((raddr2==waddr)&&(we == `WRITEENABLE)&&(re2==`READENABLE))begin
            rdata2 <= wdata;
        end else if (re2 == `READENABLE) begin 
            rdata2 <= regs[raddr2];
        end else begin
            rdata2 <= `ZEROWORD;
        end
    end

endmodule
