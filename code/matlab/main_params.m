%% main_params.m - 差速驱动轮电机系统参数定义
% 仓储分拣机器人差速驱动轮系统综合设计
% 学号: 1120230476, AB=04, CD=76
% 所有物理参数集中管理，供其他脚本和 Simulink 模型调用
%
% 使用方法: 在 MATLAB 命令窗口运行 main_params，参数将加载到工作区

clear; clc;
fprintf('========================================\n');
fprintf(' 差速驱动轮电机系统 - 参数加载\n');
fprintf('========================================\n\n');

%% ==================== 1. 题目给定参数 ====================

% 学号参数
AB = 04;
CD = 76;

% 整车参数
m_robot   = 50;       % 整机质量 [kg]
r_wheel   = 0.08;     % 驱动轮半径 [m]
mu_roll   = 0.04;     % 滚动阻力系数
theta_max = 5;        % 最大坡度 [°]
eta_mech  = 0.90;     % 机械传动效率
g         = 9.81;     % 重力加速度 [m/s^2]

% 速度指标
n_low     = 60 + AB;    % 低速靠站轮速 [rpm] = 64 rpm
n_high    = 240 + CD;   % 通道巡航轮速 [rpm] = 316 rpm

% 电源与功率约束
V_dc      = 48;       % 直流母线电压 [V]
P_cont    = 150;      % 单轮电机连续功率上限 [W]
P_peak    = 2 * P_cont;  % 峰值功率（10s 内 2 倍过载）[W]

% 性能指标要求
t_rise_max   = 0.8;   % 上升时间上限 [s]
overshoot_n  = 0.10;  % 转速超调量上限 (10%)
overshoot_i  = 0.05;  % 电流超调量上限 (5%)

fprintf('--- 题目给定参数 ---\n');
fprintf('低速靠站轮速: %d rpm\n', n_low);
fprintf('通道巡航轮速: %d rpm\n', n_high);
fprintf('调速范围 D = %.2f\n', n_high/n_low);

%% ==================== 2. 减速器参数 ====================

i_gear    = 10;        % 减速比（单级行星齿轮减速器）
eta_gear  = 0.90;      % 减速器效率
J_gear    = 5e-6;      % 减速器等效转动惯量（估计值）[kg·m^2]

% 电机端转速
n_motor_low  = n_low * i_gear;    % 低速靠站电机转速 [rpm]
n_motor_high = n_high * i_gear;   % 通道巡航电机转速 [rpm]

fprintf('\n--- 减速器折算结果 ---\n');
fprintf('减速比: %d:1\n', i_gear);
fprintf('低速靠站电机转速: %d rpm\n', n_motor_low);
fprintf('通道巡航电机转速: %d rpm\n', n_motor_high);

%% ==================== 3. 负载力学分析 ====================

theta_rad = deg2rad(theta_max);

% 各工况负载力（单轮，两轮平均分担）
F_roll_flat  = mu_roll * m_robot * g / 2;
T_w_flat     = F_roll_flat * r_wheel;

F_roll_slope = mu_roll * m_robot * g * cos(theta_rad) / 2;
F_slope      = m_robot * g * sin(theta_rad) / 2;
F_total_up   = F_roll_slope + F_slope;
T_w_slope    = F_total_up * r_wheel;

F_total_down = F_slope - F_roll_slope;
T_w_down     = F_total_down * r_wheel;

fprintf('\n--- 负载力分析（单轮）---\n');
fprintf('平路滚动阻力: %.2f N, 轮端转矩: %.4f Nm\n', F_roll_flat, T_w_flat);
fprintf('坡道上行总阻力: %.2f N, 轮端转矩: %.4f Nm\n', F_total_up, T_w_slope);
fprintf('坡道下行净力: %.2f N, 轮端转矩: %.4f Nm\n', F_total_down, T_w_down);

% 折算到电机轴
T_rated_need = T_w_slope / (i_gear * eta_gear);

fprintf('\n--- 折算到电机轴（稳态）---\n');
fprintf('坡道稳态转矩需求: %.4f Nm\n', T_rated_need);

% 转动惯量折算
J_wheel        = m_robot * r_wheel^2 / 2;
J_wheel_motor  = J_wheel / i_gear^2;

fprintf('\n--- 惯量折算 ---\n');
fprintf('整车等效到单轮惯量: %.4f kg·m^2\n', J_wheel);
fprintf('折算到电机轴: %.6f kg·m^2\n', J_wheel_motor);

%% ==================== 4. 加速过程分析 ====================

omega_w_high = n_high * 2 * pi / 60;
omega_m_high = n_motor_high * 2 * pi / 60;

alpha_w_need = omega_w_high / t_rise_max;

J_motor_est   = 1.5e-5;
J_total_motor = J_motor_est + J_gear + J_wheel_motor;

alpha_m_need = alpha_w_need * i_gear;
T_acc_motor  = J_total_motor * alpha_m_need;
T_peak_need  = T_rated_need + T_acc_motor;

P_rated_need = T_rated_need * omega_m_high;
P_peak_need  = T_peak_need * omega_m_high;

fprintf('\n========================================\n');
fprintf(' 电机选型需求汇总\n');
fprintf('========================================\n');
fprintf('额定转矩需求: %.4f Nm\n', T_rated_need);
fprintf('额定转速需求: %d rpm\n', n_motor_high);
fprintf('额定功率需求: %.1f W\n', P_rated_need);
fprintf('峰值转矩需求: %.4f Nm\n', T_peak_need);
fprintf('峰值功率需求: %.1f W\n', P_peak_need);
fprintf('总转动惯量: %.6f kg·m^2\n', J_total_motor);
fprintf('调速范围: %.2f:1\n', n_motor_high / n_motor_low);

if P_rated_need > P_cont
    warning('额定功率需求 %.1f W 超过连续功率上限 %d W！', P_rated_need, P_cont);
else
    fprintf('\n[OK] 额定功率 %.1f W < 连续上限 %d W\n', P_rated_need, P_cont);
end
if P_peak_need > P_peak
    fprintf('[注意] 峰值功率 %.1f W 超过过载上限 %d W\n', P_peak_need, P_peak);
    fprintf('       加速过程短时超限，仿真中验证实际波形\n');
else
    fprintf('[OK] 峰值功率 %.1f W < 过载上限 %d W\n', P_peak_need, P_peak);
end

%% ==================== 5. 电机参数（选型后填入）====================
% BLDC 电机等效为直流电机模型参数
% 选型依据: 48V供电, 额定转速>=3160rpm, 额定转矩>=0.28Nm
% 数据来源: 典型48V/150W BLDC电机（如 Maxon EC 45 flat 级别）

motor.type    = 'BLDC';
motor.V_rated = 48;
motor.P_rated = 150;
motor.n_rated = 3200;
motor.T_rated = 0.45;
motor.I_rated = 3.5;
motor.Ra      = 1.2;          % 等效电枢电阻 [Ohm]
motor.La      = 1.5e-3;       % 等效电枢电感 [H]
motor.Ke      = 0.1432;       % 反电动势系数 [V·s/rad]
motor.Kt      = 0.1432;       % 转矩系数 [N·m/A]
motor.J_motor = 1.5e-5;       % 转子转动惯量 [kg·m^2]
motor.B_visc  = 5e-5;         % 粘滞摩擦系数 [N·m·s/rad]

fprintf('\n[OK] 电机参数已定义（BLDC等效模型）\n');
fprintf('     额定转矩 %.3f Nm > 需求 %.4f Nm (裕量 %.0f%%)\n', ...
    motor.T_rated, T_rated_need, (motor.T_rated/T_rated_need-1)*100);
fprintf('     额定转速 %d rpm > 需求 %d rpm\n', motor.n_rated, n_motor_high);

%% ==================== 6. 控制系统参数（待设计）====================

ctrl.Kp_i = 0;   % 电流环比例增益（待整定）
ctrl.Ki_i = 0;   % 电流环积分增益（待整定）
ctrl.Kp_n = 0;   % 速度环比例增益（待整定）
ctrl.Ki_n = 0;   % 速度环积分增益（待整定）

ctrl.I_max = motor.I_rated * 2;
ctrl.f_pwm = 20e3;
ctrl.Ts    = 1/ctrl.f_pwm;
ctrl.beta  = 0;
ctrl.alpha = 0;

fprintf('\n[注意] 控制器参数待整定，当前为占位值\n');

%% ==================== 7. 保存参数到工作区 ====================
fprintf('\n========================================\n');
fprintf(' 参数加载完成，已保存到工作区\n');
fprintf('========================================\n');
fprintf('运行 load_analysis.m 进行详细力学分析\n');
fprintf('运行 motor_selection.m 进行电机选型对比\n');
