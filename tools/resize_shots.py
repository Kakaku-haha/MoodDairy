"""Downscale 1080x1920 emulator captures (9:16) to 450x800 store screenshots.

Usage: python resize_shots.py <source-dir> <dest-dir> <glob-prefix>
"""

import glob
import os
import sys

from PIL import Image, ImageFilter

TARGET = (450, 800)


def convert(src, dst):
    img = Image.open(src).convert("RGB")
    if img.size != (1080, 1920):
        raise SystemExit(f"unexpected source size {img.size} for {src}")
    img = img.resize(TARGET, Image.LANCZOS)
    img = img.filter(ImageFilter.UnsharpMask(radius=1.0, percent=45, threshold=2))
    img.save(dst, optimize=True)
    return img.size


if __name__ == "__main__":
    raw = sys.argv[1]
    out = sys.argv[2]
    prefix = sys.argv[3] if len(sys.argv) > 3 else ""
    os.makedirs(out, exist_ok=True)
    files = sorted(glob.glob(os.path.join(raw, f"{prefix}*.png")))
    if not files:
        raise SystemExit(f"no files in {raw} matching {prefix}*.png")
    for f in files:
        name = os.path.basename(f)
        if name.startswith("d384-"):
            name = name[len("d384-"):]
        size = convert(f, os.path.join(out, name))
        print(f"{os.path.basename(f)} -> {name} {size}")
    print("total", len(files))
