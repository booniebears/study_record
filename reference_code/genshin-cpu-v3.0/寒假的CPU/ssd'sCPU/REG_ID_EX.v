module REG_ID_EX(ID_start_mult,ID_start_div,ID_updatemd,ID_md_signal,ID_B_code,ID_sa,ID_RegDst,ID_RegWrite,ID_ALUXSrc,ID_ALUYSrc,ID_ALUControl,ID_md_control,ID_MemWrite,ID_MemtoReg,ID_WriteReg,ID_usigned,ID_Qa,ID_Qb,ID_ext32,ID_FwdA,ID_FwdB,ID_load_option,ID_save_option,Clk,Reset,
E_start_mult,E_start_div,E_updatemd,E_md_signal,E_B_code,E_sa,E_RegDst,E_RegWrite,E_ALUXSrc,E_ALUYSrc,E_ALUControl,E_md_control,E_MemWrite,E_MemtoReg,E_WriteReg,E_usigned,E_Qa,E_Qb,E_ext32,E_FwdA,E_FwdB,E_load_option,E_save_option,stall,stallstall,busy);

    input [31:0] ID_Qa,ID_Qb,ID_ext32,ID_sa;
    input [4:0] ID_WriteReg;
    input [2:0] ID_FwdA,ID_FwdB;
    input [3:0] ID_ALUControl,busy;
    input [2:0] ID_load_option,ID_md_control;
    input [1:0] ID_save_option;
    input Clk,Reset,stall,stallstall;
    input ID_RegDst,ID_RegWrite,ID_ALUYSrc,ID_MemWrite,ID_MemtoReg,ID_ALUXSrc,ID_usigned,ID_B_code,ID_md_signal,ID_updatemd,ID_start_mult,ID_start_div;

    wire clr;
    assign clr=(~stall)&(~stallstall);

    output reg[31:0] E_Qa,E_Qb,E_ext32,E_sa;
    output reg[2:0] E_FwdA,E_FwdB;
    output reg[3:0] E_ALUControl;
    output reg[4:0] E_WriteReg;
    output reg[2:0] E_load_option,E_md_control;
    output reg[1:0] E_save_option;
    output reg E_RegDst,E_RegWrite,E_ALUYSrc,E_MemWrite,E_MemtoReg,E_ALUXSrc,E_usigned,E_B_code,E_md_signal,E_updatemd,E_start_mult,E_start_div;

    initial begin
        E_sa = 0;
        E_ALUControl = 0;
        E_ALUXSrc = 0;
        E_ALUYSrc = 0;
        E_ext32 = 0;
        E_FwdA = 0;
        E_FwdB = 0;
        E_MemtoReg = 0;
        E_MemWrite = 0;
        E_Qa = 0;
        E_Qb = 0;
        E_RegDst = 0;
        E_RegWrite = 0;
        E_WriteReg = 0;  
        E_usigned = 0;
        E_B_code = 0;
        E_load_option = 0;
        E_save_option = 0;
        E_md_control = 0;
        E_md_signal = 0;
        E_updatemd = 0;
        E_start_mult = 0;
        E_start_div = 0;
    end

    always @(posedge Clk or negedge Reset)  
    begin  
    //$display("test?????????");
   // if(busy==0)begin
        if (clr==0) begin  
                E_sa = 0;
                E_ALUControl = 0;
                E_ALUXSrc = 0;
                E_ALUYSrc = 0;
                E_ext32 = 0;
                E_FwdA = 0;
                E_FwdB = 0;
                E_MemtoReg = 0;
                E_MemWrite = 0;
                E_Qa = 0;
                E_Qb = 0;
                E_RegDst = 0;
                E_RegWrite = 0;
                E_WriteReg = 0;  
                E_usigned = 0;
                E_B_code = 0;
                E_load_option = 0;
                E_save_option = 0;
                E_md_control = 0;
                E_md_signal = 0;
                E_updatemd = 0;
                E_start_mult = 0;
                E_start_div = 0;
            end  
        else   
            begin
                //$display("test");
                E_sa = ID_sa;
                E_ALUControl = ID_ALUControl;
                E_ALUXSrc = ID_ALUXSrc;
                E_ALUYSrc = ID_ALUYSrc;
                E_ext32 = ID_ext32;
                E_FwdA = ID_FwdA;
                E_FwdB = ID_FwdB;
                E_MemtoReg = ID_MemtoReg;
                E_MemWrite = ID_MemWrite;
                E_Qa = ID_Qa;
                E_Qb = ID_Qb;
                E_RegDst = ID_RegDst;
                E_RegWrite = ID_RegWrite;
                E_WriteReg = ID_WriteReg;  
                E_usigned = ID_usigned;
                E_B_code = ID_B_code;
                E_load_option = ID_load_option;
                E_save_option = ID_save_option;
                E_md_control = ID_md_control;
                E_md_signal = ID_md_signal;
                E_updatemd = ID_updatemd;
                E_start_mult = ID_start_mult;
                E_start_div = ID_start_div;
            end  
       // end
    end

endmodule
