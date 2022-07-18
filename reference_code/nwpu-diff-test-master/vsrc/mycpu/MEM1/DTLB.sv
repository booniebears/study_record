/*
 * @Author: npuwth
 * @Date: 2021-07-16 19:41:02
 * @LastEditTime: 2021-07-30 20:32:53
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "/root/difftest/nwpu-diff-test-master/vsrc/mycpu/CPU_Defines.svh"
`include "/root/difftest/nwpu-diff-test-master/vsrc/mycpu/CommonDefines.svh"

`define IDLE               1'b0
`define SEARCH             1'b1

module DTLB ( 
    input logic                   clk,
    input logic                   rst,
    input logic  [31:0]           Virt_Daddr,
    input logic                   TLBBuffer_Flush,
    input TLB_Entry               D_TLBEntry,//来自TLB
    input logic                   s1_found,  //来自TLB
    input LoadType                MEM_LoadType,
    input StoreType               MEM_StoreType,
    input logic  [2:0]            CP0_Config_K0,
    output logic [31:0]           Phsy_Daddr,
    output logic                  D_IsCached,
    output logic                  D_IsTLBBufferValid,
    output logic                  D_IsTLBStall,
    output logic [2:0]            MEM_TLBExceptType,
    output logic [31:13]          D_VPN2
);

`ifdef EN_TLB
    logic                         D_TLBState;
    logic                         D_TLBNextState;
    TLB_Buffer                    D_TLBBuffer;
    logic                         D_TLBBuffer_Wr;
    logic                         D_TLBBufferHit;
//-----------------TLB Buffer Hit信号的生成-------------------------------//
    always_comb begin //TLBD
        if(Virt_Daddr < 32'hC000_0000 && Virt_Daddr > 32'h7FFF_FFFF) begin
                D_TLBBufferHit = 1'b1; 
        end
        else if(MEM_LoadType.ReadMem != 1'b0 || MEM_StoreType.DMWr != 1'b0) begin
            if((Virt_Daddr[31:13] == D_TLBBuffer.VPN2) && D_TLBBuffer.Valid) begin
                D_TLBBufferHit = 1'b1;
            end
            else begin
                D_TLBBufferHit = 1'b0;
            end
        end
        else begin
                D_TLBBufferHit = 1'b1;
        end
    end

    assign D_IsTLBStall        = ~ D_TLBBufferHit;

//----------------状态机控制逻辑------------------------------------//
    assign D_TLBBuffer_Wr      = (D_TLBState == `SEARCH);

    always_comb begin
        if(rst == `RstEnable) begin
            D_TLBNextState = `IDLE;
        end
        else if(D_TLBBufferHit == 1'b0) begin
            D_TLBNextState = `SEARCH;
        end
        else begin
            D_TLBNextState = `IDLE;
        end
    end

    always_ff @(posedge clk ) begin
        if(rst == `RstEnable) begin
            D_TLBState     = `IDLE;    
        end
        else begin
            D_TLBState     = D_TLBNextState;
        end
    end
//----------------------根据TLB进行虚实地址转换-------------------------//
    always_comb begin //TLBD
        if(Virt_Daddr < 32'hC000_0000 && Virt_Daddr > 32'h9FFF_FFFF) begin
            Phsy_Daddr        = Virt_Daddr - 32'hA000_0000;
        end
        else if(Virt_Daddr < 32'hA000_0000 && Virt_Daddr > 32'h7FFF_FFFF) begin
            Phsy_Daddr        = Virt_Daddr - 32'h8000_0000;
        end
        else if(Virt_Daddr[12] == 1'b0) begin
            Phsy_Daddr        = {D_TLBBuffer.PFN0,Virt_Daddr[11:0]};
        end
        else begin
            Phsy_Daddr        = {D_TLBBuffer.PFN1,Virt_Daddr[11:0]};
        end
    end
//----------------------对Cache属性进行判断----------------------------//
`ifdef All_Uncache
    assign D_IsCached                                = 1'b0;
`else
    always_comb begin //TLBD
        if(Virt_Daddr < 32'hC000_0000 && Virt_Daddr > 32'h9FFF_FFFF) begin
            D_IsCached                               = 1'b0;
        end
        else if(Virt_Daddr < 32'hA000_0000 && Virt_Daddr > 32'h7FFF_FFFF) begin
            if(CP0_Config_K0 == 3'b011) begin
                D_IsCached                           = 1'b1;
            end
            else begin
                D_IsCached                           = 1'b0;
            end
        end
        else begin
            if(Virt_Daddr[12] == 1'b0) begin
                if(D_TLBBuffer.C0 == 3'b011)  D_IsCached                           = 1'b1;
                else                          D_IsCached                           = 1'b0;
            end
            else begin
                if(D_TLBBuffer.C1 == 3'b011)  D_IsCached                           = 1'b1;
                else                          D_IsCached                           = 1'b0;
            end
        end
    end
`endif
//-----------------------对TLB Buffer进行赋值----------------------------//
    always_ff @(posedge clk ) begin //TLBD
        if(rst == `RstEnable || TLBBuffer_Flush == 1'b1) begin
            D_TLBBuffer.VPN2          <= '0;
            D_TLBBuffer.ASID          <= '0;
            D_TLBBuffer.G             <= '0;
            D_TLBBuffer.PFN0          <= '0;
            D_TLBBuffer.C0            <= '0;
            D_TLBBuffer.D0            <= '0;
            D_TLBBuffer.V0            <= '0;
            D_TLBBuffer.PFN1          <= '0;
            D_TLBBuffer.C1            <= '0;
            D_TLBBuffer.D1            <= '0;
            D_TLBBuffer.V1            <= '0;
            D_TLBBuffer.Valid         <= '0;
            D_TLBBuffer.IsInTLB       <= '0;
        end
        else if(D_TLBBuffer_Wr ) begin
            D_TLBBuffer.VPN2          <= Virt_Daddr[31:13];
            D_TLBBuffer.ASID          <= D_TLBEntry.ASID;
            D_TLBBuffer.G             <= D_TLBEntry.G;
            D_TLBBuffer.PFN0          <= D_TLBEntry.PFN0;
            D_TLBBuffer.C0            <= D_TLBEntry.C0;
            D_TLBBuffer.D0            <= D_TLBEntry.D0;
            D_TLBBuffer.V0            <= D_TLBEntry.V0;
            D_TLBBuffer.PFN1          <= D_TLBEntry.PFN1;
            D_TLBBuffer.C1            <= D_TLBEntry.C1;
            D_TLBBuffer.D1            <= D_TLBEntry.D1;
            D_TLBBuffer.V1            <= D_TLBEntry.V1;
            D_TLBBuffer.Valid         <= 1'b1;
            D_TLBBuffer.IsInTLB       <= s1_found;
        end
    end

    assign D_VPN2                     = Virt_Daddr[31:13];
//------------------------------对异常和Valid信号进行赋值----------------------------------------------//    
    always_comb begin //TLBD
    if(MEM_LoadType.ReadMem != 1'b0 || MEM_StoreType.DMWr != 1'b0) begin
        if(Virt_Daddr < 32'hC000_0000 && Virt_Daddr > 32'h7FFF_FFFF) begin  //不走TLB，认为有效
            D_IsTLBBufferValid                              = 1'b1; 
            MEM_TLBExceptType                               = `MEM_TLBNoneEX;
        end
        else if(D_TLBBufferHit == 1'b0) begin 
            D_IsTLBBufferValid                              = 1'b0;
            MEM_TLBExceptType                               = `MEM_TLBNoneEX;
        end
        else if(D_TLBBuffer.IsInTLB == 1'b1 ) begin //说明TLB Buffer对上了
            if(Virt_Daddr[12] == 1'b0) begin
                if(D_TLBBuffer.V0 == 1'b0) begin //无效异常
                    if(MEM_LoadType.ReadMem == 1'b1) begin
                    D_IsTLBBufferValid                      = 1'b0; 
                    MEM_TLBExceptType                       = `MEM_RdTLBInvalid;
                    end
                    else begin
                    D_IsTLBBufferValid                      = 1'b0; 
                    MEM_TLBExceptType                       = `MEM_WrTLBInvalid;
                    end
                end
                else if(D_TLBBuffer.V0 == 1'b1 && D_TLBBuffer.D0 == 1'b0 && MEM_StoreType.DMWr == 1'b1) begin
                    D_IsTLBBufferValid                      = 1'b0; //判断是否有修改例外
                    MEM_TLBExceptType                       = `MEM_TLBModified;
                end
                else begin
                    D_IsTLBBufferValid                      = 1'b1;
                    MEM_TLBExceptType                       = `MEM_TLBNoneEX;
                end                     
            end
            else begin
                if(D_TLBBuffer.V1 == 1'b0) begin //无效异常
                    if(MEM_LoadType.ReadMem == 1'b1) begin
                    D_IsTLBBufferValid                      = 1'b0; 
                    MEM_TLBExceptType                       = `MEM_RdTLBInvalid;
                    end
                    else begin
                    D_IsTLBBufferValid                      = 1'b0; 
                    MEM_TLBExceptType                       = `MEM_WrTLBInvalid;
                    end
                end
                else if(D_TLBBuffer.V1 == 1'b1 && D_TLBBuffer.D1 == 1'b0 && MEM_StoreType.DMWr == 1'b1) begin
                    D_IsTLBBufferValid                      = 1'b0; //判断是否有修改例外
                    MEM_TLBExceptType                       = `MEM_TLBModified;

                end
                else begin
                    D_IsTLBBufferValid                      = 1'b1;
                    MEM_TLBExceptType                       = `MEM_TLBNoneEX;
                end   
            end
        end
        else begin     //说明缺页异常
            if(MEM_LoadType.ReadMem == 1'b1) begin
                D_IsTLBBufferValid                         = 1'b0;
                MEM_TLBExceptType                          = `MEM_RdTLBRefill;
            end
            else begin
                D_IsTLBBufferValid                         = 1'b0;
                MEM_TLBExceptType                          = `MEM_WrTLBRefill;
            end
        end
    end
    else begin
        D_IsTLBBufferValid                                 = 1'b0;
        MEM_TLBExceptType                                  = `MEM_TLBNoneEX;
    end
    end
`else 
    always_comb begin //TLBD
        if(Virt_Daddr < 32'hC000_0000 && Virt_Daddr > 32'h9FFF_FFFF) begin
            Phsy_Daddr        = Virt_Daddr - 32'hA000_0000;
        end
        else if(Virt_Daddr < 32'hA000_0000 && Virt_Daddr > 32'h7FFF_FFFF) begin
            Phsy_Daddr        = Virt_Daddr - 32'h8000_0000;
        end
        else begin
            Phsy_Daddr        = Virt_Daddr;
        end
    end
`ifdef All_Uncache
    assign D_IsCached         = 1'b0;
`else 
    always_comb begin
        if(Virt_Daddr < 32'hC000_0000 && Virt_Daddr > 32'h9FFF_FFFF) begin
            D_IsCached                               = 1'b0;
        end
        else if(Virt_Daddr < 32'hA000_0000 && Virt_Daddr > 32'h7FFF_FFFF) begin
            D_IsCached                               = 1'b1;
        end
        else begin
            D_IsCached                               = 1'b1;
        end
    end
`endif
    assign D_IsTLBBufferValid = (MEM_LoadType.ReadMem == 1'b1) || (MEM_StoreType.DMWr == 1'b1);
    assign MEM_TLBExceptType  = `MEM_TLBNoneEX;
    assign D_IsTLBStall       = 1'b0;
`endif
endmodule