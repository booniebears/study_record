`include "macro.v"

module id(
    input wire rst,
    input wire[`INSTADDRBUS] pc_i,
    input wire[`INSTBUS] inst_i,

    input wire[`REGBUS] reg1_data_i,
    input wire[`REGBUS] reg2_data_i,

    // Data from Execution
    input wire ex_wreg_i,
    input wire[`REGBUS] ex_wdata_i,
    input wire[`REGADDRBUS] ex_wd_i,
	 input wire[`ALUOPBUS] ex_aluop_i,
    // Data from Writeback
    input wire mem_wreg_i,
    input wire[`REGBUS] mem_wdata_i,
    input wire[`REGADDRBUS] mem_wd_i,
	 
	 input wire is_in_delayslot_i,

    output reg reg1_read_o,
    output reg reg2_read_o,
    output reg[`REGADDRBUS] reg1_addr_o,
    output reg[`REGADDRBUS] reg2_addr_o,

    output reg[`ALUOPBUS] aluop_o,
    output reg[`ALUSELBUS] alusel_o,
    output reg[`REGBUS] reg1_o,
    output reg[`REGBUS] reg2_o,
    output reg[`REGADDRBUS] wd_o,
    output reg wreg_o,
	 
	 output reg next_inst_in_delayslot_o,
	 
	 output reg	jmp_flag_o,
	 output reg[`REGBUS] jmp_target_address_o,
	 output reg[`REGBUS] link_addr_o,
	 output reg	is_in_delayslot_o,
	 
	 output wire stallreq,
	 
	 output wire[`REGBUS] inst_o
);

    wire[5:0] op = inst_i[31:26]; //Instruction Code
    wire[4:0] sa= inst_i[10:6];   //sa
    wire[5:0] func = inst_i[5:0]; //Function Code
    wire[4:0] rt = inst_i[20:16]; //rt
	 wire[4:0] rs = inst_i[25:21]; //rs
	 wire[4:0] rd = inst_i[15:11]; //rd
	 assign inst_o = inst_i;
    reg[`REGBUS] imm;
    reg instvalid;
	 
	 wire[`REGBUS] pc_plus_8;
	 wire[`REGBUS] pc_plus_4;
	 wire[`REGBUS] imm_sll2_signedext;
	 assign pc_plus_8 = pc_i + 8;
	 assign pc_plus_4 = pc_i + 4;
	 assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00 };
	 
	 reg stallreq_for_reg1_loadrelate;
	 reg stallreq_for_reg2_loadrelate;
	 wire pre_inst_is_load;
	 assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;
	 assign pre_inst_is_load = (
											(ex_aluop_i == `EXE_LBU_OP)||
											(ex_aluop_i == `EXE_LH_OP) ||
											(ex_aluop_i == `EXE_LHU_OP)||
											(ex_aluop_i == `EXE_LW_OP) ||
											(ex_aluop_i == `EXE_LWR_OP)||
											(ex_aluop_i == `EXE_LWL_OP)||
											(ex_aluop_i == `EXE_LL_OP) ||
											(ex_aluop_i == `EXE_SC_OP)
										) ? 1'b1 : 1'b0;

    always @(*) begin
        if (rst==`RSTENABLE) begin 
            aluop_o <= `EXE_NOP_OP;
            alusel_o<= `EXE_RES_NOP;
            wd_o    <= `NOPREGADDR;
            wreg_o <= `WRITEDISABLE;
            instvalid <= `INSTVALID;
            reg1_read_o <= `READDISABLE;
            reg2_read_o <= `READDISABLE;
            reg1_addr_o <= `NOPREGADDR;
            reg2_addr_o <= `NOPREGADDR;
            imm <= `ZEROWORD;
				link_addr_o <= `ZEROWORD;
				jmp_target_address_o <= `ZEROWORD;
				jmp_flag_o <= `NOJMP;
				next_inst_in_delayslot_o <= `NOTINDELAYSLOT;
        end else begin 
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wd_o    <= rd;
            wreg_o <= `WRITEDISABLE;
            instvalid <= `INSTINVALID;
            reg1_read_o <= `READDISABLE;
            reg2_read_o <= `READDISABLE;
            reg1_addr_o <= rs;
            reg2_addr_o <= rt;
            imm <= `ZEROWORD;
				link_addr_o <= `ZEROWORD;
				jmp_target_address_o <= `ZEROWORD;
				jmp_flag_o <= `NOJMP;
				next_inst_in_delayslot_o <= `NOTINDELAYSLOT;

            case (op)
					`EXE_SPECIAL: begin
								case (func)
								   //LOGIC
									`EXE_OR: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_OR_OP;
										alusel_o <= `EXE_RES_LOGIC;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_AND: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_AND_OP;
										alusel_o <= `EXE_RES_LOGIC;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_XOR: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_XOR_OP;
										alusel_o <= `EXE_RES_LOGIC;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_NOR: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_NOR_OP;
										alusel_o <= `EXE_RES_LOGIC;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									//SHIFT
									`EXE_SLLV: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_SLL_OP;
										alusel_o <= `EXE_RES_SHIFT;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_SRLV: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_SRL_OP;
										alusel_o <= `EXE_RES_SHIFT;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_SRAV: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_SRAV_OP;
										alusel_o <= `EXE_RES_SHIFT;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_SYNC: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_NOP_OP;
										alusel_o <= `EXE_RES_NOP;
										reg1_read_o <= `READDISABLE;
										reg2_read_o <= `READDISABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_SLL: begin
										if (rs==`NOPREGADDR) begin
											wreg_o <= `WRITEENABLE;
											aluop_o <= `EXE_SLL_OP;
											alusel_o <= `EXE_RES_SHIFT;
											reg1_read_o <= `READDISABLE;
											reg2_read_o <= `READENABLE;
											imm[4:0] <= sa;
											instvalid <= `INSTVALID;
										end
									end
									
									`EXE_SRL: begin
										if (rs==`NOPREGADDR) begin
											wreg_o <= `WRITEENABLE;
											aluop_o <= `EXE_SRL_OP;
											alusel_o <= `EXE_RES_SHIFT;
											reg1_read_o <= `READDISABLE;
											reg2_read_o <= `READENABLE;
											imm[4:0] <= sa;
											instvalid <= `INSTVALID;
										end
									end
									
									`EXE_SRA: begin
										if (rs==`NOPREGADDR) begin
											wreg_o <= `WRITEENABLE;
											aluop_o <= `EXE_SRA_OP;
											alusel_o <= `EXE_RES_SHIFT;
											reg1_read_o <= `READDISABLE;
											reg2_read_o <= `READENABLE;
											imm[4:0] <= sa;
											instvalid <= `INSTVALID;
										end
									end
									//MOVE
									`EXE_MFHI: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_MFHI_OP;
										alusel_o <= `EXE_RES_MOVE;
										reg1_read_o <= `READDISABLE;
										reg2_read_o <= `READDISABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_MFLO: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_MFLO_OP;
										alusel_o <= `EXE_RES_MOVE;
										reg1_read_o <= `READDISABLE;
										reg2_read_o <= `READDISABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_MTHI: begin
										wreg_o <= `WRITEDISABLE;
										aluop_o <= `EXE_MTHI_OP;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READDISABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_MTLO: begin
										wreg_o <= `WRITEDISABLE;
										aluop_o <= `EXE_MTLO_OP;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READDISABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_MOVN: begin
										aluop_o <= `EXE_MOVN_OP;
										alusel_o <= `EXE_RES_MOVE;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
										if (reg2_o != `ZEROWORD) begin
											wreg_o <= `WRITEENABLE;
										end else begin
											wreg_o <= `WRITEDISABLE;
										end
									end
									
									`EXE_MOVZ: begin
										aluop_o <= `EXE_MOVZ_OP;
										alusel_o <= `EXE_RES_MOVE;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
										if (reg2_o == `ZEROWORD) begin
											wreg_o <= `WRITEENABLE;
										end else begin
											wreg_o <= `WRITEDISABLE;
										end
									end
									//ARITHMATIC
									`EXE_SLT: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_SLT_OP;
										alusel_o <= `EXE_RES_ARITH;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_SLTU: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_SLTU_OP;
										alusel_o <= `EXE_RES_ARITH;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_ADD: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_ADD_OP;
										alusel_o <= `EXE_RES_ARITH;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_ADDU: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_ADDU_OP;
										alusel_o <= `EXE_RES_ARITH;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_SUB: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_SUB_OP;
										alusel_o <= `EXE_RES_ARITH;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_SUBU: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_SUBU_OP;
										alusel_o <= `EXE_RES_ARITH;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_MULT: begin
										wreg_o <= `WRITEDISABLE;
										aluop_o <= `EXE_MULT_OP;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_MULTU: begin
										wreg_o <= `WRITEDISABLE;
										aluop_o <= `EXE_MULTU_OP;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_DIV: begin
										wreg_o <= `WRITEDISABLE;
										aluop_o <= `EXE_DIV_OP;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									
									`EXE_DIVU: begin
										wreg_o <= `WRITEDISABLE;
										aluop_o <= `EXE_DIVU_OP;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READENABLE;
										instvalid <= `INSTVALID;
									end
									//JMP
									`EXE_JR: begin
										wreg_o	<= `WRITEDISABLE;
										aluop_o	<= `EXE_JR_OP;
										alusel_o <= `EXE_RES_JUMP;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READDISABLE;
										instvalid <= `INSTVALID;
										
										jmp_target_address_o <= reg1_o;
										jmp_flag_o <= `JMP;
										next_inst_in_delayslot_o <= `INDELAYSLOT;
									end
									
									`EXE_JALR: begin
										wreg_o <= `WRITEENABLE;
										aluop_o <= `EXE_JALR_OP;
										alusel_o <= `EXE_RES_JUMP;
										reg1_read_o <= `READENABLE;
										reg2_read_o <= `READDISABLE;
										wd_o <= rd;
										instvalid <= `INSTVALID;
										
										link_addr_o <= pc_plus_8;
										jmp_target_address_o <= reg1_o;
										jmp_flag_o <= `JMP;
										next_inst_in_delayslot_o <= `INDELAYSLOT;
									end
									
									default: begin
									end
									
								endcase
					end
					//LOGIC
               `EXE_ORI: begin
						  wreg_o <= `WRITEENABLE;
						  aluop_o<= `EXE_OR_OP;
						  alusel_o<=`EXE_RES_LOGIC;
						  reg1_read_o <= `READENABLE;
						  reg2_read_o <= `READDISABLE;
						  imm <= {16'h0, inst_i[15:0]};
						  wd_o <= rt;
						  instvalid <= `INSTVALID;
					 end
					 
					 `EXE_ANDI: begin
					 	  wreg_o <= `WRITEENABLE;
						  aluop_o<= `EXE_AND_OP;
						  alusel_o<=`EXE_RES_LOGIC;
						  reg1_read_o <= `READENABLE;
						  reg2_read_o <= `READDISABLE;
						  imm <= {16'h0, inst_i[15:0]};
						  wd_o <= rt;
						  instvalid <= `INSTVALID;
					 end
					 
					 `EXE_XORI: begin
					 	  wreg_o <= `WRITEENABLE;
						  aluop_o<= `EXE_XOR_OP;
						  alusel_o<=`EXE_RES_LOGIC;
						  reg1_read_o <= `READENABLE;
						  reg2_read_o <= `READDISABLE;
						  imm <= {16'h0, inst_i[15:0]};
						  wd_o <= rt;
						  instvalid <= `INSTVALID;
					 end
					 
					 `EXE_LUI: begin
					 	  wreg_o <= `WRITEENABLE;
						  aluop_o<= `EXE_OR_OP;
						  alusel_o<=`EXE_RES_LOGIC;
						  reg1_read_o <= `READENABLE;
						  reg2_read_o <= `READDISABLE;
						  imm <= {inst_i[15:0], 16'h0};
						  wd_o <= rt;
						  instvalid <= `INSTVALID;
					 end
					 
					 `EXE_PREF: begin
					 	  wreg_o <= `WRITEENABLE;
						  aluop_o<= `EXE_NOP_OP;
						  alusel_o<=`EXE_RES_NOP;
						  reg1_read_o <= `READDISABLE;
						  reg2_read_o <= `READDISABLE;
						  instvalid <= `INSTVALID;
					 end
					 //ARITHMATIC
					 `EXE_SLTI: begin
					     wreg_o <= `WRITEENABLE;
						  aluop_o <= `EXE_SLT_OP;
						  alusel_o <= `EXE_RES_ARITH;
						  reg1_read_o <= `READENABLE;
						  reg2_read_o <= `READDISABLE;
						  imm <= {{16{inst_i[15]}},inst_i[15:0]};
						  wd_o <= rt;
						  instvalid <= `INSTVALID;
					 end
					 
					 `EXE_SLTIU: begin
					     wreg_o <= `WRITEENABLE;
						  aluop_o <= `EXE_SLTU_OP;
						  alusel_o <= `EXE_RES_ARITH;
						  reg1_read_o <= `READENABLE;
						  reg2_read_o <= `READDISABLE;
						  imm <= {{16{inst_i[15]}},inst_i[15:0]};
						  wd_o <= rt;
						  instvalid <= `INSTVALID;
					 end
					 
					 `EXE_ADDI: begin
						  wreg_o <= `WRITEENABLE;
						  aluop_o <= `EXE_ADD_OP;
						  alusel_o <= `EXE_RES_ARITH;
						  reg1_read_o <= `READENABLE;
						  reg2_read_o <= `READDISABLE;
						  imm <= {{16{inst_i[15]}},inst_i[15:0]};
						  wd_o <= rt;
						  instvalid <= `INSTVALID;
					 end
					 
					 `EXE_ADDIU: begin
					     wreg_o <= `WRITEENABLE;
						  aluop_o <= `EXE_ADDU_OP;
						  alusel_o <= `EXE_RES_ARITH;
						  reg1_read_o <= `READENABLE;
						  reg2_read_o <= `READDISABLE;
						  imm <= {{16{inst_i[15]}},inst_i[15:0]};
						  wd_o <= rt;
						  instvalid <= `INSTVALID;
					 end
					 //JMP
					 `EXE_J: begin
						  wreg_o <= `WRITEDISABLE;
						  aluop_o <= `EXE_J_OP;
						  alusel_o <= `EXE_RES_JUMP;
						  reg1_read_o <= `READDISABLE;
						  reg2_read_o <= `READDISABLE;
						  instvalid <= `INSTVALID;
						  
						  jmp_flag_o <= `JMP;
						  next_inst_in_delayslot_o <= `INSTVALID;
						  jmp_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
					 end
					 
					 `EXE_JAL: begin
						  wreg_o <= `WRITEENABLE;
						  aluop_o <= `EXE_JAL_OP;
						  alusel_o	<= `EXE_RES_JUMP;
						  reg1_read_o	<= `READDISABLE;
						  reg2_read_o  <= `READDISABLE;
						  wd_o <= 5'b11111;
						  instvalid <= `INSTVALID;
						  
						  link_addr_o <= pc_plus_8;
						  jmp_flag_o  <= `JMP;
						  jmp_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
						  next_inst_in_delayslot_o <= `INDELAYSLOT;
					end
					
					`EXE_BEQ: begin
						  wreg_o <= `WRITEDISABLE;
						  aluop_o <= `EXE_BEQ_OP;
						  alusel_o <= `EXE_RES_JUMP;
						  reg1_read_o <= `READENABLE;
						  reg2_read_o <= `READENABLE;
						  instvalid <= `INSTVALID;
						  if (reg1_o == reg2_o) begin
								jmp_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								jmp_flag_o <= `JMP;
								next_inst_in_delayslot_o <= `INDELAYSLOT;
						  end
					end
					
					`EXE_BGTZ: begin
						  wreg_o <= `WRITEDISABLE;
						  aluop_o <= `EXE_BGTZ_OP;
						  alusel_o <= `EXE_RES_JUMP;
						  reg1_read_o <= `READENABLE;
						  reg2_read_o <= `READDISABLE;
						  instvalid <= `INSTVALID;
						  if ((reg1_o[31]==1'b0)&&(reg1_o!=`ZEROWORD)) begin
								jmp_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								jmp_flag_o <= `JMP;
								next_inst_in_delayslot_o <= `INDELAYSLOT;
						  end
					end
					
					`EXE_BLEZ: begin
						  wreg_o <= `WRITEDISABLE;
						  aluop_o <= `EXE_BLEZ_OP;
						  alusel_o <= `EXE_RES_JUMP;
						  reg1_read_o <= `READENABLE;
						  reg2_read_o <= `READDISABLE;
						  instvalid <= `INSTVALID;
						  if ((reg1_o[31]==1'b1)||(reg1_o ==`ZEROWORD)) begin
								jmp_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								jmp_flag_o <= `JMP;
								next_inst_in_delayslot_o <= `INDELAYSLOT;
						  end
					end
					
					`EXE_BNE: begin
						  wreg_o <= `WRITEDISABLE;
						  aluop_o <= `EXE_BNE_OP;
						  alusel_o <= `EXE_RES_JUMP;
						  reg1_read_o <= `READENABLE;
						  reg2_read_o <= `READENABLE;
						  instvalid <= `INSTVALID;
						  if (reg1_o != reg2_o) begin
								jmp_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								jmp_flag_o <= `JMP;
								next_inst_in_delayslot_o <= `INDELAYSLOT;
						  end
					end
					
					`EXE_REGIMM: begin
						  case (rt)
								`EXE_BGEZ: begin
									wreg_o <= `WRITEDISABLE;
									aluop_o <= `EXE_BGEZ_OP;
									alusel_o <= `EXE_RES_JUMP;
									reg1_read_o <= `READENABLE;
									reg2_read_o <= `READDISABLE;
									instvalid <= `INSTVALID;
								   if (reg1_o[31]==1'b0) begin
										jmp_target_address_o <= pc_plus_4 + imm_sll2_signedext;
										jmp_flag_o <= `JMP;
										next_inst_in_delayslot_o <= `INDELAYSLOT;
								   end
								end
								
								`EXE_BGEZAL: begin
									wreg_o <= `WRITEENABLE;
									aluop_o <= `EXE_BGEZAL_OP;
									alusel_o <= `EXE_RES_JUMP;
									reg1_read_o <= `READENABLE;
									reg2_read_o <= `READDISABLE;
									wd_o <= 5'b11111;
									instvalid <= `INSTVALID;
									link_addr_o <= pc_plus_8; 
								   if (reg1_o[31]==1'b0) begin
										jmp_target_address_o <= pc_plus_4 + imm_sll2_signedext;
										jmp_flag_o <= `JMP;
										next_inst_in_delayslot_o <= `INDELAYSLOT;
								   end
								end
								
								`EXE_BLTZ: begin
									wreg_o <= `WRITEDISABLE;
									aluop_o <= `EXE_BLTZ_OP;
									alusel_o <= `EXE_RES_JUMP;
									reg1_read_o <= `READENABLE;
									reg2_read_o <= `READDISABLE;
									instvalid <= `INSTVALID;
								   if (reg1_o[31]==1'b1) begin
										jmp_target_address_o <= pc_plus_4 + imm_sll2_signedext;
										jmp_flag_o <= `JMP;
										next_inst_in_delayslot_o <= `INDELAYSLOT;
								   end
								end
								
								`EXE_BLTZAL: begin
									wreg_o <= `WRITEENABLE;
									aluop_o <= `EXE_BLTZAL_OP;
									alusel_o <= `EXE_RES_JUMP;
									reg1_read_o <= `READENABLE;
									reg2_read_o <= `READDISABLE;
									wd_o <= 5'b11111;
									link_addr_o <= pc_plus_8; 
									instvalid <= `INSTVALID;
								   if (reg1_o[31]==1'b1) begin
										jmp_target_address_o <= pc_plus_4 + imm_sll2_signedext;
										jmp_flag_o <= `JMP;
										next_inst_in_delayslot_o <= `INDELAYSLOT;
								   end
								end
								
								default: begin
								end
						  endcase
					  end
					
					  //LOAD
					`EXE_LB: begin
						wreg_o <= `WRITEENABLE;
						aluop_o <= `EXE_LB_OP;
						alusel_o <= `EXE_RES_LS;
						reg1_read_o <= `READENABLE;
						reg2_read_o <= `READDISABLE;
						wd_o <= rt;
						instvalid <= `INSTVALID;
					end
					
					`EXE_LBU: begin
						wreg_o <= `WRITEENABLE;
						aluop_o <= `EXE_LBU_OP;
						alusel_o <= `EXE_RES_LS;
						reg1_read_o <= `READENABLE;
						reg2_read_o <= `READDISABLE;
						wd_o <= rt;
						instvalid <= `INSTVALID;
					end
					
					`EXE_LH: begin
						wreg_o <= `WRITEENABLE;
						aluop_o <= `EXE_LH_OP;
						alusel_o <= `EXE_RES_LS;
						reg1_read_o <= `READENABLE;
						reg2_read_o <= `READDISABLE;
						wd_o <= rt;
						instvalid <= `INSTVALID;
					end
					
					`EXE_LHU: begin
						wreg_o <= `WRITEENABLE;
						aluop_o <= `EXE_LHU_OP;
						alusel_o <= `EXE_RES_LS;
						reg1_read_o <= `READENABLE;
						reg2_read_o <= `READDISABLE;
						wd_o <= rt;
						instvalid <= `INSTVALID;
					end
					
					`EXE_LW: begin
						wreg_o <= `WRITEENABLE;
						aluop_o <= `EXE_LW_OP;
						alusel_o <= `EXE_RES_LS;
						reg1_read_o <= `READENABLE;
						reg2_read_o <= `READDISABLE;
						wd_o <= rt;
						instvalid <= `INSTVALID;
					end
					
					`EXE_LWL: begin
						wreg_o <= `WRITEENABLE;
						aluop_o <= `EXE_LWL_OP;
						alusel_o <= `EXE_RES_LS;
						reg1_read_o <= `READENABLE;
						reg2_read_o <= `READENABLE;
						wd_o <= rt;
						instvalid <= `INSTVALID;
					end
					
					`EXE_LWR: begin
						wreg_o <= `WRITEENABLE;
						aluop_o <= `EXE_LWR_OP;
						alusel_o <= `EXE_RES_LS;
						reg1_read_o <= `READENABLE;
						reg2_read_o <= `READENABLE;
						wd_o <= rt;
						instvalid <= `INSTVALID;
					end
					//STORE
					`EXE_SB: begin
						wreg_o <= `WRITEDISABLE;
						aluop_o <= `EXE_SB_OP;
						alusel_o <= `EXE_RES_LS;
						reg1_read_o <= `READENABLE;
						reg2_read_o <= `READENABLE;
						instvalid <= `INSTVALID;
					end
					
					`EXE_SH: begin
						wreg_o <= `WRITEDISABLE;
						aluop_o <= `EXE_SH_OP;
						alusel_o <= `EXE_RES_LS;
						reg1_read_o <= `READENABLE;
						reg2_read_o <= `READENABLE;
						instvalid <= `INSTVALID;
					end
					
					`EXE_SW: begin
						wreg_o <= `WRITEDISABLE;
						aluop_o <= `EXE_SW_OP;
						alusel_o <= `EXE_RES_LS;
						reg1_read_o <= `READENABLE;
						reg2_read_o <= `READENABLE;
						instvalid <= `INSTVALID;
					end
					
					`EXE_SWL: begin
						wreg_o <= `WRITEDISABLE;
						aluop_o <= `EXE_SWL_OP;
						alusel_o <= `EXE_RES_LS;
						reg1_read_o <= `READENABLE;
						reg2_read_o <= `READENABLE;
						instvalid <= `INSTVALID;
					end
					
					`EXE_SWR: begin
						wreg_o <= `WRITEDISABLE;
						aluop_o <= `EXE_SWR_OP;
						alusel_o <= `EXE_RES_LS;
						reg1_read_o <= `READENABLE;
						reg2_read_o <= `READENABLE;
						instvalid <= `INSTVALID;
					end
					 
					 `EXE_SPECIAL2: begin
							case(func)
								`EXE_CLZ: begin
									wreg_o <= `WRITEENABLE;
									aluop_o <= `EXE_CLZ_OP;
									alusel_o <= `EXE_RES_ARITH;
									reg1_read_o <= `READENABLE;
									reg2_read_o <= `READDISABLE;
									instvalid <= `INSTVALID;
								end
								
								`EXE_CLO: begin
									wreg_o <= `WRITEENABLE;
									aluop_o <= `EXE_CLO_OP;
									alusel_o <= `EXE_RES_ARITH;
									reg1_read_o <= `READENABLE;
									reg2_read_o <= `READDISABLE;
									instvalid <= `INSTVALID;
								end
								
								`EXE_MUL: begin
									wreg_o <= `WRITEENABLE;
									aluop_o <= `EXE_MUL_OP;
									alusel_o <= `EXE_RES_ARITH;
									reg1_read_o <= `READENABLE;
									reg2_read_o <= `READENABLE;
									instvalid <= `INSTVALID;
								end
								
								`EXE_MADD: begin
									wreg_o <= `WRITEDISABLE;
									aluop_o <= `EXE_MADD_OP;
									//alusel_o <= `EXE_RES_MUL;
									reg1_read_o <= `READENABLE;
									reg2_read_o <= `READENABLE;
									instvalid <= `INSTVALID;
								end
								
								`EXE_MADDU: begin
									wreg_o <= `WRITEDISABLE;
									aluop_o <= `EXE_MADDU_OP;
									//alusel_o <= `EXE_RES_MUL;
									reg1_read_o <= `READENABLE;
									reg2_read_o <= `READENABLE;
									instvalid <= `INSTVALID;
								end
								
								`EXE_MSUB: begin
									wreg_o <= `WRITEDISABLE;
									aluop_o <= `EXE_MSUB_OP;
									//alusel_o <= `EXE_RES_MUL;
									reg1_read_o <= `READENABLE;
									reg2_read_o <= `READENABLE;
									instvalid <= `INSTVALID;
								end
								
								`EXE_MSUBU: begin
									wreg_o <= `WRITEDISABLE;
									aluop_o <= `EXE_MSUBU_OP;
									//alusel_o <= `EXE_RES_MUL;
									reg1_read_o <= `READENABLE;
									reg2_read_o <= `READENABLE;
									instvalid <= `INSTVALID;
								end
								
								default: begin
								end
							endcase
					 end
					 
               default: begin
               end
					 
            endcase

        end
    end


    always @(*) begin
		  stallreq_for_reg1_loadrelate <= `NOSTOP;
        if (rst==`RSTENABLE) begin
            reg1_o <= `ZEROWORD;
        // Data Hazzard
		  end else if ( pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o
							 && reg1_read_o == 1'b1 ) begin
				stallreq_for_reg1_loadrelate <= `STOP;
        end else if ((reg1_read_o==`READENABLE)&&(ex_wreg_i==`WRITEENABLE)&&(ex_wd_i==reg1_addr_o)) begin
            reg1_o <= ex_wdata_i;
        end else if ((reg1_read_o==`READENABLE)&&(mem_wreg_i==`WRITEENABLE)&&(mem_wd_i==reg1_addr_o)) begin
            reg1_o <= mem_wdata_i;
        end else if (reg1_read_o == `READENABLE) begin
            reg1_o <= reg1_data_i;
        end else if (reg1_read_o == `READDISABLE) begin
            reg1_o <= imm;
        end else begin
            reg1_o <= `ZEROWORD;
        end 
    end


    always @(*) begin
		  stallreq_for_reg2_loadrelate <= `NOSTOP;
        if (rst==`RSTENABLE) begin
            reg2_o <= `ZEROWORD;
        // Data Hazzard
		  end else if ( pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o
							 && reg2_read_o == 1'b1 ) begin
				stallreq_for_reg2_loadrelate <= `STOP;
        end else if ((reg2_read_o==`READENABLE)&&(ex_wreg_i==`WRITEENABLE)&&(ex_wd_i==reg2_addr_o)) begin
            reg2_o <= ex_wdata_i;
        end else if ((reg2_read_o==`READENABLE)&&(mem_wreg_i==`WRITEENABLE)&&(mem_wd_i==reg2_addr_o)) begin
            reg2_o <= mem_wdata_i;
        end else if (reg2_read_o == `READENABLE) begin
            reg2_o <= reg2_data_i;
        end else if (reg2_read_o == `READDISABLE) begin
            reg2_o <= imm;
        end else begin
            reg2_o <= `ZEROWORD;
        end 
    end
	 
	 
	 always @(*) begin
		  if (rst == `RSTENABLE) begin
			   is_in_delayslot_o <= `NOTINDELAYSLOT;
		  end else begin	
				is_in_delayslot_o <= is_in_delayslot_i;
		  end
	 end

endmodule
