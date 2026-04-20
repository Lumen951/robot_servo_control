# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Comprehensive course design for a warehouse sorting robot's **differential drive wheel servo control system** (差速驱动轮电机系统). The project covers the full engineering loop: load analysis, motor selection, drive circuit design, dual-loop controller design, MATLAB/Simulink simulation, and efficiency analysis.

Student ID parameters: AB=04, CD=76. Key derived specs: low-speed docking 64 rpm, cruise 316 rpm, 48V DC bus, 150W continuous per wheel (2x overload for 10s).

## Architecture

The project follows a sequential MATLAB script pipeline — each script depends on the previous one loading variables into the workspace:

```
main_params.m          (all physical/electrical parameters, run first)
  → load_analysis.m    (load mechanics, gear reduction, torque/inertia)
  → motor_selection.m  (BLDC vs DC brushed vs PMSM comparison)
  → controller_design.m (dual-loop PI tuning: current loop type-I, speed loop type-II, Bode plots)
  → run_simulation.m   (6 operating conditions via Simulink sim_model.slx)
  → plot_results.m     (per-condition response curves, performance summary)
  → efficiency_analysis.m (copper/iron/switching losses, regen vs resistive braking)
```

`main_params.m` is the single source of truth for all system parameters.

## Key Design Decisions

- **Transmission**: Single-stage planetary gear reducer, ratio 10:1, efficiency 0.90
- **Motor type**: BLDC (brushless DC), three-phase inverter drive with six-step commutation
- **Equivalent model**: BLDC in two-phase-on mode is equivalent to a DC motor for control design
- **Control**: Speed-current dual closed-loop with PI regulators. Current loop designed as Type-I system (KT=0.5), speed loop as Type-II system (h=5)
- **Anti-windup**: Dual-clamping (integrator + output) to prevent integral saturation overshoot
- **Braking**: Regenerative braking on downhill; brake chopper + resistor on DC bus to prevent overvoltage

## MATLAB Conventions

- All scripts use `fprintf` for structured console output with Chinese labels
- Physical units are SI (m, kg, N, rad/s) internally; display converts to rpm where appropriate
- Figures save to `code/figures/` as PNG at 300 DPI
- Scripts check for prerequisite variables with `if ~exist('varname', 'var')` and auto-run dependencies

## File Encoding

UTF-8. MATLAB R2020a+ supports UTF-8 natively.

## Course Requirements

- 6 mandatory simulation conditions: no-load start, rated-load start (slope), low→high speed switch, forward→reverse, downhill braking, emergency stop
- Each condition must output: speed response, current response, electromagnetic torque response, with rise time / overshoot / steady-state error annotated
- LLM-assisted motor selection requires: full prompt text, raw LLM output, human verification/correction table — stored in `大模型辅助记录/`
