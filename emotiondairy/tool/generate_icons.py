"""Generate the warm sun-face launcher icon used by 暖迹."""

from pathlib import Path
import math

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SIZE = 1024


def mix(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def make_icon() -> Image.Image:
    image = Image.new("RGB", (SIZE, SIZE), "#FBF2E8")
    draw = ImageDraw.Draw(image)

    top = (251, 238, 224)
    bottom = (244, 216, 199)
    for y in range(SIZE):
        t = y / (SIZE - 1)
        draw.line([(0, y), (SIZE, y)], fill=mix(top, bottom, t))

    # Soft halo behind the sun.
    for radius in range(430, 270, -3):
        alpha = int(14 * (1 - (radius - 270) / 160))
        overlay = Image.new("RGBA", image.size, (255, 255, 255, 0))
        ImageDraw.Draw(overlay).ellipse(
            [512 - radius, 500 - radius, 512 + radius, 500 + radius],
            fill=(255, 255, 255, alpha),
        )
        image = Image.alpha_composite(image.convert("RGBA"), overlay).convert("RGB")
        draw = ImageDraw.Draw(image)

    # Short, rounded rays.
    for index in range(12):
        angle = math.radians(index * 30 - 90)
        inner = 278
        outer = 318 if index % 2 == 0 else 304
        x1 = 512 + math.cos(angle) * inner
        y1 = 500 + math.sin(angle) * inner
        x2 = 512 + math.cos(angle) * outer
        y2 = 500 + math.sin(angle) * outer
        draw.line([(x1, y1), (x2, y2)], fill=(222, 170, 137), width=18)

    # Sun body with a gentle radial shading.
    outer_color = (183, 97, 70)
    inner_color = (224, 144, 104)
    for radius in range(248, 0, -2):
        t = 1 - radius / 248
        color = mix(outer_color, inner_color, math.pow(t, 1.45))
        draw.ellipse(
            [512 - radius, 500 - radius, 512 + radius, 500 + radius],
            fill=color,
        )

    # Warm highlight arc.
    draw.arc(
        [300, 288, 724, 712],
        start=196,
        end=252,
        fill=(238, 180, 145),
        width=16,
    )

    # Face.
    eye_color = (255, 249, 243)
    draw.ellipse([420, 452, 468, 500], fill=eye_color)
    draw.ellipse([556, 452, 604, 500], fill=eye_color)
    draw.arc(
        [402, 438, 622, 670],
        start=24,
        end=156,
        fill=eye_color,
        width=22,
    )

    # A little sparkle.
    sparkle = (255, 249, 240)
    draw.polygon(
        [(762, 214), (778, 262), (826, 278), (778, 294), (762, 342),
         (746, 294), (698, 278), (746, 262)],
        fill=sparkle,
    )

    # Soft corner glow.
    overlay = Image.new("RGBA", image.size, (255, 255, 255, 0))
    ImageDraw.Draw(overlay).ellipse(
        [-230, -260, 330, 300], fill=(255, 255, 255, 34)
    )
    image = Image.alpha_composite(image.convert("RGBA"), overlay).convert("RGB")
    return image


def main() -> None:
    icon = make_icon()
    preview_dir = ROOT / "preview"
    preview_dir.mkdir(exist_ok=True)
    icon.save(preview_dir / "app_icon.png", "PNG", optimize=True)

    android_icons = list((ROOT / "android" / "app" / "src" / "main").glob(
        "res/mipmap-*/ic_launcher.png"
    ))
    ios_icons = list(
        (ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset").glob(
            "*.png"
        )
    )

    for path in [*android_icons, *ios_icons]:
        with Image.open(path) as existing:
            resized = icon.resize(existing.size, Image.Resampling.LANCZOS)
            resized.save(path, "PNG", optimize=True)
        print(f"icon {path.relative_to(ROOT)} {resized.size[0]}x{resized.size[1]}")

    icon.resize((512, 512), Image.Resampling.LANCZOS).save(
        preview_dir / "app_icon_512.png", "PNG", optimize=True
    )

    web_icons = {
        "favicon.png": 64,
        "icons/Icon-192.png": 192,
        "icons/Icon-512.png": 512,
        "icons/Icon-maskable-192.png": 192,
        "icons/Icon-maskable-512.png": 512,
    }
    for relative, size in web_icons.items():
        target = ROOT / "web" / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        icon.resize((size, size), Image.Resampling.LANCZOS).save(
            target, "PNG", optimize=True
        )
        print(f"icon web/{relative} {size}x{size}")


if __name__ == "__main__":
    main()
