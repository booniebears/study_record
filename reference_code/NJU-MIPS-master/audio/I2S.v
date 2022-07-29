module I2S(input clk,
			  output reg DACDAT,
			  output DACLRCLK,
			  output BCLK,
			  output XCK,
			  input en,
			  input [15:0]f_1,
			  input [15:0]f_2,
			  input double
			  );
			  
xck XCKgen(.refclk(clk),
			  .rst(~en),
			  .outclk_0(XCK),
			  .locked()
			  );
			  
			
freq_div #(12) BCLKgen(.clkin(XCK),
							  .rst(0),
							  .clkout(BCLK)
							  );
							  
freq_div #(32) DACLRCLKgen(.clkin(BCLK),
									.rst(0),
									.clkout(DACLRCLK)
									);			  



wire [31:0]tmp_1 = f_1*32'd65536;
wire [15:0]d_1 = tmp_1/32'd48000;
wire [15:0]T_1 = 32'd48000/f_1;
reg [15:0]k_1 = 0;
reg [15:0]cnt_1 = 0;
wire signed [15:0]sin_1;

reg [3:0]index = 0;

sintable SINTABLE(.address(k_1[15:6]),
						.clock(clk),
						.q(sin_1)
						);
								
wire signed [15:0] sin = sin_1;
												
always @(negedge BCLK)
	index <= index + 4'd1;

always @(index)
begin
	case (index)
		4'd15: DACDAT = sin[0];
		4'd14: DACDAT = sin[1];
		4'd13: DACDAT = sin[2];
		4'd12: DACDAT = sin[3];
		4'd11: DACDAT = sin[4];
		4'd10: DACDAT = sin[5];
		4'd9: DACDAT  = sin[6];
		4'd8: DACDAT  = sin[7];
		4'd7: DACDAT  = sin[8];
		4'd6: DACDAT  = sin[9];
		4'd5: DACDAT  = sin[10];
		4'd4: DACDAT  = sin[11];
		4'd3: DACDAT  = sin[12];
		4'd2: DACDAT  = sin[13];
		4'd1: DACDAT  = sin[14];
		4'd0: DACDAT  = sin[15];
		default: DACDAT <= 16'd0;
	endcase
end

always @(posedge DACLRCLK)
begin 
	  k_1 <= k_1 + d_1;
end
		

endmodule
		