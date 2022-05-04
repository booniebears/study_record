/*
 * @Author: npuwth
 * @Date: 2021-04-03 10:24:26
 * @LastEditTime: 2021-07-19 23:10:55
 * @LastEditors: Please set LastEditors
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "/mnt/soc_run_os/vsim-func/vsrc/mycpu/CommonDefines.svh"
`include "/mnt/soc_run_os/vsim-func/vsrc/mycpu/CPU_Defines.svh"

module WB_Reg (
//-----------------------------------------------------------------//   
    input logic                         clk,
    input logic                         rst,
    input logic                         WB_Flush,
    input logic                         WB_Wr,
    
    input logic 		[31:0] 		          MEM2_PC,	
    input logic     [31:0]              MEM2_Instr,		
    input logic 		[1:0]  		          MEM2_WbSel,				
    input logic 		[4:0]  		          MEM2_Dst,
	  input logic 		[31:0] 		          MEM2_DMOut,
    input logic     [31:0]              MEM2_OutB,
	  input RegsWrType                    MEM2_RegsWrType,//经过exception solvement的新写使能
    input logic     [31:0]              MEM2_Result,//选择器提前的WB_Result
    `ifdef DEBUG
    input logic		  [31:0] 		          MEM2_ALUOut,		
		input logic     [3:0]               MEM2_DCache_Wen,
		input logic     [31:0]              MEM2_DataToDcache,
		`endif
    // input logic                         MEM2_store_req,
    // input logic                         MEM2_Isincache,
//------------------------------------------------------------------//
    output logic 		[31:0] 		          WB_PC,
    output logic    [31:0]              WB_Instr,			
    output logic 		[1:0]  		          WB_WbSel,				
    output logic 		[4:0]  		          WB_Dst,
	  output logic 		[31:0] 		          WB_DMOut,
    output logic    [31:0]              WB_OutB,
	  output RegsWrType                   WB_RegsWrType, //经过exception solvement的新写使能
    `ifdef DEBUG
    output logic		[31:0] 		          WB_ALUOut,		
		output logic     [3:0]              WB_DCache_Wen,
		output logic     [31:0]             WB_DataToDcache,
		`endif
    output logic    [31:0]              WB_Result
    // output logic                        WB_store_req,
    // output logic                        WB_Isincache
);

  always_ff @(posedge clk ) begin
    if( rst == `RstEnable || WB_Flush == `FlushEnable) begin
      WB_PC                             <= 32'b0;
      WB_Instr                          <= 32'b0;
      WB_WbSel                          <= 2'b0;
      WB_Dst                            <= 5'b0;
      WB_DMOut                          <= 32'b0;
      WB_OutB                           <= 32'b0;
      WB_RegsWrType                     <= '0;
      WB_Result                         <= '0;
      `ifdef DEBUG
      WB_ALUOut                         <= 32'b0;
      WB_DCache_Wen                     <='0;
      WB_DataToDcache                   <='0;
      `endif
      // WB_store_req                      <= '0;
      // WB_Isincache                      <= '0;
    end
    else if( WB_Wr ) begin
      WB_PC                             <= MEM2_PC;
      WB_Instr                          <= MEM2_Instr;
      WB_WbSel                          <= MEM2_WbSel;
      WB_Dst                            <= MEM2_Dst;
      WB_DMOut                          <= MEM2_DMOut;
      WB_OutB                           <= MEM2_OutB;
      WB_RegsWrType                     <= MEM2_RegsWrType;
      WB_Result                         <= MEM2_Result;
      `ifdef DEBUG
      WB_ALUOut                         <= MEM2_ALUOut;
      WB_DCache_Wen                     <= MEM2_DCache_Wen  ; 
      WB_DataToDcache                   <= MEM2_DataToDcache; 
      `endif
      // WB_store_req                      <= MEM2_store_req;
      // WB_Isincache                      <= MEM2_Isincache;
    end
  end

endmodule