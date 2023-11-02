//数码管显示驱动模块
module seg_display
#(parameter CNT_SEL_MAX = 10'd999)
(
    input   wire        clk     ,
    input   wire        rst_n   ,
    input   wire[3:0]   in0     ,
    input   wire[3:0]   in1     ,
    input   wire[3:0]   in2     ,
    input   wire[3:0]   in3     ,
    input   wire[3:0]   in4     ,
    input   wire[3:0]   in5     ,
    
    output  reg[5:0]    sel     ,
    output  reg[7:0]    dig     
);
    

    reg [9:0] cnt_sel;      //计数器，用于控制扫描速度

    reg [3:0] display_data;  //某一个特定字段的输出数据
    parameter DIG0 = 8'hc0,  //输出对应字段所需的输出Dig信号, 低位代表A
              DIG1 = 8'hf9,
              DIG2 = 8'ha4,
              DIG3 = 8'hb0,
              DIG4 = 8'h99,
              DIG5 = 8'h92,
              DIG6 = 8'h82,
              DIG7 = 8'hf8,
              DIG8 = 8'h80,
              DIG9 = 8'h90,
              DIG_ALL = 8'h00;
             
    //cnt_sel控制扫描速度
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cnt_sel <= 10'd0;
        end else if(cnt_sel == CNT_SEL_MAX) begin
            cnt_sel <= 10'd0;
        end else begin
            cnt_sel <= cnt_sel + 10'd1;
        end

    end

    //sel
    //扫描数码管的选择信号
    always @ (posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            sel <= 6'b000001;
        end else if(cnt_sel == CNT_SEL_MAX) begin
            sel <= {sel[4:0],sel[5]};  //循环左移
        end else begin
            sel <= sel;
        end
    end
    
    
    //display_data
    //依据sel信号选择需要输出的数据
    always @ (*) begin
        case(sel) 
            6'b000001: begin
                display_data = in0;
            end
            6'b000010: begin
                display_data = in1;
            end
            6'b000100: begin
                display_data = in2;
            end
            6'b001000: begin
                display_data = in3;
            end
            6'b010000: begin
                display_data = in4;
            end
            6'b100000: begin
                display_data = in5;
            end 
            default: begin
                display_data = 4'b0;
            end
        endcase
    
    end
    
    //dig
    always @ (*) begin
        case(display_data) 
            4'd0:begin
                dig = DIG0;
            end
            4'd1:begin
                dig = DIG1;
            end
            4'd2:begin
                dig = DIG2;
            end
            4'd3:begin
                dig = DIG3;
            end
            4'd4:begin
                dig = DIG4;
            end
            4'd5:begin
                dig = DIG5;
            end
            4'd6:begin
                dig = DIG6;
            end
            4'd7:begin
                dig = DIG7;
            end
            4'd8:begin
                dig = DIG8;
            end
            4'd9:begin
                dig = DIG9;
            end
            default:begin
                dig = DIG_ALL;
            end
        endcase
    
    end


endmodule