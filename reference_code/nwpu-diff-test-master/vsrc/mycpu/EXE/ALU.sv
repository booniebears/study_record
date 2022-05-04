/*
 * @Author: Seddon Shen
 * @Date: 2021-03-27 15:31:34
 * @LastEditTime: 2021-07-25 22:56:34
 * @LastEditors: Seddon Shen
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \nontrival-cpu\Src\refactor\EXE\ALU.sv
 * 
 */
`include "/mnt/soc_run_os/vsim-func/vsrc/mycpu/CommonDefines.svh"
`include "/mnt/soc_run_os/vsim-func/vsrc/mycpu/CPU_Defines.svh"
`define   TEST 
module ALU (
    input  logic  [31:0]       EXE_ResultA,
    input  logic  [31:0]       EXE_ResultB,
    input  logic  [4:0]        EXE_ALUOp,
    output logic  [31:0]       EXE_ALUOut,
    output logic               Overflow_valid
);

`ifndef TEST
    logic [31:0] EXE_Countbit_Out;
    logic        EXE_Countbit_Opt;
    
    assign       EXE_Countbit_Opt = (EXE_ALUOp == `EXE_ALUOp_CLO);
    
    Countbit U_Countbit (                 //CLO,CLZ
        .option(EXE_Countbit_Opt),
        .value(EXE_ResultA),
        .count(EXE_Countbit_Out)
    );
`endif 
    always_comb begin
        unique case (EXE_ALUOp)
            `EXE_ALUOp_ADD,`EXE_ALUOp_ADDU :  EXE_ALUOut = EXE_ResultA + EXE_ResultB;//可以直接相加
            `EXE_ALUOp_SUB,`EXE_ALUOp_SUBU :  EXE_ALUOut = EXE_ResultA - EXE_ResultB;//可以直接相减
            //包含OR和ORI
            `EXE_ALUOp_ORI  :  EXE_ALUOut = EXE_ResultA | EXE_ResultB;
            `EXE_ALUOp_NOR  :  EXE_ALUOut = ~(EXE_ResultA | EXE_ResultB);
            `EXE_ALUOp_SLL,`EXE_ALUOp_SLLV  :  EXE_ALUOut = EXE_ResultB << EXE_ResultA[4:0];//这个时候EXE_Shamt本来就只剩最低四位了，而用Shamt之后其实就本致相同了
            `EXE_ALUOp_SRL,`EXE_ALUOp_SRLV  :  EXE_ALUOut = EXE_ResultB >> EXE_ResultA[4:0];//这个时候EXE_Shamt本来就只剩最低四位了
            `EXE_ALUOp_SRA,`EXE_ALUOp_SRAV  :  EXE_ALUOut = ($signed(EXE_ResultB)) >>> EXE_ResultA[4:0];//这样写也就导致了ResultA在移位时已经被置为可变长度或者s
            //包含SLT和SLTI
            `EXE_ALUOp_SLT   :  begin
                if ($signed(EXE_ResultA) < $signed(EXE_ResultB) )  EXE_ALUOut = 32'b0000_0000_0000_0001;
                else  EXE_ALUOut = 32'b0;
            end
            //包含SLTU和SLTIU
            `EXE_ALUOp_SLTU  : begin
                if ((EXE_ResultA) < (EXE_ResultB) ) EXE_ALUOut = 32'b0000_0000_0000_0001;//TODO: 去掉了unsigned的系统函数
                else  EXE_ALUOut = 32'b0;
            end
            `EXE_ALUOp_XOR  :  EXE_ALUOut = EXE_ResultA ^ EXE_ResultB;
            `EXE_ALUOp_AND  :  EXE_ALUOut = EXE_ResultA & EXE_ResultB;
            `ifndef TEST
            `EXE_ALUOp_CLZ  :  EXE_ALUOut = EXE_Countbit_Out;
            `EXE_ALUOp_CLO  :  EXE_ALUOut = EXE_Countbit_Out;
            `endif 
            default: EXE_ALUOut = '0;//Do nothing
        endcase
    end 

    assign Overflow_valid = (EXE_ALUOp == `EXE_ALUOp_ADD )&&( ( (!EXE_ResultA[31] && !EXE_ResultB[31]) && (EXE_ALUOut[31]) )||( (EXE_ResultA[31] && EXE_ResultB[31]) && (!EXE_ALUOut[31]) )) ||
                                         (EXE_ALUOp == `EXE_ALUOp_SUB)&&( ( (!EXE_ResultA[31] && EXE_ResultB[31]) && (EXE_ALUOut[31]) )||( (EXE_ResultA[31] && !EXE_ResultB[31]) && (!EXE_ALUOut[31]) ));
    // TODO: 针对EXE_ALUOP字段，当其为'x的时候，是否需要将overflow的异常置为'0 ,现在是'x
endmodule