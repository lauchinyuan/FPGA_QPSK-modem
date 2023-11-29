module qpsk_demod
    #(parameter HEADER = 8'hcc)  //帧头
    (
        input wire          clk     ,
        input wire          rst_n   ,
        input wire  [27:0]  qpsk    ,
        
        output wire [39:0]  para_out
    );
    
    wire        clk_sam     ; 
    wire [7:0]  carry_sin   ;
    wire [7:0]  carry_cos   ;
    wire [35:0] demo_I      ;
    wire [35:0] demo_Q      ;
    wire [55:0] filtered_I  ;
    wire [55:0] filtered_Q  ;
    wire        sync_I      ;
    wire        sync_Q      ;
    wire        sync_flag   ;
    wire        sync_flag_d1; 
    wire        demo_ser_o  ;
    wire        header_flag ;
    wire        valid_flag  ;
    wire [57:0] phase_error ;
    wire [23:0] pd          ;  //costas环路滤波器输出
    
    
    //产生采样时钟
    sam_clk_gen sam_clk_gen_inst(
            .clk        (clk    ),  //50MHz
            .rst_n      (rst_n  ),

            .clk_o      (clk_sam)
        );
    
    //产生cos波形
    dds_demo_cos dds_demo_cos_inst (
        .aclk(clk_sam),                     // input wire aclk
        .aresetn(rst_n),                    // input wire aresetn
        .s_axis_phase_tvalid(1'b1),         // input wire s_axis_phase_tvalid
        .s_axis_phase_tdata(24'hffffff-pd),  // input wire [23 : 0] s_axis_phase_tdata,pd调相
        .m_axis_data_tvalid(),              // output wire m_axis_data_tvalid
        .m_axis_data_tdata(carry_cos),      // output wire [7 : 0] m_axis_data_tdata
        .m_axis_phase_tvalid(),             // output wire m_axis_phase_tvalid
        .m_axis_phase_tdata()               // output wire [23 : 0] m_axis_phase_tdata
    );
    
    
    //产生sin波形
    dds_demo_sin dds_demo_sin_inst (
        .aclk(clk_sam),                     // input wire aclk
        .aresetn(rst_n),                    // input wire aresetn
        .s_axis_phase_tvalid(1'b1),         // input wire s_axis_phase_tvalid
        .s_axis_phase_tdata(24'hffffff-pd),  // input wire [23 : 0] s_axis_phase_tdata,pd调相
        .m_axis_data_tvalid(),              // output wire m_axis_data_tvalid
        .m_axis_data_tdata(carry_sin),      // output wire [7 : 0] m_axis_data_tdata
        .m_axis_phase_tvalid(),             // output wire m_axis_phase_tvalid
        .m_axis_phase_tdata()               // output wire [23 : 0] m_axis_phase_tdata
    );
    
    

    
    //I路乘相干载波cos
    mul_demo mul_demo_I(
        .CLK(clk_sam),      // input wire CLK
        .A(qpsk),           // input wire [27 : 0] A
        .B(carry_cos),      // input wire [7 : 0] B
        .P(demo_I)          // output wire [35 : 0] P
    ); 

    //Q路乘相干载波sin
    mul_demo mul_demo_Q(
        .CLK(clk_sam),      // input wire CLK
        .A(qpsk),           // input wire [27 : 0] A
        .B(carry_sin),      // input wire [7 : 0] B
        .P(demo_Q)          // output wire [35 : 0] P
    );  
      
    
    //I路调制信号经过低通滤波
    demo_lowpass demo_lowpass_I (
        .aclk(clk_sam),                      // input wire aclk
        .s_axis_data_tvalid(1'b1),           // input wire s_axis_data_tvalid
        .s_axis_data_tready(),               // output wire s_axis_data_tready
        .s_axis_data_tdata({{4{demo_I[35]}}, demo_I}), //[39:0]
        .m_axis_data_tvalid(),              // output wire m_axis_data_tvalid
        .m_axis_data_tdata(filtered_I)      // output wire [55 : 0] m_axis_data_tdata
    );
    
    
    //Q路调制信号经过低通滤波
    demo_lowpass demo_lowpass_Q (
        .aclk(clk_sam),                     // input wire aclk
        .s_axis_data_tvalid(1'b1),          // input wire s_axis_data_tvalid
        .s_axis_data_tready(),              // output wire s_axis_data_tready
        .s_axis_data_tdata({{4{demo_Q[35]}}, demo_Q}), //[39:0]
        .m_axis_data_tvalid(),              // output wire m_axis_data_tvalid
        .m_axis_data_tdata(filtered_Q)      // output wire [55 : 0] m_axis_data_tdata
    );  
    
    //鉴相器
    phase_detector phase_detector_inst(
        .filtered_I     (filtered_I         ), //I路经过低通滤波后信号
        .filtered_Q     (filtered_Q         ), //Q路经过低通滤波后信号

        .phase_error    (phase_error        )  //输出的相位误差
    );
    
    //costas环路滤波器
    costas_loop_filter costas_loop_filter_inst
    (
        .clk             (clk_sam         ), //采样频率
        .rst_n           (rst_n           ),
        .pd_err          (phase_error     ), //由鉴相器输出的原始相位误差信号
        
        .pd              (pd              )  //滤波器输出, 用于调整dds相位偏移
    );
    
    
/*     LoopFilter loop_filter_inst(
       .clk(clk_sam),                         //500KHz
       .rst_n(rst_n),
       .phase_err(phase_error[57:4]),      //输入的相位误差
       
       .df(df)           //输出环路滤波器
    ); */
    
    
    //Gardner位同步，并进行抽样判决，输出判决后的两路信号
    gardner_sync gardner_sync_inst
    (
        .clk            (clk_sam            ),  //采样频率
        .rst_n          (rst_n              ),
        .data_in_I      (filtered_I[54:40]  ),  //截断处理,并将截断后数据加载到Gardner位同步模块
        .data_in_Q      (filtered_Q[54:40]  ),

        .sync_out_I     (sync_I             ),
        .sync_out_Q     (sync_Q             ),
        .sync_flag      (sync_flag          )   //最佳抽样判决时刻标志
    );
    
    //合并IQ两路
    iq_comb 
    #(.SAMPLE(100))   //每个码元的采样数
    iq_comb_inst
    (
        .clk            (clk_sam    ),
        .rst_n          (rst_n      ),
        .sync_I         (sync_I     ),
        .sync_Q         (sync_Q     ),
        .sync_flag_i    (sync_flag  ),   //从Gardner位同步器输入的同步标志
                         
        .demo_ser_o     (demo_ser_o ),
        .sync_flag_o    (sync_flag_d1)   //输出到后续模块的同步输出数据
    );

    //数据有效性检测，并输出最终的并行40bit结果
    data_valid 
    #(.HEADER(HEADER))  //帧头
    data_valid_inst
    (
        .clk            (clk_sam        ),  //采样频率
        .rst_n          (rst_n          ),
        .ser_i          (demo_ser_o     ),  //从iq_comb模块输入的串行数据
        .sync_flag      (sync_flag_d1   ),  //同步标志

        .header_flag    (header_flag    ),  //侦测到正确的帧头
        .valid_flag     (valid_flag     ),  //帧头和校验和都正确标志，代表有效数据
        .valid_data_o   (para_out       )   //将有效数据进行并行输出
    );
    
    

    
endmodule
