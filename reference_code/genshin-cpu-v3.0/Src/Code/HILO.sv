/*
 * @Author: npuwth
 * @Date: 2021-04-07 14:52:54
 * @LastEditTime: 2021-06-30 16:26:11
 * @LastEditors: Seddon Shen
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

//`timescale 1ns / 1ps
//******************************************************************************
//                          特殊寄存器HI、LO模块
//******************************************************************************
`include "CommonDefines.svh"
`include "CPU_Defines.svh"

module HILO(
    input logic                rst,
    input logic                clk,
    input logic                MULT_DIV_finish,
    input logic   [1:0]        EXE_MultiExtendOp,//MADD等指令的拓展信号，到HI LO
    //写端口
    input logic                HIWr,
    input logic                LOWr,
    input logic   [`RegBus]    Data_Wr,    //  MTLO MTHI
    input logic   [`RegBus]    EXE_MULTDIVtoLO,  // 乘除法写
    input logic   [`RegBus]    EXE_MULTDIVtoHI,  // 乘除法写
    //读端口
    output logic  [`RegBus]    HI_Rd,
    output logic  [`RegBus]    LO_Rd
    );
    logic [`RegBus] HI;
    logic [`RegBus] LO;
    logic [63:0] ProdinHILO = {HI,LO};//HILO原结果
    logic [63:0] ProdinEXE  = {EXE_MULTDIVtoHI,EXE_MULTDIVtoLO};//EXE计算得到的结果
    logic [63:0] ProdAdd    = ProdinHILO + ProdinEXE;
    logic [63:0] ProdSub    = ProdinHILO - ProdinEXE;
        
    //下面是旁路
    always_comb begin
        if(MULT_DIV_finish == 1'b1)
            HI_Rd = EXE_MULTDIVtoHI;
        else if(HIWr == 1'b1)
            HI_Rd = Data_Wr;
        else begin
            HI_Rd = HI;
        end
    end

    always_comb begin
        if(MULT_DIV_finish == 1'b1)
            LO_Rd = EXE_MULTDIVtoLO;
        else if(LOWr == 1'b1)
            LO_Rd = Data_Wr;
        else begin
            LO_Rd = LO;
        end
    end

    
    always @ ( posedge clk or negedge rst) begin
        if(rst == `RstEnable) begin
            HI <= `ZeroWord;
        end else if (MULT_DIV_finish == 1'b1) begin
            if(EXE_MultiExtendOp == 2'b00)begin
                HI <= EXE_MULTDIVtoHI;
            end
            else if (EXE_MultiExtendOp == 2'b01) begin
                //ADD
                HI <= ProdAdd[63:32];
            end
            else if (EXE_MultiExtendOp == 2'b10) begin
               //SUB
               HI <= ProdSub[63:32]; 
            end
            else begin
                HI <= EXE_MULTDIVtoHI;
            end
        end else if (HIWr == `WriteEnable) begin
            HI <= Data_Wr;
        end 
    end
    always @ ( posedge clk or negedge rst) begin
        if(rst == `RstEnable) begin
            LO <= `ZeroWord;
        end else if (MULT_DIV_finish == 1'b1) begin
            if(EXE_MultiExtendOp == 2'b00)begin
                LO <= EXE_MULTDIVtoLO;
            end
            else if (EXE_MultiExtendOp == 2'b01) begin
                //ADD
                LO <= ProdAdd[31:0];
            end
            else if (EXE_MultiExtendOp == 2'b10) begin
               //SUB
               LO <= ProdSub[31:0]; 
            end
            else begin
                LO <= EXE_MULTDIVtoLO;
            end
        end else if (LOWr == `WriteEnable) begin
            LO <= Data_Wr;
        end
        // `ifdef DEBUG
        //     $monitor("HI:%8X LO:%8X",HI_Rd,LO_Rd);
        // `endif
    end
    
endmodule
