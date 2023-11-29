`timescale 1ns / 1ps
module tb_interpolate_filter();
    parameter DATALENTH = 500_000               ;  //500k个数据
    reg             clk                         ;
    reg             rst_n                       ;
    reg [14:0]      data_I [DATALENTH-1:0]      ;
    reg [14:0]      data_Q [DATALENTH-1:0]      ;
    reg [15:0]      uk                          ;
    reg [14:0]      data_in_I                   ;
    reg [14:0]      data_in_Q                   ;
        
    wire [19:0]     I_y                         ;
    wire [19:0]     Q_y                         ;
    integer         k                           ;
    
    
    initial begin
        clk = 1'b1      ;
        rst_n <= 1'b0   ;
        uk <= 16'b0100_0000_0000_0000; //uk设为0.5
        //载入由Matlab生成的数据
        $readmemb("C:/Users/Lau Chinyuan/Desktop/QPSK_CLK/testbench_data/dataI.txt",data_I);
        $readmemb("C:/Users/Lau Chinyuan/Desktop/QPSK_CLK/testbench_data/dataQ.txt",data_Q);
    #30
        rst_n <= 1'b1   ;
    #1600000 //模拟发送端和接收端之间的延时
        for(k=0;k<DATALENTH;k=k+1) begin
            #2000 //500kHz输入频率数据
            data_in_I <= data_I[k];
            data_in_Q <= data_Q[k];
        end
    
    end
    
    always #2000 clk = ~clk;  //500kHz时钟
    
    
    
    interpolate_filter interpolate_filter_inst
    (
        .clk            (clk        ),
        .rst_n          (rst_n      ),
        .data_in_I      (data_in_I  ),
        .data_in_Q      (data_in_Q  ),
        .uk             (uk         ),  //小数间隔，15bit小数位

        .I_y            (I_y        ),  //I路插值输出
        .Q_y            (Q_y        )   //Q路插值输出
    );
    
endmodule
