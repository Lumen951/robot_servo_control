%% efficiency_analysis.m - 效率与损耗分析
% 对应设计任务 3.3：效率与损耗分析（2分）
%
% 功能：
%   1. 分析 BLDC 电机铜耗、铁耗
%   2. 分析三相逆变器 MOSFET 导通损耗与开关损耗
%   3. 分析减速器机械传动损耗
%   4. 对比回馈制动与能耗制动的能量利用率
%   5. 提出降损措施
%
% 依赖: main_params.m（需先运行）

%% 检查参数是否已加载
if ~exist('motor', 'var')
    fprintf('正在加载系统参数...\n');
    main_params;
end

fprintf('\n========================================\n');
fprintf(' 差速驱动轮系统效率与损耗分析\n');
fprintf('========================================\n');

%% ==================== 1. 电机损耗分析 ====================

fprintf('\n--- 1. BLDC 电机损耗 ---\n');

I_rated = motor.I_rated;
Ra_val  = motor.Ra;
omega_rated = n_motor_high * 2*pi / 60;

% 铜耗
P_cu = I_rated^2 * Ra_val;
fprintf('铜耗 P_Cu = I^2*R = %.1f^2 * %.3f = %.2f W\n', I_rated, Ra_val, P_cu);

% 铁耗（磁滞 + 涡流，占额定功率 2-5%）
k_fe = 0.03;
P_fe = k_fe * motor.P_rated;
fprintf('铁耗 P_Fe = %.0f%% * P_rated = %.2f W\n', k_fe*100, P_fe);

% 机械损耗（轴承摩擦、风阻）
P_mech_loss = motor.B_visc * omega_rated^2;
fprintf('机械损耗 P_mech = B*w^2 = %.2f W\n', P_mech_loss);

P_motor_loss = P_cu + P_fe + P_mech_loss;
T_load_motor = T_w_slope / (i_gear * eta_gear);
P_motor_out  = T_load_motor * omega_rated;
P_motor_in   = P_motor_out + P_motor_loss;
eta_motor    = P_motor_out / P_motor_in * 100;

fprintf('\n电机损耗汇总:\n');
fprintf('  铜耗:     %.2f W (%.1f%%)\n', P_cu, P_cu/P_motor_in*100);
fprintf('  铁耗:     %.2f W (%.1f%%)\n', P_fe, P_fe/P_motor_in*100);
fprintf('  机械损耗: %.2f W (%.1f%%)\n', P_mech_loss, P_mech_loss/P_motor_in*100);
fprintf('  ─────────────────────\n');
fprintf('  总损耗:   %.2f W\n', P_motor_loss);
fprintf('  输出功率: %.2f W\n', P_motor_out);
fprintf('  输入功率: %.2f W\n', P_motor_in);
fprintf('  电机效率: %.1f%%\n', eta_motor);

%% ==================== 2. 功率器件损耗分析 ====================

fprintf('\n--- 2. 三相逆变器 MOSFET 损耗 ---\n');

% MOSFET 参数（48V 系统选型）
mos.Rds_on  = 0.010;
mos.t_rise  = 20e-9;
mos.t_fall  = 15e-9;
mos.Qg      = 50e-9;
mos.Vgs     = 10;
mos.num     = 6;  % 三相全桥6个 MOSFET

f_sw = ctrl.f_pwm;

% 导通损耗（三相桥，同一时刻2个管子导通）
P_cond_per = I_rated^2 * mos.Rds_on;
P_cond_total = 2 * P_cond_per;
fprintf('MOSFET 导通损耗:\n');
fprintf('  单管: P_cond = %.3f W\n', P_cond_per);
fprintf('  总导通损耗（2管同时导通）: %.3f W\n', P_cond_total);

% 开关损耗
P_sw_per = 0.5 * V_dc * I_rated * (mos.t_rise + mos.t_fall) * f_sw;
P_sw_total = 2 * P_sw_per;
fprintf('MOSFET 开关损耗:\n');
fprintf('  单管: P_sw = %.3f W\n', P_sw_per);
fprintf('  总开关损耗: %.3f W\n', P_sw_total);

% 栅极驱动损耗
P_gate = mos.num * mos.Qg * mos.Vgs * f_sw;
fprintf('栅极驱动损耗: %.3f W\n', P_gate);

% 续流二极管损耗（体二极管）
V_diode = 0.7;
P_diode = V_diode * I_rated * 0.05;
fprintf('续流二极管损耗: %.3f W\n', P_diode);

P_power_loss = P_cond_total + P_sw_total + P_gate + P_diode;
eta_inverter = (1 - P_power_loss / P_motor_in) * 100;

fprintf('\n逆变器损耗汇总:\n');
fprintf('  导通损耗: %.3f W\n', P_cond_total);
fprintf('  开关损耗: %.3f W\n', P_sw_total);
fprintf('  驱动损耗: %.3f W\n', P_gate);
fprintf('  二极管损耗: %.3f W\n', P_diode);
fprintf('  ─────────────────────\n');
fprintf('  总损耗:   %.3f W\n', P_power_loss);
fprintf('  逆变器效率: %.1f%%\n', eta_inverter);

%% ==================== 3. 机械传动损耗 ====================

fprintf('\n--- 3. 减速器机械传动损耗 ---\n');

v_cruise = omega_rated * r_wheel / i_gear;
P_wheel_out = F_total_up * v_cruise;       % 轮端输出功率（每轮）
P_gear_in   = P_wheel_out / eta_gear;       % 减速器输入功率
P_trans_loss = P_gear_in - P_wheel_out;

fprintf('轮端输出功率（坡道巡航）: %.2f W\n', P_wheel_out);
fprintf('减速器输入功率:         %.2f W\n', P_gear_in);
fprintf('减速器损耗:             %.2f W\n', P_trans_loss);
fprintf('减速器效率:             %.1f%%\n', eta_gear*100);

%% ==================== 4. 系统总效率 ====================

fprintf('\n--- 4. 系统总效率 ---\n');

P_dc_in = P_motor_in + P_power_loss;
eta_system = P_wheel_out / P_dc_in * 100;

fprintf('\n功率流向（额定工况: 坡道巡航，单轮）:\n');
fprintf('  直流母线输入:   %.2f W (100%%)\n', P_dc_in);
fprintf('  -> 逆变器损耗:  %.2f W (%.1f%%)\n', P_power_loss, P_power_loss/P_dc_in*100);
fprintf('  -> 电机输入:    %.2f W (%.1f%%)\n', P_motor_in, P_motor_in/P_dc_in*100);
fprintf('     -> 电机损耗: %.2f W (%.1f%%)\n', P_motor_loss, P_motor_loss/P_dc_in*100);
fprintf('     -> 机械输出: %.2f W (%.1f%%)\n', P_motor_out, P_motor_out/P_dc_in*100);
fprintf('        -> 减速器损耗: %.2f W (%.1f%%)\n', P_trans_loss, P_trans_loss/P_dc_in*100);
fprintf('        -> 轮端输出:   %.2f W (%.1f%%)\n', P_wheel_out, P_wheel_out/P_dc_in*100);
fprintf('\n系统总效率: eta_sys = %.1f%%\n', eta_system);
fprintf('链路: 逆变器(%.1f%%) x 电机(%.1f%%) x 减速器(%.1f%%) = %.1f%%\n', ...
    eta_inverter, eta_motor, eta_gear*100, ...
    eta_inverter*eta_motor/100*eta_gear);

%% ==================== 5. 制动方式能量分析 ====================

fprintf('\n--- 5. 坡道下行制动能量分析 ---\n');

% 坡道下行一个完整行程的能量
E_slope = m_robot * g * sin(deg2rad(theta_max)) * r_wheel * 2*pi * n_high;
fprintf('坡道下行时的能量流向:\n');
fprintf('  重力做功功率（单轮）: %.2f W\n', F_slope * v_cruise);
fprintf('  摩擦消耗功率:        %.2f W\n', F_roll_slope * v_cruise);
fprintf('  净回馈功率:          %.2f W\n', (F_slope - F_roll_slope) * v_cruise);

fprintf('\n制动方式对比:\n');
fprintf('  维度         | 回馈制动              | 能耗制动\n');
fprintf('  ─────────────────────────────────────────────\n');
fprintf('  能量回收     | 回充到48V母线          | 全部转化为热量\n');
fprintf('  电路复杂度   | 需制动斩波器+电阻防过压 | 仅需制动电阻\n');
fprintf('  适用场景     | 频繁坡道运行           | 偶尔制动\n');
fprintf('  推荐方案     | 优先回馈+制动电阻保护  | 低成本场景\n');

%% ==================== 6. 降损措施建议 ====================

fprintf('\n--- 6. 降损措施建议 ---\n');
fprintf('1. 选用低 Rds(on) MOSFET，降低逆变器导通损耗\n');
fprintf('2. 合理选择 PWM 频率（10-20kHz），平衡纹波与开关损耗\n');
fprintf('3. 坡道下行采用回馈制动，提高能量利用率\n');
fprintf('4. 选用高效率行星齿轮减速器（eta>0.92）\n');
fprintf('5. BLDC 电机效率优于有刷电机，长期运行节省能量\n');
fprintf('6. 轻量化设计降低整车质量，减小加速和爬坡能耗\n');

%% ==================== 7. 损耗汇总表 ====================

fprintf('\n========================================\n');
fprintf(' 损耗汇总表（额定工况，单轮）\n');
fprintf('========================================\n');

loss_items = {'电机铜耗', '电机铁耗', '电机机械损耗', ...
              'MOSFET导通损耗', 'MOSFET开关损耗', '驱动+二极管损耗', ...
              '减速器损耗'};
loss_values = [P_cu, P_fe, P_mech_loss, ...
               P_cond_total, P_sw_total, P_gate+P_diode, ...
               P_trans_loss];

P_total_loss = sum(loss_values);

fprintf('%-20s | %8s | %8s\n', '损耗项', '功率[W]', '占比');
fprintf('%s\n', repmat('-', 1, 42));
for i = 1:length(loss_items)
    fprintf('%-20s | %8.3f | %5.1f%%\n', ...
        loss_items{i}, loss_values(i), loss_values(i)/P_total_loss*100);
end
fprintf('%s\n', repmat('-', 1, 42));
fprintf('%-20s | %8.3f | %5.1f%%\n', '总损耗', P_total_loss, 100);
fprintf('%-20s | %8.3f |\n', '有效输出', P_wheel_out);
fprintf('%-20s | %7.1f%%|\n', '系统总效率', eta_system);
fprintf('========================================\n');

%% ==================== 8. 绘制损耗分布图 ====================

fig_loss = figure('Name', '损耗分布', 'Position', [100 100 800 400], 'Visible', 'off');

subplot(1,2,1);
pie(loss_values, loss_items);
title('损耗分布');

subplot(1,2,2);
categories = {'逆变器', '电机', '减速器'};
cat_values = [P_cond_total+P_sw_total+P_gate+P_diode, ...
              P_cu+P_fe+P_mech_loss, ...
              P_trans_loss];
bar(cat_values);
set(gca, 'XTickLabel', categories);
ylabel('损耗 [W]');
title('分类损耗对比');
grid on;

fig_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end
saveas(fig_loss, fullfile(fig_dir, 'loss_analysis.png'));
fprintf('\n损耗分析图已保存到 figures/loss_analysis.png\n');
close(fig_loss);
