module freq_div(input clkin,
				input rst,
				output reg clkout = 0
				);
				
parameter dividelimit = 12;
parameter limit = dividelimit/2;
reg[31:0] clkcount = 0;

always @ (negedge clkin)
		if (rst)
		begin
			clkcount = 0;
			clkout = 1'b0;
		end
		else 
		begin 
				clkcount = clkcount + 1;
				if (clkcount >= limit)
				begin
					clkcount = 32'd0;
					clkout = ~clkout;
				end
				else 
					clkout = clkout;
		end

endmodule 