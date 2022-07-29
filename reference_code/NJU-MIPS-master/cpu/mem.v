`include "macro.v"
module mem(
    input wire rst,

    input wire[`REGADDRBUS]  wd_i,
    input wire  wreg_i,
    input wire[`REGBUS]  wdata_i,
	 
	 input wire[`REGBUS]  hi_i,
	 input wire[`REGBUS]  lo_i,
	 input wire				 whilo_i,
	 
	 input wire[`ALUOPBUS] aluop_i,
	 input wire[`REGBUS]  mem_addr_i,
	 input wire[`REGBUS]  reg2_i,
	 
	 //From RAM
	 input wire[`REGBUS]  mem_data_i,

    output reg[`REGADDRBUS]  wd_o,
    output reg  wreg_o,
    output reg[`REGBUS]  wdata_o,
	 
	 output reg[`REGBUS]  hi_o,
	 output reg[`REGBUS]  lo_o,
	 output reg				 whilo_o,
	 
	 //To RAM
	 output reg[`REGBUS]  mem_addr_o,
	 output wire			 mem_we_o,
	 output reg[3:0]		 mem_sel_o,
	 output reg[`REGBUS]  mem_data_o,
	 output reg		 		 mem_ce_o
	 
);

	 wire[`REGBUS] zero32;
	 assign zero32 = `ZEROWORD;
	 reg mem_we;
	 assign mem_we_o = mem_we;
		

    always @(*) begin
        if (rst == `RSTENABLE) begin
            wd_o <= `NOPREGADDR;
            wreg_o <= `WRITEDISABLE;
            wdata_o <= `ZEROWORD;
				hi_o <= `ZEROWORD;
				lo_o <= `ZEROWORD;
				whilo_o <= `WRITEDISABLE;
				mem_addr_o <= `ZEROWORD;
				mem_we <= `WRITEDISABLE;
				mem_sel_o <= 4'b0000;
				mem_data_o <= `ZEROWORD;
				mem_ce_o <= `CHIPDISABLE;
        end else begin
            wd_o <= wd_i;
            wreg_o <= wreg_i;
            wdata_o <= wdata_i;
				hi_o <= hi_i;
				lo_o <= lo_i;
				whilo_o <= whilo_i;
				mem_addr_o <= `ZEROWORD;
				mem_we <= `WRITEDISABLE;
				mem_sel_o <= 4'b1111;
				mem_data_o <= `ZEROWORD;
				mem_ce_o <= `CHIPDISABLE;
				case (aluop_i)
					`EXE_LB_OP: begin
						mem_addr_o <= mem_addr_i;
						mem_we <= `WRITEDISABLE;
						mem_ce_o <= `CHIPENABLE;
						case (mem_addr_i[1:0])
							2'b00: begin
								wdata_o <= {{24{mem_data_i[31]}}, mem_data_i[31:24]};
								mem_sel_o <= 4'b1000;
							end
							2'b01: begin
								wdata_o <= {{24{mem_data_i[23]}}, mem_data_i[23:16]};
								mem_sel_o <= 4'b0100;
							end
							2'b10: begin
								wdata_o <= {{24{mem_data_i[15]}}, mem_data_i[15:8]};
								mem_sel_o <= 4'b0010;
							end
							2'b11: begin
								wdata_o <= {{24{mem_data_i[7]}}, mem_data_i[7:0]};
								mem_sel_o <= 4'b0001;
							end
							default: begin
								wdata_o <= `ZEROWORD;
							end
					  endcase
				  end
				  
					 `EXE_LBU_OP: begin
							mem_addr_o <= mem_addr_i;
							mem_we <= `WRITEDISABLE;
							mem_ce_o <= `CHIPENABLE;
							case (mem_addr_i[1:0])
								2'b00: begin
									wdata_o <= {{24{1'b0}}, mem_data_i[31:24]};
									mem_sel_o <= 4'b1000;
								end
								2'b01: begin
									wdata_o <= {{24{1'b0}}, mem_data_i[23:16]};
									mem_sel_o <= 4'b0100;
								end
								2'b10: begin
									wdata_o <= {{24{1'b0}}, mem_data_i[15:8]};
									mem_sel_o <= 4'b0010;
								end
								2'b11: begin
									wdata_o <= {{24{1'b0}}, mem_data_i[7:0]};
									mem_sel_o <= 4'b0001;
								end
								default: begin
									wdata_o <= `ZEROWORD;
								end
						  endcase
					  end
					  
					  `EXE_LH_OP: begin
							mem_addr_o <= mem_addr_i;
							mem_we <= `WRITEDISABLE;
							mem_ce_o <= `CHIPENABLE;
							case (mem_addr_i[1:0])
								2'b00: begin
									wdata_o <= {{16{mem_data_i[31]}}, mem_data_i[31:16]};
									mem_sel_o <= 4'b1100;
								end
								2'b10: begin
									wdata_o <= {{16{mem_data_i[15]}}, mem_data_i[15:0]};
									mem_sel_o <= 4'b0011;
								end
								default: begin
									wdata_o <= `ZEROWORD;
								end
						  endcase
					  end
					  
					  `EXE_LHU_OP: begin
							mem_addr_o <= mem_addr_i;
							mem_we <= `WRITEDISABLE;
							mem_ce_o <= `CHIPENABLE;
							case (mem_addr_i[1:0])
								2'b00: begin
									wdata_o <= {{16{1'b0}}, mem_data_i[31:16]};
									mem_sel_o <= 4'b1100;
								end
								2'b10: begin
									wdata_o <= {{16{1'b0}}, mem_data_i[15:0]};
									mem_sel_o <= 4'b0011;
								end
								default: begin
									wdata_o <= `ZEROWORD;
								end
						  endcase
					  end
					  
					  `EXE_LW_OP: begin
						  mem_addr_o <= mem_addr_i;
						  mem_we <= `WRITEDISABLE;
						  wdata_o <= mem_data_i;
						  mem_sel_o <= 4'b1111;
						  mem_ce_o <= `CHIPENABLE;
					  end
					  
					  `EXE_LWL_OP:	begin
							mem_addr_o <= {mem_addr_i[31:2], 2'b00};
							mem_we <= `WRITEDISABLE;
							mem_sel_o <= 4'b1111;
							mem_ce_o <= `CHIPENABLE;
							case (mem_addr_i[1:0])
								2'b00:	begin
									wdata_o <= mem_data_i[31:0];
								end
								2'b01:	begin
									wdata_o <= {mem_data_i[23:0],reg2_i[7:0]};
								end
								2'b10:	begin
									wdata_o <= {mem_data_i[15:0],reg2_i[15:0]};
								end
								2'b11:	begin
									wdata_o <= {mem_data_i[7:0],reg2_i[23:0]};	
								end
								default:	begin
									wdata_o <= `ZEROWORD;
								end
							endcase				
						end
						
					 `EXE_LWR_OP: begin
							mem_addr_o <= {mem_addr_i[31:2], 2'b00};
							mem_we <= `WRITEDISABLE;
							mem_sel_o <= 4'b1111;
							mem_ce_o <= `CHIPENABLE;
							case (mem_addr_i[1:0])
								2'b00:	begin
									wdata_o <= {reg2_i[31:8],mem_data_i[31:24]};
								end
								2'b01:	begin
									wdata_o <= {reg2_i[31:16],mem_data_i[31:16]};
								end
								2'b10:	begin
									wdata_o <= {reg2_i[31:24],mem_data_i[31:8]};
								end
								2'b11:	begin
									wdata_o <= mem_data_i;	
								end
								default:	begin
									wdata_o <= `ZEROWORD;
								end
							endcase					
					end
					//STORE
					`EXE_SB_OP: begin
							mem_addr_o <= mem_addr_i;
							mem_we <= `WRITEENABLE;
							mem_data_o <= {reg2_i[7:0], reg2_i[7:0], reg2_i[7:0], reg2_i[7:0]};
							mem_ce_o <= `CHIPENABLE;
							case (mem_addr_i[1:0])
								2'b00: begin
									mem_sel_o <= 4'b1000;
								end
								2'b01: begin
									mem_sel_o <= 4'b0100;
								end
								2'b10: begin
									mem_sel_o <= 4'b0010;
								end
								2'b11: begin
									mem_sel_o <= 4'b0001;
								end
								default: begin
									mem_sel_o <= 4'b0000;
								end
							endcase
					end
					
					`EXE_SH_OP: begin
							mem_addr_o <= mem_addr_i;
							mem_we <= `WRITEENABLE;
							mem_data_o <= {reg2_i[15:0], reg2_i[15:0]};
							mem_ce_o <= `CHIPENABLE;
							case (mem_addr_i[1:0])
								2'b00: begin
									mem_sel_o <= 4'b1100;
								end
								2'b10: begin
									mem_sel_o <= 4'b0011;
								end
								default: begin
									mem_sel_o <= 4'b0000;
								end
							endcase
					end
					
					`EXE_SW_OP: begin
							mem_addr_o <= mem_addr_i;
							mem_we <= `WRITEENABLE;
							mem_data_o <= reg2_i;
							mem_sel_o <= 4'b1111;
							mem_ce_o <= `CHIPENABLE;
					end
					
					`EXE_SWL_OP: begin
						mem_addr_o <= {mem_addr_i[31:2], 2'b00};
						mem_we <= `WRITEENABLE;
						mem_ce_o <= `CHIPENABLE;
						case (mem_addr_i[1:0])
							2'b00:	begin						  
								mem_sel_o <= 4'b1111;
								mem_data_o <= reg2_i;
							end
							2'b01:	begin
								mem_sel_o <= 4'b0111;
								mem_data_o <= {zero32[7:0],reg2_i[31:8]};
							end
							2'b10:	begin
								mem_sel_o <= 4'b0011;
								mem_data_o <= {zero32[15:0],reg2_i[31:16]};
							end
							2'b11:	begin
								mem_sel_o <= 4'b0001;	
								mem_data_o <= {zero32[23:0],reg2_i[31:24]};
							end
							default:	begin
								mem_sel_o <= 4'b0000;
							end
						endcase							
					end
				
					`EXE_SWR_OP: begin
						mem_addr_o <= {mem_addr_i[31:2], 2'b00};
						mem_we <= `WRITEENABLE;
						mem_ce_o <= `CHIPENABLE;
						case (mem_addr_i[1:0])
							2'b00:	begin						  
								mem_sel_o <= 4'b1000;
								mem_data_o <= {reg2_i[7:0],zero32[23:0]};
							end
							2'b01:	begin
								mem_sel_o <= 4'b1100;
								mem_data_o <= {reg2_i[15:0],zero32[15:0]};
							end
							2'b10:	begin
								mem_sel_o <= 4'b1110;
								mem_data_o <= {reg2_i[23:0],zero32[7:0]};
							end
							2'b11:	begin
								mem_sel_o <= 4'b1111;	
								mem_data_o <= reg2_i[31:0];
							end
							default:	begin
								mem_sel_o <= 4'b0000;
							end
						endcase											
					end 
					
					default: begin
					end
				endcase
        end
    end

endmodule
