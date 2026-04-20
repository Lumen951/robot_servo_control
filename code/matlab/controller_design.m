%% controller_design.m - 控制器参数整定
% 对应设计任务 3.6：系统建模、控制器设计（9分）
%
% 功能：
%   1. 建立 BLDC 等效直流电机双闭环系统数学模型
%   2. 按工程整定法设计电流环（典型I型）和转速环（典型II型）PI参数
%   3. 绘制 Bode 图验证稳定性
%   4. 输出控制器参数供 Simulink 模型使用
%
% 依赖: main_params.m（需先运行，且电机参数已更新为实际选型值）

%% 检查参数是否已加载
if ~exist('motor', 'var')
    fprintf('正在加载系统参数...\n');
    main_params;
end

fprintf('\n========================================\n');
fprintf(' 双闭环控制器参数整定\n');
fprintf('========================================\n');

%% ==================== 1. 系统参数提取 ====================

Ra = motor.Ra;
La = motor.La;
Ke = motor.Ke;
Kt = motor.Kt;
Jm = motor.J_motor;

J_sys = Jm + J_gear + J_wheel_motor;
B_sys = motor.B_visc;

Ce = Ke;

Tl = La / Ra;
Tm = Ra * J_sys / (Ce * Kt);

fprintf('\n--- 系统关键参数 ---\n');
fprintf('电枢电阻 Ra = %.3f Ohm\n', Ra);
fprintf('电枢电感 La = %.4f H\n', La);
fprintf('反电动势系数 Ce = %.4f V·s/rad\n', Ce);
fprintf('转矩系数 Kt = %.4f Nm/A\n', Kt);
fprintf('系统总惯量 J = %.2e kg·m^2\n', J_sys);
fprintf('电气时间常数 Tl = %.4f s\n', Tl);
fprintf('机电时间常数 Tm = %.4f s\n', Tm);

%% ==================== 2. PWM 功率变换器模型 ====================

Ts_pwm = 1 / ctrl.f_pwm;
Tpwm = Ts_pwm / 2;
Ks = V_dc / 10;

fprintf('\n--- PWM 变换器参数 ---\n');
fprintf('PWM 频率: %.0f Hz\n', ctrl.f_pwm);
fprintf('PWM 等效延迟: Tpwm = %.2e s\n', Tpwm);
fprintf('PWM 增益: Ks = %.2f V/V\n', Ks);

%% ==================== 3. 反馈系数设计 ====================

I_max = motor.I_rated * 2;
beta = 10 / I_max;
alpha = 10 / n_motor_high;

ctrl.beta = beta;
ctrl.alpha = alpha;
ctrl.I_max = I_max;

fprintf('\n--- 反馈系数 ---\n');
fprintf('电流反馈系数 beta = %.4f V/A\n', beta);
fprintf('速度反馈系数 alpha = %.6f V/rpm\n', alpha);
fprintf('电流限幅值 I_max = %.1f A\n', I_max);

%% ==================== 4. 电流环设计（典型 I 型系统）====================

fprintf('\n========================================\n');
fprintf(' 电流环设计（典型 I 型系统）\n');
fprintf('========================================\n');

T_oi = 2e-3;
T_sigma_i = Tpwm + T_oi;

tau_i = Tl;

KT_i = 0.5;
K_open_i = KT_i / T_sigma_i;

Kp_i = K_open_i * Ra * tau_i / (Ks * beta);
Ki_i = Kp_i / tau_i;

ctrl.Kp_i = Kp_i;
ctrl.Ki_i = Ki_i;

fprintf('电流环小时间常数 T_sigma_i = %.2e s\n', T_sigma_i);
fprintf('PI 零点时间常数 tau_i = Tl = %.4f s\n', tau_i);
fprintf('KT = %.2f (超调约 4.3%%)\n', KT_i);
fprintf('\n电流环 PI 参数:\n');
fprintf('  Kp_i = %.4f\n', Kp_i);
fprintf('  Ki_i = %.4f\n', Ki_i);
fprintf('  tau_i = %.4f s\n', tau_i);

omega_ci = KT_i / T_sigma_i;
f_ci = omega_ci / (2*pi);
T_cl_i = 1 / omega_ci;
fprintf('\n电流环截止频率: omegac_i = %.1f rad/s (f = %.1f Hz)\n', omega_ci, f_ci);
fprintf('电流环闭环等效时间常数: T_cl_i = %.4f s\n', T_cl_i);

%% ==================== 5. 转速环设计（典型 II 型系统）====================

fprintf('\n========================================\n');
fprintf(' 转速环设计（典型 II 型系统）\n');
fprintf('========================================\n');

T_on = 5e-3;
T_sigma_n = T_cl_i + T_on;

h = 5;

tau_n = h * T_sigma_n;
Kp_n = J_sys * beta / (alpha * Kt * (h+1) * T_sigma_n) * (2*pi/60);
Ki_n = Kp_n / tau_n;

ctrl.Kp_n = Kp_n;
ctrl.Ki_n = Ki_n;

fprintf('转速环小时间常数 T_sigma_n = %.4f s\n', T_sigma_n);
fprintf('h 参数 = %d\n', h);
fprintf('PI 零点时间常数 tau_n = h*T_sigma_n = %.4f s\n', tau_n);
fprintf('\n转速环 PI 参数:\n');
fprintf('  Kp_n = %.4f\n', Kp_n);
fprintf('  Ki_n = %.4f\n', Ki_n);
fprintf('  tau_n = %.4f s\n', tau_n);

omega_cn = 1 / ((h+1) * T_sigma_n);
f_cn = omega_cn / (2*pi);
fprintf('\n转速环截止频率: omegac_n = %.1f rad/s (f = %.1f Hz)\n', omega_cn, f_cn);

%% ==================== 6. Bode 图分析 ====================

fprintf('\n--- 绘制 Bode 图验证稳定性 ---\n');

s = tf('s');

ACR = Kp_i * (tau_i*s + 1) / (tau_i*s);
G_pwm = Ks / (Tpwm*s + 1);
G_oi = 1 / (T_oi*s + 1);
G_elec = 1 / (Ra * (Tl*s + 1));
W_open_i = ACR * G_pwm * G_elec * beta;

W_cl_i = feedback(ACR * G_pwm * G_elec, beta);

ASR = Kp_n * (tau_n*s + 1) / (tau_n*s);
G_on = 1 / (T_on*s + 1);
G_mech = Kt / (J_sys * s);
W_open_n = ASR * G_on * W_cl_i * G_mech * alpha;

figure('Name', '双闭环 Bode 图分析', 'Position', [100 100 1200 800]);

subplot(2,2,1);
margin(W_open_i);
title('电流环开环 Bode 图');
grid on;

subplot(2,2,2);
W_cl_i_full = feedback(W_open_i, 1);
step(W_cl_i_full);
title('电流环闭环阶跃响应');
grid on;

subplot(2,2,3);
margin(W_open_n);
title('转速环开环 Bode 图');
grid on;

subplot(2,2,4);
W_cl_n = feedback(W_open_n, 1);
step(W_cl_n);
title('转速环闭环阶跃响应');
grid on;

fig_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end
saveas(gcf, fullfile(fig_dir, 'bode_analysis.png'));
fprintf('Bode 图已保存到 figures/bode_analysis.png\n');

%% ==================== 7. 稳定性指标 ====================

fprintf('\n--- 稳定性指标 ---\n');

[Gm_i, Pm_i, Wcg_i, Wcp_i] = margin(W_open_i);
fprintf('电流环:\n');
fprintf('  增益裕度: %.2f dB (at %.1f rad/s)\n', 20*log10(Gm_i), Wcg_i);
fprintf('  相位裕度: %.1f deg (at %.1f rad/s)\n', Pm_i, Wcp_i);

[Gm_n, Pm_n, Wcg_n, Wcp_n] = margin(W_open_n);
fprintf('转速环:\n');
fprintf('  增益裕度: %.2f dB (at %.1f rad/s)\n', 20*log10(Gm_n), Wcg_n);
fprintf('  相位裕度: %.1f deg (at %.1f rad/s)\n', Pm_n, Wcp_n);

if Pm_i >= 45
    fprintf('\n[OK] 电流环相位裕度 %.1f deg >= 45 deg\n', Pm_i);
else
    fprintf('\n[警告] 电流环相位裕度 %.1f deg < 45 deg，需调整\n', Pm_i);
end

if Pm_n >= 30
    fprintf('[OK] 转速环相位裕度 %.1f deg >= 30 deg\n', Pm_n);
else
    fprintf('[警告] 转速环相位裕度 %.1f deg < 30 deg，需调整\n', Pm_n);
end

%% ==================== 8. 参数汇总输出 ====================

fprintf('\n========================================\n');
fprintf(' 控制器参数汇总（供 Simulink 使用）\n');
fprintf('========================================\n');
fprintf('电流环 PI:\n');
fprintf('  Kp_i = %.6f\n', ctrl.Kp_i);
fprintf('  Ki_i = %.6f\n', ctrl.Ki_i);
fprintf('  tau_i = %.6f s\n', tau_i);
fprintf('  电流限幅 = +/-%.1f A\n', ctrl.I_max);
fprintf('转速环 PI:\n');
fprintf('  Kp_n = %.6f\n', ctrl.Kp_n);
fprintf('  Ki_n = %.6f\n', ctrl.Ki_n);
fprintf('  tau_n = %.6f s\n', tau_n);
fprintf('反馈系数:\n');
fprintf('  beta (电流) = %.4f V/A\n', ctrl.beta);
fprintf('  alpha (速度) = %.6f V/rpm\n', ctrl.alpha);
fprintf('滤波时间常数:\n');
fprintf('  T_oi (电流滤波) = %.2e s\n', T_oi);
fprintf('  T_on (转速滤波) = %.2e s\n', T_on);
fprintf('PWM:\n');
fprintf('  频率 = %.0f Hz\n', ctrl.f_pwm);
fprintf('  增益 Ks = %.2f\n', Ks);
fprintf('========================================\n');
