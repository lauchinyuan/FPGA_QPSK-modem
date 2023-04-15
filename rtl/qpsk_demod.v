module qpsk_demod
	#(parameter SAMPLE = 100) //未分流时，每一个bit采样数
	(
		input wire			clk		,
		input wire 			rst_n	,
		input wire 	[21:0] 	qpsk	,
		
		output wire [39:0]	para_out
    );
	
	wire 		clk_500k	; 
	wire [7:0] 	carry_sin	;
	wire [7:0] 	carry_cos	;
	wire [29:0]	demo_I		;
	wire [29:0]	demo_Q		;
	wire [47:0]	filtered_I	;
	wire [47:0]	filtered_Q	;	
	wire		sample_d_I	;
	wire		sample_d_Q	;
	reg	 [7:0]	sample_cnt	;  
	wire		demo_ser_o	;
	
	
	wire [14:0]	filtered_I_cut	;
	wire [14:0]	filtered_Q_cut	;	

	//产生500kHz采样时钟
	sam_clk_gen sam_clk_gen_inst(
			.clk		(clk	),  //50MHz
			.rst_n		(rst_n	),

			.clk_o	    (clk_500k)
		);
	
	//产生sin波形
	dds_sin dds_sin_demo_inst(
		.aclk(clk_500k),                                // input wire aclk
		.aresetn(rst_n),                          // input wire aresetn
		.m_axis_data_tvalid(),    // output wire m_axis_data_tvalid
		.m_axis_data_tdata(carry_sin),      // output wire [7 : 0] m_axis_data_tdata
		.m_axis_phase_tvalid(),  // output wire m_axis_phase_tvalid
		.m_axis_phase_tdata()    // output wire [23 : 0] m_axis_phase_tdata
	);
	
	//产生cos波形
	dds_cos dds_cos_demo_inst(
		.aclk(clk_500k),                                // input wire aclk
		.aresetn(rst_n),                          // input wire aresetn
		.m_axis_data_tvalid(),    // output wire m_axis_data_tvalid
		.m_axis_data_tdata(carry_cos),      // output wire [7 : 0] m_axis_data_tdata
		.m_axis_phase_tvalid(),  // output wire m_axis_phase_tvalid
		.m_axis_phase_tdata()    // output wire [23 : 0] m_axis_phase_tdata
	);
	
	//I路乘相干载波cos
	mul_demo mul_demo_I(
		.CLK(clk_500k),  // input wire CLK
		.A(qpsk),      // input wire [21 : 0] A
		.B(carry_cos),      // input wire [7 : 0] B
		.P(demo_I)      // output wire [29 : 0] P
	);	

	//Q路乘相干载波sin
	mul_demo mul_demo_Q(
		.CLK(clk_500k),  // input wire CLK
		.A(qpsk),      // input wire [21 : 0] A
		.B(carry_sin),      // input wire [7 : 0] B
		.P(demo_Q)      // output wire [29 : 0] P
	);	
	
	//I路调制信号经过低通滤波
	demo_lowpass demo_lowpass_I (
		.aclk(clk_500k),            // input wire aclk
		.s_axis_data_tvalid(1'b1),  // input wire s_axis_data_tvalid
		.s_axis_data_tready(),  // output wire s_axis_data_tready
		.s_axis_data_tdata(demo_I[23:0]),    // 经过仿真确认demo_I高位没有使用
		.m_axis_data_tvalid(),  // output wire m_axis_data_tvalid
		.m_axis_data_tdata(filtered_I)    // output wire [47 : 0] m_axis_data_tdata
	);
	
	//Q路调制信号经过低通滤波
	demo_lowpass demo_lowpass_Q (
		.aclk(clk_500k),            // input wire aclk
		.s_axis_data_tvalid(1'b1),  // input wire s_axis_data_tvalid
		.s_axis_data_tready(),  // output wire s_axis_data_tready
		.s_axis_data_tdata(demo_Q[23:0]),    // input wire [23 : 0] s_axis_data_tdata
		.m_axis_data_tvalid(),  // output wire m_axis_data_tvalid
		.m_axis_data_tdata(filtered_Q)    // output wire [47 : 0] m_axis_data_tdata
	);	
	
	//sample_cnt
	//用于判断每个bit的抽样时间
	//由于分为IQ两路后相当于采样个数为2*SAMPLE
	//故在sample_cnt == (SAMPLE - 1)时判决，即为中间时刻
	always @ (posedge clk_500k or negedge rst_n) begin
		if(rst_n == 1'b0) begin
			sample_cnt <= 8'd0;
		end else if(sample_cnt == SAMPLE - 1) begin
			sample_cnt <= 8'd0;
		end else begin
			sample_cnt <= sample_cnt + 8'd1;
		end
	end
	
	//抽样判决，判决门限为0,判决时刻为sample_cnt == (SAMPLE - 1)时
	//所以判断有符号数的符号位即可
	assign sample_d_I = (sample_cnt == (SAMPLE - 1))?(~filtered_I[47]):sample_d_I;
	assign sample_d_Q = (sample_cnt == (SAMPLE - 1))?(~filtered_Q[47]):sample_d_Q;
	
	//合并IQ两路
	iq_comb 
	#(.SAMPLE(SAMPLE)) //未分流时，每一个bit采样数
	iq_comb_inst
	(
		.clk			(clk_500k	),
		.rst_n			(rst_n		),
		.sample_d_I		(sample_d_I	),
		.sample_d_Q		(sample_d_Q	),

		.demo_ser_o	    (demo_ser_o	)
    );	
	
	//串并转换
	ser2para
	#(.SAMPLE(100)) //每一个bit采样样本数
	ser2para_inst
	(
		.clk		(clk_500k),
		.rst_n		(rst_n	),
		.ser_i		(demo_ser_o),
                     
		.para_o     (para_out )
    );
	
	
	//截断处理
	assign filtered_I_cut = filtered_I[42:28];
	assign filtered_Q_cut = filtered_Q[42:28];
	
	

	
endmodule
