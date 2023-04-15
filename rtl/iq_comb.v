`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 将判决后的IQ两路数据组合成串行数据输出
//输入的时钟频率为和采样率相同
//////////////////////////////////////////////////////////////////////////////////
module iq_comb
	#(parameter SAMPLE = 100) //未分流时，每一个bit采样数
	(
		input wire			clk			,
		input wire 			rst_n		,
		input wire 			sample_d_I	,
		input wire 			sample_d_Q	,
		
		output wire			demo_ser_o
    );
	
/* 	reg 		clk_500k	; 
	reg [5:0] 	cnt_500k	; */
	
	// 判断串行输出的是I路还是Q路,0代表Q, 1代表I
	reg 		iq_switch	; 
	reg [7:0]	sample_cnt	;
	
	
	//计数器，每SAMPLE个周期变换一个通道
	//sample_cnt
	always @ (posedge clk or negedge rst_n) begin
		if(rst_n == 1'b0) begin
			sample_cnt <= 8'd0;
		end else if(sample_cnt == SAMPLE - 1) begin
			sample_cnt <= 8'd0;
		end else begin
			sample_cnt <= sample_cnt + 8'd1;
		end
	end
	
	//iq_switch
	always @ (posedge clk or negedge rst_n) begin
		if(rst_n == 1'b0) begin
			iq_switch <= 1'b0;
		end else if(sample_cnt == SAMPLE - 2) begin
			iq_switch <= ~iq_switch;
		end else begin
			iq_switch <= iq_switch;
		end
	end	
	
	assign demo_ser_o = (iq_switch)? sample_d_I: sample_d_Q;
	
endmodule
