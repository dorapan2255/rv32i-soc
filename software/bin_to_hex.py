#!/usr/bin/env python3
"""把little-endian裸二进制转换为$readmemh使用的32-bit字。"""

import argparse
from pathlib import Path


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--size", type=int, required=True)
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()

    data = args.input.read_bytes()
    if args.size % 4 != 0:
        raise SystemExit("memory image大小必须是4的倍数")
    if len(data) > args.size:
        raise SystemExit(
            f"程序为{len(data)}字节，超过Instruction Memory的{args.size}字节"
        )

    padded = data + bytes(args.size - len(data))
    words = [
        int.from_bytes(padded[offset : offset + 4], byteorder="little")
        for offset in range(0, args.size, 4)
    ]
    args.output.write_text(
        "".join(f"{word:08x}\n" for word in words), encoding="ascii"
    )


if __name__ == "__main__":
    main()
