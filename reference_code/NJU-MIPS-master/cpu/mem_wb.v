`include "macro.v"
module mem_wb(
    input wire clk,
    input wire rst,
    
    input wire[`REGADDRBUS] mem_wd,
    input wire mem_wreg,
    input wire[`REGBUS] mem_wdata,
	 input wire[`REGBUS] mem_hi,
	 input wire[`REGBUS] mem_lo,
	 input wire	mem_whilo,

    input wire[5:0] stall,

    output reg[`REGADDRBUS] wb_wd,
    output reg wb_wreg,
    output reg[`REGBUS] wb_wdata,
	 output reg[`REGBUS] wb_hi,
	 output reg[`REGBUS] wb_lo,
	 output reg		wb_whilo
);

    always @ (posedge clk) begin
        if (rst == `RSTENABLE) begin
            wb_wd <= `NOPREGADDR;
            wb_wreg <= `WRITEDISABLE;
            wb_wdata <= `ZEROWORD;
				wb_hi <= `ZEROWORD;
				wb_lo <= `ZEROWORD;
				wb_whilo <= `WRITEDISABLE;
        end else if (stall[4] == `STOP && stall[5] == `NOSTOP) begin
            wb_wd <= `NOPREGADDR;
            wb_wreg <= `WRITEDISABLE;
            wb_wdata <= `ZEROWORD;
			wb_hi <= `ZEROWORD;
			wb_lo <= `ZEROWORD;
			wb_whilo <= `WRITEDISABLE;
        end else if (stall[4] == `NOSTOP) begin
            wb_wd <= mem_wd;
            wb_wreg <= mem_wreg;
            wb_wdata <= mem_wdata;
			wb_hi <= mem_hi;
			wb_lo <= mem_lo;
			wb_whilo <= mem_whilo;
        end
    end

endmodule
