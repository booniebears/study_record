`include "macro.v"
module pc_reg(
	input wire			clk,
	input wire			rst,
   input wire[5:0]   stall,
	
	input wire			jmp_flag_i,
	input wire[`REGBUS]      jmp_target_address_i,
	
	output reg[`INSTADDRBUS] pc,
	output reg			ce
);

	always @ (posedge clk) begin
		if (rst == `RSTENABLE) begin
			ce <= `CHIPDISABLE;
		end else begin
			ce <= `CHIPENABLE;
		end
	end
		
	always @ (posedge clk) begin
		if (ce == `CHIPDISABLE) begin
			pc <= 32'h00000000;
		end else if (stall[0] == `NOSTOP) begin
			if (jmp_flag_i == `JMP) begin
				pc <= jmp_target_address_i;
			end else begin
				pc <= pc + 4'h4;
			end
		end
	end
	
endmodule 
