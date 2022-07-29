`include "macro.v"
module id_ex(
    input wire clk,
    input wire rst,

    input wire[`ALUOPBUS] id_aluop,
    input wire[`ALUSELBUS] id_alusel,
    input wire[`REGBUS] id_reg1,
    input wire[`REGBUS] id_reg2,
    input wire[`REGADDRBUS] id_wd,
    input wire id_wreg,
	 input wire[`REGBUS] id_inst,

    input wire[5:0] stall,
	 
	 input wire[`REGBUS] id_link_address,
	 input wire	id_is_in_delayslot,
	 input wire next_inst_in_delayslot_i,

    output reg[`ALUOPBUS] ex_aluop,
    output reg[`ALUSELBUS] ex_alusel,
    output reg[`REGBUS] ex_reg1,
    output reg[`REGBUS] ex_reg2,
    output reg[`REGADDRBUS] ex_wd,
    output reg ex_wreg,
	 output reg[`REGBUS] ex_inst,
	 
	 output reg[`REGBUS] ex_link_address,
	 output reg	ex_is_in_delayslot,
	 output reg is_in_delayslot_o
 );

    always @(posedge clk) begin
        if (rst == `RSTENABLE) begin
            ex_aluop <= `EXE_NOP_OP;
            ex_alusel <= `EXE_RES_NOP;
            ex_reg1 <= `ZEROWORD;
            ex_reg2 <= `ZEROWORD;
            ex_wd <= `NOPREGADDR;
            ex_wreg <= `WRITEDISABLE;
				ex_inst <= `ZEROWORD;
				ex_link_address <= `ZEROWORD;
			   ex_is_in_delayslot <= `NOTINDELAYSLOT;
	         is_in_delayslot_o <= `NOTINDELAYSLOT;	
        end else if (stall[2] ==`STOP && stall[3] == `NOSTOP) begin
            ex_aluop <= `EXE_NOP_OP;
            ex_alusel <= `EXE_RES_NOP;
            ex_reg1 <= `ZEROWORD;
            ex_reg2 <= `ZEROWORD;
            ex_wd <= `NOPREGADDR;
            ex_wreg <= `WRITEDISABLE;
				ex_link_address <= `ZEROWORD;
	         ex_is_in_delayslot <= `NOTINDELAYSLOT;	
				ex_inst <= `ZEROWORD;
        end else if (stall[2] == `NOSTOP) begin
            ex_aluop <= id_aluop;
            ex_alusel<= id_alusel;
            ex_reg1  <= id_reg1;
            ex_reg2  <= id_reg2;
            ex_wd    <= id_wd;
            ex_wreg  <= id_wreg;
				ex_link_address <= id_link_address;
				ex_is_in_delayslot <= id_is_in_delayslot;
				is_in_delayslot_o <= next_inst_in_delayslot_i;
				ex_inst <= id_inst;
        end
    end

endmodule
