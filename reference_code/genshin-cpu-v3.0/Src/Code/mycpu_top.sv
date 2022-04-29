/*
 * @Author: npuwth
 * @Date: 2021-06-28 18:45:50
 * @LastEditTime: 2021-06-30 21:19:40
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "CPU_Defines.svh"
`include "CommonDefines.svh"

module mycpu_top (
    input  logic  [ 5:0]       ext_int,
    input  logic               aclk,
    input  logic               aresetn,
    output logic  [ 3:0]       arid,
    output logic  [31:0]       araddr,
    output logic  [ 3:0]       arlen,
    output logic  [ 2:0]       arsize,
    output logic  [ 1:0]       arburst,
    output logic  [ 1:0]       arlock,
    output logic  [ 3:0]       arcache,
    output logic  [ 2:0]       arprot,
    output logic               arvalid,
    input  logic               arready,
    input  logic  [ 3:0]       rid,
    input  logic  [31:0]       rdata,
    input  logic  [ 1:0]       rresp,
    input  logic               rlast,
    input  logic               rvalid,
    output logic               rready,
    output logic  [ 3:0]       awid,
    output logic  [31:0]       awaddr,
    output logic  [ 3:0]       awlen,
    output logic  [ 2:0]       awsize,
    output logic  [ 1:0]       awburst,
    output logic  [ 1:0]       awlock,
    output logic  [ 3:0]       awcache,
    output logic  [ 2:0]       awprot,
    output logic               awvalid,
    input  logic               awready,
    output logic  [ 3:0]       wid,
    output logic  [31:0]       wdata,
    output logic  [ 3:0]       wstrb,
    output logic               wlast,
    output logic               wvalid,
    input  logic               wready,
    input  logic  [ 3:0]       bid,
    input  logic  [ 1:0]       bresp,
    input  logic               bvalid,
    output logic               bready,
    output [31:0]              debug_wb_pc,        
    output [31:0]              debug_wb_rf_wdata,  
    output [3:0]               debug_wb_rf_wen,    
    output [4:0]               debug_wb_rf_wnum   
);
    AsynExceptType             Interrupt;
    logic [31:0]               WB_PC;                     //来自WB级
    logic [31:0]               WB_Result;                 //来自WB级
    logic [4:0]                WB_Dst;                    //来自WB级
    logic                      ID_Flush_Exception;        //来自exception
    logic                      EXE_Flush_Exception;       //来自exception
    logic                      MEM_Flush_Exception;       //来自exception
    logic                      DH_PCWr;                   //来自DataHazard
    logic                      DH_IDWr;                   //来自DataHazard
    logic                      EXE_Flush_DataHazard;      //来自DataHazard
    logic                      EXE_MULTDIVStall;          //来自EXE级的乘除法
    logic [1:0]                IsExceptionOrEret;         //来自MEM级，表示有异常或异常返回
    logic                      ID_Flush_BranchSolvement;  //来自EXE级的branchsolvement，清空ID寄存器
    logic                      ID_IsAImmeJump;            //来自ID级，表示是j，jal跳转
    //-----------------------------流水线寄存器的写使能和flush------------------------------//
    logic                      PC_Wr;                     //来自WRFlushControl
    logic                      ID_Wr;                     //来自WRFlushControl
    logic                      EXE_Wr;                    //来自WRFlushControl  
    logic                      MEM_Wr;                    //来自WRFlushControl
    logic                      WB_Wr;                     //来自WRFlushControl
    logic                      ID_Flush;                  //来自WRFlushControl
    logic                      EXE_Flush;                 //来自WRFlushControl
    logic                      MEM_Flush;                 //来自WRFlushControl
    logic                      WB_Flush;                  //来自WRFlushControl
    //--------------------------------------------------------------------------------------//
    logic                      WB_DisWr;                  //来自WRFlushControl,传至WB级，用于生成WB_Final_Wr
    logic                      HiLo_Not_Flush;            //来自WRFlushControl,传至HILO寄存器

    logic                      EXE_Finish;                //来自EXE，用于乘除法是否结束  

    logic [31:0]               EXE_BusA_L1;               //来自EXE，用于MT指令写HiLo，也用于生成jr的npc
    logic [31:0]               HI_Bus;                    //ID级从HI读出的数据，放入TOP_ID
    logic [31:0]               LO_Bus;                    //ID级从LO读出的数据，放入TOP_ID
    logic [31:0]               EXE_MULTDIVtoHI;           //EXE级乘除法运算结果写入HI
    logic [31:0]               EXE_MULTDIVtoLO;           //EXE级乘除法运算结果写入LO
    RegsWrType                 EXE_RegsWrType;            //EXE级的写使能，用于HILO的写
    RegsWrType                 WB_Final_Wr;               //WB级最终的写使能
    RegsWrType                 WB_RegsWrType;
    
    logic [4:0]                ID_rs;                     //来自ID级，用于DataHazard检测
    logic [4:0]                ID_rt;                     //来自ID级，用于DataHazard检测  
    logic [4:0]                ID_rd;                     //来自ID级，用于读CP0寄存器
    logic [31:0]               CP0_Bus;                   //ID级从CP0读出的数据

    logic [1:0]                ID_rsrtRead;               //来自ID级，用于DataHazard检测
    logic [4:0]                EXE_rt;                    //来自EXE级，用于DataHazard检测
    LoadType                   EXE_LoadType;              //来自EXE级，用于DataHazard检测
    BranchType                 EXE_BranchType;            //来自EXE级，传至IF，用于生成NPC
    logic [31:0]               EXE_PC;                    //来自EXE级，用于生成NPC
    logic [31:0]               EXE_Imm32;                 //来自EXE级，用于生成NPC  
    logic [31:0]               Exception_CP0_EPC;         //来自CP0的EPC寄存器，传至IF，用于NPC     
    
    logic [31:0]               CP0_BadVAddr;              //CP0寄存器
    logic [31:0]               CP0_Count;                 //CP0寄存器
    logic [31:0]               CP0_Compare;               //CP0寄存器
    logic [31:0]               CP0_Status;                //CP0寄存器
    logic [31:0]               CP0_Cause;                 //CP0寄存器
    logic [31:0]               CP0_EPC;                   //CP0寄存器 
    logic [31:0]               CP0_Index;                 //CP0寄存器
    logic [31:0]               CP0_EntryHi;               //CP0寄存器 
    logic [31:0]               CP0_EntryLo0;              //CP0寄存器 
    logic [31:0]               CP0_EntryLo1;              //CP0寄存器 

    logic [31:0]               WB_Hi;
    logic [31:0]               WB_Lo;
    logic [1:0]                EXE_MultiExtendOp;           
    assign Interrupt = {ext_int[0],ext_int[1],ext_int[2],ext_int[3],ext_int[4],ext_int[5]};  //硬件中断信号
    assign debug_wb_pc = WB_PC;                                                              //写回级的PC
    assign debug_wb_rf_wdata = WB_Result;                                                    //写回寄存器的数据
    assign debug_wb_rf_wen = (WB_Final_Wr.RFWr) ? 4'b1111 : 4'b0000;                       //4位字节写使能
    assign debug_wb_rf_wnum = WB_Dst;                                                        //写回寄存器的地址

    CPU_Bus_Interface           cpu_ibus();
    CPU_Bus_Interface           cpu_dbus();
    AXI_Bus_Interface           axi_ibus();
    AXI_Bus_Interface           axi_dbus();
    AXI_UNCACHE_Interface       axi_ubus();
    IF_ID_Interface             IIBus();
    ID_EXE_Interface            IEBus();
    EXE_MEM_Interface           EMBus();
    MEM_WB_Interface            MWBus();
    WB_CP0_Interface            WCBus();

    WrFlushControl U_WRFlushControl (
        .ID_Flush_Exception     (ID_Flush_Exception),
        .EXE_Flush_Exception    (EXE_Flush_Exception),
        .MEM_Flush_Exception    (MEM_Flush_Exception),
        .DH_PCWr                (DH_PCWr),
        .DH_IDWr                (DH_IDWr),
        .EXE_Flush_DataHazard   (EXE_Flush_DataHazard), // 以上三个是数据冒险的3个控制信号
        .DIVMULTBusy            (EXE_MULTDIVStall),
        .IsExceptionorEret      (IsExceptionOrEret),
        .BranchFailed           (ID_Flush_BranchSolvement),
        .ID_IsAImmeJump         (ID_IsAImmeJump),
        .Icache_data_ok         (cpu_ibus.data_ok),
        .Icache_busy            (~cpu_ibus.addr_ok),  // addr_ok = 1表示cache空闲
        .Dcache_data_ok         (cpu_dbus.data_ok),
        .Dcache_busy            (~cpu_dbus.addr_ok),  // addr_ok = 1表示cache空闲
        //-------------------------------- output-----------------------------//
        .PC_Wr                  (PC_Wr),
        .ID_Wr                  (ID_Wr),
        .EXE_Wr                 (EXE_Wr),
        .MEM_Wr                 (MEM_Wr),
        .WB_Wr                  (WB_Wr),
        .ID_Flush               (ID_Flush),
        .EXE_Flush              (EXE_Flush),
        .MEM_Flush              (MEM_Flush),
        .WB_Flush               (WB_Flush),
        .WB_DisWr               (WB_DisWr),
        .HiLo_Not_Flush         (HiLo_Not_Flush),
        .IcacheFlush            (cpu_ibus.flush),
        .DcacheFlush            (cpu_dbus.flush)
    );

    //------------------------AXI-----------------------//
    AXIInteract AXIInteract_dut (
        .clk                    (aclk ),
        .resetn                 (aresetn ),
        .DcacheAXIBus           (axi_dbus.slave ),
        .IcacheAXIBus           (axi_ibus.slave ),
        .UncacheAXIBus          (axi_ubus.slave) ,
        .m_axi_arid             (arid ),
        .m_axi_araddr           (araddr ),
        .m_axi_arlen            (arlen ),
        .m_axi_arsize           (arsize ),
        .m_axi_arburst          (arburst ),
        .m_axi_arlock           (arlock ),
        .m_axi_arcache          (arcache ),
        .m_axi_arprot           (arprot ),
        .m_axi_arvalid          (arvalid ),
        .m_axi_arready          (arready ),
        .m_axi_rid              (rid ),
        .m_axi_rdata            (rdata ),
        .m_axi_rresp            (rresp ),
        .m_axi_rlast            (rlast ),
        .m_axi_rvalid           (rvalid ),
        .m_axi_rready           (rready ),
        .m_axi_awid             (awid ),
        .m_axi_awaddr           (awaddr ),
        .m_axi_awlen            (awlen ),
        .m_axi_awsize           (awsize ),
        .m_axi_awburst          (awburst ),
        .m_axi_awlock           (awlock ),
        .m_axi_awcache          (awcache ),
        .m_axi_awprot           (awprot ),
        .m_axi_awvalid          (awvalid ),
        .m_axi_awready          (awready ),
        .m_axi_wid              (wid ),
        .m_axi_wdata            (wdata ),
        .m_axi_wstrb            (wstrb ),
        .m_axi_wlast            (wlast ),
        .m_axi_wvalid           (wvalid ),
        .m_axi_wready           (wready ),
        .m_axi_bid              (bid ),
        .m_axi_bresp            (bresp ),
        .m_axi_bvalid           (bvalid ),
        .m_axi_bready           (bready)
    );

    HILO U_HILO (
        .clk                   (aclk),
        .rst                   (aresetn),
        .MULT_DIV_finish       (EXE_Finish & HiLo_Not_Flush),
        .EXE_MultiExtendOp     (EXE_MultiExtendOp),
        .HIWr                  (EXE_RegsWrType.HIWr & HiLo_Not_Flush), //把写HI，LO统一在EXE级
        .LOWr                  (EXE_RegsWrType.LOWr & HiLo_Not_Flush),
        .Data_Wr               (EXE_BusA_L1),
        .EXE_MULTDIVtoLO       (EXE_MULTDIVtoLO),
        .EXE_MULTDIVtoHI       (EXE_MULTDIVtoHI),
        .HI_Rd                 (HI_Bus),
        .LO_Rd                 (LO_Bus)
    );

    cp0_reg U_CP0(
        .clk (aclk ),
        .rst (aresetn ),
        .CP0_RdAddr (ID_rd ),
        .CP0_RdData (CP0_Bus ),
        .Interrupt (Interrupt ),
        .WCBus (WCBus.CP0 ),
        //-------------------output----------------------//
        .CP0_BadVAddr (CP0_BadVAddr ),
        .CP0_Count (CP0_Count ),
        .CP0_Compare (CP0_Compare ),
        .CP0_Status (CP0_Status ),
        .CP0_Cause (CP0_Cause ),
        .CP0_EPC (CP0_EPC ),
        .CP0_Index (CP0_Index ),
        .CP0_EntryHi (CP0_EntryHi ),
        .CP0_EntryLo0 (CP0_EntryLo0 ),
        .CP0_EntryLo1 (CP0_EntryLo1 )
    );

    DataHazard U_DataHazard ( 
        //input
        .ID_rs(ID_rs),
        .ID_rt(ID_rt),
        .ID_rsrtRead(ID_rsrtRead),
        .EXE_rt(EXE_rt),
        .EXE_ReadMEM(EXE_LoadType.ReadMem),
        //output
        .PC_Wr(DH_PCWr),
        .ID_Wr(DH_IDWr),
        .EXE_Flush(EXE_Flush_DataHazard)
    );

    TOP_IF U_TOP_IF ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .PC_Wr (PC_Wr ),
        .MEM_CP0Epc (Exception_CP0_EPC ),
        .EXE_BusA_L1 (EXE_BusA_L1 ),
        .ID_Flush_BranchSolvement (ID_Flush_BranchSolvement ),
        .ID_IsAImmeJump (ID_IsAImmeJump ),
        .IsExceptionOrEret (IsExceptionOrEret ),
        .EXE_BranchType (EXE_BranchType ),
        .ID_Wr (ID_Wr ),
        .ID_Flush_Exception (ID_Flush_Exception ),
        .EXE_Flush_DataHazard (EXE_Flush_DataHazard ),
        .EXE_PC (EXE_PC ),
        .EXE_Imm32 (EXE_Imm32 ),
        .IIBus  ( IIBus.IF),
        .cpu_ibus (cpu_ibus),
        .axi_ibus (axi_ibus)
    );

    TOP_ID U_TOP_ID ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .ID_Flush (ID_Flush ),
        .ID_Wr (ID_Wr ),
        .WB_Result (WB_Result ),
        .WB_Dst (WB_Dst ),
        .WB_RegsWrType (WB_RegsWrType ),
        .CP0_Bus (CP0_Bus ),
        .HI_Bus (HI_Bus ),
        .LO_Bus (LO_Bus ),
        .IIBus (IIBus.ID ),
        .IEBus (IEBus.ID ),
        //-------------------------------output-------------------//
        .ID_rsrtRead  (ID_rsrtRead ),
        .ID_IsAImmeJump (ID_IsAImmeJump),
        .ID_rs(ID_rs),
        .ID_rt(ID_rt),
        .ID_rd(ID_rd)
    );

    TOP_EXE U_TOP_EXE ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .EXE_Flush (EXE_Flush ),
        .EXE_Wr (EXE_Wr ),
        .WB_RegsWrType (WB_RegsWrType ), //???
        .WB_Dst (WB_Dst ),
        .WB_Result (WB_Result ),
        .HiLo_Not_Flush (HiLo_Not_Flush ),
        .IEBus (IEBus.EXE ),
        .EMBus (EMBus.EXE ),
        //--------------------------output-------------------------//
        .ID_Flush_BranchSolvement (ID_Flush_BranchSolvement ),
        .EXE_Finish (EXE_Finish ),
        .EXE_MULTDIVStall  (EXE_MULTDIVStall),
        .EXE_MULTDIVtoHI (EXE_MULTDIVtoHI),
        .EXE_MULTDIVtoLO (EXE_MULTDIVtoLO),
        .EXE_BusA_L1 (EXE_BusA_L1),
        .EXE_BranchType (EXE_BranchType),
        .EXE_RegsWrType (EXE_RegsWrType ),
        .EXE_PC (EXE_PC),
        .EXE_Imm32 (EXE_Imm32),
        .EXE_LoadType (EXE_LoadType),
        .EXE_rt(EXE_rt),
        .EXE_MultiExtendOp(EXE_MultiExtendOp)
    );

    TOP_MEM U_TOP_MEM ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .MEM_Flush (MEM_Flush ),
        .MEM_Wr (MEM_Wr ),
        .CP0_Status (CP0_Status ),
        .CP0_Cause (CP0_Cause ),
        .CP0_EPC (CP0_EPC ),
        .WB_Wr (WB_Wr),
        .EMBus (EMBus.MEM ),
        .MWBus (MWBus.MEM ),
        .cpu_dbus (cpu_dbus),
        .axi_dbus (axi_dbus),
        .axi_ubus (axi_ubus),
        //--------------------------output-------------------------//
        .ID_Flush_Exception (ID_Flush_Exception ),
        .EXE_Flush_Exception (EXE_Flush_Exception ),
        .MEM_Flush_Exception (MEM_Flush_Exception ),
        .IsExceptionOrEret (IsExceptionOrEret ),
        .Exception_CP0_EPC  ( Exception_CP0_EPC)
    );

    TOP_WB U_TOP_WB ( 
        .clk (aclk ),
        .resetn (aresetn ),
        .WB_Flush (WB_Flush ),
        .WB_Wr (WB_Wr ),
        .WB_DisWr (WB_DisWr ),
        .MWBus (MWBus.WB ),
        .WCBus (WCBus.WB ),
        //--------------------------output-------------------------//
        .WB_Result (WB_Result ),
        .WB_Dst (WB_Dst ),
        .WB_Final_Wr (WB_Final_Wr ),
        .WB_RegsWrType (WB_RegsWrType),
        .WB_PC(WB_PC ),
        .WB_Hi (WB_Hi ),
        .WB_Lo (WB_Lo )
    );

endmodule

