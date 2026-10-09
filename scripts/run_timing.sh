#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if ! command -v yosys >/dev/null 2>&1; then
    echo "ERROR: 未在 PATH 中找到 Yosys。" >&2
    exit 1
fi
yosys_command="$(command -v yosys)"

if ! command -v sta >/dev/null 2>&1; then
    echo "ERROR: 未在 PATH 中找到 OpenSTA（sta）。" >&2
    exit 1
fi
sta_command="$(command -v sta)"

mkdir -p reports

echo "[1/2] 使用 $($yosys_command -V) 进行 Nangate45 标准单元映射"
"$yosys_command" -Q -l reports/rv32i_core_nangate45_synthesis.log \
    -s scripts/synth_core_nangate45.ys

echo "[2/2] 使用 OpenSTA $($sta_command -version) 进行静态时序分析"
"$sta_command" -no_init -no_splash -exit scripts/sta_core.tcl \
    2>&1 | tee reports/rv32i_core_sta.log

echo "完成：请查看 reports/rv32i_core_nangate45_stats.txt 和 reports/rv32i_core_sta.log"
