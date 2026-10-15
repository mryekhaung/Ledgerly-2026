"""Decode a PNG and report the distinct colours and their pixel counts.

Pure-Python (zlib + unfilter): no Pillow in this environment. Enough to answer
"is a card the same colour as the page behind it", which is the question the
light-mode surface ramp has to settle.
"""

from __future__ import annotations

import struct
import sys
import zlib
from collections import Counter
from pathlib import Path


def read_png(path: Path):
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise SystemExit(f"{path}: not a PNG")

    pos = 8
    width = height = bit_depth = color_type = None
    idat = bytearray()
    palette = b""

    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos : pos + 4])
        ctype = data[pos + 4 : pos + 8]
        body = data[pos + 8 : pos + 8 + length]
        pos += 12 + length

        if ctype == b"IHDR":
            width, height, bit_depth, color_type = struct.unpack(">IIBB", body[:10])
        elif ctype == b"PLTE":
            palette = body
        elif ctype == b"IDAT":
            idat += body
        elif ctype == b"IEND":
            break

    if bit_depth != 8 or color_type not in (2, 6):
        raise SystemExit(f"unsupported: depth={bit_depth} type={color_type}")

    channels = 3 if color_type == 2 else 4
    raw = zlib.decompress(bytes(idat))
    stride = width * channels

    # Undo the per-scanline filters.
    out = bytearray()
    prev = bytearray(stride)
    p = 0
    for _ in range(height):
        f = raw[p]
        p += 1
        line = bytearray(raw[p : p + stride])
        p += stride
        for i in range(stride):
            a = line[i - channels] if i >= channels else 0
            b = prev[i]
            c = prev[i - channels] if i >= channels else 0
            if f == 1:
                line[i] = (line[i] + a) & 0xFF
            elif f == 2:
                line[i] = (line[i] + b) & 0xFF
            elif f == 3:
                line[i] = (line[i] + ((a + b) >> 1)) & 0xFF
            elif f == 4:
                pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
                pr = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
                line[i] = (line[i] + pr) & 0xFF
        out += line
        prev = line

    return width, height, channels, bytes(out)


def main() -> int:
    path = Path(sys.argv[1])
    width, height, channels, px = read_png(path)
    counts = Counter()
    for y in range(height):
        row = y * width * channels
        for x in range(width):
            i = row + x * channels
            counts[(px[i], px[i + 1], px[i + 2])] += 1

    print(f"{path.name}: {width}x{height}")
    print(f"distinct colours: {len(counts)}")
    for rgb, n in counts.most_common(14):
        print(f"  #{rgb[0]:02X}{rgb[1]:02X}{rgb[2]:02X}  {n:>7} px  {100*n/(width*height):5.1f}%")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
