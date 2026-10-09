#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if ! command -v yosys >/dev/null 2>&1; then
    echo "ERROR: 未在 PATH 中找到 Yosys。请安装 Yosys 或将其 bin 目录加入 PATH。" >&2
    exit 1
fi
yosys_command="$(command -v yosys)"

mkdir -p reports

echo "Using: $($yosys_command -V)"
"$yosys_command" -Q -l reports/rv32i_core_synthesis.log \
    -s scripts/synth_core.ys

echo
echo "Synthesis completed. Key statistics:"
cat reports/rv32i_core_stats.txt
