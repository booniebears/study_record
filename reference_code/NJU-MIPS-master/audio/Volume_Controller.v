module Volume_Controller(input clk,
								 output [8:0] volume,
								 input ch_n,
								 input dir
								 );
								 
reg [8:0] tmp = 9'h60;
assign volume = tmp;
always @(negedge ch_n)
begin
	if (dir)
	begin
		if (tmp[6:0] < 7'b1111011)
			tmp <= tmp+9'd5;
	end
	else
	begin
		if (tmp[6:0] > 7'b0101111)
			tmp <= tmp-9'd5;
	end
end

endmodule 