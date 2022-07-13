/*
 * @Author: npuwth
 * @Date: 2021-04-03 10:24:26
 * @LastEditTime: 2021-07-20 10:25:22
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module MEM2_Reg (
//-----------------------------------------------------------------//   
    input logic                         clk,
    input logic                         rst,
    input logic                         MEM2_Flush,
    input logic                         MEM2_Wr,
    
    input logic		  [31:0] 		          MEM_ALUOut,		
    input logic 		[31:0] 	 	          MEM_PC,	
    input logic     [31:0]              MEM_Instr,		
    input logic 		[1:0]  		          MEM_WbSel,				
    input logic 		[4:0]  		          MEM_Dst,
    input logic     [31:0]              MEM_OutB,
	  input RegsWrType                    MEM_RegsWrType_final,//经过exception solvement的新写使能
	  input logic     [4:0]		            MEM_ExcType,
	  input logic                         MEM_IsABranch,
	  input logic                         MEM_IsAJumpCall,
	  input logic                         MEM_IsInDelaySlot,
    // input logic                         MEM_store_req,
    // input logic                         MEM_Isincache,
    input LoadType                      MEM_LoadType,
//------------------------------------------------------------------//
    output logic		[31:0] 		          MEM2_ALUOut,		
    output logic 		[31:0] 		          MEM2_PC,
    output logic    [31:0]              MEM2_Instr,			
    output logic 		[1:0]  		          MEM2_WbSel,				
    output logic 		[4:0]  		          MEM2_Dst,
    output logic    [31:0]              MEM2_OutB,
    output RegsWrType                   MEM2_RegsWrType,
    output logic    [4:0]		            MEM2_ExcType,
    output logic                        MEM2_IsABranch,
    output logic                        MEM2_IsAJumpCall,
    output logic                        MEM2_IsInDelaySlot,
    // output logic                        MEM2_store_req,
    // output logic                        MEM2_Isincache,
    output LoadType                     MEM2_LoadType
);

  always_ff @(posedge clk ) begin
    if( rst == `RstEnable || MEM2_Flush == `FlushEnable) begin
      MEM2_ALUOut                         <= 32'b0;
      MEM2_PC                             <= 32'b0;
      MEM2_Instr                          <= 32'b0;
      MEM2_WbSel                          <= 2'b0;
      MEM2_Dst                            <= 5'b0;
      MEM2_OutB                           <= 32'b0;
      MEM2_RegsWrType                     <= '0;
      MEM2_ExcType                        <= '0;
      MEM2_IsABranch                      <= 1'b0;
      MEM2_IsAJumpCall                    <= 1'b0;
      MEM2_IsInDelaySlot                  <= 1'b0;
      MEM2_LoadType                       <= '0;
      // MEM2_store_req                      <= '0;
      // MEM2_Isincache                      <= '0;
    end
    else if( MEM2_Wr ) begin
      MEM2_ALUOut                         <= MEM_ALUOut;
      MEM2_PC                             <= MEM_PC;
      MEM2_Instr                          <= MEM_Instr;
      MEM2_WbSel                          <= MEM_WbSel;
      MEM2_Dst                            <= MEM_Dst;
      MEM2_OutB                           <= MEM_OutB;
      MEM2_RegsWrType                     <= MEM_RegsWrType_final;
      MEM2_ExcType                        <= MEM_ExcType;
      MEM2_IsABranch                      <= MEM_IsABranch;
      MEM2_IsAJumpCall                    <= MEM_IsAJumpCall;
      MEM2_IsInDelaySlot                  <= MEM_IsInDelaySlot;
      MEM2_LoadType                       <= MEM_LoadType;
      // MEM2_store_req                      <= MEM_store_req;
      // MEM2_Isincache                      <= MEM_Isincache;
    end
  end

endmodule