#!/usr/bin/env python3
"""Pixel-level PDF render checks for Maintainiac's PDF quality gate.

The smoke gate already proves Poppler can open and render each sample PDF.
This script goes one step deeper and proves the rendered page has real ink,
multiple colors, and sane dimensions so blank or broken renders cannot pass
just because a PNG file exists.
"""

from __future__ import annotations

import argparse
import struct
import sys
import zlib
from pathlib import Path


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Assert rendered PDF PNG pixels.")
    parser.add_argument("png", type=Path)
    parser.add_argument("--min-width", type=int, default=500)
    parser.add_argument("--min-height", type=int, default=650)
    parser.add_argument("--min-non-white-ratio", type=float, default=0.002)
    parser.add_argument("--min-unique-colors", type=int, default=8)
    parser.add_argument("--max-dark-ratio", type=float, default=0.70)
    return parser.parse_args()


def read_png(path: Path) -> tuple[int, int, list[tuple[int, int, int]]]:
    data = path.read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise ValueError(f"{path} is not a PNG")

    offset = len(PNG_SIGNATURE)
    width = height = bit_depth = color_type = None
    compressed = bytearray()

    while offset < len(data):
        if offset + 8 > len(data):
            raise ValueError(f"{path} has a truncated PNG chunk header")
        length = struct.unpack(">I", data[offset : offset + 4])[0]
        chunk_type = data[offset + 4 : offset + 8]
        chunk_data_start = offset + 8
        chunk_data_end = chunk_data_start + length
        if chunk_data_end + 4 > len(data):
            raise ValueError(f"{path} has a truncated PNG chunk")
        chunk_data = data[chunk_data_start:chunk_data_end]
        offset = chunk_data_end + 4

        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type = struct.unpack(
                ">IIBB", chunk_data[:10]
            )
        elif chunk_type == b"IDAT":
            compressed.extend(chunk_data)
        elif chunk_type == b"IEND":
            break

    if width is None or height is None or bit_depth is None or color_type is None:
        raise ValueError(f"{path} is missing an IHDR chunk")
    if bit_depth != 8 or color_type not in (2, 6):
        raise ValueError(
            f"{path} uses unsupported PNG format: bit_depth={bit_depth}, "
            f"color_type={color_type}"
        )

    channels = 3 if color_type == 2 else 4
    stride = width * channels
    raw = zlib.decompress(bytes(compressed))
    pixels: list[tuple[int, int, int]] = []
    previous = bytearray(stride)
    pos = 0

    for _row in range(height):
        filter_type = raw[pos]
        pos += 1
        scanline = bytearray(raw[pos : pos + stride])
        pos += stride
        unfiltered = _unfilter_scanline(scanline, previous, filter_type, channels)
        previous = unfiltered
        for index in range(0, stride, channels):
            pixels.append((unfiltered[index], unfiltered[index + 1], unfiltered[index + 2]))

    return width, height, pixels


def _unfilter_scanline(
    scanline: bytearray, previous: bytearray, filter_type: int, channels: int
) -> bytearray:
    result = bytearray(scanline)
    for index, value in enumerate(scanline):
        left = result[index - channels] if index >= channels else 0
        up = previous[index]
        upper_left = previous[index - channels] if index >= channels else 0
        if filter_type == 0:
            predictor = 0
        elif filter_type == 1:
            predictor = left
        elif filter_type == 2:
            predictor = up
        elif filter_type == 3:
            predictor = (left + up) // 2
        elif filter_type == 4:
            predictor = _paeth(left, up, upper_left)
        else:
            raise ValueError(f"unsupported PNG filter type {filter_type}")
        result[index] = (value + predictor) & 0xFF
    return result


def _paeth(left: int, up: int, upper_left: int) -> int:
    estimate = left + up - upper_left
    left_distance = abs(estimate - left)
    up_distance = abs(estimate - up)
    upper_left_distance = abs(estimate - upper_left)
    if left_distance <= up_distance and left_distance <= upper_left_distance:
        return left
    if up_distance <= upper_left_distance:
        return up
    return upper_left


def main() -> int:
    args = parse_args()
    try:
        width, height, pixels = read_png(args.png)
    except Exception as exc:
        print(f"PDF render pixel assertion failed: {exc}", file=sys.stderr)
        return 1

    if width < args.min_width or height < args.min_height:
        print(
            f"{args.png} rendered too small: {width}x{height}, expected at least "
            f"{args.min_width}x{args.min_height}",
            file=sys.stderr,
        )
        return 1

    total = len(pixels)
    non_white = sum(1 for r, g, b in pixels if min(r, g, b) < 245)
    dark = sum(1 for r, g, b in pixels if max(r, g, b) < 40)
    unique_colors = len(set(pixels))
    non_white_ratio = non_white / total
    dark_ratio = dark / total

    if non_white_ratio < args.min_non_white_ratio:
        print(
            f"{args.png} looks blank: non-white ratio {non_white_ratio:.5f}",
            file=sys.stderr,
        )
        return 1
    if unique_colors < args.min_unique_colors:
        print(
            f"{args.png} has too little visual detail: {unique_colors} colors",
            file=sys.stderr,
        )
        return 1
    if dark_ratio > args.max_dark_ratio:
        print(
            f"{args.png} looks mostly black: dark ratio {dark_ratio:.5f}",
            file=sys.stderr,
        )
        return 1

    print(
        f"{args.png}: {width}x{height}, non_white={non_white_ratio:.5f}, "
        f"dark={dark_ratio:.5f}, colors={unique_colors}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
