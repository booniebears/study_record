`include "macro.v"

module ctrl(
    input wire rst,
    input wire stallreq_id,
    input wire stallreq_ex,
    output reg[5:0] stall 
);

    always @(*) begin
        if (rst == `RSTENABLE) begin
            stall <= 6'b000000;
        end else if (stallreq_ex == `STOP) begin 
            stall <= 6'b001111;
        end else if (stallreq_id == `STOP) begin 
            stall <= 6'b000111;
        end else begin
            stall <= 6'b000000;
        end
    end

endmodule
