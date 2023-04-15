//////////////////////////////////////////////////////////////////////////////////
// Dependencies: 生成40bit数据帧，并行输出
//////////////////////////////////////////////////////////////////////////////////
module data_gen
(
	input wire [7:0] 	dec_s	,
	input wire [7:0]	dec_m	,
	input wire [7:0] 	dec_h	,
	
	output wire [39:0] 	para_o	
);

	wire [7:0]	valid	; //校验和
	
	assign valid = 8'hff + dec_s + dec_m + dec_h; //计算校验和
	assign para_o = {8'hff, dec_h, dec_m, dec_s, valid};

endmodule
