%% plot_results.m - 仿真结果绘图脚本
% 差速驱动轮系统 - 6种工况结果绘图
%
% 使用方法:
%   1. 先运行 run_simulation.m 完成所有6个工况仿真
%   2. 每个工况跑完后在命令行运行 save_case(k)
%   3. 全部保存完后直接运行 plot_results

%% 检查数据是否存在
if ~exist('results', 'var') || isempty(results)
    error('Results not found! Run save_case(1) through save_case(6) first.');
end

if length(results) < 6
    error('Only %d cases saved. Need all 6 cases.', length(results));
end

load cases_config;

fprintf('\n========================================\n');
fprintf(' 差速驱动轮系统 - 仿真结果绘图\n');
fprintf('========================================\n');

%% 图片保存路径
fig_path = fullfile(fileparts(mfilename('fullpath')), '..', 'figures');
if ~exist(fig_path, 'dir')
    mkdir(fig_path);
end

%% 全局绘图设置
set(0, 'DefaultAxesFontSize', 11);
set(0, 'DefaultLineLineWidth', 1.2);

%% 计算性能指标函数
function [tr, os, ess, peak] = calc_performance(t, y, ref, threshold_pct)
    if abs(ref) < 1e-6
        ref = max(abs(y));
    end
    idx_10 = find(y >= 0.1*ref, 1);
    idx_90 = find(y >= 0.9*ref, 1);
    if ~isempty(idx_10) && ~isempty(idx_90)
        tr = t(idx_90) - t(idx_10);
    else
        tr = NaN;
    end

    [peak_val, ~] = max(abs(y));
    peak = peak_val;
    steady_idx = find(t > t(end)*0.7, 1):length(t);
    ess_val = mean(y(steady_idx));
    if abs(ess_val) > 1e-6
        os = abs(peak_val - abs(ess_val)) / abs(ess_val) * 100;
        ess = abs(abs(ess_val) - abs(ref)) / abs(ref) * 100;
    else
        os = 0; ess = 0;
    end
end

%% ==================== 1. 每个工况单独绘图 ====================

for k = 1:6
    fprintf('Plotting Case %d: %s\n', k, results(k).name);

    t   = results(k).time;
    n   = results(k).speed;
    ia  = results(k).current;
    Te  = results(k).torque;

    valid_idx = t >= 0;
    t = t(valid_idx); n = n(valid_idx);
    ia = ia(valid_idx); Te = Te(valid_idx);

    % 参考值
    ref_n = n_motor_high;

    % 计算性能指标
    [tr_n, os_n, ess_n, peak_n] = calc_performance(t, n, ref_n, 1);

    % 创建Figure
    fig = figure('Name', sprintf('Case %d: %s', k, results(k).tag), ...
                 'Position', [50 50 1200 800], 'Visible', 'off');

    % --- 子图1: 转速响应 ---
    subplot(3,1,1);
    plot(t, n, 'b-', 'LineWidth', 1.2); hold on;
    plot([0, t(end)], [ref_n, ref_n], 'r--', 'LineWidth', 1);
    ylabel('Speed n [rpm]');
    title(sprintf('Case %d: %s', k, results(k).name), 'FontSize', 12);
    grid on;
    legend('Actual Speed', 'Reference', 'Location', 'best');
    if ~isnan(tr_n)
        text(0.02, 0.85, sprintf('t_r=%.3fs, os=%.1f%%', tr_n, os_n), ...
            'Units', 'normalized', 'FontSize', 9, 'BackgroundColor', 'w');
    end

    % --- 子图2: 电流响应 ---
    subplot(3,1,2);
    plot(t, ia, 'r-', 'LineWidth', 1.2); hold on;
    yline(ctrl.I_max, 'k--', sprintf('I_{max}=%.1fA', ctrl.I_max), 'LineWidth', 0.8);
    yline(-ctrl.I_max, 'k--', 'LineWidth', 0.8);
    ylabel('Current i_a [A]');
    grid on;
    legend('Actual Current', 'Current Limit', 'Location', 'best');

    % --- 子图3: 电磁转矩 ---
    subplot(3,1,3);
    plot(t, Te, 'Color', [0.1 0.5 0.1], 'LineWidth', 1.2); hold on;
    plot([0, t(end)], [0, 0], 'k:', 'LineWidth', 0.5);
    xlabel('Time t [s]');
    ylabel('Torque T_e [Nm]');
    grid on;
    legend('Electromagnetic Torque', 'Zero', 'Location', 'best');

    xlim([0, min(5, t(end))]);

    fname = fullfile(fig_path, sprintf('%s.png', results(k).tag));
    exportgraphics(fig, fname, 'Resolution', 300);
    fprintf('  Saved: %s\n', fname);
    close(fig);
end

%% ==================== 2. 六工况转速对比总图 ====================
fprintf('\nPlotting summary comparison...\n');

fig2 = figure('Name', 'Speed Response Comparison', ...
              'Position', [50 50 1400 900], 'Visible', 'off');

colors = lines(6);
for k = 1:6
    t = results(k).time;
    n = results(k).speed;
    valid_idx = t >= 0;
    subplot(2,3,k);
    plot(t(valid_idx), n(valid_idx), 'Color', colors(k,:), 'LineWidth', 1.2); hold on;
    if k == 4 || k == 5
        plot([0, t(end)], [0, 0], 'r--');
    else
        plot([0, t(end)], [n_motor_high, n_motor_high], 'r--');
    end
    title(sprintf('Case %d', k));
    ylabel('n [rpm]');
    xlabel('t [s]');
    grid on;
    xlim([0, 5]);
end
sgtitle('Speed Response - All 6 Cases', 'FontSize', 14);

fname = fullfile(fig_path, 'all_cases_speed_comparison.png');
exportgraphics(fig2, fname, 'Resolution', 300);
fprintf('  Saved: %s\n', fname);
close(fig2);

%% ==================== 3. 性能指标汇总表 ====================
fprintf('\n========================================\n');
fprintf(' PERFORMANCE METRICS SUMMARY\n');
fprintf('========================================\n');

fprintf('%-4s | %-25s | %-10s | %-10s | %-10s | %-10s\n', ...
    'No.', 'Case', 'RiseTime[s]', 'Overshoot', 'SteadyErr', 'Status');
fprintf('%s\n', repmat('-', 1, 85));

performance = [];
for k = 1:6
    t = results(k).time; n = results(k).speed;
    valid_idx = t >= 0; t = t(valid_idx); n = n(valid_idx);
    ref_n = n_motor_high;

    [tr_k, os_k, ess_k] = calc_performance(t, n, ref_n, 1);

    tr_ok = tr_k <= t_rise_max;
    os_ok = os_k <= overshoot_n * 100;
    if tr_ok && os_ok
        status = 'OK';
    elseif ~tr_ok && ~os_ok
        status = 'FAIL';
    else
        status = 'MARGINAL';
    end

    fprintf('%-4d | %-25s | %10.3f | %9.1f%% | %9.1f%% | %-10s\n', ...
        k, results(k).tag, tr_k, os_k, ess_k, status);

    performance(k).tr = tr_k;
    performance(k).os = os_k;
    performance(k).ess = ess_k;
    performance(k).status = status;
end

%% ==================== 4. 汇总柱状图 ====================
fig3 = figure('Name', 'Performance Metrics', ...
              'Position', [50 50 1400 500], 'Visible', 'off');

subplot(1,3,1);
bar([performance.tr]);
xticklabels(arrayfun(@(k) sprintf('Case%d',k), 1:6, 'UniformOutput', false));
ylabel('Rise Time [s]');
yline(t_rise_max, 'r--', sprintf('Limit=%.1fs', t_rise_max));
title('Rise Time');
grid on;

subplot(1,3,2);
bar([performance.os]);
xticklabels(arrayfun(@(k) sprintf('Case%d',k), 1:6, 'UniformOutput', false));
ylabel('Overshoot [%%]');
yline(overshoot_n*100, 'r--', sprintf('Limit=%.0f%%', overshoot_n*100));
title('Overshoot');
grid on;

subplot(1,3,3);
bar([performance.ess]);
xticklabels(arrayfun(@(k) sprintf('Case%d',k), 1:6, 'UniformOutput', false));
ylabel('Steady-State Error [%%]');
title('Steady-State Error');
grid on;

sgtitle('Performance Metrics Summary', 'FontSize', 14);

fname = fullfile(fig_path, 'performance_metrics_summary.png');
exportgraphics(fig3, fname, 'Resolution', 300);
fprintf('  Saved: %s\n', fname);
close(fig3);

%% ==================== 5. 保存数据 ====================
save(fullfile(fig_path, 'simulation_results.mat'), 'results', 'performance', 'cases');
fprintf('\n========================================\n');
fprintf(' All plots saved to %s\n', fig_path);
fprintf(' Data saved to simulation_results.mat\n');
fprintf('========================================\n');
