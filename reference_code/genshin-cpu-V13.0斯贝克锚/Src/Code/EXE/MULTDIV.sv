/*
 * @Author: Seddon Shen
 * @Date: 2021-03-27 15:31:34
 * @LastEditTime: 2021-07-06 11:46:13
 * @LastEditors: Seddon Shen
 * @Description: Copyright 2021 GenshinCPU
 * @FilePath: \Code\EXE\MULTDIV.sv
 * 
 */
`include "../CommonDefines.svh"
`include "../CPU_Defines.svh"
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
logic EXE_MULTStall;
logic EXE_DIVStall;
logic  ismulti;
assign ismulti = (EXE_ALUOp == `EXE_ALUOp_MULT || EXE_ALUOp == `EXE_ALUOp_MULTU || EXE_ALUOp == `EXE_ALUOp_MADD || EXE_ALUOp == `EXE_ALUOp_MADDU || 
                EXE_ALUOp == `EXE_ALUOp_MSUB || EXE_ALUOp == `EXE_ALUOp_MSUBU) ? 1 : 0 ;
logic signflag;


always_ff @(posedge clk ) begin
    if (!rst) begin
            dividend_tdata <= `ZeroWord;
            divisor_tdata  <= `ZeroWord;
    end
    else begin
        if (prestate == T && (EXE_ALUOp == `EXE_ALUOp_DIV || EXE_ALUOp == `EXE_ALUOp_DIVU) ) begin
            dividend_tdata <= EXE_ResultA;
            divisor_tdata  <= EXE_ResultB;
        end
    end
end



// 除法的状态机
always_ff @(posedge clk ) begin
        if (!rst) prestate <= T;
        else      prestate <= nextstate;
end
//除法状态机的状态转移
always_comb begin
         if (prestate == T) begin
             Signed_divisor_tvalid    = 1'b0;
             Signed_dividend_tvalid   = 1'b0;
             Unsigned_divisor_tvalid  = 1'b0;
             Unsigned_dividend_tvalid = 1'b0;
         end  
         else if (prestate == S) begin
            if (EXE_ALUOp == `EXE_ALUOp_DIV) begin
                Signed_divisor_tvalid    = 1'b1;
                Signed_dividend_tvalid   = 1'b1;
                Unsigned_divisor_tvalid  = 1'b0;
                Unsigned_dividend_tvalid = 1'b0;
                end 
            else if(EXE_ALUOp == `EXE_ALUOp_DIVU) begin
                Signed_divisor_tvalid    = 1'b0;
                Signed_dividend_tvalid   = 1'b0;
                Unsigned_divisor_tvalid  = 1'b1;
                Unsigned_dividend_tvalid = 1'b1;
                end
            else begin
                Signed_divisor_tvalid    = 1'b0;
                Signed_dividend_tvalid   = 1'b0;
                Unsigned_divisor_tvalid  = 1'b0;
                Unsigned_dividend_tvalid = 1'b0;
                end
            end
         else if (prestate == Q) begin
             Signed_divisor_tvalid      = 1'b0;
             Signed_dividend_tvalid     = 1'b0;
             Unsigned_divisor_tvalid    = 1'b0;
             Unsigned_dividend_tvalid   = 1'b0;
         end else begin
             Signed_divisor_tvalid      = 1'b0;
             Signed_dividend_tvalid     = 1'b0;
             Unsigned_divisor_tvalid    = 1'b0;
             Unsigned_dividend_tvalid   = 1'b0;
         end
    end
// 除法状态机的控制信号
always_comb begin
        if (ExceptionAssert == `InterruptAssert)  // 前面流水级有异常，需要清空状态机状态
            nextstate = T;
        else begin
            case(prestate)
                T:begin
                  if(EXE_ALUOp == `EXE_ALUOp_DIV || EXE_ALUOp == `EXE_ALUOp_DIVU)
                    nextstate = S;
                  else
                    nextstate = T;
                end
                S:begin
                  if(((Signed_dividend_tready == 1'b1 && Signed_divisor_tready == 1'b1) && EXE_ALUOp == `EXE_ALUOp_DIV ) ||
                    ((Unsigned_dividend_tready == 1'b1 && Unsigned_divisor_tready == 1'b1) && EXE_ALUOp == `EXE_ALUOp_DIVU ))
                    nextstate = Q;
                  else
                    nextstate = S;
                end
                Q:begin
                  if(div_finish == 1'b1)
                    nextstate = T;
                  else
                    nextstate = Q;
                end
                default:begin
                    nextstate = T;
                end
            endcase
        end
end



Signed_div U_SignedDIV (
    .aclk(clk),                                         // input wire clk
    .s_axis_divisor_tvalid (Signed_divisor_tvalid),      // input wire s_axis_divisor_tvalid
    .s_axis_divisor_tready (Signed_divisor_tready),      // output wire s_axis_divisor_tready
    .s_axis_divisor_tdata  (divisor_tdata),              // input wire [31 : 0] s_axis_divisor_tdata
    .s_axis_dividend_tvalid(Signed_dividend_tvalid),     // input wire s_axis_dividend_tvalid
    .s_axis_dividend_tready(Signed_dividend_tready),     // output wire s_axis_dividend_tready
    .s_axis_dividend_tdata (dividend_tdata),             // input wire [31 : 0] s_axis_dividend_tdata
    .m_axis_dout_tvalid    (Signed_div_finish),          // output wire m_axis_dout_tvalid
    .m_axis_dout_tdata     (Signed_dout_tdata)           // output wire [63 : 0] m_axis_dout_tdata
    );

Unsigned_div U_UnsignedDIV (
   .aclk(clk),                                          // input wire clk
   .s_axis_divisor_tvalid  (Unsigned_divisor_tvalid),    // input wire s_axis_divisor_tvalid
   .s_axis_divisor_tready  (Unsigned_divisor_tready),    // output wire s_axis_divisor_tready
   .s_axis_divisor_tdata   (divisor_tdata),              // input wire [31 : 0] s_axis_divisor_tdata
   .s_axis_dividend_tvalid (Unsigned_dividend_tvalid),   // input wire s_axis_dividend_tvalid
   .s_axis_dividend_tready (Unsigned_dividend_tready),   // output wire s_axis_dividend_tready
   .s_axis_dividend_tdata  (dividend_tdata),             // input wire [31 : 0] s_axis_dividend_tdata
   .m_axis_dout_tvalid     (Unsigned_div_finish),        // output wire m_axis_dout_tvalid
   .m_axis_dout_tdata      (Unsigned_dout_tdata)         // output wire [63 : 0] m_axis_dout_tdata
);
// always_comb begin 
//     EXE_ExceptType_new = EXE_ExceptType;
//     EXE_ExceptType_new.Overflow = ((!EXE_ResultA[31] && !EXE_ResultB[31]) && (EXE_ALUOut_r[31]))||((EXE_ResultA[31] && EXE_ResultB[31]) && (!EXE_ALUOut_r[31]));
// end
    //assign EXE_ALUOut = EXE_ALUOut_r;
    //assign EXE_ALUOut = Prod[63:0];
mulsinglecycle mul1sign(
    .mul_clk(clk),
    .resetn(rst),
    .mul_signed(signflag),
    .x(EXE_ResultA),
    .y(EXE_ResultB),
    .result(Prod)
);
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
            EXE_MultiExtendOp = 'x;
            //Prod = 'x;
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
        if (!rst) prestate_mul <= T;
        else      prestate_mul <= nextstate_mul;
end


//空闲态
//执行态
//执行完毕的状态（还在乘法指令）
//空闲态
//其实也刚好是T S Q三个状态即可
//因此复用状态名称


// 乘法状态机的控制信号
always_comb begin
        if (ExceptionAssert == `InterruptAssert)  // 前面流水级有异常，需要清空状态机状态
            nextstate_mul = T;
        else begin
            case(prestate_mul)
                T:begin
                  if(ismulti)
                    begin
                      nextstate_mul = S;
                      EXE_MULTStall = 1'b1;
                    end
                  else
                    begin
                      nextstate_mul = T;
                      EXE_MULTStall = 1'b0;
                    end
                end
                S:begin
                    nextstate_mul = Q;
                    EXE_MULTStall = 1'b0;
                end
                Q:begin
                 if(ismulti)
                    begin
                      nextstate_mul = Q;
                      EXE_MULTStall = 1'b0;
                    end
                  else
                    begin
                      nextstate_mul = T;
                      EXE_MULTStall = 1'b0;
                    end
                end
                default:begin
                    nextstate_mul = T;
                    EXE_MULTStall = 1'b0;
                end
            endcase
        end
end

always_comb begin
        if (prestate_mul == T) begin
            multi_finish = 1'b0;
        end  
        else if (prestate_mul == S) begin
            multi_finish = 1'b1;
        end
        else if (prestate_mul == Q) begin
            multi_finish = 1'b0;
        end
        else begin
            multi_finish = 1'b0;
        end
    end

    assign div_finish   = Signed_div_finish | Unsigned_div_finish;                                  //除法完成信号
    //assign multi_finish = (EXE_ALUOp == `EXE_ALUOp_MULT || EXE_ALUOp == `EXE_ALUOp_MULTU) ? 1 : 0;  //乘法完成信号
    assign EXE_Finish   = multi_finish | div_finish;                                                //总完成信号

    assign EXE_MULTDIVtoLO = (multi_finish        ) ? Prod[31:0] : 
                             (Signed_div_finish   ) ? Signed_dout_tdata[63:32]  : 
                             (Unsigned_div_finish ) ? Unsigned_dout_tdata[63:32]: 31'bx;

    assign EXE_MULTDIVtoHI = (multi_finish        ) ? Prod[63:32] : 
                             (Signed_div_finish   ) ? Signed_dout_tdata[31:0]   : 
                             (Unsigned_div_finish ) ? Unsigned_dout_tdata[31:0] : 31'bx;
    //assign EXE_ALUOut = ;
    // assign EXE_MULTStall = multi_finish;
    assign EXE_DIVStall = ((EXE_ALUOp == `EXE_ALUOp_DIV || EXE_ALUOp == `EXE_ALUOp_DIVU) && div_finish == 1'b0) ? 1 : 0 ;
    assign EXE_MULTDIVStall = EXE_MULTStall || EXE_DIVStall;
endmodule


//为了代码的方便起见，我将乘法的Booth编码和树均放在了单元同模块下
// partial product generator for booth algorithm
module booth_gen
(
    input  logic [63:0] x,
    input  logic [2:0] y,  // {y[i+1], y[i], y[i-1]}
    output logic [63:0] p,
    output logic c
);

  wire [64:0] x_ = {x, 1'b0};
  generate
    genvar i;
    for (i=0; i<64; i=i+1) begin
      assign p[i] = (y == 3'b001 || y == 3'b010) & x_[i+1]
                  | (y == 3'b101 || y == 3'b110) & ~x_[i+1]
                  | (y == 3'b011) & x_[i]
                  | (y == 3'b100) & ~x_[i];
    end
  endgenerate
  assign c = y == 3'b100 || y == 3'b101 || y == 3'b110;

endmodule

// 17-bit wallace tree unit
module wallace_unit_17(
    input  logic [16:0] in,
    input  logic [14:0] cin,
    output logic c,
    output logic out,
    output logic [14:0] cout
);

  wire [14:0] s;
  assign {cout[0], s[0]} = in[16] + in[15] + in[14];
  assign {cout[1], s[1]} = in[13] + in[12] + in[11];
  assign {cout[2], s[2]} = in[10] + in[9] + in[8];
  assign {cout[3], s[3]} = in[7] + in[6] + in[5];
  assign {cout[4], s[4]} = in[4] + in[3] + in[2];
  assign {cout[5], s[5]} = in[1] + in[0];
  assign {cout[6], s[6]} = s[0] + s[1] + s[2];
  assign {cout[7], s[7]} = s[3] + s[4] + s[5];
  assign {cout[8], s[8]} = cin[0] + cin[1] + cin[2];
  assign {cout[9], s[9]} = cin[3] + cin[4] + cin[5];
  assign {cout[10], s[10]} = s[6] + s[7] + s[8];
  assign {cout[11], s[11]} = s[9] + cin[6] + cin[7];
  assign {cout[12], s[12]} = s[10] + s[11] + cin[8];
  assign {cout[13], s[13]} = cin[9] + cin[10] + cin[11];
  assign {cout[14], s[14]} = s[12] + s[13] + cin[12];
  assign {c, out} = s[14] + cin[13] + cin[14];

endmodule

module mulsinglecycle(
    input  logic mul_clk,
    input  logic resetn,
    input  logic mul_signed,
    input  logic [31:0] x,
    input  logic [31:0] y,
    output logic [63:0] result
);

  wire [63:0] x_ext = {{32{x[31] & mul_signed}}, x};
  wire [34:0] y_ext = {{2{y[31] & mul_signed}}, y, 1'b0};
  wire [63:0] part_prod [16:0];     // partial product
  wire [16:0] part_switch [63:0];   // switched partial product
  wire [16:0] part_carry;

  genvar i, j;
  generate
    for (i=0; i<17; i=i+1) begin
      booth_gen part_mul(
        .x(x_ext << 2*i),
        .y(y_ext[(i+1)*2:i*2]),
        .p(part_prod[i]),
        .c(part_carry[i])
      );
      for (j=0; j<64; j=j+1) begin
        assign part_switch[j][i] = part_prod[i][j];
      end
    end
  endgenerate

  reg [16:0] part_switch_reg [63:0];
  reg [16:0] part_carry_reg;
  integer k;
  always @(posedge mul_clk) begin
    for (k=0; k<64; k=k+1) begin
      part_switch_reg[k] <= part_switch[k];
    end
    part_carry_reg <= part_carry;
  end

  wire [14:0] wallace_carry [64:0];
  assign wallace_carry[0] = part_carry_reg[14:0];
  wire [63:0] out_carry, out_sum;
  generate
    for (i=0; i<64; i=i+1) begin
      wallace_unit_17 u_wallace(
        .in(part_switch_reg[i]),
        .cin(wallace_carry[i]),
        .c(out_carry[i]),
        .out(out_sum[i]),
        .cout(wallace_carry[i+1])
      );
    end
  endgenerate
  

  assign result = {out_carry[62:0], part_carry_reg[15]} + out_sum + part_carry_reg[16];

endmodule
