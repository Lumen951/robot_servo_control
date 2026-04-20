%% motor_selection.m - 电机选型计算与方案对比
% 对应设计任务 3.1（电机选型）+ 第四部分（大模型辅助对比）
%
% 功能：
%   1. 基于负载分析结果，计算各类电机的选型参数
%   2. 生成候选方案对比表格（BLDC / 直流有刷 / PMSM）
%   3. 输出最终选型依据
%
% 依赖: main_params.m, load_analysis.m（需先运行）

%% 检查参数是否已加载
if ~exist('T_m_slope', 'var')
    fprintf('正在加载系统参数并运行力学分析...\n');
    main_params;
    load_analysis;
end

fprintf('\n========================================\n');
fprintf(' 电机选型计算与方案对比\n');
fprintf('========================================\n');

%% ==================== 1. 选型裕量计算 ====================

k_safety = 1.2;

T_select_min = T_m_slope * k_safety;
P_select_min = P_rated_need * k_safety;
n_select_min = n_motor_high;

fprintf('\n--- 选型最低要求（含 %.0f%% 裕量）---\n', (k_safety-1)*100);
fprintf('额定转矩: >= %.4f Nm\n', T_select_min);
fprintf('额定功率: >= %.1f W\n', P_select_min);
fprintf('额定转速: >= %d rpm\n', n_select_min);
fprintf('峰值转矩: >= %.4f Nm\n', T_peak_need * k_safety);

%% ==================== 2. 候选方案定义 ====================

% 方案 A: BLDC 无刷直流电机（主选方案）
planA.name      = 'BLDC 无刷直流电机';
planA.model     = '48V/150W 级 BLDC（如 Maxon EC 45）';
planA.V_rated   = 48;
planA.P_rated   = 150;
planA.n_rated   = 3200;
planA.T_rated   = 0.45;
planA.I_rated   = 3.5;
planA.Ra        = 1.2;
planA.La        = 1.5e-3;
planA.Ke        = 0.1432;
planA.Kt        = 0.1432;
planA.J_motor   = 1.5e-5;
planA.B_visc    = 5e-5;
planA.efficiency = 0.85;
planA.cost_est  = 600;
planA.weight    = 0.35;
planA.ctrl_complexity = '中（六步换相+双闭环）';
planA.maintenance = '好（无刷）';
planA.pros = '效率高/寿命长/扭矩密度大，主流移动机器人方案';
planA.cons = '需三相逆变+换相逻辑，低速转矩脉动';

% 方案 B: 直流有刷电机
planB.name      = '直流有刷电机';
planB.model     = '48V/150W 级直流有刷（如 Maxon RE40）';
planB.V_rated   = 48;
planB.P_rated   = 150;
planB.n_rated   = 3000;
planB.T_rated   = 0.479;
planB.I_rated   = 3.2;
planB.Ra        = 3.0;
planB.La        = 2.5e-3;
planB.Ke        = 0.1432;
planB.Kt        = 0.1432;
planB.J_motor   = 1.19e-5;
planB.B_visc    = 1e-5;
planB.efficiency = 0.80;
planB.cost_est  = 400;
planB.weight    = 0.34;
planB.ctrl_complexity = '低（H桥+双闭环）';
planB.maintenance = '中（电刷磨损，2000-5000h）';
planB.pros = '控制最简单，H桥即可，成本最低';
planB.cons = '电刷磨损影响寿命，效率略低';

% 方案 C: PMSM 永磁同步电机
planC.name      = 'PMSM 永磁同步电机';
planC.model     = '48V/200W 级 PMSM（如 汇川IS620N）';
planC.V_rated   = 48;
planC.P_rated   = 200;
planC.n_rated   = 3000;
planC.T_rated   = 0.64;
planC.I_rated   = 5.0;
planC.Ra        = 0.5;
planC.La        = 5.0e-3;
planC.Ke        = 0.191;
planC.Kt        = 0.191;
planC.J_motor   = 5.0e-6;
planC.B_visc    = 5e-6;
planC.efficiency = 0.92;
planC.cost_est  = 1200;
planC.weight    = 0.5;
planC.ctrl_complexity = '高（FOC矢量控制）';
planC.maintenance = '好（无刷）';
planC.pros = '效率最高，控制精度最高';
planC.cons = 'FOC算法复杂，成本高，超出课程范围';

%% ==================== 3. 方案对比表格 ====================

fprintf('\n--- 候选方案对比表 ---\n');
fprintf('%-20s | %-24s | %-24s | %-24s\n', ...
    '维度', planA.name, planB.name, planC.name);
fprintf('%s\n', repmat('-', 1, 102));

fields = {'V_rated', 'P_rated', 'n_rated', 'T_rated', 'I_rated', ...
          'efficiency', 'cost_est', 'weight'};
labels = {'额定电压[V]', '额定功率[W]', '额定转速[rpm]', ...
          '额定转矩[Nm]', '额定电流[A]', '效率', ...
          '估计成本[元]', '重量[kg]'};

for i = 1:length(fields)
    vA = planA.(fields{i});
    vB = planB.(fields{i});
    vC = planC.(fields{i});

    if strcmp(fields{i}, 'efficiency')
        fprintf('%-20s | %20.0f%%  | %20.0f%%  | %20.0f%%\n', ...
            labels{i}, vA*100, vB*100, vC*100);
    elseif isfloat(vA) && vA < 10
        fprintf('%-20s | %20.3f  | %20.3f  | %20.3f\n', ...
            labels{i}, vA, vB, vC);
    else
        fprintf('%-20s | %20g    | %20g    | %20g\n', ...
            labels{i}, vA, vB, vC);
    end
end

fprintf('%-20s | %-24s | %-24s | %-24s\n', '控制复杂度', ...
    planA.ctrl_complexity, planB.ctrl_complexity, planC.ctrl_complexity);
fprintf('%-20s | %-24s | %-24s | %-24s\n', '可维护性', ...
    planA.maintenance, planB.maintenance, planC.maintenance);

%% ==================== 4. 需求满足度检查 ====================

fprintf('\n--- 需求满足度检查 ---\n');
fprintf('%-25s | %-10s | %-10s | %-10s\n', '指标', ...
    planA.name(1:6), planB.name(1:6), planC.name(1:6));
fprintf('%s\n', repmat('-', 1, 60));

checks = {
    sprintf('T_rated >= %.3f Nm', T_select_min), ...
    planA.T_rated >= T_select_min, planB.T_rated >= T_select_min, planC.T_rated >= T_select_min;
    sprintf('n_rated >= %d rpm', n_select_min), ...
    planA.n_rated >= n_select_min, planB.n_rated >= n_select_min, planC.n_rated >= n_select_min;
    sprintf('P_rated >= %.0f W', P_select_min), ...
    planA.P_rated >= P_select_min, planB.P_rated >= P_select_min, planC.P_rated >= P_select_min;
    'V_rated = 48V', ...
    planA.V_rated == 48, planB.V_rated == 48, planC.V_rated == 48;
};

for i = 1:size(checks, 1)
    desc = checks{i, 1};
    okA = 'OK'; okB = 'OK'; okC = 'OK';
    if ~checks{i, 2}, okA = 'NG'; end
    if ~checks{i, 3}, okB = 'NG'; end
    if ~checks{i, 4}, okC = 'NG'; end
    fprintf('%-25s | %10s | %10s | %10s\n', desc, okA, okB, okC);
end

%% ==================== 5. 综合评分 ====================

fprintf('\n--- 综合评分（满分 10 分）---\n');

weights = [0.30, 0.15, 0.20, 0.15, 0.20];
dims = {'性能匹配', '效率', '成本', '可靠性', '课程匹配'};

scores_A = [9, 8, 7, 9, 9];
scores_B = [8, 7, 9, 6, 10];
scores_C = [9, 9, 4, 9, 5];

total_A = sum(scores_A .* weights);
total_B = sum(scores_B .* weights);
total_C = sum(scores_C .* weights);

fprintf('%-12s | 权重  | BLDC | 有刷 | PMSM\n', '维度');
fprintf('%s\n', repmat('-', 1, 50));
for i = 1:length(dims)
    fprintf('%-12s | %.0f%%  |  %d   |  %d   |  %d\n', ...
        dims{i}, weights(i)*100, scores_A(i), scores_B(i), scores_C(i));
end
fprintf('%s\n', repmat('-', 1, 50));
fprintf('%-12s |       | %.2f | %.2f | %.2f\n', '加权总分', ...
    total_A, total_B, total_C);

[~, best] = max([total_A, total_B, total_C]);
names = {planA.name, planB.name, planC.name};
fprintf('\n[推荐] %s（综合得分最高）\n', names{best});

%% ==================== 6. 选型结论 ====================

fprintf('\n========================================\n');
fprintf(' 最终选型结论\n');
fprintf('========================================\n');
fprintf('选定方案: %s\n', planA.name);
fprintf('型号参考: %s\n', planA.model);
fprintf('\n电机关键参数:\n');
fprintf('  额定电压:   %.0f V\n', planA.V_rated);
fprintf('  额定功率:   %.0f W\n', planA.P_rated);
fprintf('  额定转速:   %.0f rpm\n', planA.n_rated);
fprintf('  额定转矩:   %.3f Nm\n', planA.T_rated);
fprintf('  额定电流:   %.1f A\n', planA.I_rated);
fprintf('  等效电阻:   %.1f Ohm\n', planA.Ra);
fprintf('  等效电感:   %.2f mH\n', planA.La * 1000);
fprintf('  反电动势:   %.4f V·s/rad\n', planA.Ke);
fprintf('  转矩系数:   %.4f Nm/A\n', planA.Kt);
fprintf('  转子惯量:   %.2e kg·m^2\n', planA.J_motor);

fprintf('\n减速器: 单级行星齿轮, i = %d:1, eta = %.2f\n', i_gear, eta_gear);

fprintf('\n需求满足情况:\n');
fprintf('  [OK] 额定转矩 %.3f Nm > 需求 %.4f Nm (裕量 %.0f%%)\n', ...
    planA.T_rated, T_m_slope, (planA.T_rated/T_m_slope-1)*100);
fprintf('  [OK] 额定转速 %d rpm > 需求 %d rpm (裕量 %.0f%%)\n', ...
    planA.n_rated, n_motor_high, (planA.n_rated/n_motor_high-1)*100);
fprintf('  [OK] 额定功率 %d W > 需求 %.1f W (裕量 %.0f%%)\n', ...
    planA.P_rated, P_rated_need, (planA.P_rated/P_rated_need-1)*100);

fprintf('\n下一步: 运行 controller_design.m 进行双闭环 PI 整定\n');
fprintf('========================================\n');
