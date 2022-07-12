`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: UltraMIPS
// Engineer: ghc
// 
// Create Date: 2020/06/23 14:31:11
// Design Name: 
// Module Name: my_axi_interface
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: test edition
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"
`include "defines_cache.v"
module my_axi_interface(
        input              clk,
        input              resetn, 
        
        input              flush,
                
        //Cache////////
        input wire             cache_ce,
        input wire             cache_wen,
        input wire             cache_ren,
        input wire [3:0]       cache_wsel,
        input wire [3:0]       cache_rsel,
        input wire[`RegBus]    cache_raddr,
        input wire[`RegBus]    cache_waddr,  
        input wire[`RegBus]    cache_wdata,   
        input wire             cache_rready,   
        input wire             cache_wvalid,   
        input wire             cache_wlast,    
        
        output reg[`RegBus]    rdata_o,       
        output reg             rdata_valid_o, //this will be set to 1 when rdata is ready
        output wire            wdata_resp_o,  //this will be set to 1 when the interface ready to get data.
        //burst
        input wire[`AXBURST]   cache_burst_type, 
        input wire[`AXSIZE]    cache_burst_size,
        input wire[`AXLEN]     cacher_burst_length,
        input wire[`AXLEN]     cachew_burst_length,
       
        //axi///////
        //ar
        output [3 :0]    arid         ,
        output reg[31:0] araddr       ,
        output reg[7 :0] arlen        ,
        output reg[2 :0] arsize       ,
        output reg[1 :0] arburst      ,
        output [1 :0]    arlock       ,
        output reg[3 :0] arcache      ,
        output [2 :0]    arprot       ,
        output reg       arvalid      ,
        input            arready      ,
        
        //r           
        input  [3 :0] rid          ,
        input  [31:0] rdata        ,
        input  [1 :0] rresp        ,
        input         rlast        ,
        input         rvalid       ,
        output reg    rready       ,
        
        //aw          
        output [3 :0]    awid         ,
        output reg[31:0] awaddr       ,
        output reg[7 :0] awlen        ,
        output reg[2 :0] awsize       ,
        output reg[1 :0] awburst      ,
        output [1 :0]    awlock       ,
        output reg[3 :0] awcache      ,
        output [2 :0]    awprot       ,
        output reg       awvalid      ,
        input            awready      ,
        
        //w          
        output [3 :0]     wid          ,
        output wire[31:0] wdata        ,
        output reg[3 :0]  wstrb        ,
        output wire       wlast        ,
        output wire       wvalid       ,
        input             wready       ,
        
        //b           
        input  [3 :0] bid          ,
        input  [1 :0] bresp        ,
        input         bvalid       ,
        output        bready       
    );
    
    reg[2:0] rcurrent_state;
    reg[2:0] rnext_state;
    
    reg[2:0] wcurrent_state;
    reg[2:0] wnext_state;
    reg wvalid_ins;
    
    assign arid = 4'b0000;
    assign arlock = `AXLOCK_NORMAL;
    assign arprot = 3'b000;
    
    assign awid = 4'b0000;
    assign awlock = `AXLOCK_NORMAL;
    assign awprot = 3'b000;
    
    assign wid = 4'b0000;
    assign bready = `True_v;
    
    assign wdata_resp_o = wvalid_ins & wready;
    assign wdata = cache_wdata;
    assign wlast = cache_wlast;
    assign wvalid = wvalid_ins & cache_wvalid; 
    
    
    
    always@(posedge clk)begin
        if(resetn == `RstEnable || flush == `True_v)begin
            rcurrent_state <= `AXI_IDLE;
            wcurrent_state <= `AXI_IDLE;
        end else begin
            rcurrent_state <= rnext_state;
            wcurrent_state <= wnext_state;
        end
    end
    
    //next state
    always@(*)begin
        if(resetn == `RstEnable || flush == `True_v)begin
            rnext_state = `AXI_IDLE;
        end else begin
            case(rcurrent_state)
            `AXI_IDLE: begin
                if(cache_ce == `True_v && cache_ren == `True_v 
                    && !(cache_raddr == awaddr && wnext_state != `AXI_IDLE))begin //avoid read-write conflict
                    rnext_state = `ARREADY;
                end else begin
                    rnext_state = `AXI_IDLE;
                end
            end
            `ARREADY:  begin
                if(arready == `True_v)begin
                    rnext_state = `RVALID;
                end else begin
                    rnext_state = `ARREADY;
                end
            end
            `RVALID:   begin
                if(rvalid == `False_v && rready == `False_v && rdata_valid_o == `True_v)begin
                    rnext_state = `AXI_IDLE;
                end else begin
                    rnext_state = `RVALID;
                end
            end
            default: rnext_state = `AXI_IDLE;
            endcase
        end
    end
    
    always@(*)begin
        if(resetn == `RstEnable || flush == `True_v)begin
            wnext_state = `AXI_IDLE;
        end else begin
            case(wcurrent_state)
            `AXI_IDLE: begin
                if(cache_ce == `True_v && cache_wen == `True_v)begin
                    wnext_state = `AWREADY;
                end else begin
                    wnext_state = `AXI_IDLE;
                end
            end
            `AWREADY:  begin
                if(awready == `True_v)begin
                    wnext_state = `WREADY;
                end else begin
                    wnext_state = `AWREADY;
                end
            end
            `WREADY:   begin
                if(wready == `True_v && wlast == `True_v)begin
                    wnext_state = `BVALID; 
                end else begin
                    wnext_state = `WREADY;
                end
            end
            `BVALID:   begin
                if(bvalid == `True_v)begin
                    wnext_state = `AXI_IDLE; 
                end else begin
                    wnext_state = `BVALID; 
                end
            end
            default: wnext_state = `AXI_IDLE;
            endcase
        end
    end
    
     //output ctrl
    always@(posedge clk)begin  
        if(resetn == `RstEnable || flush == `True_v)begin
            araddr <= `ZeroWord;      
            arlen <= 4'b0000;     
            arsize <= `AXSIZE_FOUR_BYTE;       
            arburst <= `AXBURST_INCR;
            arcache <= 4'b0000;
            arvalid <= `False_v;
            
            rready <= `False_v;
            rdata_o <= `ZeroWord;
            rdata_valid_o <= `False_v;
            
            awaddr <= `ZeroWord;       
            awlen <= 4'b0000;       
            awsize <= `AXSIZE_FOUR_BYTE;      
            awburst <= `AXBURST_INCR;   
            awcache <= 4'b0000;
            awvalid <= `False_v;
            
            wvalid_ins <= `False_v;          
            wstrb <= 4'b1111;
            
        end else begin
            case(rcurrent_state)
            `AXI_IDLE: begin                         
                rready <= `False_v;                                                                   
                rdata_o <= `ZeroWord;
                rdata_valid_o <= `False_v;
                if(cache_ce == `True_v && cache_ren == `True_v 
                   && !(cache_raddr == awaddr && wnext_state != `AXI_IDLE))begin
                    arlen <= cacher_burst_length;     
                    if(cache_rsel == 4'b0001 || cache_rsel == 4'b0010 || cache_rsel == 4'b0100 || cache_rsel == 4'b1000)begin
                        arsize <= 3'b000;
                    end else if(cache_rsel == 4'b0011 || cache_rsel == 4'b1100)begin
                        arsize <= 3'b001;
                    end else begin
                        arsize <= cache_burst_size;
                    end           
                    arburst <= cache_burst_type; 
                    arcache <= 4'b0000;    
                    arvalid <= `True_v;
                    araddr <= cache_raddr;
                end else begin  
                    arvalid <= `False_v;
                    araddr <= `ZeroWord;
                    arlen <= 4'b0000;           
                    arburst <= `AXBURST_INCR;
                    arcache <= 4'b0000;
                end
            end
            `ARREADY:  begin
                if(arready == `True_v)begin  //
                    araddr <= `ZeroWord;      
                    arlen <= 4'b0000;           
                    arburst <= `AXBURST_INCR;
                    arcache <= 4'b0000;
                    arvalid <= `False_v;
                    rready <= `True_v; 
                end else begin
                    
                end
            end
            `RVALID:  begin
                rdata_valid_o <= rvalid;
                if(rvalid == `True_v && rlast == `True_v)begin
                    rdata_o <= rdata;
                    rready <= `False_v;
                end else if(rvalid == `True_v) begin
                    rdata_o <= rdata;
                end else if(rvalid == `False_v && rready == `False_v && rdata_valid_o == `True_v) begin     
                    arsize <= 3'b010;               
                end
            end
            default:;
            endcase
            
            case(wcurrent_state)
            `AXI_IDLE: begin                                                                                                       
                if(cache_ce == `True_v && cache_wen == `True_v)begin  
                    awlen <= cachew_burst_length;       
                    if(cache_wsel == 4'b0001 || cache_wsel == 4'b0010 || cache_wsel == 4'b0100 || cache_wsel == 4'b1000)begin
                        awsize <= 3'b000;
                    end else if(cache_wsel == 4'b0011 || cache_wsel == 4'b1100)begin
                        awsize <= 3'b001;
                    end else begin
                        awsize <= cache_burst_size;
                    end             
                    awburst <= cache_burst_type;   
                    awcache <= 4'b0000;          
                    awvalid <= `True_v;
                    awaddr <= cache_waddr;
                    wstrb <= cache_wsel;

                end else begin  
                    wvalid_ins <= `False_v;      
                    awaddr <= `ZeroWord;       
                    awlen <= 4'b0000;       
                    awburst <= `AXBURST_INCR;   
                    awcache <= 4'b0000;
                    awvalid <= `False_v;     
                end
            end
            `AWREADY:  begin
                if(awready == `True_v)begin       
                    awlen <= 4'b0000;       
                    awburst <= `AXBURST_INCR;   
                    awcache <= 4'b0000;
                    awvalid <= `False_v;                 
                    wvalid_ins <= `False_v;
               
                end else begin
                    wvalid_ins <= `False_v;
                   
                end
            end
            `WREADY:   begin
                if(wready == `True_v && wlast == `True_v && wvalid_ins == `True_v)begin
                    wvalid_ins <= `False_v;
                    
                end else if(wdata_resp_o == `True_v)begin
                    wvalid_ins <= `True_v;
                    
                end else begin
                    wvalid_ins <= `True_v;
                   
                end
            end
            `BVALID:   begin
                wvalid_ins <= `False_v;
                wstrb <= 4'b1111;
                awsize <= 3'b010;
                if(bvalid == `True_v)begin
                    awaddr <= `ZeroWord;   
                end
            end
            default:;        
            endcase
        end
    end

endmodule
