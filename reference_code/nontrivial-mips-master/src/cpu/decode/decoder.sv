`include "cpu_defs.svh"

module decoder(
	input  virt_t          vaddr,
	input  uint32_t        instr,
	output decoded_instr_t decoded_instr
);

// setup instruction fields
logic [5:0] opcode, funct;
reg_addr_t rs, rt, rd;

virt_t pc_plus4;
assign pc_plus4 = vaddr + 32'd4;
assign decoded_instr.default_jump_i = pc_plus4
       + { {14{instr[15]}}, instr[15:0], 2'b0 };
assign decoded_instr.default_jump_j = {
       pc_plus4[31:28], instr[25:0], 2'b0 };

assign opcode    = instr[31:26];
assign rs        = instr[25:21];
assign rt        = instr[20:16];
assign rd        = instr[15:11];
assign funct     = instr[5:0];

`ifdef ENABLE_FPU
reg_addr_t fs, ft, fd;
assign ft = instr[20:16];
assign fs = instr[15:11];
assign fd = instr[10:6];
`endif

logic is_branch, is_jump_i, is_jump_r, is_call, is_return;
decode_branch branch_decoder_inst(
	.*,
	.imm_branch(),
	.imm_jump()
);

always_comb begin
	unique casez( { is_branch, is_return, is_call, is_jump_i | is_jump_r } )
		4'b1???: decoded_instr.cf = ControlFlow_Branch;
		4'b01??: decoded_instr.cf = ControlFlow_Return;
		4'b001?: decoded_instr.cf = ControlFlow_Call;
		4'b0001: decoded_instr.cf = ControlFlow_Jump;
		default: decoded_instr.cf = ControlFlow_None;
	endcase
end

always_comb begin
	decoded_instr.rs1        = '0;
	decoded_instr.rs2        = '0;
	decoded_instr.rd         = '0;
	`ifdef ENABLE_FPU
	decoded_instr.fs1        = '0;
	decoded_instr.fs2        = '0;
	decoded_instr.fd         = '0;
	decoded_instr.fpu_we     = 1'b0;
	decoded_instr.fcsr_we    = 1'b0;
	decoded_instr.is_fpu     = 1'b0;
	decoded_instr.is_fpu_multicyc = 1'b0;
	`endif
	decoded_instr.op         = OP_SLL;
	decoded_instr.use_imm    = 1'b0;
	decoded_instr.imm_signed = 1'b1;
	decoded_instr.is_load    = 1'b0;
	decoded_instr.is_store   = 1'b0;
	decoded_instr.is_priv    = opcode == 6'b101111 || opcode == 6'b010000;
	decoded_instr.delayed_exec   = 1'b0;
	decoded_instr.is_nonrw_priv  = 1'b0;
	decoded_instr.is_multicyc    = 1'b0;
	decoded_instr.is_controlflow = is_branch | is_jump_i | is_jump_r;

	unique casez(opcode)
		6'b000000: begin  // SPECIAL (Reg-Reg)
			decoded_instr.rs1 = rs;
			decoded_instr.rs2 = rt;
			decoded_instr.rd  = rd;
			unique case(funct)
				/* shift */
				6'b000000, 6'b000010, 6'b000011,
				6'b000100, 6'b000110, 6'b000111,
				/* add and substract (no exception) */
				6'b100001, 6'b100011,
				/* logical */
				6'b100100, 6'b100101, 6'b100110, 6'b100111,
				/* compare and set */
				6'b101010, 6'b101011:
					decoded_instr.delayed_exec = 1'b1;
				default: decoded_instr.delayed_exec = 1'b0;
			endcase
			unique casez(funct)
				6'b0110??: decoded_instr.is_multicyc = 1'b1;
				6'b0100?1: decoded_instr.is_multicyc = 1'b1;
				default:   decoded_instr.is_multicyc = 1'b0;
			endcase
			unique case(funct)
				/* shift */
				6'b000000: decoded_instr.op = OP_SLL;
				6'b000010: decoded_instr.op = OP_SRL;
				6'b000011: decoded_instr.op = OP_SRA;
				6'b000100: decoded_instr.op = OP_SLLV;
				6'b000110: decoded_instr.op = OP_SRLV;
				6'b000111: decoded_instr.op = OP_SRAV;
				/* unconditional jump (reg) */
				6'b001000: decoded_instr.op = OP_JALR;
				6'b001001: decoded_instr.op = OP_JALR;
				/* conditional move */
				6'b001011: decoded_instr.op = OP_MOVN;
				6'b001010: decoded_instr.op = OP_MOVZ;
				/* breakpoint and syscall */
				6'b001100: decoded_instr.op = OP_SYSCALL;
				6'b001101: decoded_instr.op = OP_BREAK;
				/* sync */
				6'b001111: decoded_instr.op = OP_SLL;
				/* HI/LO move */
				6'b010000: decoded_instr.op = OP_MFHI;
				6'b010001: decoded_instr.op = OP_MTHI;
				6'b010010: decoded_instr.op = OP_MFLO;
				6'b010011: decoded_instr.op = OP_MTLO;
				/* multiplication and division */
				6'b011000: decoded_instr.op = OP_MULT;
				6'b011001: decoded_instr.op = OP_MULTU;
				6'b011010: decoded_instr.op = OP_DIV;
				6'b011011: decoded_instr.op = OP_DIVU;
				/* add and substract */
				6'b100000: decoded_instr.op = OP_ADD;
				6'b100001: decoded_instr.op = OP_ADDU;
				6'b100010: decoded_instr.op = OP_SUB;
				6'b100011: decoded_instr.op = OP_SUBU;
				/* logical */
				6'b100100: decoded_instr.op = OP_AND;
				6'b100101: decoded_instr.op = OP_OR;
				6'b100110: decoded_instr.op = OP_XOR;
				6'b100111: decoded_instr.op = OP_NOR;
				/* compare and set */
				6'b101010: decoded_instr.op = OP_SLT;
				6'b101011: decoded_instr.op = OP_SLTU;
				`ifdef ENABLE_FPU
				/* FPU conditional move */
				6'b000001: begin
					decoded_instr.op  = OP_MOVCI;
					decoded_instr.rs2 = '0;
				end
				`endif
				`ifdef COMPILE_FULL_M
				/* trap */
				6'b110000: decoded_instr.op = OP_TGE;
				6'b110001: decoded_instr.op = OP_TGEU;
				6'b110010: decoded_instr.op = OP_TLT;
				6'b110011: decoded_instr.op = OP_TLTU;
				6'b110100: decoded_instr.op = OP_TEQ;
				6'b110110: decoded_instr.op = OP_TNE;
				`endif
				default:   decoded_instr.op = OP_INVALID;
			endcase
		end
		`ifdef COMPILE_FULL_M
		6'b011100: begin // SPECIAL2 (Reg-Reg)
			decoded_instr.rs1 = rs;
			decoded_instr.rs2 = rt;
			decoded_instr.rd  = rd;
			unique casez(funct)
				6'b000?0?, 6'b000010:
					decoded_instr.is_multicyc = 1'b1;
				default: decoded_instr.is_multicyc = 1'b0;
			endcase
			unique case(funct)
				6'b000000: decoded_instr.op = OP_MADD;
				6'b000001: decoded_instr.op = OP_MADDU;
				6'b000100: decoded_instr.op = OP_MSUB;
				6'b000101: decoded_instr.op = OP_MSUBU;
				6'b000010: decoded_instr.op = OP_MUL;
				6'b100000: decoded_instr.op = OP_CLZ;
				6'b100001: decoded_instr.op = OP_CLO;
				default:   decoded_instr.op = OP_INVALID;
			endcase
		end
		`endif
		6'b000001: begin // REGIMM (Reg-Imm)
			decoded_instr.rs1 = rs;
			decoded_instr.rd  = (instr[20:17] == 4'b1000) ? 5'd31 : 5'd0;
			decoded_instr.use_imm = 1'b1;
			decoded_instr.delayed_exec = (instr[19:17] == 3'b000) & `CPU_DELAYED_BRANCH;
			unique case(instr[20:16])
				`ifdef COMPILE_FULL_M
				/* trap */
				5'b01000: decoded_instr.op = OP_TGE;
				5'b01001: decoded_instr.op = OP_TGEU;
				5'b01010: decoded_instr.op = OP_TLT;
				5'b01011: decoded_instr.op = OP_TLTU;
				5'b01100: decoded_instr.op = OP_TEQ;
				5'b01110: decoded_instr.op = OP_TNE;
				`endif
				/* branch */
				5'b00000: decoded_instr.op = OP_BLTZ;
				5'b00001: decoded_instr.op = OP_BGEZ;
				5'b10000: decoded_instr.op = OP_BLTZAL;
				5'b10001: decoded_instr.op = OP_BGEZAL;
				default:  decoded_instr.op = OP_INVALID;
			endcase
		end

		6'b0001??: begin // branch (Reg-Imm)
			decoded_instr.rs1 = rs;
			decoded_instr.rs2 = rt;
			decoded_instr.delayed_exec = `CPU_DELAYED_BRANCH;
			unique case(opcode[1:0])
				2'b00: decoded_instr.op = OP_BEQ;
				2'b01: decoded_instr.op = OP_BNE;
				2'b10: decoded_instr.op = OP_BLEZ;
				2'b11: decoded_instr.op = OP_BGTZ;
			endcase
		end

		6'b001???: begin // logic and arithmetic (Reg-Imm)
			decoded_instr.rs1 = rs;
			decoded_instr.rd  = rt;
			decoded_instr.use_imm      = 1'b1;
			decoded_instr.delayed_exec = (opcode[2:0] != 3'b000);
			decoded_instr.imm_signed   = ~opcode[2];
			unique case(opcode[2:0])
				3'b100: decoded_instr.op = OP_AND;
				3'b101: decoded_instr.op = OP_OR;
				3'b110: decoded_instr.op = OP_XOR;
				3'b111: decoded_instr.op = OP_LUI;
				3'b000: decoded_instr.op = OP_ADD;
				3'b001: decoded_instr.op = OP_ADDU;
				3'b010: decoded_instr.op = OP_SLT;
				3'b011: decoded_instr.op = OP_SLTU;
			endcase
		end

		6'b100???: begin // load (Reg-Imm)
			decoded_instr.rs1     = rs;
			decoded_instr.rs2     = (opcode[1:0] == 2'b10) ? rt : '0;
			decoded_instr.rd      = rt;
			decoded_instr.is_load = 1'b1;
			unique case(opcode[2:0])
				3'b000: decoded_instr.op = OP_LB;
				3'b001: decoded_instr.op = OP_LH;
				3'b010: decoded_instr.op = OP_LWL;
				3'b011: decoded_instr.op = OP_LW;
				3'b100: decoded_instr.op = OP_LBU;
				3'b101: decoded_instr.op = OP_LHU;
				3'b110: decoded_instr.op = OP_LWR;
				3'b111: decoded_instr.op = OP_INVALID;
			endcase
		end

		6'b101???: begin // store (Reg-Imm)
			decoded_instr.rs1      = rs;
			decoded_instr.rs2      = rt;
			decoded_instr.is_store = 1'b1;
			unique case(opcode[2:0])
				3'b000:  decoded_instr.op = OP_SB;
				3'b001:  decoded_instr.op = OP_SH;
				3'b010:  decoded_instr.op = OP_SWL;
				3'b011:  decoded_instr.op = OP_SW;
				3'b110:  decoded_instr.op = OP_SWR;
				3'b111:  decoded_instr.op = OP_CACHE;
				default: decoded_instr.op = OP_INVALID;
			endcase
		end
		
		`ifdef COMPILE_FULL_M
		6'b110000: begin // load linked word (Reg-Imm)
			decoded_instr.rs1     = rs;
			decoded_instr.rd      = rt;
			decoded_instr.op      = OP_LL;
			decoded_instr.is_load = 1'b1;
		end
		
		6'b111000: begin // store conditional word (Reg-Imm)
			decoded_instr.rs1      = rs;
			decoded_instr.rs2      = rt;
			decoded_instr.rd       = rt;
			decoded_instr.op       = OP_SC;
			decoded_instr.is_store = 1'b1;
		end

		6'b110011: begin // prefetch
			decoded_instr.op = OP_SLL;
		end
		`endif
		
		6'b00001?: begin // jump and link
			decoded_instr.rd  = {$bits(reg_addr_t){opcode[0]}};
			decoded_instr.op  = OP_JAL;
		end

		6'b010000: begin // COP0
			unique case(instr[25:21])
				5'b00000: begin
					decoded_instr.op = OP_MFC0;
					decoded_instr.rd = rt;
					decoded_instr.is_multicyc = 1'b1;
				end
				5'b00100: begin
					decoded_instr.op  = OP_MTC0;
					decoded_instr.rs1 = rt;
				end
				5'b10000: begin
					decoded_instr.is_nonrw_priv = 1'b1;
					unique case(instr[5:0])
						`ifdef COMPILE_FULL_M
						6'b000001: decoded_instr.op = OP_TLBR;
						6'b000010: decoded_instr.op = OP_TLBWI;
						6'b000110: decoded_instr.op = OP_TLBWR;
						6'b001000: decoded_instr.op = OP_TLBP;
						6'b100000: decoded_instr.op = OP_SLL;  // wait
						`endif
						6'b011000: decoded_instr.op = OP_ERET;
						default: decoded_instr.op = OP_INVALID;
					endcase
				end
				default: decoded_instr.op = OP_INVALID;
			endcase
		end

`ifdef ENABLE_FPU
		6'b110101: begin
			decoded_instr.op      = OP_LDC1A;
			decoded_instr.rs1     = rs;
			decoded_instr.fd      = ft;
			decoded_instr.fpu_we  = 1'b1;
			decoded_instr.is_load = 1'b1;
			decoded_instr.is_fpu  = 1'b1;
		end
		6'b111101: begin
			decoded_instr.op       = OP_SDC1A;
			decoded_instr.rs1      = rs;
			decoded_instr.fs2      = ft;
			decoded_instr.is_store = 1'b1;
			decoded_instr.is_fpu   = 1'b1;
		end
		6'b110001: begin
			decoded_instr.op      = OP_LWC1;
			decoded_instr.rs1     = rs;
			decoded_instr.fd      = ft;
			decoded_instr.fpu_we  = 1'b1;
			decoded_instr.is_load = 1'b1;
			decoded_instr.is_fpu  = 1'b1;
		end
		6'b111001: begin
			decoded_instr.op       = OP_SWC1;
			decoded_instr.rs1      = rs;
			decoded_instr.fs2      = ft;
			decoded_instr.is_store = 1'b1;
			decoded_instr.is_fpu   = 1'b1;
		end
		6'b010001: begin  // COP1
			decoded_instr.is_fpu = 1'b1;
			unique case(instr[25:21])
				5'b00000: begin
					decoded_instr.op  = OP_MFC1;
					decoded_instr.rd  = rt;
					decoded_instr.fs1 = instr[15:11];
				end
				5'b00010: begin
					decoded_instr.op  = OP_CFC1;
					decoded_instr.rd  = rt;
				end
				5'b00100: begin
					decoded_instr.op  = OP_MTC1;
					decoded_instr.rs1 = rt;
					decoded_instr.fd  = instr[15:11];
					decoded_instr.fpu_we = 1'b1;
				end
				5'b00110: begin
					decoded_instr.op  = OP_CTC1;
					decoded_instr.rs1 = rt;
					decoded_instr.fcsr_we = 1'b1;
				end
				5'b01000: begin
					decoded_instr.op  = OP_BC1;
					decoded_instr.is_controlflow = 1'b1;
				end
				5'b10000: begin // fmt = S
					decoded_instr.fs1 = fs;
					decoded_instr.fs2 = ft;
					decoded_instr.fd  = fd;
					decoded_instr.fpu_we  = 1'b1;
					decoded_instr.fcsr_we = 1'b1;
					decoded_instr.is_fpu_multicyc = 1'b1;
					unique casez(instr[5:0])
						6'b000000: decoded_instr.op = OP_FPU_ADD;
						6'b000001: decoded_instr.op = OP_FPU_SUB;
						6'b000010: decoded_instr.op = OP_FPU_MUL;
						6'b000011: decoded_instr.op = OP_FPU_DIV;
						6'b000100: decoded_instr.op = OP_FPU_SQRT;
						6'b000101: decoded_instr.op = OP_FPU_ABS;
						6'b000111: decoded_instr.op = OP_FPU_NEG;
						6'b001100: decoded_instr.op = OP_FPU_ROUND;
						6'b001101: decoded_instr.op = OP_FPU_TRUNC;
						6'b001110: decoded_instr.op = OP_FPU_CEIL;
						6'b001111: decoded_instr.op = OP_FPU_FLOOR;
						6'b100100: decoded_instr.op = OP_FPU_CVTW;
						6'b000110: begin
							decoded_instr.op = OP_FPU_MOV;
							decoded_instr.is_fpu_multicyc = 1'b0;
						end
						6'b010001: begin
							decoded_instr.op = OP_FPU_CMOV;
							decoded_instr.fs2 = '0;
							decoded_instr.is_fpu_multicyc = 1'b0;
						end
						6'b01001?: begin
							decoded_instr.op = OP_FPU_CMOV;
							decoded_instr.rs2 = rt;
							decoded_instr.fs2 = '0;
							decoded_instr.is_fpu_multicyc = 1'b0;
						end
						6'b11????: begin
							decoded_instr.op = OP_FPU_COND;
							decoded_instr.fd = '0;
							decoded_instr.fpu_we = 1'b0;
						end
						default: begin
							decoded_instr.op = OP_INVALID;
							decoded_instr.fcsr_we = 1'b0;
							decoded_instr.fpu_we  = 1'b0;
							decoded_instr.is_fpu_multicyc = 1'b0;
						end
					endcase
				end
				5'b10100: begin // fmt = W
					decoded_instr.fs1 = fs;
					decoded_instr.fs2 = ft;
					decoded_instr.fd  = fd;
					decoded_instr.fpu_we  = 1'b1;
					decoded_instr.fcsr_we = 1'b1;
					decoded_instr.is_fpu_multicyc = 1'b1;
					unique casez(instr[5:0])
						6'b100000: decoded_instr.op = OP_FPU_CVTS;
						default: begin
							decoded_instr.op = OP_INVALID;
							decoded_instr.fcsr_we = 1'b0;
							decoded_instr.fpu_we  = 1'b0;
							decoded_instr.is_fpu_multicyc = 1'b0;
						end
					endcase
				end
				default: decoded_instr.op = OP_INVALID;
			endcase
		end
`endif

`ifdef ENABLE_ASIC
		6'b010010: begin // COP2
			unique case(instr[25:21])
				5'b00000: begin
					decoded_instr.op = OP_MFC2;
					decoded_instr.rd = rt;
					decoded_instr.is_multicyc = 1'b1;
				end
				5'b00100: begin
					decoded_instr.op  = OP_MTC2;
					decoded_instr.rs1 = rt;
				end
				default: decoded_instr.op = OP_INVALID;
			endcase
		end
`endif

		default: decoded_instr.op = OP_INVALID;
	endcase
end

endmodule
