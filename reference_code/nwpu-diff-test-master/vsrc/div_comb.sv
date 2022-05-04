module div_comb(a,b,yshang,yyushu);
   input[31:0] a; //被除数
   input[31:0] b; //除数
   output[31:0] yshang; //
   output[31:0] yyushu; //
   reg[31:0] yshang;
   reg[31:0] yyushu;
   reg[31:0] tempa;
   reg[31:0] tempb;
   reg[63:0] temp_a;
   reg[63:0] temp_b;
   always @(a or b)
   begin
      tempa = a;
      tempb = b;
   end
   integer i;
   always @(tempa or tempb)
   begin
         temp_a = {32'h00000000,tempa}; //
         temp_b = {tempb,32'h00000000}; //
         for(i = 0;i < 32;i = i + 1) //32次循环
         begin
                  temp_a = {temp_a[62:0],1'b0}; //左移一位
                  if(temp_a[63:32] >= tempb) //注意：temp_a的高32位于tempb比较，不是与temp_b比较
                           temp_a = temp_a - temp_b + 1'b1; //加1表示商加1
                  else
                           temp_a = temp_a;
         end
         yshang = temp_a[31:0];
         yyushu = temp_a[63:32];
   end

endmodule 