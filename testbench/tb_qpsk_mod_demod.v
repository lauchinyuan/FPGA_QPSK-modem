`timescale 1ns / 1ps
module tb_qpsk_mod_demod();
	reg			clk		;
	reg			rst_n	;
	reg	[39:0]	para_i	;
	
	wire [39:0]	para_out;
	
	initial begin
		clk = 1'b1;
		para_i <= 40'b1100_1100_0001_0111_0001_1000_0001_1001_0001_0100;
		rst_n <= 1'b0;
	#50
		rst_n <= 1'b1;
	end
	
	always #10 clk = ~clk; //50Mhz时钟
	qpsk_mod_demod qpsk_mod_demod_inst
	(
		.clk			(clk		),
		.rst_n			(rst_n		),
		.para_in		(para_i		),

		.para_out       (para_out   )
	);
endmodule
