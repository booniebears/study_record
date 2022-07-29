`include "macro.v"
module inst_ram(
	 input wire clk,
    input wire ce,
	 input wire rom_ce,
	 
    input wire[`INSTADDRBUS] inst_addr,
    output reg[`INSTBUS] inst,
	 
	 input wire we,
	 input wire[`INSTADDRBUS] addr,
	 input wire[`INSTBUS] data_i,
	 output reg[`INSTBUS] data_o
);

	 reg [`INSTBUS] inst_ram_mem[63:0];
	 
	 always @(posedge clk) begin
		if (rom_ce == `CHIPDISABLE) begin
	   end else begin
			inst <= inst_ram_mem[inst_addr[`INSTNUMLOG2+1:2]];
		end
	 end
	 
	 always @(posedge clk) begin
		if (ce == `CHIPDISABLE) begin
		end else if (we == `WRITEENABLE) begin
			inst_ram_mem[addr[`INSTNUMLOG2+1:2]] <= data_i;
		end
	 end
	 
	 always @(posedge clk) begin
		if (ce == `CHIPDISABLE) begin
		end else begin
			data_o <= inst_ram_mem[addr[`INSTNUMLOG2+1:2]];
		end
	 end


endmodule
