/*
 * @Author: npuwth
 * @Date: 2021-06-16 18:10:55
 * @LastEditTime: 2021-07-16 21:36:26
 * @LastEditors: npuwth
 * @Copyright 2021 GenshinCPU
 * @Version:1.0
 * @IO PORT:
 * @Description: 
 */

`include "/root/difftest/nwpu-diff-test-master/vsrc/mycpu/CommonDefines.svh"
`include "/root/difftest/nwpu-diff-test-master/vsrc/mycpu/CPU_Defines.svh"
`include "/root/difftest/nwpu-diff-test-master/vsrc/mycpu/Cache_Defines.svh"

module TOP_IF ( 
    input logic                 clk,
    input logic                 resetn,
    input logic                 IF_Wr,
    input logic                 IF_Flush,
    PREIF_IF_Interface          PIBus,
    IF_ID_Interface             IIBus,
    CPU_Bus_Interface           cpu_ibus
);  
    
    IF_REG U_IF_REG (
        .clk                    (clk ),
        .rst                    (resetn ),
        .IF_Wr                  (IF_Wr ),
        .IF_Flush               (IF_Flush ),
        .PREIF_PC               (PIBus.PREIF_PC ),
        .PREIF_ExceptType       (PIBus.PREIF_ExceptType ),
//-----------------------------output-------------------------------------//
        .IF_PC                  (IIBus.IF_PC ),
        .IF_ExceptType          (IIBus.IF_ExceptType)
    );  

    assign IIBus.IF_Instr = cpu_ibus.rdata;

endmodule