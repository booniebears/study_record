/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-07-26 16:22:54
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module TOP_WB ( 
    input logic                  clk,
    input logic                  resetn,
    input logic                  WB_Flush,
    input logic                  WB_Wr,
    input logic                  WB_DisWr,
    MEM2_WB_Interface            M2WBus,
    //--------------------output--------------------//
    output logic [31:0]          WB_Result,
    output logic [4:0]           WB_Dst,
    output RegsWrType            WB_Final_Wr,
    output RegsWrType            WB_RegsWrType,
    output logic [31:0]          WB_PC
);
    logic [31:0]                 WB_DMOut;
    logic [31:0]                 WB_ALUOut;
    LoadType                     WB_LoadType;
    logic [31:0]                 WB_DMResult;
    logic [31:0]                 WB_Result_L1;
    logic [31:0]                 WB_Instr;
    logic [31:0]                 WB_OutB;
    logic [1:0]                  WB_WbSel;

    assign WB_Final_Wr = (WB_DisWr)? '0: WB_RegsWrType ;  // Dcache 停滞流水线时 wb级数据不能写入RF
    
    WB_Reg U_WB_REG ( 
        .clk                  (clk ),
        .rst                  (resetn ),
        .WB_Flush             (WB_Flush ),
        .WB_Wr                (WB_Wr ),

        .MEM2_ALUOut          (M2WBus.MEM2_ALUOut ),
        .MEM2_LoadType        (M2WBus.MEM2_LoadType ),
        .MEM2_PC              (M2WBus.MEM2_PC ),
        .MEM2_Instr           (M2WBus.MEM2_Instr ),
        .MEM2_WbSel           (M2WBus.MEM2_WbSel ),
        .MEM2_Dst             (M2WBus.MEM2_Dst ),
        .MEM2_DMOut           (M2WBus.MEM2_DMOut ),
        .MEM2_OutB            (M2WBus.MEM2_OutB ),
        .MEM2_RegsWrType      (M2WBus.MEM2_RegsWrType ),
        .MEM2_Result          (M2WBus.MEM2_Result),  
        //-------------------------out----------------------------//
        .WB_ALUOut            (WB_ALUOut ),
        .WB_LoadType          (WB_LoadType ),
        .WB_PC                (WB_PC ),
        .WB_Instr             (WB_Instr ),
        .WB_WbSel             (WB_WbSel ),
        .WB_Dst               (WB_Dst ),
        .WB_DMOut             (WB_DMOut ),
        .WB_OutB              (WB_OutB ),
        .WB_RegsWrType        (WB_RegsWrType ),
        .WB_Result            (WB_Result_L1)
    );

    EXT2 U_EXT2 ( 
        .WB_DMOut             (WB_DMOut ),
        .WB_ALUOut            (WB_ALUOut ),
        .WB_LoadType          (WB_LoadType ),
        .WB_DMResult          ( WB_DMResult)
  );


    MUX2to1 #(32) U_MUXINWB ( 
        .d0                   (WB_Result_L1     ),
        .d1                   (WB_DMResult      ),
        .sel2_to_1            (WB_WbSel == 2'b11),
        .y                    (WB_Result        ) 
    );


endmodule