
//////////////////////////////////////////////////////////////////////////////////
// Dependencies: 将输入的40bit并行数据转换为串行输出
// 并行数据的高位先出
// 输出码元速率为clk/DIV
// 默认配置:clk为50MHz,DIV = 10000,输出码元速率即为5kHz
//////////////////////////////////////////////////////////////////////////////////
module para2ser
    #(parameter DIV = 14'd1000)
    (
        input wire          clk         ,
        input wire          rst_n       ,
        input wire  [39:0]  para_i      ,
        
        output reg          ser_o       
    );
    
    //计时器，每次计数到DIV-1,ser_o更新1bit数据
    reg [13:0]  div_cnt;  
    
    //记录当前要输出的bit位
    reg [5:0]   bit_cnt;
    
    //div_cnt
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            div_cnt <= 14'd0;
        end else if(div_cnt == DIV - 1) begin
            div_cnt <= 14'd0;
        end else begin
            div_cnt <= div_cnt + 14'd1;
        end
    end
    
    //bit_cnt
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            bit_cnt <= 6'd0;
        end else if((bit_cnt == 6'd39) && (div_cnt == DIV - 1)) begin
            bit_cnt <= 6'd0;
        end else if(div_cnt == DIV - 1) begin
            bit_cnt <= bit_cnt + 6'd1;
        end else begin
            bit_cnt <= bit_cnt;
        end
    end
    
    // ser_o
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            ser_o <= 1'b0;
        end else begin
            ser_o <= para_i[39 - bit_cnt];
        end
    end
    
    
    
    
endmodule
