from pathlib import Path

from PIL import Image, ImageEnhance, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
ICON_DIR = ROOT / "assets" / "icon"
SOURCE = ICON_DIR / "app_icon_v2.png"


def square_rgb(image: Image.Image, size: int = 1024) -> Image.Image:
    image = image.convert("RGB")
    if image.size != (size, size):
        image = ImageOps.fit(image, (size, size), Image.Resampling.LANCZOS)
    return image


def main() -> None:
    master = square_rgb(Image.open(SOURCE))
    master.save(SOURCE, optimize=True)

    # Android adaptive foreground: retain the full artwork but inset it so the
    # mascot and ricochet point survive circular/squircle launcher masks.
    foreground = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    inset = master.resize((700, 700), Image.Resampling.LANCZOS)
    foreground.paste(inset, (162, 162))
    foreground.save(ICON_DIR / "app_icon_v2_foreground.png", optimize=True)

    # iOS dark appearance keeps the icon full-bleed and gives the teal field a
    # deeper lacquer finish while preserving warm mascot contrast.
    dark = ImageEnhance.Brightness(master).enhance(0.72)
    dark = ImageEnhance.Color(dark).enhance(1.18)
    glow = master.filter(ImageFilter.GaussianBlur(18))
    dark = Image.blend(dark, glow, 0.10)
    dark.save(ICON_DIR / "app_icon_v2_dark.png", optimize=True)

    # The iOS tinted appearance expects a legible grayscale source.
    tinted = ImageOps.grayscale(master)
    tinted = ImageOps.autocontrast(tinted, cutoff=1)
    tinted = ImageEnhance.Contrast(tinted).enhance(1.28)
    tinted.save(ICON_DIR / "app_icon_v2_tinted.png", optimize=True)

    listing = master.resize((512, 512), Image.Resampling.LANCZOS)
    listing.save(
        ROOT / "store_listing" / "final" / "google_play" / "listing_icon_512x512.png",
        optimize=True,
    )


if __name__ == "__main__":
    main()
