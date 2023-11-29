`timescale 1ns / 1ps
module tb_iq_comb();
    reg         clk         ;
    reg         rst_n       ;
    reg         sync_I      ;
    reg         sync_Q      ;
    reg         sync_flag_i ;  
    
    wire        demo_ser_o  ;
    wire        sync_flag_o ;

    initial begin
        clk = 1'b1;
        rst_n <= 1'b0;
        sync_flag_i <= 1'b0;
        sync_I <= {$random} % 2;  //产生0-1随机数
        sync_Q <= {$random} % 2;    
    #2000
        rst_n <= 1'b1;
        sync_flag_i <= 1'b1;
        sync_I <= 1'b1;  //第一组IQ数据
        sync_Q <= 1'b0; 
    #2000 //sync_flag_i信号在本案例中一次维持1个时钟周期
        sync_flag_i <= 1'b0;
    #440000
        sync_flag_i <= 1'b1;
        sync_I <= 1'b1;  //第二组IQ数据
        sync_Q <= 1'b0;
    #2000 //sync_flag_i信号在本案例中一次维持1个时钟周期
        sync_flag_i <= 1'b0;
    #440000
        sync_flag_i <= 1'b1;
        sync_I <= {$random} % 2;  //第三组IQ数据
        sync_Q <= {$random} % 2;
    #2000 //sync_flag_i信号在本案例中一次维持1个时钟周期
        sync_flag_i <= 1'b0;
    #440000
        sync_flag_i <= 1'b1;
        sync_I <= {$random} % 2;  //第四组IQ数据
        sync_Q <= {$random} % 2;
    #2000 //sync_flag_i信号在本案例中一次维持1个时钟周期
        sync_flag_i <= 1'b0;
    #440000
        sync_flag_i <= 1'b1;
        sync_I <= {$random} % 2;  //第五组IQ数据
        sync_Q <= {$random} % 2;
    #2000 //sync_flag_i信号在本案例中一次维持1个时钟周期
        sync_flag_i <= 1'b0;
    end
    
    always #1000 clk = ~clk; //500kHz时钟

    iq_comb 
    #(.SAMPLE(100))
    iq_comb_inst
    (
        .clk            (clk        ),
        .rst_n          (rst_n      ),
        .sync_I         (sync_I     ),
        .sync_Q         (sync_Q     ),
        .sync_flag_i    (sync_flag_i),  //从Gardner位同步器输入的同步标志

        .demo_ser_o     (demo_ser_o ),
        .sync_flag_o    (sync_flag_o)   //输出到后续模块的同步输出数据
    );
    
endmodule
