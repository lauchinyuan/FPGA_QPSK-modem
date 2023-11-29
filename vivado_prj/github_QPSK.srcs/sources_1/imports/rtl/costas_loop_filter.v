`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: lauchinyuan
// Email: lauchinyuan@yeah.net
// Create Date: 2023/11/05 11:13:01
// Module Name: costas_loop_filter
// Description: COSTAS环中的环路滤波器, 一阶IIR低通滤波器
// 系统函数H(z) = c1+{[c2*z^(-1)]/[1-z^(-1)]}
// 时域差分方程y(n)-y(n-1) = c1*x(n)+(c2-c1)*x(n-1) = c1*(x(n)-x(n-1))+c2*x(n-1)
//////////////////////////////////////////////////////////////////////////////////


module costas_loop_filter
(
        input wire              clk             ,
        input wire              rst_n           ,
        

        input wire [57:0]       pd_err          , 
        
        output wire[23:0]       pd                //滤波器输出, 与相位控制字位宽相同
);

    reg [57:0]  pd_err_d        ; //pd_err打一拍, 作为x(n-1)
    wire[57:0]  pd_err_sub      ; //x(n)-x(n-1)
    reg [23:0]  pd_sub          ; //y(n)-y(n-1)
    
    //滤波相位控制字输出寄存器, 位宽为24bit(相位控制字位宽)
    reg [23:0]  pd_reg          ; 
    
    //更新速度计数器, 依据该计数器的值选择不同的C1\C2参数组
    reg [15:0]   cnt_update     ;
    
    //cnt_update
    always@(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            cnt_update <= 'd0;
        end else if(cnt_update == 'd19999) begin //前2000个点使用较大的系数
            cnt_update <= cnt_update;
        end else begin
            cnt_update <= cnt_update + 'd1;
        end
    end

    //pd_err_d
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pd_err_d <= 'd0;
        end else begin
            pd_err_d <= pd_err;
        end
    end
    
    //滤波器输出
    //pd输出pd_reg结果
    assign pd = pd_reg;
    
    
    //pd_reg
    always@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            pd_reg <= 'd0;
        end else begin
            pd_reg <= pd_reg + pd_sub;  //y(n) = y(n-1)+[y(n)-y(n-1)]
        end
    end
    
    //x(n)-x(n-1)
    assign pd_err_sub = pd_err - pd_err_d; 

    //滤波得到y的增量y(n)-y(n-1), c1\c2较小是由于输入的相位误差位宽大, 小数精度很高, 相当于增益非常大
    //初始捕获状态下, 参数较大, 捕获时间更短
    //c1 = 2^(-35)
    //c2 = 2^(-38)
    
    //跟踪状态使用小参数, 使相位增量更平稳
    //c1 = 2^(-38)
    //c2 = 2^(-41)
    
    //y(n)-y(n-1)=c1*(x(n)-x(n-1))+c2*x(n-1)
    always@(*) begin
        if(cnt_update == 'd1999) begin //跟踪状态使用小参数
            pd_sub = {{3{pd_err_sub[57]}}, pd_err_sub[57:37]} + {{6{pd_err_d[57]}},pd_err_d[57:40]};
        end else begin //捕获状态使用大参数
            pd_sub = pd_err_sub[57:34] + {{3{pd_err_d[57]}},pd_err_d[57:37]};
        end
    end
    
    
endmodule