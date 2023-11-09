`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 2023/04/22 16:39:39
// Design Name: 
// Module Name: phase_detector
// Description: 载波同步鉴相器
// 
//////////////////////////////////////////////////////////////////////////////////

module phase_detector(
        input wire  [55:0]  filtered_I  , //I路经过低通滤波后信号
        input wire  [55:0]  filtered_Q  , //Q路经过低通滤波后信号
        
        output wire [57:0]  phase_error   //输出的相位误差
    );
    
    //由于n位二进制有符号数(补码)的表示范围为(-2^(n-1)-2^(n)), 并不关于0对称, 则直接取反会出现溢出情况
    //例如:3bit有符号数的最大值为3'b011 = 3'd3, 最小值为3'b100 = -(3'd4), 则无法直接通过按位取反加一得到-4的相反数
    //解决方法, 扩展1bit, 使用4bit无符号数即可表达-4
    wire [56:0] ext_I       ;   //filtered_I扩展1bit符号位
    wire [56:0] ext_Q       ;   //filtered_Q扩展1bit符号位
    
    
    wire [56:0] inversed_I  ;   //取反的I路数据
    wire [56:0] inversed_Q  ;   //取反的Q路数据
    
    //依据另一路符号位确定的本通道的信号
    reg [56:0]  channel_I   ;   
    reg [56:0]  channel_Q   ;
    
    assign ext_I = {filtered_I[55], filtered_I};
    assign ext_Q = {filtered_Q[55], filtered_Q};
    
    assign inversed_I = ~ext_I + 'd1;  
    assign inversed_Q = ~ext_Q + 'd1;
    
    //channel_Q
    always @ (*) begin
        if(filtered_I[55]) begin  //负数
            channel_Q = inversed_Q;
        end else begin
            channel_Q = ext_Q;
        end
    end
    
    //channel_I
    //这里和Q路逻辑相反，使得原来的减法器变成了加法器
    always @ (*) begin
        if(filtered_Q[55]) begin  //负数
            channel_I = ext_I;
        end else begin
            channel_I = inversed_I;
        end
    end
    
    assign phase_error = {channel_Q[56],channel_Q} + {channel_I[56],channel_I};
    
endmodule
