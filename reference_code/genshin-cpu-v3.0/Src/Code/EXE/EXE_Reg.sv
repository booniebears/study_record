/*
 * @Author: npuwth
 * @Date: 2021-03-31 15:16:20
 * @LastEditTime: 2021-06-29 20:13:02
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */
 `include "../CPU_Defines.svh"
 `include "../CommonDefines.svh"

module EXE_Reg ( 
    input logic                          clk,
    input logic                          rst,
    input logic                          EXE_Flush,
    input logic                          EXE_Wr,

    input logic     [31:0]               ID_BusA,            //从RF中读出的A数据
	  input logic     [31:0]               ID_BusB,            //从RF中读出的B数据
	  input logic     [31:0]               ID_Imm32,           //在ID 被extend的 立即数
	  input logic 		[31:0]               ID_PC,
	  input logic     [31:0]               ID_Instr,
	  input logic 		[4:0]	               ID_rs,	
	  input logic 		[4:0]	               ID_rt,	
	  input logic 		[4:0]	               ID_rd,
	  input logic 		[4:0]                ID_ALUOp,	 		// ALU操作符
  	input LoadType        		           ID_LoadType,	 	// LoadType信号 
  	input StoreType       		           ID_StoreType,  		// StoreType信号
  	input RegsWrType      		           ID_RegsWrType,		// 寄存器写信号打包
  	input logic 		[1:0]   	           ID_WbSel,        	// 选择写回数据
  	input logic 		[1:0]   	           ID_DstSel,   		// 选择目标寄存器使能
  	input ExceptinPipeType 		           ID_ExceptType,		// 异常类型
	  input logic                          ID_ALUSrcA,
	  input logic                          ID_ALUSrcB,
	  input logic     [1:0]                ID_RegsReadSel,
	  input logic 					               ID_IsAImmeJump,
	  input BranchType                     ID_BranchType,
//-------------------------------------------------------------------------------//
    output logic     [31:0]              EXE_BusA,            //从RF中读出的A数据
	  output logic     [31:0]              EXE_BusB,            //从RF中读出的B数据
	  output logic     [31:0]              EXE_Imm32,           //在ID 被extend的 立即数
	  output logic 		 [31:0]              EXE_PC,
	  output logic     [31:0]              EXE_Instr,
	  output logic 		 [4:0]	             EXE_rs,	
	  output logic 		 [4:0]	             EXE_rt,	
	  output logic 		 [4:0]	             EXE_rd,
	  output logic 		 [4:0]               EXE_ALUOp,	 		// ALU操作符
  	output LoadType        		           EXE_LoadType,	 	// LoadType信号 
  	output StoreType       		           EXE_StoreType,  		// StoreType信号
  	output RegsWrType      		           EXE_RegsWrType,		// 寄存器写信号打包
  	output logic 	   [1:0]   	           EXE_WbSel,        	// 选择写回数据
  	output logic 	   [1:0]   	           EXE_DstSel,   		// 选择目标寄存器使能
  	output ExceptinPipeType 		         EXE_ExceptType,		// 异常类型
	  output logic                         EXE_ALUSrcA,
	  output logic                         EXE_ALUSrcB,
	  output logic     [1:0]               EXE_RegsReadSel,
	  output logic 					               EXE_IsAImmeJump,
	  output BranchType                    EXE_BranchType,
    output logic     [4:0]               EXE_Shamt

);

  always_ff @( posedge clk or negedge rst ) begin
    if( (rst == `RstEnable) || (EXE_Flush == `FlushEnable) ) begin
      EXE_BusA                           <= 32'b0;
      EXE_BusB                           <= 32'b0;
      EXE_Imm32                          <= 32'b0;
      EXE_PC                             <= 32'b0;
      EXE_rs                             <= 5'b0;
      EXE_rt                             <= 5'b0;
      EXE_rd                             <= 5'b0;
      EXE_ALUOp                          <= 5'b0;
      EXE_LoadType                       <= '0;
      EXE_StoreType                      <= '0;
      EXE_RegsWrType                     <= '0;
      EXE_WbSel                          <= 2'b0;
      EXE_DstSel                         <= 2'b0;
      EXE_ExceptType                     <= '0;
      EXE_Shamt                          <= 5'b0;
      EXE_BranchType                     <= '0;
      EXE_IsAImmeJump                    <= 1'b0;
      EXE_ALUSrcA                        <= 1'b0;
      EXE_ALUSrcB                        <= 1'b0;
      EXE_Instr                          <= 32'b0;
      EXE_RegsReadSel                    <= 2'b0;
    end
    else if( EXE_Wr ) begin
      EXE_BusA                           <= ID_BusA;
      EXE_BusB                           <= ID_BusB;
      EXE_Imm32                          <= ID_Imm32;
      EXE_PC                             <= ID_PC;
      EXE_rs                             <= ID_rs;
      EXE_rt                             <= ID_rt;
      EXE_rd                             <= ID_rd;
      EXE_ALUOp                          <= ID_ALUOp;
      EXE_LoadType                       <= ID_LoadType;
      EXE_StoreType                      <= ID_StoreType;
      EXE_RegsWrType                     <= ID_RegsWrType;
      EXE_WbSel                          <= ID_WbSel;
      EXE_DstSel                         <= ID_DstSel;
      EXE_ExceptType                     <= ID_ExceptType;
      EXE_Shamt                          <= ID_Imm32[10:6];
      EXE_BranchType                     <= ID_BranchType;
      EXE_IsAImmeJump                    <= ID_IsAImmeJump;
      EXE_ALUSrcA                        <= ID_ALUSrcA;
      EXE_ALUSrcB                        <= ID_ALUSrcB;
      EXE_Instr                          <= ID_Instr;
      EXE_RegsReadSel                    <= ID_RegsReadSel;
    end
  end

endmodule