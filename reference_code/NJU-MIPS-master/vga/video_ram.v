`include "macro.v"
module video_ram(
	input wire clk,
	input wire ce,
   input wire we,
	input wire[`VIDEOADDRBUS] addr,
	input wire[3:0] sel,
	input wire[`VIDEOBUS] data_i,
	output reg[`VIDEOBUS] data_o,
	
	input [11:0] vga_rdaddress,
	output reg [`BYTEWIDTH] vga_q
);
	
	wire[`BYTEWIDTH] data_mem0, data_mem1, data_mem2, data_mem3;
	wire[`BYTEWIDTH] video_mem0, video_mem1, video_mem2, video_mem3;
	
	video_ram_ip0 ram0(
		.clock(clk), 
		
		.address_a(addr[`VIDEOMEMNUMLOG2+1:2]),
		.wren_a(ce&&we&&sel[0]),
		.data_a(data_i[7:0]),
		.q_a(),
		
		.address_b(vga_rdaddress[`VIDEOMEMNUMLOG2+1:2]),
		.wren_b(1'b0),
		.data_b(`ZEROBYTE),
		.q_b(video_mem0)
	);
	
	video_ram_ip1 ram1(
		.clock(clk), 
		
		.address_a(addr[`VIDEOMEMNUMLOG2+1:2]),
		.wren_a(ce&&we&&sel[1]),
		.data_a(data_i[15:8]),
		.q_a(),
		
		.address_b(vga_rdaddress[`VIDEOMEMNUMLOG2+1:2]),
		.wren_b(1'b0),
		.data_b(`ZEROBYTE),
		.q_b(video_mem1)
	);
	
	video_ram_ip2 ram2(
		.clock(clk), 
		
		.address_a(addr[`VIDEOMEMNUMLOG2+1:2]),
		.wren_a(ce&&we&&sel[2]),
		.data_a(data_i[23:16]),
		.q_a(),
		
		.address_b(vga_rdaddress[`VIDEOMEMNUMLOG2+1:2]),
		.wren_b(1'b0),
		.data_b(`ZEROBYTE),
		.q_b(video_mem2)
	);
	
	video_ram_ip3 ram3(
		.clock(clk), 
		
		.address_a(addr[`VIDEOMEMNUMLOG2+1:2]),
		.wren_a(ce&&we&&sel[3]),
		.data_a(data_i[31:24]),
		.q_a(),
		
		.address_b(vga_rdaddress[`VIDEOMEMNUMLOG2+1:2]),
		.wren_b(1'b0),
		.data_b(`ZEROBYTE),
		.q_b(video_mem3)
	);
	
	video_ram_ip0 rambk0(
		.clock(clk), 
		
		.address_a(addr[`VIDEOMEMNUMLOG2+1:2]),
		.wren_a(ce&&we&&sel[0]),
		.data_a(data_i[7:0]),
		.q_a(),
		
		.address_b(addr[`VIDEOMEMNUMLOG2+1:2]),
		.wren_b(1'b0),
		.data_b(`ZEROBYTE),
		.q_b(data_mem0)
	);
	
	video_ram_ip1 rambk1(
		.clock(clk), 
		
		.address_a(addr[`VIDEOMEMNUMLOG2+1:2]),
		.wren_a(ce&&we&&sel[1]),
		.data_a(data_i[15:8]),
		.q_a(),
		
		.address_b(addr[`VIDEOMEMNUMLOG2+1:2]),
		.wren_b(1'b0),
		.data_b(`ZEROBYTE),
		.q_b(data_mem1)
	);
	
	video_ram_ip2 rambk2(
		.clock(clk), 
		
		.address_a(addr[`VIDEOMEMNUMLOG2+1:2]),
		.wren_a(ce&&we&&sel[2]),
		.data_a(data_i[23:16]),
		.q_a(),
		
		.address_b(addr[`VIDEOMEMNUMLOG2+1:2]),
		.wren_b(1'b0),
		.data_b(`ZEROBYTE),
		.q_b(data_mem2)
	);
	
	video_ram_ip3 rambk3(
		.clock(clk), 
		
		.address_a(addr[`VIDEOMEMNUMLOG2+1:2]),
		.wren_a(ce&&we&&sel[3]),
		.data_a(data_i[31:24]),
		.q_a(),
		
		.address_b(addr[`VIDEOMEMNUMLOG2+1:2]),
		.wren_b(1'b0),
		.data_b(`ZEROBYTE),
		.q_b(data_mem3)
	);

	
	always @(posedge clk) begin
		if (ce == `CHIPDISABLE) begin
	   end else if (we == `WRITEDISABLE) begin
			data_o <= {data_mem3, data_mem2, data_mem1, data_mem0};
		end else
			data_o <= `ZEROWORD;
	end
	
	always @(posedge clk) begin
		case (vga_rdaddress[1:0])
			2'd3: vga_q <= video_mem0;
			2'd2: vga_q <= video_mem1;
			2'd1: vga_q <= video_mem2;
			2'd0: vga_q <= video_mem3;
			default: begin
			end
		endcase
	end
	
endmodule 