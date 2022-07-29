`include "macro.v"
module ex_mem(
    input wire clk,
    input wire rst,

    input wire[`REGADDRBUS]  ex_wd,
    input wire               ex_wreg,
    input wire[`REGBUS]      ex_wdata,
	 
	 input wire[`REGBUS]		  ex_hi,
	 input wire[`REGBUS]	     ex_lo,
	 input wire					  ex_whilo,
	 
	 input wire[`ALUOPBUS]	  ex_aluop,
	 input wire[`REGBUS]	 	  ex_mem_addr,
	 input wire[`REGBUS]		  ex_reg2,

    input wire[5:0]          stall,
	 
	 input wire[`DOUBLEREGBUS] hilo_i,
	 input wire[1:0]			  cnt_i,

    output reg[`REGADDRBUS]  mem_wd,
    output reg               mem_wreg,
    output reg[`REGBUS]      mem_wdata,
	 output reg[`REGBUS]		  mem_hi,
	 output reg[`REGBUS]		  mem_lo,
	 output reg        		  mem_whilo,
	 
	 output reg[`DOUBLEREGBUS] hilo_o,
	 output reg[1:0]			  cnt_o,
	 
	 output reg[`ALUOPBUS]	  mem_aluop,
	 output reg[`REGBUS]		  mem_mem_addr,
	 output reg[`REGBUS]		  mem_reg2
);

    always @(posedge clk) begin
        if (rst == `RSTENABLE) begin
            mem_wd <= `NOPREGADDR;
            mem_wreg <= `WRITEDISABLE;
            mem_wdata <= `ZEROWORD;
				mem_hi <= `ZEROWORD;
				mem_lo <= `ZEROWORD;
				mem_whilo <= `WRITEDISABLE;
				mem_aluop <= `EXE_NOP_OP;
				mem_mem_addr <= `ZEROWORD;
				mem_reg2 <= `ZEROWORD;
				hilo_o <= {`ZEROWORD, `ZEROWORD};
				cnt_o <= 2'b00;
        end else if (stall[3] == `STOP && stall[4] == `NOSTOP) begin
            mem_wd <= `NOPREGADDR;
            mem_wreg <= `WRITEDISABLE;
            mem_wdata <= `ZEROWORD;
				mem_hi <= `ZEROWORD;
				mem_lo <= `ZEROWORD;
				mem_whilo <= `WRITEDISABLE;
				mem_aluop <= `EXE_NOP_OP;
				mem_mem_addr <= `ZEROWORD;
				mem_reg2 <= `ZEROWORD;
				hilo_o <= hilo_i;
				cnt_o <= cnt_i;
        end else if (stall[3] == `NOSTOP) begin
            mem_wd <= ex_wd;
            mem_wreg <= ex_wreg;
            mem_wdata <= ex_wdata;
				mem_hi <= ex_hi;
				mem_lo <= ex_lo;
				mem_whilo <= ex_whilo;
				mem_aluop <= ex_aluop;
				mem_mem_addr <= ex_mem_addr;
				mem_reg2 <= ex_reg2;
				hilo_o <= {`ZEROWORD, `ZEROWORD};
				cnt_o <= 2'b00;
        end else begin
				hilo_o <= hilo_i;
				cnt_o <= cnt_i;
		  end
    end

endmodule
