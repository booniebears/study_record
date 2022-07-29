`include "macro.v"
module inst_rom(
	 input wire clk,
    input wire ce,
	 input wire [3:0]sel,
    input wire[`INSTADDRBUS] inst_addr,
    output reg[`INSTBUS] inst,
	 input wire[`INSTADDRBUS] addr,
	 output reg[`INSTBUS] data_o
);

	 wire[`INSTBUS] inst_t;
	 wire[`INSTBUS] data_o_t;
	 inst_rom_ip ROM(
	   .clock(clk),
		.address_a(inst_addr[`INSTNUMLOG2+1:2]),
		.address_b(addr[`INSTNUMLOG2+1:2]),
		.q_a(inst_t),
		.q_b(data_o_t)
	 );
	 
	 always @(posedge clk) begin
		if (ce == `CHIPDISABLE) begin
	   end else begin
			inst <= inst_t;
		end
	 end
	 
	 always @(posedge clk) begin
		if (ce == `CHIPDISABLE) begin
	   end else if (sel==4'hF) begin
			data_o <= data_o_t;
		end else
			data_o <= `ZEROWORD;
	 end


endmodule
