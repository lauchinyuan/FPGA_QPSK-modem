`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Description: 将判决后的IQ两路数据组合成串行数据输出
//输入的时钟频率为和采样率相同
//////////////////////////////////////////////////////////////////////////////////
module iq_comb
#(parameter SAMPLE = 100)
    (
        input wire          clk         ,  //500kHz
        input wire          rst_n       ,
        input wire          sync_I      ,
        input wire          sync_Q      ,
        input wire          sync_flag_i ,  //从Gardner位同步器输入的同步标志
        
        output wire         demo_ser_o  ,
        output wire         sync_flag_o    //输出到后续模块的同步输出数据
        //对于一组IQ数据需要两个sync_flag_o有效信号
    );
    
    // 判断串行输出的是I路还是Q路,0代表Q, 1代表I
    reg         iq_switch   ;
    wire        q2i_flag    ;
    reg         q2i_flag_d1 ;
    reg         sync_flag_i_d1;
    
    reg         sync_I_d    ;
    reg         sync_Q_d    ;
    
    
    //计算采样次数，计算到SAMPLE-1时从输出串行数据从Q通道转换到I通道
    reg [6:0]   sample_cnt  ;
    
    //sample_cnt
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            sample_cnt <= 7'd0;
        end else if((sample_cnt == SAMPLE - 1) && !iq_switch) begin
            sample_cnt <= 7'd0;
        end else if(sync_flag_i) begin
        //一组有效的IQ信号到来,清零重新计数
            sample_cnt <= 7'd0;
        end else if(!iq_switch) begin  //计算Q路数据输出的样本数
            sample_cnt <= sample_cnt + 7'd1;
        end else begin
            sample_cnt <= 7'd0;
        end
    end
    
    //iq_switch
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            iq_switch <= 1'b0;
        end else if(sync_flag_i) begin
        //一组有效的IQ信号到来,首先将通道交给Q路输出
            iq_switch <= 1'b0;
        end else if(q2i_flag) begin
        //从Q通道转换到I通道
            iq_switch <= 1'b1;
        end else begin
            iq_switch <= iq_switch;
        end
    end 
    
    //q2i_flag打一拍得到同步信号,这一同步信号与输出并行数据的I路数据的开头对齐
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            q2i_flag_d1 <= 1'b0;
        end else begin
            q2i_flag_d1 <= q2i_flag;
        end
    end
    
    //将输入的同步信号sync_flag_i打一拍得到同步信号sync_flag_i_d1
    //并将输出同步数据打一拍
    //使得sync_flag_o与输出数据的变化位置对齐
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            sync_flag_i_d1 <= 1'b0  ;
            sync_I_d <= 1'b0        ;
            sync_Q_d <= 1'b0        ;
        end else begin
            sync_flag_i_d1 <= sync_flag_i   ;
            sync_I_d <= sync_I              ;
            sync_Q_d <= sync_Q              ;
        end
    end
    
    //输出同步标志,与IQ两路的起始点对齐
    assign sync_flag_o = sync_flag_i_d1 | q2i_flag_d1;
    
    //q2i_flag
    //Q路数据以及输出SAMPLE个样本
    assign q2i_flag = ((sample_cnt == SAMPLE - 1) && !iq_switch)?1'b1: 1'b0;
    
    //依据iq_switch交替选择输出通道，输出数据比原先延迟一个时钟周期
    assign demo_ser_o = (iq_switch == 1'b1)? sync_I_d: sync_Q_d;
    
endmodule
