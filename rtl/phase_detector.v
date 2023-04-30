`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Create Date: 2023/04/22 16:39:39
// Design Name: 
// Module Name: phase_detector
// Description: 载波同步鉴相器
// 
//////////////////////////////////////////////////////////////////////////////////

module phase_detector(
        input wire  [14:0]  filtered_I  , //I路经过低通滤波后信号
        input wire  [14:0]  filtered_Q  , //Q路经过低通滤波后信号
        
        output wire [15:0]  phase_error   //输出的相位误差
    );
    
    wire [14:0] inversed_I  ;   //取反的I路数据
    wire [14:0] inversed_Q  ;   //取反的Q路数据
    
    //依据另一路符号位确定的本通道的信号
    reg [14:0]  channel_I   ;   
    reg [14:0]  channel_Q   ;
    
    assign inversed_I = ~filtered_I + 15'd1;  
    assign inversed_Q = ~filtered_Q + 15'd1;
    
    //channel_Q
    always @ (*) begin
        if(filtered_I[14]) begin  //负数
            channel_Q = inversed_Q;
        end else begin
            channel_Q = filtered_Q;
        end
    end
    
    //channel_I
    //这里和Q路逻辑相反，使得原来的减法器变成了加法器
    always @ (*) begin
        if(filtered_Q[14]) begin  //负数
            channel_I = filtered_I;
        end else begin
            channel_I = inversed_I;
        end
    end
    
    assign phase_error = {channel_Q[14],channel_Q} + {channel_I[14],channel_I};
    
endmodule
