/*
 * @Author: Johnson Yang
 * @Date: 2021-03-27 17:12:06
 * @LastEditTime: 2021-07-14 20:08:05
 * @LastEditors: Johnson Yang
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 协处理器CP0（实现了CP0中的 BadVAddr、Count、Compare、Status、Cause、EPC6个寄存器的部分功能）
 * 
 */
 

`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"

module cp0_reg (  
    input logic             clk,
    input logic             rst,
    input logic  [5:0]      Interrupt,                 //6个外部硬件中断输入 
    // read port        
    input logic  [4:0]      CP0_RdAddr,                //要读取的CP0寄存器的地址
    output logic [31:0]     CP0_RdData,                //读出的CP0某个寄存器的值 
    //write port from reg
    input RegsWrType        MEM_RegsWrType,
    input logic  [4:0]      MEM_Dst,
    input logic  [31:0]     MEM_Result,
    //write port from tlb
    input logic             MEM_IsTLBP,                //写index寄存器
    input logic             MEM_IsTLBR,                //写EntryHi，EntryLo0，EntryLo1
    CP0_MMU_Interface       CMBus, 
    //exception
    input ExceptinPipeType  WB_ExceptType,
    input logic  [31:0]     WB_PC,
    input logic             WB_IsInDelaySlot,
    input logic  [31:0]     WB_ALUOut,
    //connect to exception to dectect
    output logic [7:0]      CP0_Status_IM7_0,
    output logic [1:1]      CP0_Status_EXL,
    output logic [0:0]      CP0_Status_IE,
    output logic [15:10]    CP0_Cause_IP7_2,
    output logic [9:8]      CP0_Cause_IP1_0,
    output logic [31:0]     CP0_EPC 
    );

    logic                   Count2;
    logic                   CP0_TimerInterrupt;         //是否有定时中断发生
    logic  [4:0]            ExcType;
    logic  [5:0]            Interrupt_final;

    assign                  CP0_Status_IM7_0 = CP0.Status.IM7_0;
    assign                  CP0_Status_EXL   = CP0.Status.EXL;
    assign                  CP0_Status_IE    = CP0.Status.IE;
    assign                  CP0_Cause_IP7_2  = CP0.Cause.IP7_2;
    assign                  CP0_Cause_IP1_0  = CP0.Cause.IP1_0;
    assign                  CP0_EPC          = CP0.EPC;
    assign                  Interrupt_final  = Interrupt | {CP0_TimerInterrupt , 5'b0};  // 时钟中断号为IP7，在此标记

    cp0_regs CP0;
    

    always_comb begin  //优先级可以查看MIPS文档第三册56页
        if(WB_ExceptType.Interrupt == 1'b1)                ExcType = `EX_Interrupt;
        else if(WB_ExceptType.WrongAddressinIF == 1'b1)    ExcType = `EX_WrongAddressinIF;
        else if(WB_ExceptType.TLBRefillinIF ==1'b1)        ExcType = `EX_TLBRefillinIF;
        else if(WB_ExceptType.TLBInvalidinIF == 1'b1)      ExcType = `EX_TLBInvalidinIF;
        else if(WB_ExceptType.ReservedInstruction == 1'b1) ExcType = `EX_ReservedInstruction;
        else if(WB_ExceptType.Syscall == 1'b1)             ExcType = `EX_Syscall;
        else if(WB_ExceptType.Break == 1'b1)               ExcType = `EX_Break;
        else if(WB_ExceptType.Eret == 1'b1)                ExcType = `EX_Eret;
        else if(WB_ExceptType.Trap == 1'b1)                ExcType = `EX_Trap;
        else if(WB_ExceptType.Overflow == 1'b1)            ExcType = `EX_Overflow;
        else if(WB_ExceptType.WrWrongAddressinMEM == 1'b1) ExcType = `EX_WrWrongAddressinMEM;
        else if(WB_ExceptType.RdWrongAddressinMEM == 1'b1) ExcType = `EX_RdWrongAddressinMEM;
        else if(WB_ExceptType.RdTLBRefillinMEM == 1'b1)    ExcType = `EX_RdTLBRefillinMEM;
        else if(WB_ExceptType.WrTLBRefillinMEM == 1'b1)    ExcType = `EX_WrTLBRefillinMEM;
        else if(WB_ExceptType.RdTLBInvalidinMEM == 1'b1)   ExcType = `EX_RdTLBInvalidinMEM;  
        else if(WB_ExceptType.WrTLBInvalidinMEM == 1'b1)   ExcType = `EX_WrTLBInvalidinMEM;
        else if(WB_ExceptType.TLBModified == 1'b1)         ExcType = `EX_TLBModified;
        else                                               ExcType = `EX_None;
    end
    
    //Index
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            CP0.Index.P                    <= 1'b0;
            CP0.Index.Index                <= 'x;
        end
        else if(MEM_IsTLBP) begin
            CP0.Index.P                    <= ~CMBus.MMU_s1found;
            CP0.Index.Index                <= CMBus.MMU_index;
        end
        else if(MEM_RegsWrType.CP0Wr && MEM_Dst == `CP0_REG_INDEX) begin
            CP0.Index.Index                <= MEM_Result[3:0];
        end
    end

    //EntryLo0
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            CP0.EntryLo0.PFN0              <= 'x;
            CP0.EntryLo0.C0                <= 'x;
            CP0.EntryLo0.D0                <= 'x;
            CP0.EntryLo0.V0                <= 'x;
            CP0.EntryLo0.G0                <= 'x;
        end
        else if(MEM_IsTLBR) begin
            CP0.EntryLo0.PFN0              <= CMBus.MMU_pfn0;
            CP0.EntryLo0.C0                <= CMBus.MMU_c0;
            CP0.EntryLo0.D0                <= CMBus.MMU_d0;
            CP0.EntryLo0.V0                <= CMBus.MMU_v0;
            CP0.EntryLo0.G0                <= CMBus.MMU_g0;
        end
        else if(MEM_RegsWrType.CP0Wr && MEM_Dst == `CP0_REG_ENTRYLO0) begin
            CP0.EntryLo0.PFN0              <= MEM_Result[25:6];
            CP0.EntryLo0.C0                <= MEM_Result[5:3];
            CP0.EntryLo0.D0                <= MEM_Result[2];
            CP0.EntryLo0.V0                <= MEM_Result[1];
            CP0.EntryLo0.G0                <= MEM_Result[0];
        end
    end

    //EntryLo1
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            CP0.EntryLo1.PFN1              <= 'x;
            CP0.EntryLo1.C1                <= 'x;
            CP0.EntryLo1.D1                <= 'x;
            CP0.EntryLo1.V1                <= 'x;
            CP0.EntryLo1.G1                <= 'x;
        end
        else if(MEM_IsTLBR) begin
            CP0.EntryLo1.PFN1              <= CMBus.MMU_pfn1;
            CP0.EntryLo1.C1                <= CMBus.MMU_c1;
            CP0.EntryLo1.D1                <= CMBus.MMU_d1;
            CP0.EntryLo1.V1                <= CMBus.MMU_v1;
            CP0.EntryLo1.G1                <= CMBus.MMU_g1;
        end
        else if(MEM_RegsWrType.CP0Wr && MEM_Dst == `CP0_REG_ENTRYLO1) begin
            CP0.EntryLo1.PFN1              <= MEM_Result[25:6];
            CP0.EntryLo1.C1                <= MEM_Result[5:3];
            CP0.EntryLo1.D1                <= MEM_Result[2];
            CP0.EntryLo1.V1                <= MEM_Result[1];
            CP0.EntryLo1.G1                <= MEM_Result[0];
        end
    end

    //BadVAddr
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            CP0.BadVAddr                   <= 'x;
        end
        else if (ExcType == `EX_WrongAddressinIF) begin
            CP0.BadVAddr                   <= WB_PC;
        end
        else if (ExcType == `EX_WrWrongAddressinMEM || ExcType == `EX_RdWrongAddressinMEM) begin
            CP0.BadVAddr                   <= WB_ALUOut;
        end
        else if (ExcType == `EX_TLBRefillinIF || ExcType == `EX_TLBInvalidinIF) begin
            CP0.BadVAddr                   <= WB_PC;
        end
        else if (ExcType == `EX_RdTLBRefillinMEM || ExcType == `EX_RdTLBInvalidinMEM || ExcType == `EX_WrTLBRefillinMEM || ExcType == `EX_WrTLBInvalidinMEM || ExcType == `EX_TLBModified) begin
            CP0.BadVAddr                   <= WB_ALUOut;
        end
    end
    
    //CP0_REG_COUNT
        //Count2
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            Count2                         <= '0;
        end
        else if (MEM_RegsWrType.CP0Wr == 1'b1  && MEM_Dst == `CP0_REG_COUNT ) begin 
                Count2                     <= 1'b0;
        end else begin
                Count2                     <= Count2  + 1;
        end
    end
    //Count
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            CP0.Count                      <= 'x;
        end
        else if (MEM_RegsWrType.CP0Wr == 1'b1  && MEM_Dst == `CP0_REG_COUNT ) begin 
            CP0.Count                      <= MEM_Result;
        end
        else if (Count2 == 1'd1)begin
            CP0.Count                   <= CP0.Count + 1;   //Count寄存器的值在每个时钟周期加1
        end 
    end
    
    
    //EntryHi
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            CP0.EntryHi.VPN2               <= 'x;
            CP0.EntryHi.ASID               <= 'x;
        end
        else if(MEM_IsTLBR) begin
            CP0.EntryHi.VPN2               <= CMBus.MMU_vpn2;
            CP0.EntryHi.ASID               <= CMBus.MMU_asid;
        end
        else if(MEM_RegsWrType.CP0Wr && MEM_Dst == `CP0_REG_ENTRYHI) begin
            CP0.EntryHi.VPN2               <= MEM_Result[31:13];
            CP0.EntryHi.ASID               <= MEM_Result[7:0];
        end
        else if(ExcType == `EX_TLBRefillinIF || ExcType == `EX_TLBInvalidinIF) begin
            CP0.EntryHi.VPN2               <= WB_PC[31:13];
        end
        else if(ExcType == `EX_RdTLBRefillinMEM || ExcType == `EX_RdTLBInvalidinMEM || ExcType == `EX_WrTLBRefillinMEM || ExcType == `EX_WrTLBInvalidinMEM || ExcType == `EX_TLBModified) begin
            CP0.EntryHi.VPN2               <= WB_ALUOut[31:13];
        end
    end

    //Compare
    always_ff @(posedge clk) begin
        if(rst == `RstEnable) begin
            CP0.Compare                    <= 'x;
        end 
        else if (MEM_RegsWrType.CP0Wr == 1'b1  && MEM_Dst == `CP0_REG_COMPARE ) begin 
            CP0.Compare                    <= MEM_Result;
        end
    end
    //Time Interrupt
    always_comb begin
        if (CP0.Count == CP0.Compare ) begin
            CP0_TimerInterrupt             = 1'b1;
        end
        else begin
            CP0_TimerInterrupt             = 1'b0;
        end
    end

    //Status
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            CP0.Status.IM7_0               <= 'x ;
            CP0.Status.IE                  <= '0 ;
        end
        else if (MEM_RegsWrType.CP0Wr == 1'b1 && MEM_Dst == `CP0_REG_STATUS ) begin
            CP0.Status.IM7_0               <= MEM_Result[15:8];    
            CP0.Status.IE                  <= MEM_Result[0];
        end
    end
    //Status.EXL
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            CP0.Status.EXL                 <= '0;
        end
        else if(ExcType != `EX_None) begin
            if(ExcType == `EX_Eret) begin
                CP0.Status.EXL             <= '0;
            end
            else begin
                CP0.Status.EXL             <= 1'b1;
            end
        end
        else if(MEM_RegsWrType.CP0Wr == 1'b1 && MEM_Dst == `CP0_REG_STATUS) begin
            CP0.Status.EXL                 <= MEM_Result[1];
        end
    end
    
        //Cause.BD
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            CP0.Cause.BD                   <= '0;
        end
        else if(CP0_Status_EXL == 1'b0 && ExcType!= `EX_None ) begin
            CP0.Cause.BD                   <= WB_IsInDelaySlot;
        end 
    end
    
        //Cause.TI
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            CP0.Cause.TI                  <= '0;
        end
        else if(MEM_RegsWrType.CP0Wr == 1'b1 && MEM_Dst == `CP0_REG_COMPARE ) begin
            CP0.Cause.TI                  <= 1'b0;
        end
        else if (CP0_TimerInterrupt == 1'b1)begin
            CP0.Cause.TI                  <= 1'b1;
        end
    end

        //Cause.IP7_2
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            CP0.Cause.IP7_2               <= '0;
        end
        else 
            CP0.Cause.IP7_2               <= Interrupt_final;
    end
    
        //Cause.IP1_0
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            CP0.Cause.IP1_0               <= '0;
        end
        else if(MEM_RegsWrType.CP0Wr == 1'b1 && MEM_Dst == `CP0_REG_CAUSE ) begin
            CP0.Cause.IP1_0               <= MEM_Result[9:8];
        end
    end
        //Cause.ExcCode
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            CP0.Cause.ExcCode             <= '0;
        end
        else begin
            case(ExcType) 
                `EX_Interrupt:            CP0.Cause.ExcCode<=5'h00;        
                `EX_WrongAddressinIF:     CP0.Cause.ExcCode<=5'h04;        
                `EX_ReservedInstruction:  CP0.Cause.ExcCode<=5'h0a;        
                `EX_Syscall:              CP0.Cause.ExcCode<=5'h08;        
                `EX_Break:                CP0.Cause.ExcCode<=5'h09;        
                `EX_Trap:                 CP0.Cause.ExcCode<=5'h0d;        
                `EX_Overflow:             CP0.Cause.ExcCode<=5'h0c;        
                `EX_WrWrongAddressinMEM:  CP0.Cause.ExcCode<=5'h05;        
                `EX_RdWrongAddressinMEM:  CP0.Cause.ExcCode<=5'h04;
                `EX_TLBRefillinIF:        CP0.Cause.ExcCode<=5'h02;//TLBL        
                `EX_TLBInvalidinIF:       CP0.Cause.ExcCode<=5'h02;//TLBL       
                `EX_RdTLBRefillinMEM:     CP0.Cause.ExcCode<=5'h02;//TLBL       
                `EX_RdTLBInvalidinMEM:    CP0.Cause.ExcCode<=5'h02;//TLBL
                `EX_WrTLBRefillinMEM:     CP0.Cause.ExcCode<=5'h03;//TLBS
                `EX_WrTLBInvalidinMEM:    CP0.Cause.ExcCode<=5'h03;//TLBS
                `EX_TLBModified:          CP0.Cause.ExcCode<=5'h01;//Mod
                default:                  CP0.Cause.ExcCode<=CP0.Cause.ExcCode;
            endcase
        end
    end

    //EPC
    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            CP0.EPC                      <= 'x;
        end 
        else if(ExcType != `EX_None && CP0_Status_EXL == 1'b0 ) begin
            if(ExcType == `EX_Eret) begin
                CP0.EPC                  <= CP0.EPC;
            end
            else begin
                if(WB_IsInDelaySlot == 1'b1) begin
                    CP0.EPC              <= WB_PC-4;
                end
                else begin
                    CP0.EPC              <= WB_PC;
                end
            end
        end
        else if(MEM_RegsWrType.CP0Wr == 1'b1 && MEM_Dst == `CP0_REG_EPC) begin
            CP0.EPC                      <= MEM_Result;
        end
    end

    //read port
    always_comb begin
        case(CP0_RdAddr)
            `CP0_REG_INDEX:      CP0_RdData = {CP0.Index.P,27'b0,CP0.Index.Index};
            `CP0_REG_ENTRYLO0:   CP0_RdData = {6'b0,CP0.EntryLo0.PFN0,CP0.EntryLo0.C0,CP0.EntryLo0.D0,CP0.EntryLo0.V0,CP0.EntryLo0.G0};
            `CP0_REG_ENTRYLO1:   CP0_RdData = {6'b0,CP0.EntryLo1.PFN1,CP0.EntryLo1.C1,CP0.EntryLo1.D1,CP0.EntryLo1.V1,CP0.EntryLo1.G1};
            `CP0_REG_BADVADDR:   CP0_RdData = CP0.BadVAddr;
            `CP0_REG_COUNT:      CP0_RdData = CP0.Count;
            `CP0_REG_ENTRYHI:    CP0_RdData = {CP0.EntryHi.VPN2,5'b0,CP0.EntryHi.ASID};
            `CP0_REG_COMPARE:    CP0_RdData = CP0.Compare;
            `CP0_REG_STATUS:     CP0_RdData = {9'b0,1'b1,6'b0,CP0.Status.IM7_0,6'b0,CP0.Status.EXL,CP0.Status.IE};
            `CP0_REG_CAUSE:      CP0_RdData = {CP0.Cause.BD,CP0.Cause.TI,14'b0,CP0.Cause.IP7_2,CP0.Cause.IP1_0,1'b0,CP0.Cause.ExcCode,2'b0};
            `CP0_REG_EPC:        CP0_RdData = CP0.EPC;
            default:             CP0_RdData = 'x;
        endcase
    end

    //与TLB交互
    assign CMBus.CP0_index      = CP0.Index.Index;
    assign CMBus.CP0_vpn2       = CP0.EntryHi.VPN2;
    assign CMBus.CP0_asid       = CP0.EntryHi.ASID;
    assign CMBus.CP0_pfn0       = CP0.EntryLo0.PFN0;
    assign CMBus.CP0_c0         = CP0.EntryLo0.C0;
    assign CMBus.CP0_d0         = CP0.EntryLo0.D0;
    assign CMBus.CP0_v0         = CP0.EntryLo0.V0;
    assign CMBus.CP0_g0         = CP0.EntryLo0.G0;
    assign CMBus.CP0_pfn1       = CP0.EntryLo1.PFN1;
    assign CMBus.CP0_c1         = CP0.EntryLo1.C1;
    assign CMBus.CP0_d1         = CP0.EntryLo1.D1;
    assign CMBus.CP0_v1         = CP0.EntryLo1.V1;
    assign CMBus.CP0_g1         = CP0.EntryLo1.G1;
endmodule
