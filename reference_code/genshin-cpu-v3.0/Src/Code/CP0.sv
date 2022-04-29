/*
 * @Author: Johnson Yang
 * @Date: 2021-03-27 17:12:06
 * @LastEditTime: 2021-06-29 17:50:50
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 协处理器CP0（实现了CP0中的 BadVAddr、Count、Compare、Status、Cause、EPC6个寄存器的部分功能）
 * 
 */
 

`include "CommonDefines.svh"
`include "CPU_Defines.svh"

module cp0_reg (  
    input logic             clk,
    input logic             rst,
    // read port        
    input logic  [4:0]      CP0_RdAddr,                 //要读取的CP0寄存器的地址
    output logic [31:0]     CP0_RdData,              //读出的CP0某个寄存器的值   
    // 异常相关输入接口           
    input AsynExceptType    Interrupt,                 //6个外部硬件中断输入 
    WB_CP0_Interface        WCBus,      
    output logic   [31:0]   CP0_BadVAddr,               //8号寄存器  BadVAddr寄存器的值:最新地址相关例外的出错地址
    output logic   [31:0]   CP0_Count,                  //9号寄存器  Count寄存器的值
    output logic   [31:0]   CP0_Compare,                //11号寄存器 Compare寄存器的值
    output logic   [31:0]   CP0_Status,                 //12号寄存器 Status寄存器的值
    output logic   [31:0]   CP0_Cause,                  //13号寄存器 Cause寄存器的值
    output logic   [31:0]   CP0_EPC,                    //14号寄存器 EPC寄存器的值
    output logic   [31:0]   CP0_Index,                  //0号
    output logic   [31:0]   CP0_EntryHi,                //10号
    output logic   [31:0]   CP0_EntryLo0,               //2号
    output logic   [31:0]   CP0_EntryLo1                //3号
    );

    logic           [5:0]   Hardwareint;
    logic                   TimCount2;
    logic                   CP0_TimerInterrupt;         //是否有定时中断发生

    assign Hardwareint = 
        {
        Interrupt.HardwareInterrupt1,
        Interrupt.HardwareInterrupt2,
        Interrupt.HardwareInterrupt3,
        Interrupt.HardwareInterrupt4,
        Interrupt.HardwareInterrupt5,
        (Interrupt.HardwareInterrupt6 | CP0_TimerInterrupt)
        };
    //******************************************************************************
    //                     对CP0中寄存器的初始化复位
    //******************************************************************************
    always_ff @ ( posedge clk or negedge rst) begin
        if(rst == `RstEnable) begin
            CP0_BadVAddr       <= `ZeroWord;
            CP0_Count          <= `ZeroWord;
            CP0_Compare        <= `ZeroWord;
            CP0_Status         <= 32'b0000_0000_0100_0000_0000_0000_0000_0000;//Status寄存器的初始值：其中CU字段为0001，表示协处理器CP0存在
            CP0_Cause          <= `ZeroWord;
            CP0_EPC            <= `ZeroWord;
            CP0_Index          <= `ZeroWord;
            CP0_EntryHi        <= `ZeroWord;
            CP0_EntryLo0       <= `ZeroWord;
            CP0_EntryLo1       <= `ZeroWord;
            CP0_TimerInterrupt <= `InterruptNotAssert;
            TimCount2           <= 1'b0;
        end 
        else begin
            CP0_Cause[15:10]               <= Hardwareint;    //Cause寄存器的10-15位保存6个外部中断状态（1代表有中断需要处理）
            
            if (WCBus.WB_CP0Wr == `WriteEnable && WCBus.WB_Dst == `CP0_REG_COUNT ) begin 
                CP0_Count                  <= WCBus.WB_Result;   //将输入数据写入到Count寄存器中
                TimCount2                  <= 1'b0;
            end else begin
                TimCount2                  <= TimCount2  + 1;
            end
            if (TimCount2 == 1'd1)begin
               CP0_Count                   <= CP0_Count + 1;   //Count寄存器的值在每个时钟周期加1
            end 
            // 当Compare寄存器不为0，且Count寄存器的值等于Compare寄存器的值时，
            // 将输出信号CP0_TimerInterrupt置为1，表示时钟中断发生
            if(CP0_Compare != `ZeroWord && CP0_Count == CP0_Compare && (WCBus.WB_CP0Wr != `WriteEnable || WCBus.WB_Dst != `CP0_REG_COMPARE)) begin
                CP0_TimerInterrupt         <= `InterruptAssert;  // 发生中断
                CP0_Cause[30]              <= 1'b1;  // 中断标记位置1
            end
            //******************************************************************************
            //                     对CP0中寄存器的写操作：时序逻辑
            //  PRId、Config不可以写，Cause寄存器只有其中的IP[1:0]、IV、WP三个字段可写
            //******************************************************************************
            if(WCBus.WB_CP0Wr == `WriteEnable) begin
                unique case(WCBus.WB_Dst)
                    `CP0_REG_COMPARE:begin     //写Compare寄存器
                        CP0_Compare        <= WCBus.WB_Result;
                        CP0_TimerInterrupt <= `InterruptNotAssert;  //取消时钟中断的声明
                    end
                    `CP0_REG_STATUS:begin      //写Status寄存器
                        CP0_Status  [15:8 ]<= WCBus.WB_Result[15:8];
                        CP0_Status  [1]    <= WCBus.WB_Result[1];
                        CP0_Status  [0]    <= WCBus.WB_Result[0];
                    end
                    `CP0_REG_EPC:begin         //写EPC寄存器
                        CP0_EPC            <= WCBus.WB_Result;
                    end
                    `CP0_REG_CAUSE:begin       //写Cause寄存器
                        CP0_Cause[9:8]     <= WCBus.WB_Result[9:8];  //Cause寄存器只有IP[1:0]字段是可写的
                    end
                default:begin
                    CP0_EPC <= CP0_EPC;
                end
                endcase
            end
            // `ifdef DEBUG
            //     $monitor("CP0:BadVAddr=%8X,Count=%8X,Compare=%8X,Status=%8X,Cause=%8X,EPC=%8X",
            //     CP0_BadVAddr,
            //     CP0_Count,
            //     CP0_Compare,
            //     CP0_Status,
            //     CP0_Cause,
            //     CP0_EPC);
            // `endif
            //******************************************************************************
            //                               CP0异常处理
            //******************************************************************************            
            //存在外部中断
            if (WCBus.WB_ExceptType.Interrupt == `InterruptAssert) begin   
                    //已经在访存阶段判断了是否处于异常级
                    if(CP0_Status[1] == 1'b0) begin        //EXL字段是否有例外发生（为0代表处于正常级）
                        if(WCBus.WB_IsInDelaySlot == `InDelaySlot) begin // 是否位于延迟槽中
                            CP0_EPC            <= WCBus.WB_PC - 4;
                            CP0_Cause[31]      <= 1'b1;        //Cause寄存器的BD字段(延迟槽标记字段)
                        end else begin
                            CP0_EPC            <= WCBus.WB_PC;
                            CP0_Cause[31]      <= 1'b0;
                        end
                    end
                        //如果EXL字段为1，表示当前已经处于异常级了，又发生了新的异常，那么
                        //只需要将异常原因保存到Cause寄存器的ExcCode字段
                        CP0_Status[1]          <= 1'b1;        //Status寄存器的EXL字段
                        CP0_Cause[6:2]         <= 5'b00000;    //Cause寄存器的ExcCode字段
                end
            //地址错例外--取指令
            else if (WCBus.WB_ExceptType.WrongAddressinIF == `InterruptAssert) begin  
                    //Status[1]为EXL字段，表示是否处于异常级
                    if(CP0_Status[1] == 1'b0) begin        //EXL字段是否有例外发生（为0代表处于正常级）
                        if(WCBus.WB_IsInDelaySlot == `InDelaySlot) begin
                            CP0_EPC        <= WCBus.WB_PC - 4;
                            CP0_Cause[31]  <= 1'b1;
                        end else begin
                            CP0_EPC        <= WCBus.WB_PC;
                            CP0_Cause[31]  <= 1'b0;
                        end
                    end
                    CP0_Status[1]          <= 1'b1;
                    CP0_Cause[6:2]         <= 5'b00100;
                    CP0_BadVAddr           <= WCBus.WB_PC;
                end
            //无效指令异常
            else if (WCBus.WB_ExceptType.ReservedInstruction == `InterruptAssert)  begin   
                    if(CP0_Status[1] == 1'b0) begin
                        if(WCBus.WB_IsInDelaySlot == `InDelaySlot) begin
                            CP0_EPC        <= WCBus.WB_PC - 4;
                            CP0_Cause[31]  <= 1'b1;
                        end else begin
                            CP0_EPC        <= WCBus.WB_PC;
                            CP0_Cause[31]  <= 1'b0;
                        end
                    end
                    CP0_Status[1]          <= 1'b1;
                    CP0_Cause[6:2]         <= 5'b01010;
                end

            //系统调用异常syscall
            else if (WCBus.WB_ExceptType.Syscall == `InterruptAssert) begin  
                    //Status[1]为EXL字段，表示是否处于异常级
                    if(CP0_Status[1] == 1'b0) begin        //EXL字段是否有例外发生（为0代表处于正常级）
                        if(WCBus.WB_IsInDelaySlot == `InDelaySlot) begin
                            CP0_EPC        <= WCBus.WB_PC - 4;
                            CP0_Cause[31]  <= 1'b1;
                        end else begin
                            CP0_EPC        <= WCBus.WB_PC;
                            CP0_Cause[31]  <= 1'b0;
                        end
                    end
                    CP0_Status[1]          <= 1'b1;
                    CP0_Cause[6:2]         <= 5'b01000;
                end

            // 断点break异常
            else if (WCBus.WB_ExceptType.Break == `InterruptAssert) begin  
                    //Status[1]为EXL字段，表示是否处于异常级
                    if(CP0_Status[1] == 1'b0) begin        //EXL字段是否有例外发生（为0代表处于正常级）
                        if(WCBus.WB_IsInDelaySlot == `InDelaySlot) begin
                            CP0_EPC        <= WCBus.WB_PC - 4;
                            CP0_Cause[31]  <= 1'b1;
                        end else begin
                            CP0_EPC        <= WCBus.WB_PC;
                            CP0_Cause[31]  <= 1'b0;
                        end
                    end
                    CP0_Status[1]          <= 1'b1;
                    CP0_Cause[6:2]         <= 5'b01001;
                end
            //异常返回指令eret
            else if (WCBus.WB_ExceptType.Eret == `InterruptAssert)  begin  
                    CP0_Status[1]          <= 1'b0;
                end
            // //自陷异常
            // 32'h0000_000d:begin                 
            //     if(CP0_Status[1] == 1'b0) begin
            //         if(WCBus.WB_IsInDelaySlot == `InDelaySlot) begin
            //             CP0_EPC <= WCBus.WB_PC - 4;
            //             CP0_Cause[31] <= 1'b1;
            //         end else begin
            //             CP0_EPC <= WCBus.WB_PC;
            //             CP0_Cause[31] <= 1'b0;
            //         end
            //     end
            //     CP0_Status[1] <= 1'b1;
            //     CP0_Cause[6:2] <= 5'b01101;
            //     end
            //溢出异常
            else if (WCBus.WB_ExceptType.Overflow == `InterruptAssert) begin 
                    if(CP0_Status[1] == 1'b0) begin
                        if(WCBus.WB_IsInDelaySlot == `InDelaySlot) begin  
                            CP0_EPC        <= WCBus.WB_PC - 4;
                            CP0_Cause[31]  <= 1'b1;
                        end else begin
                            CP0_EPC        <= WCBus.WB_PC;
                            CP0_Cause[31]  <= 1'b0;
                        end
                    end
                    CP0_Status[1]          <= 1'b1;
                    CP0_Cause[6:2]         <= 5'b01100;
                end
            //地址错例外——数据写入
            else if (WCBus.WB_ExceptType.WrWrongAddressinMEM == `InterruptAssert) begin 
                    if(CP0_Status[1] == 1'b0) begin
                        if(WCBus.WB_IsInDelaySlot == `InDelaySlot) begin  
                            CP0_EPC        <= WCBus.WB_PC - 4;
                            CP0_Cause[31]  <= 1'b1;
                        end else begin
                            CP0_EPC        <= WCBus.WB_PC;
                            CP0_Cause[31]  <= 1'b0;
                        end
                    end
                    CP0_Status[1]          <= 1'b1;
                    CP0_Cause[6:2]         <= 5'b00101;
                    CP0_BadVAddr           <= WCBus.WB_ALUOut;
                end

            //地址错例外——数据读取
            else if (WCBus.WB_ExceptType.RdWrongAddressinMEM == `InterruptAssert) begin 
                    if(CP0_Status[1] == 1'b0) begin
                        if(WCBus.WB_IsInDelaySlot == `InDelaySlot) begin  
                            CP0_EPC        <= WCBus.WB_PC - 4;
                            CP0_Cause[31]  <= 1'b1;
                        end else begin
                            CP0_EPC        <= WCBus.WB_PC;
                            CP0_Cause[31]  <= 1'b0;
                        end
                    end
                    CP0_Status[1]          <= 1'b1;
                    CP0_Cause[6:2]         <= 5'b00100;
                    CP0_BadVAddr           <= WCBus.WB_ALUOut;

                end
        end
    end

    //read port
    always_comb begin
        case(CP0_RdAddr)
            `CP0_REG_COUNT:      CP0_RdData = CP0_Count;
            `CP0_REG_COMPARE:    CP0_RdData = CP0_Compare;
            `CP0_REG_STATUS:     CP0_RdData = CP0_Status;
            `CP0_REG_CAUSE:      CP0_RdData = CP0_Cause;
            `CP0_REG_EPC:        CP0_RdData = CP0_EPC;
            `CP0_REG_BADVADDR:   CP0_RdData = CP0_BadVAddr;
            `CP0_REG_INDEX:      CP0_RdData = CP0_Index;
            `CP0_REG_ENTRYHI:    CP0_RdData = CP0_EntryHi;
            `CP0_REG_ENTRYLO0:   CP0_RdData = CP0_EntryLo0;
            `CP0_REG_ENTRYLO1:   CP0_RdData = CP0_EntryLo1;
            default:             CP0_RdData = 'x;
        endcase
    end
    
endmodule
