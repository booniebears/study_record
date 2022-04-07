module Run_LED_tb (
    
);
    reg clk,rst; 
    wire [7:0] out;
    run Run1(.clk(clk),.rst(rst),.out(out));
    initial begin
        clk=0;
        rst=0;
        #2
        rst=1;
    end
    initial begin
        #10000000 $finish;
    end
    always #1 clk=~clk;
endmodule //Run_LED_tb
