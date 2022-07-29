`include "macro.v"
module data_ram(
	input wire clk,
	input wire ce,
   input wire we,
	input wire[`DATAADDRBUS] addr,
	input wire[3:0] sel,
	input wire[`DATABUS] data_i,
	output reg[`DATABUS] data_o
);
	
	wire[`BYTEWIDTH] data_mem0, data_mem1, data_mem2, data_mem3;
	
	data_ram_ip ram0(
		.rdaddress(addr[`DATAMEMNUMLOG2+1:2]), 
		.wraddress(addr[`DATAMEMNUMLOG2+1:2]),
		.clock(clk), 
		.data(data_i[7:0]), 
		.wren(ce&&we&&sel[0]), 
		.q(data_mem0)
	);
	
	data_ram_ip ram1(
		.rdaddress(addr[`DATAMEMNUMLOG2+1:2]), 
		.wraddress(addr[`DATAMEMNUMLOG2+1:2]),
		.clock(clk), 
		.data(data_i[15:8]), 
		.wren(ce&&we&&sel[1]), 
		.q(data_mem1)
	);
	
	data_ram_ip ram2(
		.rdaddress(addr[`DATAMEMNUMLOG2+1:2]),
		.wraddress(addr[`DATAMEMNUMLOG2+1:2]),	
		.clock(clk), 
		.data(data_i[23:16]), 
		.wren(ce&&we&&sel[2]), 
		.q(data_mem2)
	);
	
	data_ram_ip ram3(
		.rdaddress(addr[`DATAMEMNUMLOG2+1:2]), 
		.wraddress(addr[`DATAMEMNUMLOG2+1:2]),
		.clock(clk), 
		.data(data_i[31:24]), 
		.wren(ce&&we&&sel[3]), 
		.q(data_mem3)
	);
	
	always @(posedge clk) begin
		if (ce == `CHIPDISABLE) begin
	   end else if (we == `WRITEDISABLE) begin
			data_o <= {data_mem3, data_mem2, data_mem1, data_mem0};
		end else
			data_o <= `ZEROWORD;
	end
	
endmodule 