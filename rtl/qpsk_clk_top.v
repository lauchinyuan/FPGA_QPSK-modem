`timescale 1ns / 1ps
//顶层模块,产生时钟数据,并通过QPSK调制解调器进行发送接收
//这一例子里QPSK调制解调在同一个FPGA设备上实现
module qpsk_clk_top
#(parameter HEADER = 8'hcc,   //帧头
            CNT_MAX = 26'd49_999_999) //测试速度,正常情况下设置为26'd49_999_999时每1s更新一次数据
(
    input wire          clk         ,  //50MHz
    input wire          rst_n       ,
    
    output wire [5:0]   sel         ,
    output wire [7:0]   dig         
);
    wire [27:0]         qpsk    ;
    wire [7:0]          s_dec   ;  //秒数据
    wire [7:0]          m_dec   ;  //分数据
    wire [7:0]          h_dec   ;  //秒数据
    wire [39:0]         para_dat;
    wire [39:0]         para_out;   //输出数据,包含时分秒


    
    
    //产生时分秒数据
    clk_gen 
    #(.CNT_MAX(CNT_MAX))  
    clk_gen_inst
    (
        .clk        (clk    ),  //50Mhz时钟
        .rst_n      (rst_n  ),

        .s_dec      (s_dec  ),
        .m_dec      (m_dec  ),
        .h_dec      (h_dec  )   
    );
    
    //将数据加上数据帧头和校验和，形成40bit数据
    data_gen
    #(.HEADER(HEADER))  //帧头
    data_gen_inst
    (
        .dec_s  (s_dec  ),
        .dec_m  (m_dec  ),
        .dec_h  (h_dec  ),

        .para_o (para_dat)
    );
    
    
    //调制
    qpsk_mod qpsk_mod_inst
    (
        .clk        (clk        ),
        .rst_n      (rst_n      ),
        .para_in    (para_dat   ),

        .qpsk       (qpsk       )
    );
    
    //解调
    qpsk_demod 
    #(.HEADER(HEADER))  //帧头    
    qpsk_demod_inst
    (
        .clk        (clk        ),
        .rst_n      (rst_n      ),
        .qpsk       (qpsk       ),  //经过仿真确认高位没有使用到, 定点小数精度24bit

        .para_out   (para_out   )   //解调后的并行数据输出
    );
    
    //将解调后的时间数据进行数码管显示
    time_display time_display
    (
        .clk        (clk    ),
        .rst_n      (rst_n  ),
        .dat_i      (para_out),

        .sel        (sel    ),  //数码管选择信号
        .dig        (dig    )   //数码管数据
    );
endmodule
