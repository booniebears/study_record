module vga(
	input 							CLOCK_50,
	output		          		VGA_BLANK_N,
	output		     [7:0]		VGA_B,
	output		          		VGA_CLK,
	output		     [7:0]		VGA_G,
	output		          		VGA_HS,
	output		     [7:0]		VGA_R,
	output		          		VGA_SYNC_N,
	output		          		VGA_VS,
	
	input				  [7:0]		q,
	output	        [11:0]    rdaddress
	);
	
	
	wire CLOCK_25;
	clkgen #(25000000) vgaclk(CLOCK_50, 1'b0, 1'b1, VGA_CLK);

	assign VGA_SYNC_N = 0;
	wire [9:0] h_addr;
	wire [9:0] v_addr;
	//30*70
	wire [7:0] y = ((v_addr)/16)%30;
	wire [7:0] x = (h_addr)/9;
	assign rdaddress = x+y*70;
	//16*9
	wire [3:0] dx = (h_addr)%9 - 1;
	wire [3:0] dy = (v_addr)%16;
	wire [11:0] print_code;
	wire [7:0] ascii = q;
	ascii2pcode a2c(
		.clock(CLOCK_50),
		.address({ascii,dy}),
		.q(print_code)
	);
	//480*630
	wire [23:0] ft_color = 24'hFFFFFF;
	wire [23:0] bg_color = 24'h000000;
	wire [23:0] tmp_data = (print_code[dx]) ? ft_color:bg_color;
	wire [23:0] vga_data = (x>=8'd70||ascii==0) ? bg_color:tmp_data;
	vga_ctrl vga_controller(VGA_CLK, 1'b0, vga_data,
									h_addr, v_addr, VGA_HS, VGA_VS, VGA_BLANK_N,
									VGA_R, VGA_G, VGA_B);
	
endmodule 
	