//内插滤波器，依据输入的数据计算内插值，采用Farrow结构的插值滤波器
module interpolate_filter
(
    input wire          clk         ,
    input wire          rst_n       ,
    input wire  [14:0]  data_in_I   ,
    input wire  [14:0]  data_in_Q   ,
    input wire  [15:0]  uk          ,   //小数间隔，15bit小数位

    output wire [19:0]  I_y         ,   //I路插值输出
    output wire [19:0]  Q_y             //Q路插值输出
);

    reg [14:0]          data_in_I_d1;  //延时一个时钟的输入数据
    reg [14:0]          data_in_I_d2;  //延时两个时钟的输入数据
    reg [14:0]          data_in_I_d3;  //延时三个时钟的输入数据    
    
    
    reg [14:0]          data_in_Q_d1;  //延时一个时钟的输入数据
    reg [14:0]          data_in_Q_d2;  //延时两个时钟的输入数据
    reg [14:0]          data_in_Q_d3;  //延时三个时钟的输入数据    
    
    reg [19:0]          I_y_temp    ;  //I路插值输出临时变量
    reg [19:0]          Q_y_temp    ;  //Q路插值输出临时变量
    
    
    
    //Farrow结构插值滤波器的中间数据
    //最大的数值范围为输入数据的3倍，故设计比输入数据位宽多两位
    //实际上使用到的位宽并未达到多两位
    reg [16:0]          f1_I        ; 
    reg [16:0]          f2_I        ;
    reg [16:0]          f3_I        ;

    reg [16:0]          f1_Q        ; 
    reg [16:0]          f2_Q        ;
    reg [16:0]          f3_Q        ;
    
    // f1 = 0.5x(m)−0.5x(m−1)−0.5x(m−2)+0.5x(m−3)
    // f2 = −0.5x(m)+1.5x(m−1)−0.5x(m−2)−0.5x(m−3)
    // f3 = x(m−2)
    // y(k) = f1*(μk)^2 + f2*uk + f3
    
    
    //乘法器输出结果
    wire [32:0] mult_result_f1_1_I      ;  //f1参与的第一个乘法器结果，计算I路数据
    wire [32:0] mult_result_f1_2_I      ;  //f1参与的第二个乘法器结果，计算I路数据
    wire [32:0] mult_result_f2_1_I      ;  //f2参与的第一个乘法器结果，计算I路数据

    wire [32:0] mult_result_f1_1_Q      ;  //f1参与的第一个乘法器结果，计算Q路数据
    wire [32:0] mult_result_f1_2_Q      ;  //f1参与的第二个乘法器结果，计算Q路数据
    wire [32:0] mult_result_f2_1_Q      ;  //f2参与的第一个乘法器结果，计算Q路数据
    
    
    //对输入数据以及中间变量进行打拍
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            data_in_I_d1 <= 15'b0;
            data_in_I_d2 <= 15'b0;
            data_in_I_d3 <= 15'b0;
            data_in_Q_d1 <= 15'b0;
            data_in_Q_d2 <= 15'b0;
            data_in_Q_d3 <= 15'b0;
        end else begin
            data_in_I_d1 <= data_in_I;
            data_in_I_d2 <= data_in_I_d1;
            data_in_I_d3 <= data_in_I_d2;
            data_in_Q_d1 <= data_in_Q;
            data_in_Q_d2 <= data_in_Q_d1;
            data_in_Q_d3 <= data_in_Q_d2;
        end
    end
    
    //计算f1、f2、f3
    // f1 = 0.5x(m)−0.5x(m−1)−0.5x(m−2)+0.5x(m−3)
    // f2 = −0.5x(m)+1.5x(m−1)−0.5x(m−2)−0.5x(m−3)
    // f3 = x(m−2)
    // 通过移位实现乘法
    always @ (*) begin
        f1_I = {{3{data_in_I[14]}}, data_in_I[14:1]} - {{3{data_in_I_d1[14]}}, data_in_I_d1[14:1]} - {{3{data_in_I_d2[14]}}, data_in_I_d2[14:1]} + {{3{data_in_I_d3[14]}}, data_in_I_d3[14:1]};
        f2_I = {{2{data_in_I_d1[14]}}, data_in_I_d1} + {{3{data_in_I_d1[14]}}, data_in_I_d1[14:1]} - {{3{data_in_I[14]}}, data_in_I[14:1]} - {{3{data_in_I_d2[14]}}, data_in_I_d2[14:1]} - {{3{data_in_I_d3[14]}}, data_in_I_d3[14:1]};
        f3_I = {{2{data_in_I_d2[14]}}, data_in_I_d2};
        
        f1_Q = {{3{data_in_Q[14]}}, data_in_Q[14:1]} - {{3{data_in_Q_d1[14]}}, data_in_Q_d1[14:1]} - {{3{data_in_Q_d2[14]}}, data_in_Q_d2[14:1]} + {{3{data_in_Q_d3[14]}}, data_in_Q_d3[14:1]};
        f2_Q = {{2{data_in_Q_d1[14]}}, data_in_Q_d1} + {{3{data_in_Q_d1[14]}}, data_in_Q_d1[14:1]} - {{3{data_in_Q[14]}}, data_in_Q[14:1]} - {{3{data_in_Q_d2[14]}}, data_in_Q_d2[14:1]} - {{3{data_in_Q_d3[14]}}, data_in_Q_d3[14:1]};
        f3_Q = {{2{data_in_Q_d2[14]}}, data_in_Q_d2};
    end
    
    
    //I路乘法计算

    // y(k) = f1*(μk)^2 + f2*uk + f3
    //f1参与的第一个乘法器，计算I路数据
    mult_interploate  mult_interploate_f1_1_I(
        .CLK(clk),  // input wire CLK
        .A(f1_I),      // input wire [16 : 0] A
        .B(uk),      // input wire [15 : 0] B
        .P(mult_result_f1_1_I)      // output wire [32 : 0] P
    );
    
    //f1参与的第一个乘法器，计算I路数据
    //由于定义uk低15bit代表小数位，但乘法器计算时并不会将其与小数关联，认为其是普通二进制数
    //故这里将mult_result_f1_1_I右移15位，再与uk相乘
    mult_interploate  mult_interploate_f1_2_I(
        .CLK(clk),  
        .A(mult_result_f1_1_I[31:15]), 
        .B(uk),      
        .P(mult_result_f1_2_I)      
    );  
    
    //f2参与的第一个乘法器，计算I路数据    
    mult_interploate  mult_interploate_f2_1_I(
        .CLK(clk),  
        .A(f2_I),      
        .B(uk),      
        .P(mult_result_f2_1_I)
    );  
    
    
    
    //Q路乘法计算
    

    //f1参与的第一个乘法器，计算Q路数据
    mult_interploate  mult_interploate_f1_1_Q(
        .CLK(clk),  
        .A(f1_Q),      
        .B(uk),      
        .P(mult_result_f1_1_Q)  
    );
    
    //f1参与的第一个乘法器，计算Q路数据
    //由于定义uk低15bit代表小数位，但乘法器计算时并不会将其与小数关联，认为其是普通二进制数
    //故这里将mult_result_f1_1_Q右移15位，再与uk相乘
    mult_interploate  mult_interploate_f1_2_Q(
        .CLK(clk),  
        .A(mult_result_f1_1_Q[31:15]),  
        .B(uk),      
        .P(mult_result_f1_2_Q)      
    );  
    
    //f2参与的第一个乘法器，计算Q路数据    
    mult_interploate  mult_interploate_f2_1_Q(
        .CLK(clk),  
        .A(f2_Q),   
        .B(uk),      
        .P(mult_result_f2_1_Q)  
    );  
    
    
    //插值滤波器输出数据I_y I_Q
    //此时输出插值数据已经与本地时钟clk同步了
    always @ (posedge clk or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            I_y_temp <= 20'b0;
            Q_y_temp <= 20'b0;
        end else begin
            I_y_temp <= {{2{mult_result_f1_2_I[32]}}, mult_result_f1_2_I[32:15]} + {{2{mult_result_f2_1_I[32]}}, mult_result_f2_1_I[32:15]} + {{3{f3_I[16]}}, f3_I};
            Q_y_temp <= {{2{mult_result_f1_2_Q[32]}}, mult_result_f1_2_Q[32:15]} + {{2{mult_result_f2_1_Q[32]}}, mult_result_f2_1_Q[32:15]} + {{3{f3_Q[16]}}, f3_Q};
        end
    end
    
    assign I_y = I_y_temp;
    assign Q_y = Q_y_temp;
    
    
    



endmodule 