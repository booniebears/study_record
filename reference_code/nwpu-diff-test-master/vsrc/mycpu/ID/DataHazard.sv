/*
 * @Author: 
 * @Date: 2021-06-16 16:07:56
 * @LastEditTime: 2021-07-19 23:18:54
 * @LastEditors: Johnson Yang
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "/root/difftest/nwpu-diff-test-master/vsrc/mycpu/CommonDefines.svh"
`include "/root/difftest/nwpu-diff-test-master/vsrc/mycpu/CPU_Defines.svh"
//TODO: DH_STALL的检测可以是并行的
module DataHazard (
    input logic [4:0]  ID_rs,
    input logic [4:0]  ID_rt,
    input logic [1:0]  ID_rsrtRead,//[1]是rs [0]是rt 1'b1的时候是读
    input logic [4:0]  EXE_rt,
    input logic        EXE_ReadMEM,  // 在EXE的load指令
    input logic [4:0]  MEM_rt,       // load的目标寄存器
    input logic        MEM_ReadMEM,  // 在MEM级的load指令
    input logic [4:0]  MEM2_rt,
    input logic        MEM2_ReadMEM,
    input logic [31:0] EXE_Instr,
    input logic [31:0] MEM_Instr,
    //--------------------output-----------------------//
    output logic       ID_EX_DH_Stall,     //数据冒险的阻塞
    output logic       ID_MEM1_DH_Stall,   //数据冒险的阻塞
    output logic       ID_MEM2_DH_Stall    //数据冒险的阻塞
);
    always_comb begin
        // RFC0 的数据阻塞
        if ( EXE_ReadMEM == 1'b1 && ((ID_rs == EXE_rt && ID_rsrtRead[1] == 1'b1) || 
             (ID_rt == EXE_rt && ID_rsrtRead[0] == 1'b1))) begin
            ID_EX_DH_Stall   = 1'b1;
            ID_MEM1_DH_Stall = 1'b0;
            ID_MEM2_DH_Stall = 1'b0;
        end
        else if (MEM_ReadMEM == 1'b1 && ((ID_rs == MEM_rt && ID_rsrtRead[1] == 1'b1) || 
             (ID_rt == MEM_rt && ID_rsrtRead[0] == 1'b1))) begin
            ID_EX_DH_Stall   = 1'b0;
            ID_MEM1_DH_Stall = 1'b1;
            ID_MEM2_DH_Stall = 1'b0;
        end
        else if (MEM2_ReadMEM== 1'b1 && ((ID_rs == MEM2_rt && ID_rsrtRead[1] == 1'b1)||
             (ID_rt == MEM2_rt && ID_rsrtRead[0] == 1'b1))) begin
            ID_EX_DH_Stall   = 1'b0;
            ID_MEM1_DH_Stall = 1'b0;
            ID_MEM2_DH_Stall = 1'b1;
        end
        // MFC0 的数据阻塞
        else if ( EXE_Instr[31:21] == 11'b010000_00000 && ((ID_rs == EXE_rt && ID_rsrtRead[1] == 1'b1) || 
             (ID_rt == EXE_rt && ID_rsrtRead[0] == 1'b1))) begin //MFC0后面存在数据依赖的情况
            ID_EX_DH_Stall   = 1'b1;
            ID_MEM1_DH_Stall = 1'b0;
            ID_MEM2_DH_Stall = 1'b0;
        end 
        else if ( MEM_Instr[31:21] == 11'b010000_00000 && ((ID_rs == MEM_rt && ID_rsrtRead[1] == 1'b1) || 
             (ID_rt == MEM_rt && ID_rsrtRead[0] == 1'b1))) begin //MFC0后面存在数据依赖的情况
            ID_EX_DH_Stall   = 1'b0;
            ID_MEM1_DH_Stall = 1'b1;
            ID_MEM2_DH_Stall = 1'b0;
        end 
        else begin
            ID_EX_DH_Stall   = 1'b0;
            ID_MEM1_DH_Stall = 1'b0;
            ID_MEM2_DH_Stall = 1'b0;
        end    

    end

endmodule
