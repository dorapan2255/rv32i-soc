#!/usr/bin/env python3
"""确认编译器没有生成当前CPU尚未实现的RISC-V指令。"""

import re
import sys
from pathlib import Path


SUPPORTED = {
    "add", "sub", "and", "or", "xor", "slt",
    "addi", "andi", "ori", "xori", "sll", "srl", "sra",
    "lw", "sw", "beq", "bne", "jal", "jalr", "lui", "auipc",
}


def main() -> None:
    path = Path(sys.argv[1])
    unsupported: list[str] = []
    pattern = re.compile(
        r"^\s*[0-9a-f]+:\s+(?:[0-9a-f]{8}\s+)+([.a-zA-Z0-9_]+)"
    )

    for line in path.read_text(encoding="utf-8").splitlines():
        match = pattern.match(line)
        if not match:
            continue
        mnemonic = match.group(1)
        if mnemonic != ".word" and mnemonic not in SUPPORTED:
            unsupported.append(line.strip())

    if unsupported:
        print("ERROR: 编译器生成了当前CPU不支持的指令：", file=sys.stderr)
        print("\n".join(unsupported), file=sys.stderr)
        raise SystemExit(1)

    print(f"PASS: {path.name}只包含当前CPU支持的指令")


if __name__ == "__main__":
    main()
