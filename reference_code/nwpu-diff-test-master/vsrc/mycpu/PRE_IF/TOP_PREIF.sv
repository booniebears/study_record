/*
 * @Author: Johnson Yang
 * @Date: 2021-07-12 18:10:55
 * @LastEditTime: 2021-07-30 20:32:05
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "/mnt/soc_run_os/vsim-func/vsrc/mycpu/CommonDefines.svh"
`include "/mnt/soc_run_os/vsim-func/vsrc/mycpu/CPU_Defines.svh"
`include "/mnt/soc_run_os/vsim-func/vsrc/mycpu/Cache_Defines.svh"

module TOP_PREIF ( 
    input logic                 clk,
    input logic                 resetn,
    input logic                 PREIF_Wr,

    input logic [31:0]          MEM_CP0Epc,
    input logic [31:0]          EXE_BusA_L1,
    input logic                 ID_Flush_BranchSolvement,
    input logic                 ID_IsAImmeJump,
    input logic [2:0]           EX_Entry_Sel,
    input BranchType            EXE_BranchType,
    input logic [31:0]          ID_PC,
    input logic [31:0]          ID_Instr,
    input logic [31:0]          EXE_PC,
    input logic [31:0]          EXE_Imm32,
    input logic [31:0]          MEM_PC,
    input logic [31:0]          Exception_Vector,
    input TLB_Entry             I_TLBEntry,
    input logic                 s0_found,
    input logic                 TLBBuffer_Flush,
    input logic                 IReq_valid,
    input logic [2:0]           CP0_Config_K0,
    PREIF_IF_Interface          PIBus,
    CPU_Bus_Interface           cpu_ibus,
    AXI_Bus_Interface           axi_ibus,
    AXI_UNCACHE_Interface       axi_iubus,
//---------------------------output----------------------------------//
    output logic [31:13]        I_VPN2,
    output logic                I_IsTLBStall
);
    logic   [31:0]              PREIF_PC;
    logic   [31:0]              PREIF_NPC;
    logic   [2:0]               PCSel;
    logic   [31:0]              ID_PCAdd4;
    logic   [31:0]              PC_4;
    logic   [31:0]              JumpAddr;
    logic   [31:0]              BranchAddr;
    logic   [1:0]               IF_TLBExceptType;
    logic   [31:0]              Phsy_Iaddr;
    logic                       I_IsCached;
    logic                       I_IsTLBBufferValid;

    assign PC_4              =   PREIF_PC + 4;
    assign ID_PCAdd4         =   ID_PC+4;
    assign JumpAddr          =   {ID_PCAdd4[31:28],ID_Instr[25:0],2'b0};
    assign BranchAddr        =   EXE_PC+4+{EXE_Imm32[29:0],2'b0};

    assign PIBus.PREIF_PC    = PREIF_PC;

    always_comb begin
        if(IF_TLBExceptType == `IF_TLBRefill) begin
            PIBus.PREIF_ExceptType = {10'b0,1'b1,8'b0};
        end
        else if(IF_TLBExceptType == `IF_TLBInvalid) begin
            PIBus.PREIF_ExceptType = {11'b0,1'b1,7'b0};
        end
        else begin
            PIBus.PREIF_ExceptType = '0;
        end
    end

    PC U_PC ( 
        .clk            (clk),
        .rst            (resetn),
        .PREIF_Wr       (PREIF_Wr),
        .PREIF_NPC      (PREIF_NPC),
        //---------------output----------------//
        .PREIF_PC       (PREIF_PC)
    );

    MUX7to1 U_PCMUX (
        .d0             (PC_4),
        .d1             (JumpAddr),
        .d2             (MEM_CP0Epc),
        .d3             (Exception_Vector),    // 异常处理的地址
        .d4             (BranchAddr),
        .d5             (EXE_BusA_L1),         // JR
        .d6             (MEM_PC),
        .sel7_to_1      (PCSel),
        //---------------output----------------//
        .y              (PREIF_NPC)
    );

    PCSEL U_PCSEL(
        .isBranch       (ID_Flush_BranchSolvement),
        .isImmeJump     (ID_IsAImmeJump),
        .EX_Entry_Sel   (EX_Entry_Sel),
        .EXE_BranchType (EXE_BranchType),
        //---------------output-------------------//
        .PCSel          (PCSel)
    );

    //---------------------------------cache--------------------------------// 
    assign cpu_ibus.tag       = Phsy_Iaddr[31:12];
    assign {cpu_ibus.index,cpu_ibus.offset} = PREIF_PC[11:0];    // 如果D$ busy 则将PC送给I$ ,否则送NPC
    assign cpu_ibus.op        = 1'b0;
    assign cpu_ibus.wstrb     = '0;
    assign cpu_ibus.wdata     = 'x;
    assign cpu_ibus.isCache   = I_IsCached;
    assign cpu_ibus.valid     = IReq_valid && I_IsTLBBufferValid && (PREIF_PC[1:0] == 2'b0);
    
    Icache #(
        .DATA_WIDTH      (32),
        .LINE_WORD_NUM   (`ICACHE_LINE_WORD ),
        .ASSOC_NUM       (`ICACHE_SET_ASSOC ),
        .WAY_SIZE        (4*1024*8 )
    )
    U_Icache (
        .clk             (clk ),
        .resetn          (resetn ),
        .cpu_bus         (cpu_ibus),
        .axi_ubus        (axi_iubus),
        .axi_bus         ( axi_ibus)
    );

    ITLB U_ITLB (
        .clk             (clk ),
        .rst             (resetn ),
        .Virt_Iaddr      (PREIF_PC ),
        .TLBBuffer_Flush (TLBBuffer_Flush ),
        .I_TLBEntry      (I_TLBEntry ),
        .s0_found        (s0_found ),
        .CP0_Config_K0   (CP0_Config_K0),
    //--------------------output----------------------//    
        .Phsy_Iaddr      (Phsy_Iaddr ),
        .I_IsCached      (I_IsCached ),
        .I_IsTLBBufferValid(I_IsTLBBufferValid ),
        .I_IsTLBStall    (I_IsTLBStall ),
        .IF_TLBExceptType(IF_TLBExceptType ),
        .I_VPN2          ( I_VPN2)
  );


endmodule