module I2C_Audio_Config( clk_i2c,
								 reset_n,
								 I2C_SCLK,
								 I2C_SDAT,
								 volumn);
parameter total_cmd = 9;

input wire [8:0]volumn;

input clk_i2c; //10k I2C clock
input reset_n;
output I2C_SCLK;
inout  I2C_SDAT;

reg [23:0] mi2c_data;
reg mi2c_go;
wire mi2c_end;
reg [1:0] mi2c_state; //state 0: stop, state 1: send next
										  //state 2: wait for finish, state 3: move index
wire [2:0] mi2c_ack;
wire [7:0] audio_addr;
reg [3:0] cmd_count;
reg [6:0] audio_reg [15:0]; //register to write
reg [8:0] audio_cmd [15:0]; //register content

initial
begin
   audio_reg[0]= 7'h0f; audio_cmd[0]=9'h0; //reset
   audio_reg[1]= 7'h06; audio_cmd[1]=9'h0; //Disable Power Down
   audio_reg[2]= 7'h08; audio_cmd[2]=9'h2; //Sampling Control
   audio_reg[3]= 7'h02; audio_cmd[3]=9'h60; //Left Volume
   audio_reg[4]= 7'h03; audio_cmd[4]=9'h60; //Right Volume
   audio_reg[5]= 7'h07; audio_cmd[5]=9'h1; //I2S format
   audio_reg[6]= 7'h09; audio_cmd[6]=9'h1; //Active
	audio_reg[7]= 7'h04; audio_cmd[7]=9'h16; //Analog path
   audio_reg[8]= 7'h05; audio_cmd[8]=9'h06; //Digital path
end

assign audio_addr={7'b0011010,1'b0}; //WM8731 addr, always write

I2C_Controller u0(.CLOCK(clk_i2c),
						.I2C_SCLK(I2C_SCLK),
						.I2C_SDAT(I2C_SDAT),
						.I2C_DATA(mi2c_data),
						.GO(mi2c_go),
						.END(mi2c_end),
						.ACK(mi2c_ack),
						.RESET_N(reset_n)
						);
	
	
always @ (posedge clk_i2c or negedge reset_n)
begin
		if(!reset_n)
		begin
				cmd_count <= 4'b0;
				mi2c_state<= 4'b0;
				mi2c_go   <= 1'b0;
		end
		else
		begin
				case(mi2c_state)
						2'd0: begin
								if (cmd_count == 4'b0)
										mi2c_state <= 2'd1;
						end
						2'd1: begin
								if (cmd_count == 4'd3 || cmd_count == 4'd4)
								begin
								mi2c_data <= {audio_addr, audio_reg[cmd_count], volumn};
								end
								else
								begin
								mi2c_data <= {audio_addr, audio_reg[cmd_count],
														  audio_cmd[cmd_count]};
								end
								mi2c_go   <= 1'b1;
								mi2c_state<= 2'd2;
						end
						2'd2: begin
								if (mi2c_end)
								begin
										mi2c_state <= 2'd3;
										mi2c_go	   <= 1'b0;
								end
						end
						2'd3: begin
								cmd_count <= cmd_count + 4'd1;
								if (cmd_count + 4'd1 < total_cmd)
										mi2c_state <= 2'd1; //start next
								else
										mi2c_state <= 2'd0;
						end
				endcase
		end
end

endmodule


