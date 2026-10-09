#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if ! command -v openroad >/dev/null 2>&1; then
    echo "ERROR: 未在 PATH 中找到 OpenROAD。" >&2
    exit 1
fi
openroad_command="$(command -v openroad)"

mkdir -p results/pnr reports/pnr

echo "使用 OpenROAD $($openroad_command -version)"
"$openroad_command" -no_init -no_splash -exit scripts/pnr_core.tcl \
    2>&1 | tee reports/pnr/rv32i_core_pnr.log

echo "完成：最终数据库位于 results/pnr/rv32i_core_final.odb"
