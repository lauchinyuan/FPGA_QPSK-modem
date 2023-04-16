`timescale 1ns / 1ps
module tb_qpsk_clk_top();
	reg			clk		;
	reg			rst_n	;
	wire [39:0]	para_out;
	
	initial begin
		clk = 1'b1;
		rst_n <= 1'b0;
	#30
		rst_n <= 1'b1;
	end
	
	always #10 clk = ~clk;
	
	qpsk_clk_top 
	#(.HEADER(8'hcc))  //帧头
	qpsk_clk_top_inst
	(
		.clk			(clk		),  //50MHz
		.rst_n			(rst_n		),

		.para_out		(para_out	)	//输出数据,包含时分秒
	);
endmodule
