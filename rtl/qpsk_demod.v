module qpsk_demod
	#(parameter HEADER = 8'hcc)  //帧头
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
	wire		sync_I		;
	wire		sync_Q		;
	wire		sync_flag	;
	wire		sync_flag_d1;
	reg	 [7:0]	sample_cnt	;  
	wire		demo_ser_o	;
	wire 		header_flag	;
	wire 		valid_flag	;

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
	
	
	//Gardner位同步，并进行抽样判决，输出判决后的两路信号
	gardner_sync gardner_sync_inst
	(
		.clk			(clk_500k			),  //500kHz
		.rst_n			(rst_n				),
		.data_in_I		(filtered_I[42:28]	),  //截断处理,并将截断后数据加载到Gardner位同步模块
		.data_in_Q		(filtered_Q[42:28]	),

		.sync_out_I		(sync_I				),
		.sync_out_Q		(sync_Q				),
		.sync_flag	   	(sync_flag	   		)	//最佳抽样判决时刻标志
	);
	
	//合并IQ两路
	iq_comb 
	#(.SAMPLE(100))   //每个码元的采样数
	iq_comb_inst
	(
		.clk			(clk_500k	),
		.rst_n			(rst_n		),
		.sync_I			(sync_I		),
		.sync_Q			(sync_Q		),
		.sync_flag_i	(sync_flag	),  //从Gardner位同步器输入的同步标志
                         
		.demo_ser_o		(demo_ser_o	),
		.sync_flag_o	(sync_flag_d1)   //输出到后续模块的同步输出数据
    );

	//数据有效性检测，并输出最终的并行40bit结果
	data_valid 
	#(.HEADER(HEADER))  //帧头
	data_valid_inst
	(
		.clk			(clk_500k		),  //500KHz
		.rst_n			(rst_n			),
		.ser_i			(demo_ser_o		),  //从iq_comb模块输入的串行数据
		.sync_flag		(sync_flag_d1	),  //同步标志

		.header_flag	(header_flag	),  //侦测到正确的帧头
		.valid_flag		(valid_flag		),  //帧头和校验和都正确标志，代表有效数据
		.valid_data_o   (para_out   	)	//将有效数据进行并行输出
	);
	
	
	

	
endmodule
