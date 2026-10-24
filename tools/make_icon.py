"""Render the 暖迹 store icon (216x216) from the in-app AppLogo design."""

from PIL import Image, ImageDraw, ImageFont

SIZE = 216
SS = 8  # supersampling factor
W = SIZE * SS

TOP = (0xC9, 0x83, 0x63)  # AppColors.primaryGradient start #C98363
BOTTOM = (0xB3, 0x6A, 0x4E)  # AppColors.primaryGradient end   #B36A4E
APRICOT = (0xF5, 0xD2, 0xB4)  # AppColors.apricot
CREAM = (0xFB, 0xF6, 0xEF)  # AppColors.background
GLYPH = (0xFF, 0xFF, 0xFF)

FONT_BOLD = r"C:\Windows\Fonts\msyhbd.ttc"


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def gradient_square(size):
    """135° linear gradient, top-left -> bottom-right."""
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * (size - 1))
            px[x, y] = lerp(TOP, BOTTOM, t)
    return img


def radial_highlight(img, center, radius, color, alpha):
    """Soft radial glow composited over img."""
    size = img.size[0]
    layer = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(layer)
    steps = 64
    for i in range(steps, 0, -1):
        r = radius * i / steps
        a = round(alpha * (1 - i / steps) ** 1.6)
        draw.ellipse(
            [center[0] - r, center[1] - r, center[0] + r, center[1] + r], fill=a
        )
    tint = Image.new("RGB", (size, size), color)
    img.paste(tint, (0, 0), layer)
    return img


def draw_mark(canvas, size):
    """Rounded-square logo mark used inside rounded variant."""
    return canvas


def build(square=True):
    img = gradient_square(W)
    img = radial_highlight(
        img, (W * 0.16, W * 0.10), W * 0.95, (255, 255, 255), 44
    )

    draw = ImageDraw.Draw(img)

    # 暖 in the same proportion as AppLogo (fontSize = size * 0.46).
    font = ImageFont.truetype(FONT_BOLD, int(W * 0.46), index=0)
    text = "暖"
    left, top_, right, bottom_ = draw.textbbox((0, 0), text, font=font)
    ink_w, ink_h = right - left, bottom_ - top_
    x = (W - ink_w) / 2 - left
    y = (W - ink_h) / 2 - top_ - W * 0.012
    draw.text((x, y), text, font=font, fill=GLYPH)

    # Apricot accent dot, echoing AppLogo (top-right).
    r = W * 0.062
    cx, cy = W * 0.775, W * 0.205
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=APRICOT)

    out = img.resize((SIZE, SIZE), Image.LANCZOS)

    if not square:
        # Rounded variant: 32% radius like AppLogo, transparent corners.
        mask = Image.new("L", (SIZE * 4, SIZE * 4), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, SIZE * 4 - 1, SIZE * 4 - 1], radius=SIZE * 4 * 0.32, fill=255
        )
        mask = mask.resize((SIZE, SIZE), Image.LANCZOS)
        rounded = out.convert("RGBA")
        rounded.putalpha(mask)
        return rounded

    return out


if __name__ == "__main__":
    import os

    out_dir = r"D:\ProGram\MoodDairy\store-assets\icon"
    os.makedirs(out_dir, exist_ok=True)
    build(True).save(os.path.join(out_dir, "icon-216.png"), optimize=True)
    build(False).save(os.path.join(out_dir, "icon-216-rounded.png"), optimize=True)
    print("wrote", out_dir)
