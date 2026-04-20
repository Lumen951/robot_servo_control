%% run_simulation.m - 6种工况仿真批量运行脚本
% 差速驱动轮系统 - 6种典型工况仿真
%
% 使用方法:
%   方式1(自动): 直接运行本脚本，自动逐工况仿真
%   方式2(手动): 按参数表手动改模型参数，逐个点Run，每跑完一个运行 save_case(k)
%
% 依赖: main_params.m, controller_design.m, sim_model.slx

clear; clc; close all;
fprintf('========================================\n');
fprintf(' 差速驱动轮系统 - 6种工况仿真\n');
fprintf('========================================\n\n');

%% ==================== 0. 加载参数 ====================
fprintf('--- 加载系统参数 ---\n');
main_params;
fprintf('\n--- 运行控制器设计 ---\n');
controller_design;

%% ==================== 1. 仿真参数设置 ====================
sim_time = 5;
model_name = 'sim_model';

if ~exist([model_name '.slx'], 'file') && ~exist([model_name '.mdl'], 'file')
    error('Simulink model %s does not exist! Please build it first.', model_name);
end

results = struct();

%% ==================== 2. 工况参数表 ====================
% 每个工况: 转速指令(n_ref), 负载转矩(T_load), 扰动
% 转矩为折算到电机轴的值

cases = struct();

% --- 工况1: 空载启动（平路）---
cases(1).name     = 'Case 1: No-load Start (Flat)';
cases(1).tag      = 'case1_noload_start';
cases(1).n_final  = n_motor_high;
cases(1).T_load   = T_w_flat / (i_gear * eta_gear);
cases(1).T_dist_t = 999;
cases(1).T_dist_v = 0;

% --- 工况2: 额定负载启动（坡道5°）---
cases(2).name     = 'Case 2: Full-load Start (Slope)';
cases(2).tag      = 'case2_fullload_start';
cases(2).n_final  = n_motor_high;
cases(2).T_load   = T_w_slope / (i_gear * eta_gear);
cases(2).T_dist_t = 999;
cases(2).T_dist_v = 0;

% --- 工况3: 低速靠站→通道巡航切换 ---
cases(3).name     = 'Case 3: Low-to-High Speed Switch';
cases(3).tag      = 'case3_speed_switch';
cases(3).n_final  = n_motor_high;
cases(3).T_load   = T_w_flat / (i_gear * eta_gear);
cases(3).T_dist_t = 999;
cases(3).T_dist_v = 0;
cases(3).is_switch = true;
cases(3).n_low    = n_motor_low;
cases(3).t_switch = 2.0;

% --- 工况4: 正转→反转切换 ---
cases(4).name     = 'Case 4: Forward-to-Reverse';
cases(4).tag      = 'case4_forward_reverse';
cases(4).n_final  = -n_motor_high;
cases(4).T_load   = T_w_flat / (i_gear * eta_gear);
cases(4).T_dist_t = 999;
cases(4).T_dist_v = 0;
cases(4).is_reverse = true;
cases(4).n_init   = n_motor_high;

% --- 工况5: 坡道下行制动 ---
cases(5).name     = 'Case 5: Downhill Braking';
cases(5).tag      = 'case5_downhill_brake';
cases(5).n_final  = 0;
cases(5).T_load   = T_w_down / (i_gear * eta_gear);
cases(5).T_dist_t = 999;
cases(5).T_dist_v = 0;
cases(5).is_brake = true;

% --- 工况6: 20%负载扰动 ---
cases(6).name     = 'Case 6: 20%% Load Disturbance';
cases(6).tag      = 'case6_disturbance';
cases(6).n_final  = n_motor_high;
cases(6).T_load   = T_w_slope / (i_gear * eta_gear);
cases(6).T_dist_t = 2.5;
cases(6).T_dist_v = 0.2 * T_w_slope / (i_gear * eta_gear);

num_cases = length(cases);

%% ==================== 3. 参数表输出 ====================
fprintf('\nTotal %d cases:\n\n', num_cases);
fprintf('%-4s %-30s | %-12s | %-12s | %-10s\n', ...
    'No.', 'Case', 'n_ref[rpm]', 'T_load[Nm]', 'Note');
fprintf('%s\n', repmat('-', 1, 80));
for k = 1:num_cases
    note = '';
    if cases(k).is_switch, note = 'switch'; end
    if cases(k).is_reverse, note = 'reverse'; end
    if cases(k).is_brake, note = 'braking'; end
    fprintf('%-4d %-30s | %12.1f | %12.4f | %s\n', k, cases(k).name, ...
        cases(k).n_final, cases(k).T_load, note);
end

fprintf('\n============================================\n');
fprintf(' MANUAL SIMULATION MODE\n');
fprintf('============================================\n');
fprintf('\nFor each case:\n');
fprintf('1. Set n_ref, T_load, T_disturbance in Simulink model\n');
fprintf('2. Click Run\n');
fprintf('3. After simulation: save_case(%d)\n', 0);
fprintf('4. Repeat for next case\n');

%% Print parameter settings table
fprintf('\n============================================\n');
fprintf(' PARAMETER SETTINGS TABLE\n');
fprintf('============================================\n');
fprintf('%-4s %-10s | %-10s | %-10s | %-10s | %-10s\n', ...
    'No.', 'Tag', 'n_final', 'T_load', 'dist_time', 'dist_val');
fprintf('%s\n', repmat('-', 1, 70));
for k = 1:num_cases
    fprintf('%-4d %-10s | %10.1f | %10.4f | %10.1f | %10.4f\n', ...
        k, cases(k).tag, cases(k).n_final, cases(k).T_load, ...
        cases(k).T_dist_t, cases(k).T_dist_v);
end

%% Save cases config
save('cases_config.mat', 'cases', 'num_cases', 'sim_time');
fprintf('\nCase config saved to cases_config.mat\n');

%% ==================== 4. save_case 辅助函数 ==================

function save_case(k)
    if ~exist('sim_time', 'var') || ~exist('sim_speed', 'var')
        error('Simulation data not found! Run the Simulink model first.');
    end

    results(k).time    = sim_time;
    results(k).speed   = sim_speed;
    results(k).current = sim_current;
    results(k).torque  = sim_torque;
    results(k).name    = cases(k).name;
    results(k).tag     = cases(k).tag;

    assignin('base', 'results', results);

    fprintf('[OK] Case %d (%s) saved.\n', k, cases(k).name);
    fprintf('     Speed range: %.1f ~ %.1f rpm\n', min(sim_speed), max(sim_speed));
    fprintf('     Current range: %.2f ~ %.2f A\n', min(sim_current), max(sim_current));
end

fprintf('\n========================================\n');
fprintf(' After completing all 6 cases, run:\n');
fprintf('   plot_results\n');
fprintf('========================================\n');
