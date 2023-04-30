`timescale 1ns / 1ps
module tb_clk_gen();

    reg         clk         ;
    reg         rst_n       ;
    
    wire    [7:0]     s_dec ;
    wire    [7:0]     m_dec ;
    wire    [7:0]     h_dec ;
    
    
    initial begin
        clk = 1'b1;
        rst_n <= 1'b0;
        
        #300
        rst_n <= 1'b1;
    end

    always #10 clk = ~clk;  //50MegHz时钟



    clk_gen
    #(.CNT_MAX(26'd49)) //模块定义的CNT_MAX为26'd49_999_999,1s完成一次循环
    //modulesim测试时改为49,速度增大1Meg，相当于1ms时间秒值就会更新
    clk_gen_inst
    (
        .clk        (clk    ),
        .rst_n      (rst_n  ),

        .s_dec      (s_dec  ),
        .m_dec      (m_dec  ),
        .h_dec      (h_dec  )
        );
endmodule
