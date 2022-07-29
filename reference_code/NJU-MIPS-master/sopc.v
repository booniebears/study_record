`include "macro.v"
module sopc(
    input wire CLOCK_50,
    input wire rst,
	 output wire [7:0] vga_q,
	 input wire [11:0] vga_rdaddress,
	 input wire [7:0] input_ascii,
	 input wire input_en,
	 output reg audio_en
);

	 //mem module from cpu
	 wire mem_we_i;
    wire[`REGBUS] mem_addr_i;
    wire[`REGBUS] mem_data_i;
    wire[`REGBUS] mem_data_o;
    wire[3:0] mem_sel_i;  
    wire mem_ce_i;  
	 
	 //inst rom
	 wire [`REGBUS] inst_data_o;
	 wire[`INSTADDRBUS] inst_addr;
    wire[`INSTBUS] inst;
	 wire[`INSTBUS] inst_rom;
	 wire[`INSTBUS] inst_ram;
    wire rom_ce;
	 //special inst ram
	 wire [`REGBUS] special_data_o;
	 wire special_inst = (inst_addr >= `MMIO_ROM_SPECIAL_START) && (inst_addr < `MMIO_ROM_SPECIAL_END);
	 assign inst = (special_inst)?inst_ram:inst_rom;
	 
	 //video ram
	 wire [`REGBUS] video_data_o;
	 //keyboard
	 reg [`REGBUS] kb_ascii;
	 reg [`REGBUS] kb_en;
	 
	 //mmio
	 wire mmio_GRAM = (mem_addr_i >= `MMIO_GRAM_START) && (mem_addr_i < `MMIO_GRAM_END);
	 wire mmio_ROM = (mem_addr_i >= `MMIO_ROM_START) && (mem_addr_i < `MMIO_ROM_END);
	 wire mmio_SPECIAL = (mem_addr_i >= `MMIO_ROM_SPECIAL_START) && (mem_addr_i < `MMIO_ROM_SPECIAL_END);
	 wire mmio_KEY = (mem_addr_i == `MMIO_KEY);
	 wire mmio_KEY_EN = (mem_addr_i == `MMIO_KEY_EN);
	 wire mmio_AUDIO = (mem_addr_i == `MMIO_AUDIO);
	 wire no_mmio = (mem_addr_i >= `MMIO_NO);
	 wire [`REGBUS] ram_data_return = (mmio_GRAM)?
														video_data_o:(mmio_ROM)?
														inst_data_o:(mmio_KEY)?
														{4{input_ascii}}:(mmio_KEY_EN)?
														{4{7'b0,input_en}}:(mmio_SPECIAL)?
														special_data_o:(no_mmio)?
														mem_data_o:`ZEROWORD;
	 
	 wire clk_12P5M;
	 clkgen #(12500000)clk12P5M(
		  .clkin(CLOCK_50),
		  .rst(1'b0),
		  .clken(1'b1),
		  .clkout(clk_12P5M)
    );
	 
	 always @(clk_12P5M)
	 begin
		if (mmio_AUDIO && mem_we_i && mem_ce_i) begin
			audio_en <= mem_data_i[0];
		end
	 end
	 
	 cpu mips0(
        .clk(clk_12P5M), .rst(rst),
        .rom_addr_o(inst_addr), 
		  .rom_data_i(inst),
        .rom_ce_o(rom_ce),
		  
		  .ram_we_o(mem_we_i),
		  .ram_addr_o(mem_addr_i),
		  .ram_sel_o(mem_sel_i),
		  .ram_data_o(mem_data_i),
		  .ram_data_i(ram_data_return),
		  .ram_ce_o(mem_ce_i)
    );
	 
	 inst_ram inst_ram0(
		 .clk(~clk_12P5M),
		 .rom_ce(rom_ce),
		 .ce(mem_ce_i),

		 .inst_addr(inst_addr-`MMIO_ROM_SPECIAL_START),
		 .inst(inst_ram),
		 
		 .we(mmio_SPECIAL && mem_we_i),
		 .addr(mem_addr_i - `MMIO_ROM_SPECIAL_START),
		 .data_i(mem_data_i),
		 .data_o(special_data_o)
	 );
	 
	 inst_rom inst_rom0(
		  .clk(CLOCK_50),
        .ce(rom_ce),
		  
        .inst_addr(inst_addr), 
		  .inst(inst_rom),
		  
		  .addr(mem_addr_i),
		  .sel(mem_sel_i),
		  .data_o(inst_data_o)
    );

	 data_ram data_ram0(
		.clk(CLOCK_50),
		.ce(mem_ce_i),
		
		.addr(mem_addr_i - `MMIO_NO),
		.sel(mem_sel_i),
		.we(no_mmio && mem_we_i),
		.data_i(mem_data_i),
		.data_o(mem_data_o)
	 );
	
	 video_ram video_ram0(
		 .clk(CLOCK_50),
		 .ce(mem_ce_i),
		 
		 .addr(mem_addr_i - `MMIO_GRAM_START),
		 .sel(mem_sel_i),
		 .we(mmio_GRAM && mem_we_i),
		 .data_i(mem_data_i),
		 .data_o(video_data_o),
		 
		 .vga_rdaddress(vga_rdaddress),
		 .vga_q(vga_q)
	 );


endmodule
