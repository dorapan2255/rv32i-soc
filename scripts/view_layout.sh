#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$project_root"

if ! command -v openroad >/dev/null 2>&1; then
    echo "ERROR: 未在 PATH 中找到 OpenROAD。" >&2
    exit 1
fi
openroad_command="$(command -v openroad)"

exec "$openroad_command" -gui -no_init scripts/view_layout.tcl
