/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-06-30 22:00:28
 * @LastEditors: Please set LastEditors
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
    MEM_WB_Interface             MWBus,
    WB_CP0_Interface             WCBus,
    
    output logic [31:0]          WB_Result,
    output logic [4:0]           WB_Dst,
    output RegsWrType            WB_Final_Wr,
    output RegsWrType            WB_RegsWrType,
    output logic [31:0]          WB_PC,
    output logic [31:0]          WB_Hi,
    output logic [31:0]          WB_Lo
);
    logic [31:0]                 WB_DMOut;
    logic [31:0]                 WB_ALUOut;
    LoadType                     WB_LoadType;
    logic [31:0]                 WB_DMResult;
    logic [31:0]                 WB_Instr;
    logic [31:0]                 WB_OutB;
    logic [1:0]                  WB_WbSel;
    ExceptinPipeType             WB_ExceptType;
    logic                        WB_IsInDelaySlot;

    assign MWBus.WB_Dst          = WB_Dst;
    assign MWBus.WB_Result       = WB_Result;
    assign MWBus.WB_RegsWrType   = WB_RegsWrType;

    assign WCBus.WB_CP0Wr        = WB_Final_Wr.CP0Wr;
    assign WCBus.WB_Dst          = WB_Dst;
    assign WCBus.WB_Result       = WB_Result;
    assign WCBus.WB_ExceptType   = WB_ExceptType;
    assign WCBus.WB_PC           = WB_PC;
    assign WCBus.WB_IsInDelaySlot= WB_IsInDelaySlot;
    assign WCBus.WB_ALUOut       = WB_ALUOut;

    assign WB_Final_Wr = (WB_DisWr)? '0: WB_RegsWrType ;  // Dcache 停滞流水线时 wb级数据不能写入RF
    
    WB_Reg U_WB_REG ( 
        .clk                  (clk ),
        .rst                  (resetn ),
        .WB_Flush             (WB_Flush ),
        .WB_Wr                (WB_Wr ),
        .MEM_ALUOut           (MWBus.MEM_ALUOut ),
        .MEM_Hi               (MWBus.MEM_Hi ),
        .MEM_Lo               (MWBus.MEM_Lo ),
        .MEM_PC               (MWBus.MEM_PC ),
        .MEM_Instr            (MWBus.MEM_Instr ),
        .MEM_WbSel            (MWBus.MEM_WbSel ),
        .MEM_Dst              (MWBus.MEM_Dst ),
        .MEM_LoadType         (MWBus.MEM_LoadType ),
        .MEM_DMOut            (MWBus.MEM_DMOut ),
        .MEM_OutB             (MWBus.MEM_OutB ),
        .MEM_RegsWrType_final (MWBus.MEM_RegsWrType_final ),
        .MEM_ExceptType_final (MWBus.MEM_ExceptType_final ),
        .MEM_IsABranch        (MWBus.MEM_IsABranch ),
        .MEM_IsAImmeJump      (MWBus.MEM_IsAImmeJump ),
        .MEM_IsInDelaySlot    (MWBus.MEM_IsInDelaySlot ),
        //-------------------------out----------------------------//
        .WB_ALUOut            (WB_ALUOut ),
        .WB_Hi                (WB_Hi ),
        .WB_Lo                (WB_Lo ),
        .WB_PC                (WB_PC ),
        .WB_Instr             (WB_Instr ),
        .WB_WbSel             (WB_WbSel ),
        .WB_Dst               (WB_Dst ),
        .WB_LoadType          (WB_LoadType ),
        .WB_DMOut             (WB_DMOut ),
        .WB_OutB              (WB_OutB ),
        .WB_RegsWrType        (WB_RegsWrType ),
        .WB_ExceptType        (WB_ExceptType ),
        .WB_IsABranch         (MWBus.WB_IsABranch ),
        .WB_IsAImmeJump       (MWBus.WB_IsAImmeJump ),
        .WB_IsInDelaySlot     (WB_IsInDelaySlot )
    );

    EXT2 U_EXT2(
        .WB_DMOut             (WB_DMOut),
        .WB_ALUOut            (WB_ALUOut),
        .WB_LoadType          (WB_LoadType),
        .WB_DMResult          (WB_DMResult)
    );

    MUX4to1 #(32) U_MUXINWB(
        .d0                  (WB_PC+8),                                     // JAL,JALR等指令将PC+8写回RF
        .d1                  (WB_ALUOut),                                   // ALU计算结果
        .d2                  (WB_OutB),                                     // MTC0 MTHI LO等指令需要写寄存器
        .d3                  (WB_DMResult),                               
        .sel4_to_1           (WB_WbSel),
        .y                   (WB_Result)                                    
    );

endmodule