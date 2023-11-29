//////////////////////////////////////////////////////////////////////////////////
// Description: 将解调后的串行数据输出转换为40bit并行数据
//输入的时钟频率为和采样率相同
//////////////////////////////////////////////////////////////////////////////////
module ser2para
    #(parameter SAMPLE = 100) //每一个bit采样样本数 
    (
        input wire          clk     ,
        input wire          rst_n   ,
        input wire          ser_i   ,
        
        output reg [39:0]   para_o
    );
    
    reg [7:0]   sample_cnt  ;
    reg [5:0]   bit_cnt     ;
    
    //暂存处理的并行输出数据，在40bit转换完成后给para_o
    reg [39:0]  para_o_temp ; 
    
    
    //sample_cnt
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            sample_cnt <= 8'd0;
        end else if(sample_cnt == (SAMPLE - 1)) begin
            sample_cnt <= 8'd0;
        end else begin
            sample_cnt <= sample_cnt + 8'd1;
        end
    end
    
    //bit_cnt
    //设定在sample_cnt == (SAMPLE - 3)时采集para_o的一个bit
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            bit_cnt <= 6'd38;  //由于前面抽样判决时刻在数据中间，输入串行数据有两个bit的时间差
        end else if((bit_cnt == 6'd39) && sample_cnt == (SAMPLE - 3)) begin
            bit_cnt <= 6'd0;
        end else if(sample_cnt == (SAMPLE - 3))begin
            bit_cnt <= bit_cnt + 6'd1;
        end else begin
            bit_cnt <= bit_cnt;
        end
    end
    
    //para_o_temp
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            para_o_temp <= 40'b0;
        end else if(sample_cnt == (SAMPLE - 3)) begin
            para_o_temp[39-bit_cnt] <= ser_i;
        end else begin
            para_o_temp <= para_o_temp;
        end 
    end
    
    //para_o
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            para_o <= 40'b0;
        end else if(sample_cnt == (SAMPLE - 2) && (bit_cnt == 6'd0)) begin //比para_o_temp采集完成后再延迟一个时钟周期
            para_o <= para_o_temp;
        end else begin
            para_o <= para_o;
        end
    end

endmodule
