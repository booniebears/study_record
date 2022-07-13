/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-08-03 20:33:28
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module TOP_EXE ( 
    input logic               clk,
    input logic               resetn,
    input logic               EXE_Flush,
    input logic               EXE_Wr,
    input logic               EXE_DisWr, 
    ID_EXE_Interface          IEBus,
    EXE_MEM_Interface         EMBus,
    output logic              EXE_Prediction_Failed,
    output logic [31:0]       EXE_Correction_Vector,
    output BResult            EXE_BResult,
    output logic              EXE_MULTDIVStall
);

    logic [31:0]              EXE_BusA;
    logic [31:0]              EXE_BusB;
    logic [31:0]              EXE_Imm32;
    logic [4:0]               EXE_rs;
    logic [4:0]               EXE_rt;
    logic [4:0]               EXE_ALUOp;
    logic [1:0]               EXE_DstSel;
    logic                     EXE_ALUSrcA;
    logic                     EXE_ALUSrcB;
    logic [1:0]               EXE_RegsReadSel;
    ExceptinPipeType          EXE_ExceptType;    //未经过alu的
    logic [4:0]               EXE_Shamt;
    logic [31:0]              EXE_BusA_L2;
    logic [31:0]              EXE_BusB_L2;
    logic [1:0]               EXE_MultiExtendOp; //New add for MADD
    logic                     EXE_Finish;        //来自乘除法
    logic [31:0]              EXE_MULTDIVtoHI;
    logic [31:0]              EXE_MULTDIVtoLO;
    logic [31:0]              HI_Bus;
    logic [31:0]              LO_Bus;
    logic                     Overflow_valid;
    logic                     Trap_valid;
    logic [2:0]               EXE_TrapOp;  
    logic                     MDU_flush;
    RegsWrType                EXE_Final_Wr;
    LoadType                  EXE_LoadType;
    StoreType                 EXE_StoreType;
    logic                     EXE_Final_Finish;
    RegsWrType                EXE_RegsWrType;
    PResult                   EXE_PResult;
    // logic                     EXE_Branch_Success;
    logic                     EXE_J_Success;
    logic                     EXE_PC8_Success;    
    logic [31:0]              EXE_JumpAddr;
    logic [31:0]              EXE_BranchAddr;
    logic [31:0]              EXE_PCAdd8;

    assign IEBus.EXE_rt       = EXE_rt;
    assign IEBus.EXE_LoadType = EXE_LoadType; 
    assign IEBus.EXE_IsMFC0   = EMBus.EXE_IsMFC0;
    assign IEBus.EXE_RegsWrType = EXE_RegsWrType;
    assign IEBus.EXE_Dst      = EMBus.EXE_Dst;
    assign IEBus.EXE_Result   = EMBus.EXE_Result;
    assign EXE_Final_Wr       = (EXE_DisWr) ? '0: EXE_RegsWrType;
    assign EXE_Final_Finish   = (EXE_DisWr) ? '0: EXE_Finish;
    assign EMBus.EXE_LoadType = (EXE_DisWr) ? '0: EXE_LoadType;
    assign EMBus.EXE_StoreType= (EXE_DisWr) ? '0: EXE_StoreType;
    assign EMBus.EXE_RegsWrType = EXE_Final_Wr;

    EXE_Reg U_EXE_Reg ( 
        .clk                  (clk ),
        .rst                  (resetn ), 
        .EXE_Flush            (EXE_Flush ),
        .EXE_Wr               (EXE_Wr ),
        .ID_BusA              (IEBus.ID_BusA ),
        .ID_BusB              (IEBus.ID_BusB ),
        .ID_Imm32             (IEBus.ID_Imm32 ),
        .ID_PC                (IEBus.ID_PC ),
        .ID_Instr             (IEBus.ID_Instr ),
        .ID_rs                (IEBus.ID_rs ),
        .ID_rt                (IEBus.ID_rt ),
        .ID_rd                (IEBus.ID_rd ),
        .ID_ALUOp             (IEBus.ID_ALUOp ),
        .ID_LoadType          (IEBus.ID_LoadType ),
        .ID_StoreType         (IEBus.ID_StoreType ),
        .ID_RegsWrType        (IEBus.ID_RegsWrType ),
        .ID_WbSel             (IEBus.ID_WbSel ),
        .ID_DstSel            (IEBus.ID_DstSel ),
        .ID_ExceptType        (IEBus.ID_ExceptType_new ),
        .ID_ALUSrcA           (IEBus.ID_ALUSrcA ),
        .ID_ALUSrcB           (IEBus.ID_ALUSrcB ),
        .ID_RegsReadSel       (IEBus.ID_RegsReadSel ),
        .ID_IsAJumpCall       (IEBus.ID_IsAJumpCall ),
        .ID_BranchType        (IEBus.ID_BranchType ),
        .ID_IsTLBP            (IEBus.ID_IsTLBP),
        .ID_IsTLBW            (IEBus.ID_IsTLBW),
        .ID_IsTLBR            (IEBus.ID_IsTLBR),
        .ID_TLBWIorR          (IEBus.ID_TLBWIorR),
        .ID_TrapOp            (IEBus.ID_TrapOp),
        .ID_PResult           (IEBus.ID_PResult),
        .ID_IsMFC0            (IEBus.ID_IsMFC0 ),
        // .ID_Branch_Success    (IEBus.ID_Branch_Success),
        .ID_J_Success         (IEBus.ID_J_Success),
        .ID_PC8_Success       (IEBus.ID_PC8_Success),    
        .ID_JumpAddr          (IEBus.ID_JumpAddr),
        .ID_BranchAddr        (IEBus.ID_BranchAddr),    
        .ID_PCAdd8            (IEBus.ID_PCAdd8),
        //------------------------output--------------------------//
        .EXE_BusA             (EXE_BusA ),
        .EXE_BusB             (EXE_BusB ),
        .EXE_Imm32            (EXE_Imm32 ),
        .EXE_PC               (EMBus.EXE_PC ),
        .EXE_Instr            (EMBus.EXE_Instr ),
        .EXE_rs               (EXE_rs ),
        .EXE_rt               (EXE_rt ),
        .EXE_rd               (EMBus.EXE_rd ),
        .EXE_ALUOp            (EXE_ALUOp ),
        .EXE_LoadType         (EXE_LoadType ),
        .EXE_StoreType        (EXE_StoreType ),
        .EXE_RegsWrType       (EXE_RegsWrType ),
        .EXE_WbSel            (EMBus.EXE_WbSel ),
        .EXE_DstSel           (EXE_DstSel ),
        .EXE_ExceptType       (EXE_ExceptType ),
        .EXE_ALUSrcA          (EXE_ALUSrcA ),
        .EXE_ALUSrcB          (EXE_ALUSrcB ),
        .EXE_RegsReadSel      (EMBus.EXE_RegsReadSel ),
        .EXE_IsAJumpCall      (EMBus.EXE_IsAJumpCall ),
        .EXE_BranchType       (EMBus.EXE_BranchType ),
        .EXE_Shamt            (EXE_Shamt ),
        .EXE_IsTLBP           (EMBus.EXE_IsTLBP),
        .EXE_IsTLBW           (EMBus.EXE_IsTLBW),
        .EXE_IsTLBR           (EMBus.EXE_IsTLBR),
        .EXE_TLBWIorR         (EMBus.EXE_TLBWIorR),
        .EXE_TrapOp           (EXE_TrapOp),
        .EXE_PResult          (EXE_PResult),
        .EXE_IsMFC0           (EMBus.EXE_IsMFC0 ),
        // .EXE_Branch_Success   (EXE_Branch_Success),
        .EXE_J_Success        (EXE_J_Success),
        .EXE_PC8_Success      (EXE_PC8_Success),
        .EXE_JumpAddr         (EXE_JumpAddr),
        .EXE_BranchAddr       (EXE_BranchAddr), 
        .EXE_PCAdd8           (EXE_PCAdd8)
    );

    BranchSolve U_BranchSolve (
        .EXE_BranchType       (EMBus.EXE_BranchType),    
        .EXE_IsAJumpCall      (EMBus.EXE_IsAJumpCall), 
        .EXE_OutA             (EXE_BusA),
        .EXE_OutB             (EXE_BusB),
        .EXE_rs               (EXE_rs),
        .EXE_rd               (EMBus.EXE_rd),
        .EXE_PC               (EMBus.EXE_PC),
        .EXE_Wr               (EXE_Wr),
        .EXE_PResult          (EXE_PResult),
        // .EXE_Branch_Success   (EXE_Branch_Success),
        .EXE_J_Success        (EXE_J_Success),
        .EXE_PC8_Success      (EXE_PC8_Success),   
        .EXE_JumpAddr         (EXE_JumpAddr),
        .EXE_BranchAddr       (EXE_BranchAddr),  
        .EXE_PCAdd8           (EXE_PCAdd8),   
        //-----------------output----------------------------//
        .EXE_Prediction_Failed(EXE_Prediction_Failed),
        .EXE_Correction_Vector(EXE_Correction_Vector),
        .EXE_BResult          (EXE_BResult)
    );

    MUX2to1 #(32) U_MUXA_L2 (
        .d0                   (EXE_BusA),
        .d1                   ({27'b0,EXE_Shamt}),
        .sel2_to_1            (EXE_ALUSrcA),
        .y                    (EXE_BusA_L2)
    );//EXE级三选一A之后的那个二选一

    MUX2to1 #(32) U_MUXB_L2 (
        .d0                   (EXE_BusB),
        .d1                   (EXE_Imm32),
        .sel2_to_1            (EXE_ALUSrcB),//
        .y                    (EXE_BusB_L2)
    );//EXE级四选一B之后的那个二选一

    MUX3to1 #(32) U_MUX_OutB ( 
        .d0                   (EXE_BusB),
        .d1                   (HI_Bus),
        .d2                   (LO_Bus),
        .sel3_to_1            (EMBus.EXE_RegsReadSel),
        .y                    (EMBus.EXE_OutB)
    );

    MUX3to1 #(32) U_MUXINEXE ( //选择用于旁路的数据来自ALUOut还是OutB
        .d0                   (EMBus.EXE_PC + 8),
        .d1                   (EMBus.EXE_ALUOut),
        .d2                   (EMBus.EXE_OutB  ), 
        .sel3_to_1            (EMBus.EXE_WbSel),
        .y                    (EMBus.EXE_Result)
    );

    MUX3to1 #(5) U_EXEDstSrc(
        .d0                   (EMBus.EXE_rd),
        .d1                   (EXE_rt),
        .d2                   (5'd31),
        .sel3_to_1            (EXE_DstSel),
        .y                    (EMBus.EXE_Dst)
    );//EXE级Dst

    ALU U_ALU(
        .EXE_ResultA          (EXE_BusA_L2),
        .EXE_ResultB          (EXE_BusB_L2),
        .EXE_ALUOp            (EXE_ALUOp),
        .MUL_Out              (EXE_MULTDIVtoLO ),
        //---------------------------output-----------------//
        .EXE_ALUOut           (EMBus.EXE_ALUOut),  
        .Overflow_valid       (Overflow_valid )       
    );
`ifdef TRAP
    Trap U_TRAP (
        .EXE_TrapOp           (EXE_TrapOp  ),   // trap控制信号信号的连线
        .EXE_ResultA          (EXE_BusA ),   // 旁路之后的数据
        .EXE_ResultB          (EXE_BusB_L2 ),   // 经过立即数选择之后的数据
        .Trap_valid           (Trap_valid  )
    );
`else 
    assign Trap_valid         = '0;
`endif
    MULTDIV U_MULTDIV(
        .clk                  (clk),    
        .rst                  (resetn),            
        .EXE_ResultA          (EXE_BusA),
        .EXE_ResultB          (EXE_BusB),
        .ExceptionAssert      (EXE_Flush),  // 如果产生flush信号，需要清除状态机
    //---------------------output--------------------------//
        .EXE_ALUOp            (EXE_ALUOp),
        .EXE_MULTDIVtoLO      (EXE_MULTDIVtoLO),
        .EXE_MULTDIVtoHI      (EXE_MULTDIVtoHI),
        .EXE_Finish           (EXE_Finish),
        .EXE_MULTDIVStall     (EXE_MULTDIVStall),
        .EXE_MultiExtendOp    (EXE_MultiExtendOp)
    );

    HILO U_HILO (
        .clk                   (clk),
        .rst                   (resetn),
        .MULT_DIV_finish       (EXE_Final_Finish ),
        .EXE_MultiExtendOp     (EXE_MultiExtendOp),
        .HIWr                  (EXE_Final_Wr.HIWr), //把写HI，LO统一在EXE级
        .LOWr                  (EXE_Final_Wr.LOWr),
        .Data_Wr               (EXE_BusA),
        .EXE_MULTDIVtoLO       (EXE_MULTDIVtoLO),
        .EXE_MULTDIVtoHI       (EXE_MULTDIVtoHI),
        .HI                    (HI_Bus),
        .LO                    (LO_Bus)
    );
    // 例外检测 溢出 trap & TLB & refetch & 数据访问地址错误 
    ExceptionInEXE U_ExceptionInEXE (
        .Overflow_valid        (Overflow_valid             ),
        .Trap_valid            (Trap_valid                 ),
        .EXE_ExceptType        (EXE_ExceptType             ),
        .EXE_LoadType          (EMBus.EXE_LoadType         ),
        .MEM_IsTLBR            (EMBus.MEM_IsTLBR           ),
        .MEM_IsTLBW            (EMBus.MEM_IsTLBW           ),
        .MEM_Instr             (EMBus.MEM_Instr            ),
        .MEM_Dst               (EMBus.MEM_Dst              ),
        .EXE_ALUOut            (EMBus.EXE_ALUOut[1:0]      ),
        .EXE_StoreType         (EMBus.EXE_StoreType        ),
        .EXE_ExceptType_final  (EMBus.EXE_ExceptType_final )
    );
    
endmodule

    

