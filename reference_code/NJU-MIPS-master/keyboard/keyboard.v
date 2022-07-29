module keyboard(
	input clk,ps2_clk,ps2_data,
	output [7:0]ascii_out,
	output [7:0]kb_code,
	output en
	);
	
	parameter S0 = 0, S1 = 1;
	
	wire overflow,ready;
	wire [7:0]data;
	reg nextdata_n,clrn;
	
	reg [7:0] bakcode = 0;
	reg [7:0] code = 0;
	reg [3:0] state;
	reg shift = 0;
	reg [7:0] in_code = 0;
	reg E0 = 0;

	initial
	begin 
		clrn = 1'b0;
		state = S0;
	end
	
	wire [7:0]ascii_1;
	wire [7:0]ascii_2;
	ps2_keyboard keyboard(
	.clk(clk),.clrn(clrn),.ps2_clk(ps2_clk),.ps2_data(ps2_data),
	.nextdata_n(nextdata_n),.ready(ready),.overflow(overflow),.data(data));
	kb_rom romkb(.clock(clk),.address(in_code),.q(ascii_1));
	kb_shift_rom romkbshift(.clock(clk),.address(in_code),.q(ascii_2));
	
	
	assign ascii_out = (shift==0) ? ascii_1 : ascii_2;
	assign kb_code = in_code;
	assign en = in_code!=0&&in_code!=8'hf0&&in_code!=8'h12&&in_code!=8'h11&&in_code!=8'h14;
	
	
	always @(posedge clk) begin
		if (overflow) clrn <= 0;
		else clrn <= 1;
		
		if (ready) begin		
			case (state)
				S0: 
					if (data!=8'hf0&&data!=8'h00&&E0)
					begin
						case (data)
							8'h75:
								begin
									if (8'd150 != code && 8'd150 != bakcode && data!=0)
									begin
										if (code == 8'hf0||code == 8'h00)
										begin
											code <= 8'd150;
											in_code <= 8'd150;
										end
										else if (bakcode == 8'hf0 || bakcode == 8'h00)
										begin
											bakcode <= 8'd150;
											in_code <= 8'd150;
										end
									end
									E0 = 0;
								end
							8'h72: 
								begin
									if (8'd151 != code && 8'd151 != bakcode && data!=0)
									begin
										if (code == 8'hf0||code == 8'h00)
										begin
											code <= 8'd151;
											in_code <= 8'd151;
										end
										else if (bakcode == 8'hf0 || bakcode == 8'h00)
										begin
											bakcode <= 8'd151;
											in_code <= 8'd151;
										end
									end
									E0 = 0;
								end
							8'h6B:
								begin
									if (8'd152 != code && 8'd152 != bakcode && data!=0)
									begin
										if (code == 8'hf0||code == 8'h00)
										begin
											code <= 8'd152;
											in_code <= 8'd152;
										end
										else if (bakcode == 8'hf0 || bakcode == 8'h00)
										begin
											bakcode <= 8'd152;
											in_code <= 8'd152;
										end
									end
									E0 = 0;
								end
							8'h74:
								begin
									if (8'd153 != code && 8'd153 != bakcode && data!=0)
									begin
										if (code == 8'hf0||code == 8'h00)
										begin
											code <= 8'd153;
											in_code <= 8'd153;
										end
										else if (bakcode == 8'hf0 || bakcode == 8'h00)
										begin
											bakcode <= 8'd153;
											in_code <= 8'd153;
										end
									end
									E0 = 0;
								end
							default E0 = 0;
						endcase
					end
					else
					if (data!=8'he0)
					begin
						if (data==8'h12) shift = 1;
						else
						if (data==8'hf0) 
						begin
							state <= S1;
						end
						else if (data != code && data != bakcode && data!=0)
						begin
							if (code == 8'hf0||code == 8'h00)
							begin
									code <= data;
									in_code <= data;
							end
							else if (bakcode == 8'hf0 || bakcode == 8'h00)
							begin
								bakcode <= data;
								in_code <= data;
							end
						end
					end
					else E0 = 1;
						
				S1:
				begin
					if (E0)
						case (data)
							8'h75:
								begin
									if (8'd150 == code)
									begin
										code <= 8'hf0;
										in_code <= bakcode;
									end
									else if (8'd150 == bakcode)
									begin
										bakcode <= 8'hf0;
										in_code <= 8'hf0;
									end
									E0 = 0;
								end
							8'h72: 
								begin
									if (8'd151 == code)
									begin
										code <= 8'hf0;
										in_code <= bakcode;
									end
									else if (8'd151 == bakcode)
									begin
										bakcode <= 8'hf0;
										in_code <= 8'hf0;
									end
									E0 = 0;
								end
							8'h6B:
								begin
									if (8'd152 == code)
									begin
										code <= 8'hf0;
										in_code <= bakcode;
									end
									else if (8'd152 == bakcode)
									begin
										bakcode <= 8'hf0;
										in_code <= 8'hf0;
									end
									E0 = 0;
								end
							8'h74:
								begin
									if (8'd153 == code)
									begin
										code <= 8'hf0;
										in_code <= bakcode;
									end
									else if (8'd153 == bakcode)
									begin
										bakcode <= 8'hf0;
										in_code <= 8'hf0;
									end
									E0 = 0;
								end
							default E0 = 0;
						endcase
					else if (data == 8'h12) shift = 0;
					else if (data == 8'hf0)
						begin
							code <= 8'hf0;
							bakcode <= 8'hf0;
						end
					else if (data == code)
						begin
							code <= 8'hf0;
							in_code <= bakcode;
						end
					else if (data == bakcode)
						begin
							bakcode <= 8'hf0;
							in_code <= 8'hf0;
						end
					
					state <= S0;
			end
				
			endcase
						
			nextdata_n <= 1'b1;
		end
		else nextdata_n<=1'b0;
			
	end
	
endmodule 