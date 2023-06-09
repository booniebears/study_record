module REG_EX_MEM(E_md_control,E_md_signal,E_res_hi,E_res_lo,E_RegWrite,E_RegDst,E_MemWrite,E_MemtoReg,E_WriteReg,E_Qb,E_ALUanswer,E_load_option,E_save_option,Clk,Reset,
M_md_control,M_md_signal,M_res_hi,M_res_lo,M_RegWrite,M_RegDst,M_MemWrite,M_MemtoReg,M_WriteReg,M_Qb,M_ALUanswer,M_load_option,M_save_option,busy);

    input [31:0] E_ALUanswer,E_Qb,E_res_hi,E_res_lo;
    input [4:0] E_WriteReg;
    input [2:0] E_load_option,E_md_control;
    input [1:0] E_save_option;
    input [3:0] busy;
    input Clk,Reset,E_md_signal;
    input E_RegWrite,E_RegDst,E_MemWrite,E_MemtoReg;

    output reg[31:0] M_ALUanswer ,M_Qb,M_res_hi,M_res_lo;
    output reg[4:0] M_WriteReg;
    output reg[2:0] M_load_option,M_md_control;
    output reg[1:0] M_save_option;
    output reg M_RegWrite,M_RegDst,M_MemWrite,M_MemtoReg,M_md_signal;

    initial begin
        M_ALUanswer = 0;
        M_MemtoReg = 0;
        M_MemWrite = 0;
        M_Qb = 0;
        M_RegDst = 0;
        M_RegWrite = 0;
        M_WriteReg = 0;
        M_load_option = 0;
        M_save_option = 0;
        M_md_signal = 0;
        M_res_hi = 0;
        M_res_lo = 0;
        M_md_control = 0;
    end

    always @(posedge Clk or negedge Reset)  begin  
    /*
    if (busy!=0)begin
        M_ALUanswer = 0;
        M_MemtoReg = 0;
        M_MemWrite = 0;
        M_Qb = 0;
        M_RegDst = 0;
        M_RegWrite = 0;
        M_WriteReg = 0;
        M_load_option = 0;
        M_save_option = 0;
        M_md_signal = 0;
        M_res_hi = 0;
        M_res_lo = 0;
        M_md_control = 0;
    end
    else begin
    */
        if (!Reset)begin  
            M_ALUanswer = 0;
            M_MemtoReg = 0;
            M_MemWrite = 0;
            M_Qb = 0;
            M_RegDst = 0;
            M_RegWrite = 0;
            M_WriteReg = 0;
            M_load_option = 0;
            M_save_option = 0;
            M_md_signal = 0;
            M_res_hi = 0;
            M_res_lo = 0;
            M_md_control = 0;
            end  
        else   
            begin
                M_ALUanswer = E_ALUanswer;
                M_MemtoReg = E_MemtoReg;
                M_MemWrite = E_MemWrite;
                M_Qb = E_Qb;
                M_RegDst = E_RegDst;
                M_RegWrite = E_RegWrite;
                M_WriteReg = E_WriteReg;
                M_load_option = E_load_option;
                M_save_option = E_save_option;
                M_md_signal = E_md_signal;
                M_res_hi = E_res_hi;
                M_res_lo = E_res_lo;
                M_md_control = E_md_control;
            end 
        //end 
    end

endmodule