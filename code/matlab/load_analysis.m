%% load_analysis.m - 差速驱动轮系统负载力学分析
% 对应设计任务 3.1：系统力学分析与传动方案设计（2分）
%
% 功能：
%   1. 建立差速驱动轮完整负载模型
%   2. 分析平路/坡道各工况负载力
%   3. 完成轮端到电机轴侧的折算（转矩、转速、惯量）
%   4. 减速比选型论证
%   5. 输出传动方案选择依据
%
% 依赖: main_params.m（需先运行）

%% 检查参数是否已加载
if ~exist('i_gear', 'var')
    fprintf('正在加载系统参数...\n');
    main_params;
end

fprintf('\n========================================\n');
fprintf(' 差速驱动轮系统负载力学分析\n');
fprintf('========================================\n');

%% ==================== 1. 负载模型详细分析 ====================

fprintf('\n--- 1. 各工况负载力详细分析 ---\n');
fprintf('约定: 前进方向为正，两轮平均分担牵引力\n\n');

% 工况表
conditions = {
    '平路匀速',     0,    '平路';
    '坡道上行',     +1,   '坡道5°';
    '坡道下行',     -1,   '坡道5°';
    '平路制动',     0,    '平路';
};

fprintf('%-12s | %-10s | %-10s | %-12s | %-12s | %-10s\n', ...
    '工况', '重力分量[N]', '摩擦力[N]', '每轮负载力[N]', '轮端转矩[Nm]', '说明');
fprintf('%s\n', repmat('-', 1, 80));

% 平路工况
F_g_flat = 0;
F_f_flat = mu_roll * m_robot * g / 2;
F_w_flat = F_f_flat;
fprintf('%-12s | %8.2f  | %8.2f  | %10.2f  | %10.4f  | 稳态巡航\n', ...
    '平路匀速', F_g_flat, F_f_flat, F_w_flat, T_w_flat);

% 坡道上行
F_g_up = F_slope * 2;  % 整车重力分量
F_f_up = F_roll_slope * 2;  % 整车滚动阻力
fprintf('%-12s | %8.2f  | %8.2f  | %10.2f  | %10.4f  | 最恶劣工况\n', ...
    '坡道上行', F_g_up, F_f_up, F_total_up, T_w_slope);

% 坡道下行
fprintf('%-12s | %8.2f  | %8.2f  | %10.2f  | %10.4f  | 重力驱动\n', ...
    '坡道下行', F_g_up, F_f_up, F_total_down, T_w_down);

% 平路制动（紧急停车）
F_brake = m_robot * 0;  % 制动力由控制器决定
fprintf('%-12s | %8.2f  | %8.2f  | %10s  | %10s  | 取决于制动电流\n', ...
    '平路制动', 0, F_f_flat, '---', '---');

%% ==================== 2. 减速比选型论证 ====================

fprintf('\n--- 2. 减速比选型论证 ---\n');

ratios_scan = [5, 8, 10, 12, 15, 20];

fprintf('%-10s | %-10s | %-12s | %-12s | %-12s | %-10s\n', ...
    '减速比', '电机转速', '稳态转矩[Nm]', '峰值转矩[Nm]', '峰值功率[W]', '评价');
fprintf('%s\n', repmat('-', 1, 80));

for k = 1:length(ratios_scan)
    i_try = ratios_scan(k);
    n_m_try = n_high * i_try;
    T_steady = T_w_slope / (i_try * eta_gear);
    J_load_try = J_wheel / i_try^2;
    J_total_try = J_motor_est + J_gear + J_load_try;
    alpha_m_try = alpha_w_need * i_try;
    T_acc_try = J_total_try * alpha_m_try;
    T_peak_try = T_steady + T_acc_try;
    omega_m_try = n_m_try * 2 * pi / 60;
    P_peak_try = T_peak_try * omega_m_try;

    if P_peak_try > P_peak
        eval_str = '功率超限';
    elseif n_m_try > 6000
        eval_str = '转速偏高';
    elseif i_try < 5
        eval_str = '转矩偏大';
    else
        eval_str = '可选';
    end

    fprintf('%6d:1   | %6d rpm | %10.4f  | %10.4f  | %10.1f  | %s\n', ...
        i_try, n_m_try, T_steady, T_peak_try, P_peak_try, eval_str);
end

fprintf('\n选定减速比 i = %d:1\n', i_gear);
fprintf('理由: 使电机工作在高效区间(2000~4000rpm)，且峰值功率在过载范围内\n');

%% ==================== 3. 详细折算计算 ====================

fprintf('\n--- 3. 选定减速比 i=%d:1 的详细折算 ---\n', i_gear);

% 转速折算
fprintf('转速折算:\n');
fprintf('  低速靠站: n_w=%d rpm → n_m=%d rpm\n', n_low, n_motor_low);
fprintf('  通道巡航: n_w=%d rpm → n_m=%d rpm\n', n_high, n_motor_high);
fprintf('  调速范围: D = %.2f:1\n', n_motor_high / n_motor_low);

% 转矩折算
fprintf('\n转矩折算（电机轴侧）:\n');
T_m_flat = T_w_flat / (i_gear * eta_gear);
T_m_slope = T_w_slope / (i_gear * eta_gear);
T_m_down  = T_w_down / (i_gear * eta_gear);
fprintf('  平路稳态: %.4f Nm\n', T_m_flat);
fprintf('  坡道稳态: %.4f Nm (额定工况)\n', T_m_slope);
fprintf('  坡道下行: %.4f Nm (制动工况)\n', T_m_down);

% 惯量折算
fprintf('\n惯量折算:\n');
fprintf('  整车等效到单轮: J_w = %.4f kg·m^2\n', J_wheel);
fprintf('  折算到电机轴:   J_w/i^2 = %.6f kg·m^2\n', J_wheel_motor);
fprintf('  减速器惯量:     J_gear = %.2e kg·m^2\n', J_gear);
fprintf('  电机惯量(估):   J_m = %.2e kg·m^2\n', J_motor_est);
fprintf('  总惯量:         J_total = %.6f kg·m^2\n', J_total_motor);

% 惯量比
J_ratio = J_wheel_motor / J_motor_est;
fprintf('  惯量比(负载/电机): %.1f\n', J_ratio);
if J_ratio > 10
    fprintf('  [注意] 惯量比偏大，控制器设计需适当降低带宽\n');
end

%% ==================== 4. 加速过程详细分析 ====================

fprintf('\n--- 4. 加速过程分析 ---\n');

v_cruise = omega_w_high * r_wheel;
fprintf('最恶劣工况: 坡道 0→%.2f m/s (n_w=%d rpm), t_rise <= %.1f s\n', ...
    v_cruise, n_high, t_rise_max);

fprintf('轮端角加速度: %.2f rad/s^2\n', alpha_w_need);
fprintf('电机端角加速度: %.2f rad/s^2\n', alpha_m_need);
fprintf('加速转矩(电机轴): %.4f Nm\n', T_acc_motor);
fprintf('峰值总转矩(电机轴): %.4f Nm\n', T_peak_need);
fprintf('峰值功率: %.1f W\n', P_peak_need);

%% ==================== 5. 四象限运行分析 ====================

fprintf('\n--- 5. 四象限运行分析 ---\n');
fprintf('象限 | 运行状态       | 转矩方向 | 转速方向 | 能量流向\n');
fprintf('%s\n', repmat('-', 1, 65));
fprintf(' I   | 正转电动(加速) | 正       | 正       | 电源→电机→机械\n');
fprintf(' II  | 正转制动(减速) | 负       | 正       | 机械→电机→电源(回馈)\n');
fprintf(' III | 反转电动(加速) | 负       | 负       | 电源→电机→机械\n');
fprintf(' IV  | 反转制动(减速) | 正       | 负       | 机械→电机→电源(回馈)\n');
fprintf('\n关键工况:\n');
fprintf('  坡道下行制动 → 第 II 象限(正转制动)\n');
fprintf('  正反转切换 → 经历 II/IV 象限制动过程\n');

%% ==================== 6. 需求总结 ====================

fprintf('\n========================================\n');
fprintf(' 电机选型需求总结（单轮）\n');
fprintf('========================================\n');
fprintf('额定转速:     >= %d rpm\n', n_motor_high);
fprintf('额定转矩:     >= %.4f Nm\n', T_m_slope);
fprintf('额定功率:     >= %.1f W\n', P_rated_need);
fprintf('峰值转矩:     >= %.4f Nm (加速工况)\n', T_peak_need);
fprintf('峰值功率:     >= %.1f W (10s 过载)\n', P_peak_need);
fprintf('调速范围:     %.2f:1 (%d~%d rpm)\n', ...
    n_motor_high/n_motor_low, n_motor_low, n_motor_high);
fprintf('供电电压:     %d V DC\n', V_dc);
fprintf('连续功率上限: %d W\n', P_cont);
fprintf('过载能力:     2倍, 10s\n');
fprintf('========================================\n');
