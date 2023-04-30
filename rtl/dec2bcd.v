module dec2bcd(
    input wire      clk     ,
    input wire      rst_n   ,
    input wire[7:0] dec_in  ,  
    
    output reg[3:0] unit    ,
    output reg[3:0] ten     
    );
    
    parameter SHIFT_CNT_MAX = 4'd8;   //移位次数，与dec_in的长度保持一致
    parameter BCD_BIT_CNT = 4'd8; //输出的BCD码的位数，也是一开始补零的数量
    
    //首先将输入数据补零，每个时钟周期都对数据进行左移，左移后，每个BCD字节的大小如果大于4则加3
    //重复以上操作，直到所有输入数据移入完毕，本次时钟实验就是向左移动7次即可
    
    reg [BCD_BIT_CNT+7:0] shift_data; //处理过程的中间数据，先要进行补0
    reg [3:0]   shift_cnt;//移位次数
    reg         shift_flag; //移位标志，为1时移位，0时比较
    
    //shift_flag
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            shift_flag <= 1'b0;         //起始为0，补零装载shift_data
        end else begin
            shift_flag <= ~shift_flag;   //移位操作和判断操作依次进行
        end
    
    end
    
    //shift_cnt
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            shift_cnt <= 0;
        end else if((shift_cnt == SHIFT_CNT_MAX) && shift_flag) begin  //移位次数达到计数最大值
            shift_cnt <= 0;
        end else if(shift_flag) begin
            shift_cnt <= shift_cnt + 1; 
        end else begin
            shift_cnt <= shift_cnt;
        end
    end 
    
    //shift_data,主要处理的数据
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            shift_data <= {8'b0, dec_in};  //复位时补0
        end else if((shift_cnt == 0) && (!shift_flag)) begin  
            shift_data <= {8'b0, dec_in};  //shift_cnt = 0 且shift_flag低电平，代表新的一轮处理过程的开始     
        end else if(shift_flag) begin   //移位操作
            shift_data <= shift_data << 1;
        end else if((!shift_flag)) begin
        //判断两个bcd字段是否>4, 若有，加3，否则保持原来的数据
            shift_data[15:12] <= (shift_data[15:12] > 4'd4)?(shift_data[15:12] + 4'b0011):shift_data[15:12];
            shift_data[11:8] <= (shift_data[11:8] > 4'd4)?(shift_data[11:8] + 4'b0011):shift_data[11:8];            
        end else begin
            shift_data <= shift_data;
        end
    
    end
    
    //unit数据的提取
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            unit <= 4'b0;
        end else if((shift_cnt == SHIFT_CNT_MAX) && (!shift_flag)) begin
        //数据处理完毕，加载处理后的数据进行输出
            unit <= shift_data[11:8];
        end else begin
            unit <= unit;
        end
    end
    
    //ten
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ten <= 4'b0;
        end else if((shift_cnt == SHIFT_CNT_MAX) && (!shift_flag)) begin
            ten <= shift_data[15:12];
        end else begin
            ten <= ten;
        end
    end 

    
endmodule
