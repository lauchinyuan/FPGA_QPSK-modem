% QPSK调制解调基本过程仿真，不包括载波同步
clear all;                  % 清除所有变量
close all;                  % 关闭所有窗口
clc;                        % 清屏
%% 基本参数
M=80;                       % 产生码元数    
L=100;                      % 每个码元采样次数
fc=50e3;                    % 载波频率50kHz 
% flocal = 50010;           % 接收端的本地载波频率
flocal = 50010;             % 模拟载波频率已经同步的情况
Rb =5e3;                    % 码元速率                   
Ts=1/Rb;                    % 码元的持续时间
dt=Ts/L;                    % 采样间隔
TotalT=M*Ts;                % 总时间
t=0:dt:TotalT-dt;           % 时间
Fs=L*Rb;                    % 采样频率
C1 = 0.00090625;
C2 = C1 * 0.1;


%% 产生信号源
wave=randi([0,1],1,M);      % 随机产生信号
%帧头oxcc,23时24分25秒的一个数据包，最后一字节为校验和
%wave=[1 1 0 0 1 1 0 0 0 0 0 1 0 1 1 1 0 0 0 1 1 0 0 0 0 0 0 1 1 0 0 1 0 0 0 1 0 1 0 0];
wave=2*wave-1;              % 单极性变双极性
fz=ones(1,L);               % 定义复制的次数L,L为每码元的采样点数
x1=wave(fz,:);              % 将原来wave的第一行复制L次，称为L*M的矩阵
baseband=reshape(x1,1,L*M); % 产生双极性不归零矩形脉冲波形，将刚得到的L*M矩阵，按列重新排列形成1*(L*M)的矩阵

%% I、Q路码元
% I路码元是基带码元的奇数位置码元，Q路码元是基带码元的偶数位置码元
I=[]; Q=[];
for i=1:M
    if mod(i, 2)~=0
        I = [I, wave(i)];
    else
        Q = [Q, wave(i)];
    end
end
fz2 = ones(1,2*L);
x2 = I(fz2,:);               % 将原来I的第一行复制2L次，成为2L*(M/2)的矩阵
I_signal = reshape(x2,1,L*M);% 将刚得到的L*(M/2)矩阵，按列重新排列形成1*(L*M)的矩阵
x3 = Q(fz2,:);               % 将原来Q的第一行复制2L次，称为2L*(M/2)的矩阵
Q_signal = reshape(x3,1,L*M);% 将刚得到的L*(M/2)矩阵，按列重新排列形成1*(L*M)的矩阵


%% 成形滤波
% 通过Filter Designer生成了40阶(41个抽头系数)的升余弦平方根滤波器rcosfilter
% 采样频率为Fs,截止频率为Rb/2
Q_filtered = filter(rcosfilter,Q_signal);   %Q路成形滤波
I_filtered = filter(rcosfilter,I_signal);   %I路成形滤波
Q_filtered = double(Q_filtered);
I_filtered = double(I_filtered);
%% QPSK调制      
carry_cos=cos(2*pi*fc*t);        % 载波1
psk1=I_filtered.*carry_cos;        % PSK1的调制
carry_sin=sin(2*pi*fc*t);        % 载波2
psk2=Q_filtered.*carry_sin;        % PSK1的调制
qpsk=psk1+psk2;                 % QPSK的实现
%% 信号经过高斯白噪声信道
%qpsk_n = qpsk;              %不加噪
qpsk_n=awgn(qpsk,20);       % 信号qpsk中加入白噪声，信噪比为SNR=20dB

%% 解调部分
err_phase = zeros(1,length(t));
phase_ctrl= zeros(1,length(t));
%% 载波同步暂未进行
f_ctrl = 0;  % 频率修正控制字, 不进行载波同步设为0
carry_cos_local = cos(2*pi*(flocal+f_ctrl)*t);  % 本地载波暂时和调制端相同
carry_sin_local = sin(2*pi*(flocal+f_ctrl)*t);  % 本地载波暂时和调制端相同

% 利用调整后的本地载波与QPSK信号相乘
demo_I=qpsk_n.*carry_cos_local;         % 相干解调，乘以本地相干载波
demo_Q=qpsk_n.*carry_sin_local;  

filtered_Q = double(filter(demo_lowpass,demo_Q));   %Q路低通滤波
filtered_I = double(filter(demo_lowpass,demo_I));   %I路低通滤波

% 低通滤波后进行载波同步鉴相，模拟costas环鉴相器原始输出
inv_Q = -1*filtered_Q;
inv_I = -1*filtered_I;

% 依据I路正负选择I路待相乘的鉴相值
% if filtered_I>=0 
%     pd_I = filtered_Q;
% else 
%     pd_I = inv_Q;
% end
ind = find(filtered_I>=0);
pd_I(ind) = filtered_Q(ind); 
ind = find(filtered_I<0);
pd_I(ind) = inv_Q(ind);

% if filtered_Q>=0 
%     pd_Q = filtered_I;
% else 
%     pd_Q = inv_I;
% end

% 依据Q路正负选择Q路待相乘的鉴相值
ind = find(filtered_Q>=0);
pd_Q(ind) = filtered_I(ind);
ind = find(filtered_Q<0);
pd_Q(ind) = inv_I(ind);

% 鉴相器原始输出(未滤波)
pd = pd_I - pd_Q;

%鉴相器输出环路滤波
err_phase(1) = C1*pd(1); % 滤波器输入输出第一个数据是一样的
for i=2:length(t)
    err_phase(i) = err_phase(i-1) + C1*pd(i)+(C2-C1)*pd(i-1);
end
%% 抽样判决
k=0;                        % 设置抽样限值
sample_d_I=1*(filtered_I>k);     % 滤波后的向量的每个元素和0进行比较，大于0为1，否则为0
sample_d_Q=1*(filtered_Q>k);      % 滤波后的向量的每个元素和0进行比较，大于0为1，否则为0

%% I、Q路合并
I_comb = [];
Q_comb = [];
% 取码元的中间位置上的值进行判决
for j=L:2*L:(L*M)
    if sample_d_I(j)>0
        I_comb=[I_comb,1];
    else
        I_comb=[I_comb,-1];
    end
end
% 取码元的中间位置上的值进行判决
for k=L:2*L:(L*M)
    if sample_d_Q(k)>0
        Q_comb=[Q_comb,1];
    else
        Q_comb=[Q_comb,-1];
    end
end
code = [];
% 将I路码元为最终输出的奇数位置码元，将Q路码元为最终输出的偶数位置码元
for n=1:M
    if mod(n, 2)~=0
        code = [code, I_comb((n+1)/2)];
    else
        code = [code, Q_comb(n/2)];
    end
end

x4=code(fz,:);             % 将原来code的第一行复制L次，称为L*M的矩阵
dout=reshape(x4,1,L*M);    % 产生单极性不归零矩形脉冲波形，将刚得到的L*M矩阵，按列重新排列形成1*(L*M)的矩阵

%% 绘制原始信号
figure();                   
subplot(311);                   % 窗口分割成3*1的，当前是第1个子图 
plot(t,baseband,'LineWidth',2); % 绘制基带码元波形，线宽为2
title('基带信号波形');      
xlabel('时间/s');           
ylabel('幅度');            

subplot(312);                   % 窗口分割成3*1的，当前是第2个子图 
plot(t,I_signal,'LineWidth',2); % 绘制基带码元波形，线宽为2
title('I路信号波形');       
xlabel('时间/s');           
ylabel('幅度');             

subplot(313);                   % 窗口分割成3*1的，当前是第3个子图 
plot(t,Q_signal,'LineWidth',2); % 绘制基带码元波形，线宽为2
title('Q路信号波形');            % 标题
xlabel('时间/s');                % x轴标签
ylabel('幅度');                   % y轴标签
axis([0,TotalT,-1.1,1.1])       % 坐标范围限制


%% 绘制成形滤波后信号
figure();                  
subplot(211);                
plot(t,Q_filtered,'LineWidth',2);% 绘制成形滤波后Q路信号
title('成形滤波后Q路波形');      % 标题
xlabel('时间/s');           % x轴标签
ylabel('幅度');             % y轴标签
axis([0,TotalT,-1,1]);      % 设置坐标范围
              
subplot(212);                
plot(t,I_filtered,'LineWidth',2);% 绘制成形滤波后I路信号
title('成形滤波后I路波形');      % 标题
xlabel('时间/s');           % x轴标签
ylabel('幅度');             % y轴标签
axis([0,TotalT,-1,1]);      % 设置坐标范围

%% 绘制QPSK调制信号以及加噪后信号
figure();                  
subplot(211);                
plot(t,qpsk,'LineWidth',2); % 绘制基带码元波形，线宽为2
title('QPSK信号波形');      % 标题
xlabel('时间/s');           % x轴标签
ylabel('幅度');             % y轴标签
axis([0,TotalT,-1,1]);      % 设置坐标范围
subplot(212);               % 窗口分割成2*1的，当前是第2个子图 
plot(t,qpsk_n,'LineWidth',2);  % 绘制QPSK信号加入白噪声的波形
axis([0,TotalT,-1,1]);      % 设置坐标范围
title('通过高斯白噪声信道后的信号');% 标题
xlabel('时间/s');           % x轴标签
ylabel('幅度');             % y轴标签

%% 绘制绘制IQ两路乘以本地相干载波后的信号
figure();     
subplot(211)                             % 窗口分割成2*1的，当前是第1个子图 
plot(t,demo_I,'LineWidth',2)             % 绘制I路乘以相干载波后的信号
axis([0,TotalT,-1,1]);                   % 设置坐标范围
title("I路乘以相干载波后的信号")          % 标题
xlabel('时间/s');                        % x轴标签
ylabel('幅度');                          % y轴标签

subplot(212)                            % 窗口分割成2*1的，当前是第2个子图 
plot(t,demo_Q,'LineWidth',2)            % 绘制Q路乘以相干载波后的信号
axis([0,TotalT,-1,1]);                  % 设置坐标范围
title("Q路乘以相干载波后的信号")         % 标题
xlabel('时间/s');                       % x轴标签
ylabel('幅度');                         % y轴标签
%% 绘制鉴相器输出
figure();   
subplot(311)                             
plot(t,pd,'LineWidth',2)                
title("鉴相器计算结果");                 % 标题
xlabel('时间/s');                        % x轴标签
ylabel('幅度');                          % y轴标签

subplot(312)                            
plot(t,pd_I,'LineWidth',2)            
title("I路鉴相器输入");         
xlabel('时间/s');                        % x轴标签
ylabel('幅度');                          % y轴标签

subplot(313)                             
plot(t,pd_Q,'LineWidth',2)         
title("I路鉴相器输入");            
xlabel('时间/s');                        % x轴标签
ylabel('幅度');                          % y轴标签


%% 载波同步鉴相器结果展示
figure();   
subplot(311)                             
plot(t,pd,'LineWidth',2)     % 绘制I路乘以相干载波后的信号
title("鉴相器计算结果");                 % 标题
xlabel('时间/s');                        % x轴标签
ylabel('幅度');                          % y轴标签

subplot(312)                            
plot(t,err_phase,'LineWidth',2)          % 绘制载波同步环路滤波器输出
title("载波同步环路滤波器输出");         
xlabel('时间/s');                        % x轴标签
ylabel('幅度');                          % y轴标签

subplot(313)                             % 窗口分割成2*1的，当前是第1个子图 
plot(t,phase_ctrl,'LineWidth',2)         % 绘制载波同步相位控制字
title("载波同步相位控制字");            
xlabel('时间/s');                        % x轴标签
ylabel('幅度');                          % y轴标签


%% 绘图比较本地载波和发送端载波
figure()
nop=300;     %由于数据很多，为了便于观察选取前nop点进行绘图
start=1000;  %开始观察的点的索引
subplot(211) % 窗口分割成2*1的，当前是第1个子图 
% 绘制正弦载波
plot(t(start+1:start+nop),carry_sin(start+1:start+nop),'LineWidth',2)          
hold on
% 绘制接收端正弦载波
plot(t(start+1:start+nop),carry_sin_local(start+1:start+nop),'LineWidth',2)
hold on
legend('调制端正弦载波','接收端本地正弦载波');
title("正弦载波")   % 标题
xlabel('时间/s');   % x轴标签
ylabel('幅度');     % y轴标签

subplot(212) % 窗口分割成2*1的，当前是第1个子图 
% 绘制余弦载波
plot(t(start+1:start+nop),carry_cos(start+1:start+nop),'LineWidth',2)          
hold on
% 绘制本地余弦载波
plot(t(start+1:start+nop),carry_cos_local(start+1:start+nop),'LineWidth',2)
hold on
legend('调制端余弦载波','接收端本地余弦载波');
title("余弦载波")   % 标题
xlabel('时间/s');   % x轴标签
ylabel('幅度');     % y轴标签


%% 绘制加噪信号经过低通滤波器后的信号
figure();                  
subplot(211)                 
plot(t,filtered_I,'LineWidth',2); % 绘制I路经过低通滤波器后的信号
axis([0,TotalT,-1.1,1.1]);  % 设置坐标范围
title("I路经过低通滤波器后的信号");
xlabel('时间/s');           
ylabel('幅度');             

subplot(212)               
plot(t,filtered_Q,'LineWidth',2); % 绘制Q路经过低通滤波器后的信号
axis([0,TotalT,-1.1,1.1]);  
title("Q路经过低通滤波器后的信号");
xlabel('时间/s');          
ylabel('幅度');    

%% 绘制抽样判决结果
figure();
subplot(311)                % 窗口分割成3*1的，当前是第1个子图 
plot(t,sample_d_I,'LineWidth',2)% 画出经过抽样判决后的信号
axis([0,TotalT,-0.1,1.1]); % 设置坐标范围
title("I路经过抽样判决后的信号");
xlabel('时间/s');           
ylabel('幅度');            

subplot(312)                % 窗口分割成3*1的，当前是第2个子图 
plot(t,sample_d_Q,'LineWidth',2)% 画出经过抽样判决后的信号
axis([0,TotalT,-0.1,1.1]); % 设置坐标范用
title("Q路经过抽样判决后的信号")% 标题
xlabel('时间/s');           % x轴标签
ylabel('幅度');             % y轴标签


%% 绘图比较调制解调的信号
figure()     
subplot(411)               
plot(t,I_signal,'LineWidth',2);% 绘制基带码元波形，线宽为2
title('I路信号波形');       
xlabel('时间/s');           
ylabel('幅度');  
subplot(412)                
plot(t,sample_d_I,'LineWidth',2)
axis([0,TotalT,-0.1,1.1]); 
title("I路经过抽样判决后的信号")
subplot(413)               
plot(t,Q_signal,'LineWidth',2);
title('Q路信号波形');       
xlabel('时间/s');           
ylabel('幅度');  
subplot(414)                
plot(t,sample_d_Q,'LineWidth',2);
axis([0,TotalT,-0.1,1.1]); 
title("Q路经过抽样判决后的信号");

figure()     
subplot(211)               
plot(t,baseband,'LineWidth',2);% 绘制基带码元波形，线宽为2
title('基带信号波形');      
xlabel('时间/s');           
ylabel('幅度');   
subplot(212)   
plot(t,dout,'LineWidth',2);% 绘制基带码元波形
title('QPSK解调判决后信号'); % 标题
xlabel('时间/s');          % x轴标签
ylabel('幅度');            % y轴标签
axis([0,TotalT,-1.1,1.1])  % 坐标范围限制

subplot(313);              % 窗口分割成3*1的，当前是第3个子图 
plot(t,dout,'LineWidth',2);% 绘制基带码元波形
title('QPSK解调判决后信号'); % 标题
xlabel('时间/s');          % x轴标签
ylabel('幅度');            % y轴标签
axis([0,TotalT,-1.1,1.1])  % 坐标范围限制


%% 将仿真波形输出为txt文本作为testbench数据输入
Width = 15; %数据位宽
I_n=round(filtered_I*(2^(Width)-1));
Q_n=round(filtered_Q*(2^(Width)-1));
fid=fopen('dataI.txt','w');     
for k=1:length(I_n)
    B_s=dec2bin(I_n(k)+((I_n(k))<0)*2^Width,Width);
    for j=1:Width
        if B_s(j)=='1'
            tb=1;
        else
            tb=0;
        end
        fprintf(fid,'%d',tb);
    end
    fprintf(fid,'\r\n');
end
fprintf(fid,';');
fclose(fid);

fid=fopen('dataQ.txt','w');     
for k=1:length(Q_n)
    B_s=dec2bin(Q_n(k)+((Q_n(k))<0)*2^Width,Width);
    for j=1:Width
        if B_s(j)=='1'
            tb=1;
        else
            tb=0;
        end
        fprintf(fid,'%d',tb);
    end
    fprintf(fid,'\r\n');
end
fprintf(fid,';');
fclose(fid);