%% generate_ppt_figures.m - 生成PPT展示用高质量分析图表
% 仅使用 MATLAB 原生绘图功能，不生成示意性框图/流程图
% 保存路径: code/figures/

%% 初始化
clear; clc; close all;

fprintf('========================================\n');
fprintf(' 生成PPT展示图表 (MATLAB原生分析图)\n');
fprintf('========================================\n');

% 加载参数
main_params;
load_analysis;

fig_dir = fullfile(fileparts(mfilename('fullpath')), '..', 'figures');
if ~exist(fig_dir, 'dir'), mkdir(fig_dir); end

set(0, 'DefaultAxesFontSize', 12);
set(0, 'DefaultLineLineWidth', 1.5);

%% ==================== 图1: 各工况负载力矩对比 ====================
fprintf('[1/7] 负载力矩对比...\n');
fig1 = figure('Name', '负载力矩对比', 'Position', [100 100 900 500], 'Color', 'w');

categories = {'平路匀速', '坡道上行', '坡道下行'};
T_wheel = [T_w_flat, T_w_slope, T_w_down];
T_motor = [T_w_flat, T_w_slope, T_w_down] / (i_gear * eta_gear);

subplot(1,2,1);
b = bar(T_wheel, 'FaceColor', [0.2 0.4 0.7]);
set(gca, 'XTickLabel', categories);
ylabel('轮端转矩 T_w [Nm]');
title('各工况轮端负载转矩');
grid on;
for i = 1:length(T_wheel)
    text(i, T_wheel(i)+0.05, sprintf('%.2f', T_wheel(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10);
end

subplot(1,2,2);
b = bar(T_motor, 'FaceColor', [0.7 0.3 0.2]);
set(gca, 'XTickLabel', categories);
ylabel('电机轴转矩 T_m [Nm]');
title('折算到电机轴的负载转矩');
grid on;
for i = 1:length(T_motor)
    text(i, T_motor(i)+0.01, sprintf('%.3f', T_motor(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10);
end

sgtitle('负载力矩分析（单轮）', 'FontSize', 14, 'FontWeight', 'bold');

saveas(fig1, fullfile(fig_dir, 'ppt_load_torque_comparison.png'));
close(fig1);

%% ==================== 图2: 减速比选型参数扫描 ====================
fprintf('[2/7] 减速比参数扫描...\n');
fig2 = figure('Name', '减速比选型', 'Position', [100 100 1000 500], 'Color', 'w');

ratios = [5, 8, 10, 12, 15, 20];
T_steady_arr = zeros(size(ratios));
T_peak_arr = zeros(size(ratios));
P_peak_arr = zeros(size(ratios));
n_motor_arr = zeros(size(ratios));

for k = 1:length(ratios)
    i_try = ratios(k);
    n_motor_arr(k) = n_high * i_try;
    T_steady_arr(k) = T_w_slope / (i_try * eta_gear);
    J_load_try = J_wheel / i_try^2;
    J_total_try = J_motor_est + J_gear + J_load_try;
    alpha_m_try = alpha_w_need * i_try;
    T_acc_try = J_total_try * alpha_m_try;
    T_peak_arr(k) = T_steady_arr(k) + T_acc_try;
    omega_m_try = n_motor_arr(k) * 2*pi / 60;
    P_peak_arr(k) = T_peak_arr(k) * omega_m_try;
end

subplot(1,3,1);
plot(ratios, T_steady_arr, 'b-o', 'LineWidth', 2); hold on;
plot(ratios, T_peak_arr, 'r-s', 'LineWidth', 2);
xlabel('减速比 i'); ylabel('转矩 [Nm]');
title('电机轴转矩需求');
legend('稳态转矩', '峰值转矩', 'Location', 'best');
grid on;
xline(10, 'g--', '选定 10:1', 'LineWidth', 1);

subplot(1,3,2);
plot(ratios, n_motor_arr, 'm-d', 'LineWidth', 2);
xlabel('减速比 i'); ylabel('电机转速 [rpm]');
title('巡航时电机转速');
grid on;
xline(10, 'g--', '选定 10:1', 'LineWidth', 1);
yline(6000, 'k--', '上限 6000 rpm', 'LineWidth', 0.8);

subplot(1,3,3);
plot(ratios, P_peak_arr, 'c-^', 'LineWidth', 2); hold on;
yline(P_peak, 'r--', sprintf('过载上限 %d W', P_peak), 'LineWidth', 1.5);
xlabel('减速比 i'); ylabel('峰值功率 [W]');
title('峰值功率需求');
grid on;
xline(10, 'g--', '选定 10:1', 'LineWidth', 1);

sgtitle('减速比选型论证', 'FontSize', 14, 'FontWeight', 'bold');

saveas(fig2, fullfile(fig_dir, 'ppt_gear_ratio_selection.png'));
close(fig2);

%% ==================== 图3: 电机方案参数对比柱状图 ====================
fprintf('[3/7] 电机方案参数对比...\n');
fig3 = figure('Name', '电机方案对比', 'Position', [100 100 1100 600], 'Color', 'w');

% 三种方案的参数
names = {'BLDC', 'DC Brushed', 'PMSM'};
T_rated = [0.45, 0.479, 0.64];
n_rated = [3200, 3000, 3000];
P_rated = [150, 150, 200];
cost = [600, 400, 1200];

subplot(2,2,1);
b = bar(T_rated, 'FaceColor', [0.2 0.5 0.8]); hold on;
yline(T_m_slope, 'r--', sprintf('需求 %.3f Nm', T_m_slope), 'LineWidth', 1.5);
set(gca, 'XTickLabel', names);
ylabel('额定转矩 [Nm]');
title('额定转矩对比');
grid on;
for i = 1:length(T_rated)
    text(i, T_rated(i)+0.01, sprintf('%.3f', T_rated(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10);
end

subplot(2,2,2);
b = bar(n_rated, 'FaceColor', [0.8 0.4 0.2]); hold on;
yline(n_motor_high, 'r--', sprintf('需求 %d rpm', n_motor_high), 'LineWidth', 1.5);
set(gca, 'XTickLabel', names);
ylabel('额定转速 [rpm]');
title('额定转速对比');
grid on;
for i = 1:length(n_rated)
    text(i, n_rated(i)+50, sprintf('%d', n_rated(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10);
end

subplot(2,2,3);
b = bar(P_rated, 'FaceColor', [0.4 0.7 0.3]); hold on;
yline(P_rated_need, 'r--', sprintf('需求 %.0f W', P_rated_need), 'LineWidth', 1.5);
set(gca, 'XTickLabel', names);
ylabel('额定功率 [W]');
title('额定功率对比');
grid on;
for i = 1:length(P_rated)
    text(i, P_rated(i)+5, sprintf('%d', P_rated(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10);
end

subplot(2,2,4);
b = bar(cost, 'FaceColor', [0.6 0.3 0.6]);
set(gca, 'XTickLabel', names);
ylabel('估计成本 [元]');
title('成本对比');
grid on;
for i = 1:length(cost)
    text(i, cost(i)+30, sprintf('%d', cost(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10);
end

sgtitle('三种电机方案关键参数对比', 'FontSize', 14, 'FontWeight', 'bold');

saveas(fig3, fullfile(fig_dir, 'ppt_motor_comparison.png'));
close(fig3);

%% ==================== 图4: 综合评分对比 ====================
fprintf('[4/7] 综合评分对比...\n');
fig4 = figure('Name', '综合评分', 'Position', [100 100 900 500], 'Color', 'w');

dims = {'性能匹配', '效率', '成本', '可靠性', '课程匹配'};
scores_A = [9, 8, 7, 9, 9];   % BLDC
scores_B = [8, 7, 9, 6, 10];  % 直流有刷
scores_C = [9, 9, 4, 9, 5];   % PMSM

subplot(1,2,1);
X = categorical(dims);
X = reordercats(X, dims);
data = [scores_A; scores_B; scores_C]';
b = bar(X, data);
b(1).FaceColor = [0.2 0.5 0.8];
b(2).FaceColor = [0.8 0.4 0.2];
b(3).FaceColor = [0.4 0.7 0.3];
ylabel('评分（满分10分）');
title('各维度评分对比');
legend('BLDC', 'DC Brushed', 'PMSM', 'Location', 'best');
grid on;
ylim([0 11]);

subplot(1,2,2);
weights = [0.30, 0.15, 0.20, 0.15, 0.20];
total_A = sum(scores_A .* weights);
total_B = sum(scores_B .* weights);
total_C = sum(scores_C .* weights);
totals = [total_A, total_B, total_C];
b = bar(totals);
b.FaceColor = 'flat';
b.CData = [0.2 0.5 0.8; 0.8 0.4 0.2; 0.4 0.7 0.3];
set(gca, 'XTickLabel', names);
ylabel('加权总分（满分10分）');
title('综合评分加权总分');
grid on;
for i = 1:length(totals)
    text(i, totals(i)+0.1, sprintf('%.2f', totals(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
end
ylim([0 10]);

sgtitle('电机方案综合评分', 'FontSize', 14, 'FontWeight', 'bold');

saveas(fig4, fullfile(fig_dir, 'ppt_motor_scoring.png'));
close(fig4);

%% ==================== 图5: 系统效率链路分析 ====================
fprintf('[5/7] 效率链路分析...\n');
fig5 = figure('Name', '效率链路', 'Position', [100 100 900 500], 'Color', 'w');

% 计算各环节效率
eta_inverter = 99.5;  % 逆变器效率
eta_motor = 78.8;     % 电机效率
eta_gear = 90.0;      % 减速器效率
eta_total = eta_inverter * eta_motor / 100 * eta_gear / 100;

% 瀑布图/阶梯图展示效率链路
categories_eff = {'逆变器', '电机', '减速器', '总效率'};
efficiencies = [eta_inverter, eta_motor, eta_gear, eta_total];
colors_eff = [0.3 0.6 0.9; 0.9 0.5 0.3; 0.5 0.8 0.4; 0.8 0.3 0.6];

subplot(1,2,1);
b = bar(efficiencies, 'FaceColor', 'flat');
for k = 1:length(efficiencies)
    b.CData(k,:) = colors_eff(k,:);
end
set(gca, 'XTickLabel', categories_eff);
ylabel('效率 [%]');
title('各环节效率对比');
grid on;
for i = 1:length(efficiencies)
    text(i, efficiencies(i)+1, sprintf('%.1f%%', efficiencies(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
end
ylim([0 105]);

subplot(1,2,2);
% 级联效率图
x = [1, 2, 3, 4];
y_cascade = [100, 100*eta_inverter/100, 100*eta_inverter/100*eta_motor/100, eta_total];
plot(x, y_cascade, 'b-o', 'LineWidth', 2, 'MarkerSize', 8); hold on;
fill([x, fliplr(x)], [y_cascade, zeros(size(y_cascade))], [0.8 0.9 1], 'FaceAlpha', 0.5);
set(gca, 'XTick', x, 'XTickLabel', {'输入', '逆变器后', '电机后', '减速器后'});
ylabel('剩余效率 [%]');
title('效率级联衰减图');
grid on;
for i = 1:length(y_cascade)
    text(x(i), y_cascade(i)+2, sprintf('%.1f%%', y_cascade(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10);
end
ylim([0 110]);

sgtitle('系统效率链路分析（额定工况）', 'FontSize', 14, 'FontWeight', 'bold');

saveas(fig5, fullfile(fig_dir, 'ppt_efficiency_chain.png'));
close(fig5);

%% ==================== 图6: 损耗分布饼图 ====================
fprintf('[6/7] 损耗分布...\n');
fig6 = figure('Name', '损耗分布', 'Position', [100 100 900 400], 'Color', 'w');

% 基于 efficiency_analysis.m 的数值
loss_items = {'电机铜耗', '电机铁耗', '机械损耗', 'MOSFET损耗', '驱动+二极管', '减速器损耗'};
loss_values = [14.70, 4.50, 5.48, 0.36, 0.18, 9.16];

subplot(1,2,1);
pie(loss_values, loss_items);
title('损耗分布饼图');

subplot(1,2,2);
categories_loss = {'逆变器', '电机', '减速器'};
cat_values = [0.36+0.18, 14.70+4.50+5.48, 9.16];
b = bar(cat_values);
b.FaceColor = 'flat';
b.CData = [0.3 0.6 0.9; 0.9 0.5 0.3; 0.5 0.8 0.4];
set(gca, 'XTickLabel', categories_loss);
ylabel('损耗 [W]');
title('分类损耗对比');
grid on;
for i = 1:length(cat_values)
    text(i, cat_values(i)+0.5, sprintf('%.2f W', cat_values(i)), ...
        'HorizontalAlignment', 'center', 'FontSize', 10);
end

sgtitle('系统损耗分析（额定工况，单轮）', 'FontSize', 14, 'FontWeight', 'bold');

saveas(fig6, fullfile(fig_dir, 'ppt_loss_distribution.png'));
close(fig6);

%% ==================== 图7: 关键参数汇总表（数值展示）====================
fprintf('[7/7] 关键参数汇总...\n');
fig7 = figure('Name', '参数汇总', 'Position', [100 100 700 600], 'Color', 'w');
axis([0 10 0 10]);
axis off;
hold on;

% 绘制表格
table_data = {
    '参数', '数值', '单位';
    '整车质量', '50', 'kg';
    '驱动轮半径', '0.08', 'm';
    '最大坡度', '5', '°';
    '减速比', '10', ':1';
    '低速靠站轮速', '64', 'rpm';
    '通道巡航轮速', '316', 'rpm';
    '直流母线电压', '48', 'V';
    '单轮连续功率上限', '150', 'W';
    '电机额定转矩', '0.450', 'Nm';
    '电机额定转速', '3200', 'rpm';
    '电机额定功率', '150', 'W';
    '电流环 Kp', '0.054', '';
    '电流环 Ki', '43.21', '';
    '转速环 Kp', '35.46', '';
    '转速环 Ki', '783.56', '';
    '系统总效率', '70.6', '%';
};

col_widths = [3.5, 2.5, 1.5];
row_height = 0.5;
start_y = 8.5;
start_x = 1.5;

for row = 1:size(table_data, 1)
    y = start_y - (row-1) * row_height;
    x = start_x;
    for col = 1:size(table_data, 2)
        % 绘制单元格边框
        rectangle('Position', [x, y-row_height, col_widths(col), row_height], ...
            'EdgeColor', [0.5 0.5 0.5], 'FaceColor', 'w', 'LineWidth', 0.5);
        % 文字
        if row == 1
            text(x + col_widths(col)/2, y - row_height/2, table_data{row, col}, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'FontSize', 11, 'FontWeight', 'bold');
        else
            text(x + col_widths(col)/2, y - row_height/2, table_data{row, col}, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'FontSize', 10);
        end
        x = x + col_widths(col);
    end
end

title('差速驱动轮系统关键参数汇总', 'FontSize', 14, 'FontWeight', 'bold');

saveas(fig7, fullfile(fig_dir, 'ppt_param_summary.png'));
close(fig7);

%% ==================== 完成 ====================
fprintf('\n========================================\n');
fprintf(' 所有PPT图表已生成完毕\n');
fprintf(' 保存路径: %s\n', fig_dir);
fprintf('========================================\n');
fprintf('\n生成的图表列表:\n');
fprintf('  1. ppt_load_torque_comparison.png   - 负载力矩对比\n');
fprintf('  2. ppt_gear_ratio_selection.png     - 减速比选型\n');
fprintf('  3. ppt_motor_comparison.png         - 电机参数对比\n');
fprintf('  4. ppt_motor_scoring.png            - 综合评分对比\n');
fprintf('  5. ppt_efficiency_chain.png         - 效率链路分析\n');
fprintf('  6. ppt_loss_distribution.png        - 损耗分布\n');
fprintf('  7. ppt_param_summary.png            - 参数汇总表\n');
fprintf('  8. bode_analysis.png                - Bode图分析\n');
