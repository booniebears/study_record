`include "macro.v"
`timescale 10ns/10ps

module sopc_tst();
reg CLOCK_50;
reg rst;

initial begin
    CLOCK_50 = 1'b0;
    forever #10 CLOCK_50 = ~CLOCK_50;
end

initial begin
    rst = `RSTENABLE;
    #195 rst = `RSTDISABLE;
    #16000 $stop;
end

initial begin
    $dumpfile("wave.vcd");
    $dumpall;
end

wire [`BYTEWIDTH] vga_q;
sopc sopc0(
    .CLOCK_50(CLOCK_50),
    .rst(rst)
);

endmodule
