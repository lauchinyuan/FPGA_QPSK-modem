//利用gardner算法计算定时误差,并通过环路滤波器得到小数间隔
//同时得出最佳判决点的两路输出数据
module gardner_ted
(
    input wire          clk             ,  //500kHz
    input wire          rst_n           ,
    input wire          strobe_flag     ,  //有效插值标志
    input wire [19:0]   interpolate_I   ,  //从插值滤波器来的I路数据
    input wire [19:0]   interpolate_Q   ,  //从插值滤波器来的Q路数据
    
    output reg          sync_out_I      ,  //判决后的I路数据
    output reg          sync_out_Q      ,  //判决后的Q路数据
    output reg          sync_flag       ,  //同步标志，代表最佳判决点已到来,与输出的判决数据对齐
    output reg [15:0]   wn                 //通过环路滤波器后误差数据
);

    reg [21:0]  error               ; //gardner算法计算出的时间误差
    //用于误差数据缓存
    reg [21:0]  error_d1            ;
    
    //寄存strobe_flag的次数
    reg [7:0]   strobe_cnt          ;
    
    
    //用于计算误差的采样数据缓存
    reg [19:0]  interpolate_I_d1    ;  
    reg [19:0]  interpolate_I_d2    ;   
    reg [19:0]  interpolate_Q_d1    ;
    reg [19:0]  interpolate_Q_d2    ;

    wire        samp_flag           ;
    
    //sync_flag是samp_flag打一拍,使得sync_flag正好与经过判决后的输出数据对齐
    //后续在sync_flag高电平时采集判决数据即可
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            sync_flag <= 1'b0;
        end else begin
            sync_flag <= samp_flag;
        end
    end

    
    
    //最佳抽样判决时刻标志
    //NCO输出第一个strobe_flag时已经到达第一个最佳抽判时刻
    //故strobe_cnt == 0且strobe_flag高电平到来代表最佳抽判时刻
    assign samp_flag = ((strobe_cnt == 0) && strobe_flag)?1'b1: 1'b0;
    
    
    //计算strobe_flag的次数，也是nco溢出的次数，strobe_flag出现在最佳抽判时刻以及最佳抽判时刻中央
    //strobe_cnt在本案例中为0、1之间计数
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            strobe_cnt <= 8'd0;
        end else if((strobe_cnt == 1) && strobe_flag) begin
            strobe_cnt <= 8'd0;
        end else if(strobe_flag) begin
            strobe_cnt <= strobe_cnt + 8'd1;
        end else begin
            strobe_cnt <= strobe_cnt;
        end
    end
    

    //采集最佳判决时刻以及中间时刻的数据
    //依据Gardner算法计算误差
    //每一个码元符号只需要计算一次误差即可
    //并将得到的时间误差数据通过环路滤波，得到小数间隔
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            interpolate_I_d1 <= 20'b0;
            interpolate_I_d2 <= 20'b0;
            interpolate_Q_d1 <= 20'b0;
            interpolate_Q_d2 <= 20'b0;
            
            //这里环路滤波器输出w(n)初始值≈1/100，
            //100代表I\Q路数据每一个码元采样数(本案例为100)
            wn <= 16'b0000_0001_0100_0111;  
            error <= 22'b0;
            error_d1 <= 22'b0;

        end else if(strobe_flag) begin
            //最佳判决时刻及判决时刻中间的时刻到来
            //更新用于计算误差的数据
            interpolate_I_d1 <= interpolate_I;
            interpolate_I_d2 <= interpolate_I_d1;

            interpolate_Q_d1 <= interpolate_Q;
            interpolate_Q_d2 <= interpolate_Q_d1;
            
            if(samp_flag) begin
            //最佳判决时刻到来
            //计算并更新定时误差
            //μt(k)=I(k-1/2)[I(k)−I(k−1)]
            //依据符号位的不同，通过移位操作实现*2以及*(-2)
                case({interpolate_I[19],interpolate_I_d2[19],interpolate_Q[19],interpolate_Q_d2[19]})
                    4'b1010:begin
                        //IQ两路都是[I(k)−I(k−1)] < 0 ,两路都将中间值*(-2)并相加得到error
                        //符号位需要扩展
                        error <= ~({interpolate_I_d1[19],interpolate_I_d1[19:0],1'b0})+20'b1 + ~({interpolate_Q_d1[19],interpolate_Q_d1[19:0],1'b0})+20'b1;
                    end
                    4'b1001:begin
                        //I路[I(k)−I(k−1)]<0,Q路[I(k)−I(k−1)]>0,
                        //I路将中间值*(-2),Q路将中间值*2
                        error <= ~({interpolate_I_d1[19],interpolate_I_d1[19:0],1'b0})+20'b1 + {interpolate_Q_d1[19],interpolate_Q_d1[19:0],1'b0};
                    end
                    4'b0110: begin
                        //I路[I(k)−I(k−1)]>0,Q路[I(k)−I(k−1)]<0,
                        //I路将中间值*2,Q路将中间值*(-2)
                        error <= {interpolate_I_d1[19],interpolate_I_d1[19:0],1'b0} + ~({interpolate_Q_d1[19],interpolate_Q_d1[19:0],1'b0})+20'b1;
                    end
                    4'b0101:begin
                        //I路[I(k)−I(k−1)]>0,Q路[I(k)−I(k−1)]>0,
                        //I路将中间值*2,Q路将中间值*2 
                        error <= {interpolate_I_d1[19],interpolate_I_d1[19:0],1'b0} + {interpolate_Q_d1[19],interpolate_Q_d1[19:0],1'b0};                   
                    end
                    4'b0100,4'b0111:begin
                        //I路[I(k)−I(k−1)]>0,Q路[I(k)−I(k−1)]=0
                        //I路将中间值*2
                        error <= {interpolate_I_d1[19],interpolate_I_d1[19:0],1'b0};
                    end
                    4'b1000,4'b1011:begin
                        //I路[I(k)−I(k−1)]<0,Q路[I(k)−I(k−1)]=0
                        //I路将中间值*(-2)
                        error <= ~({interpolate_I_d1[19],interpolate_I_d1[19:0],1'b0})+20'b1;
                    end
                    4'b0001,4'b1101:begin
                        //I路[I(k)−I(k−1)]=0,Q路[I(k)−I(k−1)]>0
                        //Q路将中间值*2
                        error <= {interpolate_Q_d1[19],interpolate_Q_d1[19:0],1'b0};                        
                    end
                    4'b0010,4'b1110:begin
                        //I路[I(k)−I(k−1)]=0,Q路[I(k)−I(k−1)]<0
                        //Q路将中间值*(-2)
                        error <= ~({interpolate_Q_d1[19],interpolate_Q_d1[19:0],1'b0})+20'b1;
                    end
                    default: begin
                        error <= 22'b0;
                    end
                endcase
            //输出判决数据,判决门限设为0,故判决符号位即可
                sync_out_I <= ~interpolate_I[19];
                sync_out_Q <= ~interpolate_Q[19];
            //每个最佳判决时刻更新一次error数据
                error_d1 <= error;
                
            //通过环路滤波器计算小数间隔
            //w(ms+1)=w(ms)+c1*(err(ms)-err(ms-1))+c2*err(ms), c1 = 2^(-8)， c2≈0
                wn = wn + ({{2{error[21]}},error[21:8]}-{{2{error_d1[21]}},error_d1[21:8]});
            end
            
        end else begin
            //其他时刻数据保持不变
            interpolate_I_d1 <= interpolate_I_d1;
            interpolate_I_d2 <= interpolate_I_d2;
            interpolate_Q_d1 <= interpolate_Q_d1;
            interpolate_Q_d2 <= interpolate_Q_d2;
        end
    end
    
    


endmodule
