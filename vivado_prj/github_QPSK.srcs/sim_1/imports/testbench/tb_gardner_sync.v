`timescale 1ns / 1ps
module tb_gardner_sync();
    parameter LEN = 400000; //一共400k个数据(40*100*100)
    
    reg         clk         ;
    reg         rst_n       ;
    reg [14:0]  data_in_I   ;   
    reg [14:0]  data_in_Q   ;
    wire        sync_out_I  ;
    wire        sync_out_Q  ;
    wire        sync_flag   ;
    
    reg [14:0]  data_I [LEN-1:0];
    reg [14:0]  data_Q [LEN-1:0];
    
    integer i;

    initial begin
        clk = 1'b1;
        rst_n <= 1'b0;
        
        //将Matlab数据写入寄存器
        $readmemb("C:/Users/Lau Chinyuan/Desktop/QPSK_CLK/testbench_data/dataI.txt",data_I);
        $readmemb("C:/Users/Lau Chinyuan/Desktop/QPSK_CLK/testbench_data/dataQ.txt",data_Q);
    #30
        rst_n <= 1'b1;
    #160000  //第一次输入数据
        for(i=0;i<LEN;i=i+1) begin
            #2000  //500kHz
            data_in_I <= data_I[i];
            data_in_Q <= data_Q[i];
        end
        
    #181434467 //延时后再次输入数据，模拟接收端和发送端的传播时延
    //测试Gardner环是否具有抽样判决时刻调整能力
        for(i=0;i<LEN;i=i+1) begin
            #2000  //500kHz
            data_in_I <= data_I[LEN - 1 - i];
            data_in_Q <= data_Q[LEN - 1 - i];
        end
    end
    
    always #1000 clk = ~clk;  //500kHz时钟

    gardner_sync gardner_sync_inst
    (
        .clk            (clk        ),  //500kHz
        .rst_n          (rst_n      ),
        .data_in_I      (data_in_I  ),
        .data_in_Q      (data_in_Q  ),

        .sync_out_I     (sync_out_I ),
        .sync_out_Q     (sync_out_Q ),
        .sync_flag      (sync_flag  )   //最佳抽样判决时刻标志
    );

endmodule
