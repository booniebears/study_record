module audio(input clk,
				 output DACLRCLK, 
				 output DACDAT,
				 output XCK,
				 output BCLK,
				 output I2C_SCLK,
				 inout I2C_SDAT,
				 
				 input [7:0] kb_code,
				 
				 input ch_n,
				 input dirs,
				 input ken,
				 input en
				 );


wire [15:0] f;
wire clki2c;
wire [8:0] volume;	
wire double;

c2f rom1(.clock(clk),.address(kb_code),.q(f));
						
clkgen #(10000) I2CCKgen(.clkin(clk),
								 .rst(0),
								 .clken(1'b1),
								 .clkout(clki2c)
								 );
									
I2C_Audio_Config i2c(.clk_i2c(clki2c),
						  .reset_n(ch_n),
						  .I2C_SCLK(I2C_SCLK),
						  .I2C_SDAT(I2C_SDAT),
						  .volumn(volume)
						  );

Volume_Controller	vc(.clk(clki2c),
							 .volume(volume),
							 .ch_n(ch_n),
							 .dir(dirs)
							 );

I2S i2s( .clk(clk),
			.DACDAT(DACDAT),
			.DACLRCLK(DACLRCLK),
			.BCLK(BCLK),
			.XCK(XCK),
			.en(en&ken),
			.f_1(f),
			.f_2(),
			.double(1'b0)
			); 	
		
endmodule 