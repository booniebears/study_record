/*
 * @Author: Seddon Shen
 * @Date: 2021-03-27 15:31:34
 * @LastEditTime: 2021-07-21 10:39:45
 * @LastEditors: npuwth
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \undefinedd:\nontrival-cpu\Src\refactor\EXE\MULTDIV.sv
 * 
 */
`include "/mnt/soc_run_os/vsim-func/vsrc/mycpu/CommonDefines.svh"
`include "/mnt/soc_run_os/vsim-func/vsrc/mycpu/CPU_Defines.svh"
module MULTDIV(
    input logic           clk,    
    input logic           rst,             // 除法状态机的复位信号
    input logic  [4:0]    EXE_ALUOp,
    input logic  [31:0]   EXE_ResultA,
    input logic  [31:0]   EXE_ResultB,
    input logic           ExceptionAssert,
    output logic [31:0]   EXE_MULTDIVtoLO,
    output logic [31:0]   EXE_MULTDIVtoHI,
    output logic          EXE_Finish,
    output logic          EXE_MULTDIVStall,
    output logic [1:0]    EXE_MultiExtendOp//MADD等指令的拓展信号，到HI LO
    // 01 ADD
    // 10 SUB

    // output logic          Finish,
    // output logic [64:0]   DivOut
    );
parameter T = 2'b00;  //空闲
parameter S = 2'b01;  //等待握手
parameter Q = 2'b10;  //等待结果
// div -->  dividend_tdata / divisor_tdata 
// 除号后面的叫做除数（divisor_tdata）
logic  [31:0]   divisor_tdata;      // 除数
logic  [31:0]   dividend_tdata;     // 被除数
logic  [63:0]   Prod;
logic           multi_finish;   
logic           div_finish;   
logic           Unsigned_divisor_tvalid;
logic           Unsigned_dividend_tvalid;
logic           Unsigned_divisor_tready;
logic           Unsigned_dividend_tready;
logic           Signed_divisor_tvalid;
logic           Signed_dividend_tvalid;
logic           Signed_divisor_tready;
logic           Signed_dividend_tready;
logic           Signed_div_finish;
logic           Unsigned_div_finish;
logic  [63:0]   Signed_dout_tdata;
logic  [63:0]   Unsigned_dout_tdata;
logic  [1:0]    nextstate;
logic  [1:0]    prestate; 
logic  [1:0]    nextstate_mul;
logic  [1:0]    prestate_mul;                                                 
logic           EXE_MULTStall;
logic           EXE_DIVStall;
logic           ismulti;
logic           signflag;
logic  [63:0]   mul_result;
assign ismulti = (EXE_ALUOp == `EXE_ALUOp_MULT || EXE_ALUOp == `EXE_ALUOp_MULTU || EXE_ALUOp == `EXE_ALUOp_MADD || EXE_ALUOp == `EXE_ALUOp_MADDU || 
                EXE_ALUOp == `EXE_ALUOp_MSUB || EXE_ALUOp == `EXE_ALUOp_MSUBU) ? 1 : 0 ;

//重构乘法 改为两个周期
// assign abs_reg1 = (is_signed && reg1[31]) ? -reg1 : reg1;
// assign abs_reg2 = (is_signed && reg2[31]) ? -reg2 : reg2;
logic [31:0]    multiA;
logic [31:0]    multiB;
logic negative_result;
assign multiA = (signflag && EXE_ResultA[31]) ? -EXE_ResultA : EXE_ResultA;
assign multiB = (signflag && EXE_ResultB[31]) ? -EXE_ResultB : EXE_ResultB;
assign negative_result = signflag && (EXE_ResultA[31] ^ EXE_ResultB[31]);
assign mul_result = negative_result ? -Prod : Prod;
assign Prod = multiA * multiB;

logic negate_result;
logic [31:0] Div_yushu,Div_shang;
logic [31:0] abs_reg1, abs_reg2;
//Tsinghua
assign Signed_div_finish   = (EXE_ALUOp == `EXE_ALUOp_DIV )  ? 1 : 0;
assign Unsigned_div_finish = (EXE_ALUOp == `EXE_ALUOp_DIVU)  ? 1 : 0;   

assign negate_result = Signed_div_finish && (EXE_ResultA[31] ^ EXE_ResultB[31]);
assign abs_reg1 = (Signed_div_finish && EXE_ResultA[31]) ? -EXE_ResultA : EXE_ResultA;
assign abs_reg2 = (Signed_div_finish && EXE_ResultB[31]) ? -EXE_ResultB : EXE_ResultB;
div_comb U_div_comb(
    .a(abs_reg1),
    .b(abs_reg2),
    .yshang(Div_shang),
    .yyushu(Div_yushu)
);
logic [31:0] div_quotient, div_remainder;
assign div_quotient  = negate_result ? -Div_shang : Div_shang;
assign div_remainder = (Signed_div_finish && (EXE_ResultA[31] ^ Div_yushu[31])) ? -Div_yushu : Div_yushu;


//MADD MSUB指令支持
always_comb begin
    unique case (EXE_ALUOp)
        `EXE_ALUOp_MULT,`EXE_ALUOp_MULTU:begin
            EXE_MultiExtendOp = 2'b00;
        end
        `EXE_ALUOp_MADD,`EXE_ALUOp_MADDU:begin
            EXE_MultiExtendOp = 2'b01;
        end
        `EXE_ALUOp_MSUB,`EXE_ALUOp_MSUBU:begin
            EXE_MultiExtendOp = 2'b10;
        end
        default:begin
            EXE_MultiExtendOp = 2'b00;
        end
    endcase
    
end 
//乘法的有无符号生成逻辑
always_comb begin
    unique case (EXE_ALUOp)
        `EXE_ALUOp_MULT , `EXE_ALUOp_MADD , `EXE_ALUOp_MSUB:begin
          signflag = 1'b1;
        end
        `EXE_ALUOp_MULTU , `EXE_ALUOp_MADDU , `EXE_ALUOp_MSUBU:begin
          signflag = 1'b0;
        end
        default: signflag = 1'b0;
    endcase
    
end 

//乘法的状态机
always_ff @(posedge clk ) begin
    if (rst == `RstEnable || ExceptionAssert == 1'b1) begin
		prestate_mul <= T;
	end 
    else begin
		prestate_mul <= nextstate_mul;
	end    
end


//空闲态T
//执行态S
//结束态Q

logic [2:0] Count;//计数器

always_ff @(posedge clk ) begin
    if (prestate_mul == T && ismulti == 1'b1) begin
        Count <= 1;
    end
    else begin
        Count <= Count + 1;
    end
end

// 乘法状态机的状态转移
always_comb begin
    case(prestate_mul)
        T:begin
            if(ismulti) nextstate_mul = S;
            else        nextstate_mul = T;
        end
        S:begin
            if(Count == `MUL_Circle - 1) nextstate_mul = Q;
            else                         nextstate_mul = S;
        end
        Q:begin
            nextstate_mul = T;
        end
        default:begin
            nextstate_mul = T;
        end
    endcase
end

// 乘法状态机的控制信号
always_comb begin
        if (prestate_mul == Q) begin
            multi_finish = 1'b1;
        end
        else begin
            multi_finish = 1'b0;
        end
end

    assign div_finish   = Signed_div_finish | Unsigned_div_finish;                                  //除法完成信号
    //assign multi_finish = (EXE_ALUOp == `EXE_ALUOp_MULT || EXE_ALUOp == `EXE_ALUOp_MULTU) ? 1 : 0;  //乘法完成信号
    assign EXE_Finish   = multi_finish | div_finish;                                                //总完成信号

    assign EXE_MULTDIVtoLO = (multi_finish        ) ? mul_result[31:0]   : 
                             (Signed_div_finish   ) ? div_quotient       : 
                             (Unsigned_div_finish ) ? div_quotient       : 32'b0;

    assign EXE_MULTDIVtoHI = (multi_finish        ) ? mul_result[63:32]  : 
                             (Signed_div_finish   ) ? div_remainder      : 
                             (Unsigned_div_finish ) ? div_remainder      : 32'b0;
                             
    assign EXE_DIVStall = ((EXE_ALUOp == `EXE_ALUOp_DIV || EXE_ALUOp == `EXE_ALUOp_DIVU) && div_finish == 1'b0) ? 1 : 0 ;
    assign EXE_MULTStall= ((EXE_ALUOp == `EXE_ALUOp_MULT|| EXE_ALUOp == `EXE_ALUOp_MULTU)&& multi_finish == 1'b0) ? 1 : 0;
    assign EXE_MULTDIVStall = EXE_MULTStall || EXE_DIVStall;
endmodule