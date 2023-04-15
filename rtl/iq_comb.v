`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 将判决后的IQ两路数据组合成串行数据输出
//输入的时钟频率为和采样率相同
//////////////////////////////////////////////////////////////////////////////////
module iq_comb
	(
		input wire			clk			,
		input wire 			rst_n		,
		input wire 			sync_I		,
		input wire 			sync_Q		,
		input wire 			sync_flag_i	,  //从Gardner位同步器输入的同步标志
		
		output wire			demo_ser_o	,
		output reg	 		sync_flag_o	   //输出到后续模块的同步输出数据
    );
	
	// 判断串行输出的是I路还是Q路,0代表Q, 1代表I
	reg 		iq_switch	;
	reg			sync_I_d	;
	reg			sync_Q_d	;
	
	//iq_switch
	always @ (posedge clk or negedge rst_n) begin
		if(rst_n == 1'b0) begin
			iq_switch <= 1'b0;
		end else if(sync_flag_i) begin
			iq_switch <= ~iq_switch;
		end else begin
			iq_switch <= iq_switch;
		end
	end	
	
	//将输入的同步信号sync_flag_i打一拍得到输出的同步信号sync_flag_o
	//并将输入同步数据和输出同步数据都打一拍
	//使得sync_flag_o与输出数据的变化位置对齐
	always @ (posedge clk or negedge rst_n) begin
		if(rst_n == 1'b0) begin
			sync_flag_o <= 1'b0	;
			sync_I_d <= 1'b0	;
			sync_Q_d <= 1'b0	;
		end else begin
			sync_flag_o <= sync_flag_i	;
			sync_I_d <= sync_I			;
			sync_Q_d <= sync_Q			;
		end
	end
	
	//依据iq_switch交替选择输出通道，输出数据比原先延迟一个时钟周期
	assign demo_ser_o = (iq_switch)? sync_I_d: sync_Q_d;
	
endmodule
