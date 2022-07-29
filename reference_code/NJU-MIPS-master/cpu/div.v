`include "macro.v"

module div(
	input	wire clk,
	input wire rst,
	
	input wire         signed_div_i,
	input wire[31:0]   opdata1_i,
	input wire[31:0]	 opdata2_i,
	input wire         start_i,
	input wire         annul_i,
	
	output reg[63:0]   result_o,
	output reg			 ready_o
);

	wire[32:0] div_temp;
	reg[5:0] cnt;
	reg[64:0] dividend;
	reg[1:0] state;
	reg[31:0] divisor;	 
	reg[31:0] temp_op1;
	reg[31:0] temp_op2;
	
	assign div_temp = {1'b0,dividend[63:32]} - {1'b0,divisor};

	always @ (posedge clk) begin
		if (rst == `RSTENABLE) begin
			state <= `DIVFREE;
			ready_o <= `DIVRESULTNOTREADY;
			result_o <= {`ZEROWORD, `ZEROWORD};
		end else begin
		  case (state)
		  	`DIVFREE: begin
		  		if(start_i == `DIVSTART && annul_i == 1'b0) begin
		  			if(opdata2_i == `ZEROWORD) begin
		  				state <= `DIVBYZERO;
		  			end else begin
		  				state <= `DIVON;
		  				cnt <= 6'b000000;
		  				if(signed_div_i == 1'b1 && opdata1_i[31] == 1'b1 ) begin
		  					temp_op1 = ~opdata1_i + 1;
		  				end else begin
		  					temp_op1 = opdata1_i;
		  				end
		  				if(signed_div_i == 1'b1 && opdata2_i[31] == 1'b1 ) begin
		  					temp_op2 = ~opdata2_i + 1;
		  				end else begin
		  					temp_op2 = opdata2_i;
		  				end
		  				dividend <= {`ZEROWORD, `ZEROWORD};
						dividend[32:1] <= temp_op1;
						divisor <= temp_op2;
             end
          end else begin
						ready_o <= `DIVRESULTNOTREADY;
						result_o <= {`ZEROWORD, `ZEROWORD};
				  end          	
		  	end
			
		  	`DIVBYZERO:	begin
         	dividend <= {`ZEROWORD,`ZEROWORD};
				state <= `DIVEND;		 		
		  	end
			
		  	`DIVON: begin
		  		if(annul_i == 1'b0) begin
					if(cnt != 6'b100000) begin
						if(div_temp[32] == 1'b1) begin
							dividend <= {dividend[63:0] , 1'b0};
						end else begin
							dividend <= {div_temp[31:0] , dividend[31:0] , 1'b1};
						end
						cnt <= cnt + 6'b1;
					end else begin
						if((signed_div_i == 1'b1) && ((opdata1_i[31] ^ opdata2_i[31]) == 1'b1)) begin
							dividend[31:0] <= (~dividend[31:0] + 1);
						end
						if((signed_div_i == 1'b1) && ((opdata1_i[31] ^ dividend[64]) == 1'b1)) begin              
							dividend[64:33] <= (~dividend[64:33] + 1);
						end
						state <= `DIVEND;
						cnt <= 6'b000000;            	
					end
		  		end else begin
		  			state <= `DIVFREE;
		  		end	
		  	end
			
		  	`DIVEND: begin
				result_o <= {dividend[64:33], dividend[31:0]};  
				ready_o <= `DIVRESULTREADY;
            if(start_i == `DIVSTOP) begin
					state <= `DIVFREE;
					ready_o <= `DIVRESULTNOTREADY;
					result_o <= {`ZEROWORD, `ZEROWORD};       	
            end		  	
		  	end
		  endcase
		end
	end

endmodule 