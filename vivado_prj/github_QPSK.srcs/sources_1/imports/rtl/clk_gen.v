module clk_gen
#(parameter CNT_MAX = 26'd49_999_999)
(
    input wire          clk     ,  //50Mhz时钟
    input wire          rst_n   ,
    
    output reg[7:0]     s_dec   ,
    output reg[7:0]     m_dec   ,
    output reg[7:0]     h_dec       
    );
    
    reg [25:0] cnt;     //用于计时，作为标准
    
    
    //cnt
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cnt <= 26'd0;
        end else if(cnt == CNT_MAX) begin
            cnt <= 26'd0;
        end else begin
            cnt <= cnt + 26'd1;
        end
    end
    
    //s_dec
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            s_dec <= 8'd0;
        end else if((cnt == CNT_MAX) && (s_dec == 8'd59)) begin  //秒计数到59
            s_dec <= 8'd0;
        end else if(cnt == CNT_MAX) begin  //没有计数到最大值就在满足1秒时自增
            s_dec <= s_dec + 8'd1;
        end else begin
            s_dec <= s_dec;
        end
    end
    
    //m_dec
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            m_dec <= 8'd0;
        end else if((cnt == CNT_MAX) && (s_dec == 8'd59) && (m_dec == 8'd59)) begin  //分计数到59并满足跳转条件
            m_dec <= 8'd0;
        end else if((cnt == CNT_MAX) && (s_dec == 8'd59)) begin  //没有计数到最大值就在秒针清零时自增
            m_dec <= m_dec + 8'd1;
        end else begin
            m_dec <= m_dec;
        end
    end 
    
    //h_dec
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            h_dec <= 8'd0;
            //时计数到23：59：59并满足跳转条件
        end else if((cnt == CNT_MAX) && (s_dec == 8'd59) && (m_dec == 8'd59) && (h_dec == 8'd23)) begin  
            h_dec <= 8'd0;
            //没有计数到最大值就在分针、秒针清零时自增
        end else if((cnt == CNT_MAX) && (s_dec == 8'd59) && (m_dec == 8'd59)) begin  
            h_dec <= h_dec + 8'd1;
        end else begin
            h_dec <= h_dec;
        end
    end     
    
endmodule
