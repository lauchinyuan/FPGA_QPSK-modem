//NCO模块，产生strobe信号和小数间隔
module nco
(
    input wire          clk         ,
    input wire          rst_n       ,
    input wire [15:0]   wn          ,  //环路滤波器输出的w(n)，低15bit为小数位
    
    output reg          strobe_flag ,  //nco输出的溢出信号，代表有效插值时刻
    output reg [15:0]   uk             //输出到插值滤波器的小数间隔,低15bit为小数位
);
    reg [16:0]   nco_reg_eta        ;  //nco寄存器η
    wire         eta_overflow       ;  //nco寄存器η溢出标志
    wire[16:0]   eta_temp           ;  //nco寄存器η的中间计算数据，可能出现负值，出现负值需要进行mod1操作来更新nco寄存器η

    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            nco_reg_eta <= 17'b0_0110_0000_0000_0000    ;   //nco寄存器初始值设置为0.75
            uk <= 16'b0100_0000_0000_0000               ;   //分数间隔初始值设置为0.5
            strobe_flag <= 1'b0;
        end else if(eta_overflow) begin //nco溢出
            strobe_flag <= 1'b1;
            // η(mk+1) = η(mk) - wn + 1
            //通过mod1操作，更新nco寄存器
            nco_reg_eta <= eta_temp + 17'b0_1000_0000_0000_0000;
            
            //计算小数间隔
            //μk≈2η(mk) 
            uk <= {nco_reg_eta[15:0],1'b0};  
        end else begin
            strobe_flag <= 1'b0;
            nco_reg_eta <= eta_temp;  //nco寄存器每个时钟周期递减wn
            uk <= uk;
        end
    end
    
    assign eta_temp = nco_reg_eta - {wn[15],wn};
    assign eta_overflow = eta_temp[16];  //符号位为1代表出现负值，nco溢出
    

endmodule