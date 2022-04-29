/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-06-30 17:41:25
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module TOP_ID (
    input logic              clk,
    input logic              resetn,
    input logic              ID_Flush,
    input logic              ID_Wr,
    input logic [31:0]       WB_Result,  //写寄存器堆来自WB
    input logic [4:0]        WB_Dst,
    input RegsWrType         WB_RegsWrType,
    input logic [31:0]       CP0_Bus,
    input logic [31:0]       HI_Bus,
    input logic [31:0]       LO_Bus,
    IF_ID_Interface          IIBus,//TODO: 不如改成IF_ID_Bus 
    ID_EXE_Interface         IEBus,
    //---------------------------output------------------------------//
    output logic [1:0]       ID_rsrtRead,  //用于数据旁路与阻塞    
    output logic             ID_IsAImmeJump,  //用于PCSel，表示是j，jal跳转
    output logic [4:0]       ID_rs,
    output logic [4:0]       ID_rt,
    output logic [4:0]       ID_rd
);
    logic [15:0]             ID_Imm16;
    logic [1:0]              ID_EXTOp;
    logic [31:0]             RF_BusA;  //从寄存器堆读出的数据
    logic [31:0]             RF_BusB;
    logic [31:0]             RF_BusB_Final;
    logic                    ID_RF_ForwardA;
    logic                    ID_RF_ForwardB;
    logic [31:0]             CP0_Bus_new;
    logic                    ID_CP0_Forward;

    assign IIBus.ID_Instr = IEBus.ID_Instr;
    assign IIBus.ID_PC    = IEBus.ID_PC;
    assign ID_IsAImmeJump = IEBus.ID_IsAImmeJump;
    assign ID_rs          = IEBus.ID_rs;
    assign ID_rt          = IEBus.ID_rt;
    assign ID_rd          = IEBus.ID_rd;

    ID_Reg U_ID_Reg ( //TODO: 端口的连线还没改好
        .clk                 (clk ),
        .rst                 (resetn ),
        .ID_Flush            (ID_Flush ),
        .ID_Wr               (ID_Wr ),
        .IF_Instr            (IIBus.IF_Instr ),
        .IF_PC               (IIBus.IF_PC ),
    //------------------out----------------------------------------//        
        .ID_Instr            (IEBus.ID_Instr ),
        .ID_Imm16            (ID_Imm16 ),
        .ID_rs               (IEBus.ID_rs ),
        .ID_rt               (IEBus.ID_rt ),
        .ID_rd               (IEBus.ID_rd ),
        .ID_PC               (IEBus.ID_PC )
    );

    EXT U_EXT ( 
        .EXE_EXTOp           (ID_EXTOp),
        .ID_Imm16            (ID_Imm16),
        .ID_Imm32            (IEBus.ID_Imm32)
    );

    RF U_RF (
        .clk                 (clk),
        .rst                 (resetn),
        .WB_Dst              (WB_Dst),
        .WB_Result           (WB_Result),
        .RFWr                (WB_RegsWrType.RFWr),
        .ID_rs               (IEBus.ID_rs),
        .ID_rt               (IEBus.ID_rt),
    //-------------------out--------------------------------------------//
        .ID_BusA             (RF_BusA),
        .ID_BusB             (RF_BusB)
    );
//---------------------------对RF读出的数据进行WB/ID级旁路------------//
    assign ID_RF_ForwardA = WB_RegsWrType.RFWr && (WB_Dst == IEBus.ID_rs);
    assign ID_RF_ForwardB = WB_RegsWrType.RFWr && (WB_Dst == IEBus.ID_rt);

    MUX2to1 #(32) U_MUX_RF_FORWARDA ( 
        .d0                  (RF_BusA),
        .d1                  (WB_Result),
        .sel2_to_1           (ID_RF_ForwardA),
        .y                   (IEBus.ID_BusA)
    );
    
    MUX2to1 #(32) U_MUX_RF_FORWARDB ( 
        .d0                  (RF_BusB),
        .d1                  (WB_Result),
        .sel2_to_1           (ID_RF_ForwardB),
        .y                   (RF_BusB_Final)
    );
//-------------------对CP0读出的数据进行WB/ID级旁路-----------------------//
    assign ID_CP0_Forward = WB_RegsWrType.CP0Wr && (WB_Dst == IEBus.ID_rd);
    
    MUX2to1 #(32) U_MUX_CP0_FORWARD ( 
        .d0(CP0_Bus),
        .d1(WB_Result),
        .sel2_to_1(ID_CP0_Forward),
        .y(CP0_Bus_new)
    );

    MUX4to1 #(32) U_MUXBUSB ( 
        .d0                  (RF_BusB_Final),
        .d1                  (HI_Bus),
        .d2                  (LO_Bus),
        .d3                  (CP0_Bus_new),
        .sel4_to_1           (IEBus.ID_RegsReadSel),
        .y                   (IEBus.ID_BusB)
    );
//-----------------------------------------------------------------//
    Control U_Control (
        .ID_Instr            (IEBus.ID_Instr),
        .IF_ExceptType       (IIBus.IF_ExceptType),
//--------------------------out-------------------------------------//
        .ID_ALUOp            (IEBus.ID_ALUOp),
        .ID_LoadType         (IEBus.ID_LoadType),
        .ID_StoreType        (IEBus.ID_StoreType),
        .ID_RegsWrType       (IEBus.ID_RegsWrType),
        .ID_WbSel            (IEBus.ID_WbSel),
        .ID_DstSel           (IEBus.ID_DstSel),
        .ID_ExceptType       (IEBus.ID_ExceptType),
        .ID_ALUSrcA          (IEBus.ID_ALUSrcA),
        .ID_ALUSrcB          (IEBus.ID_ALUSrcB),
        .ID_RegsReadSel      (IEBus.ID_RegsReadSel),
        .ID_EXTOp            (ID_EXTOp),
        .ID_IsAImmeJump      (IEBus.ID_IsAImmeJump),
        .ID_BranchType       (IEBus.ID_BranchType),
        .ID_rsrtRead         (ID_rsrtRead)
    );

endmodule  