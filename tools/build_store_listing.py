from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
STORE = ROOT / "store_listing"
CAPTURES = STORE / "captures"
SOURCE = STORE / "source"
OUT = STORE / "final"

BALOO = ROOT / "assets/fonts/Baloo2-Variable.ttf"
NUNITO = ROOT / "assets/fonts/Nunito-Variable.ttf"
GOLD = "#FFC52C"
CREAM = "#FFF7D6"
TEAL = "#034C48"
DEEP = "#012D30"
CYAN = "#6DEBFF"


def cover(image: Image.Image, size: tuple[int, int], focus: tuple[float, float] = (.5, .5)) -> Image.Image:
    image = image.convert("RGB")
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    left = round((resized.width - size[0]) * focus[0])
    top = round((resized.height - size[1]) * focus[1])
    return resized.crop((left, top, left + size[0], top + size[1]))


def contain(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    image = image.copy()
    image.thumbnail(size, Image.Resampling.LANCZOS)
    return image


def fit_font(path: Path, text: str, max_width: int, start: int, minimum: int) -> ImageFont.FreeTypeFont:
    size = start
    while size >= minimum:
        font = ImageFont.truetype(str(path), size)
        box = font.getbbox(text, stroke_width=max(2, size // 22))
        if box[2] - box[0] <= max_width:
            return font
        size -= 2
    return ImageFont.truetype(str(path), minimum)


def rounded_paste(base: Image.Image, inset: Image.Image, xy: tuple[int, int], radius: int, border: int) -> None:
    x, y = xy
    mask = Image.new("L", inset.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, inset.width - 1, inset.height - 1), radius=radius, fill=255)

    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (x - border, y - border + 18, x + inset.width + border, y + inset.height + border + 18),
        radius=radius + border,
        fill=(1, 20, 22, 205),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(max(8, border * 2)))
    base.paste(shadow, (0, 0), shadow)

    frame = Image.new("RGBA", (inset.width + border * 2, inset.height + border * 2), (0, 0, 0, 0))
    fd = ImageDraw.Draw(frame)
    fd.rounded_rectangle((0, 0, frame.width - 1, frame.height - 1), radius=radius + border, fill="#B86B1C")
    fd.rounded_rectangle((border // 2, border // 2, frame.width - 1 - border // 2, frame.height - 1 - border // 2), radius=radius, outline=GOLD, width=max(3, border // 3))
    base.paste(frame, (x - border, y - border), frame)
    base.paste(inset, (x, y), mask)


def add_top_vignette(canvas: Image.Image, strength: int = 205) -> None:
    fade = max(1, int(canvas.height * .34))
    strip = Image.new("RGBA", (1, fade), (1, 39, 40, 0))
    px = strip.load()
    for y in range(fade):
        alpha = round(strength * (1 - y / fade) ** 1.6)
        px[0, y] = (1, 39, 40, alpha)
    overlay = strip.resize((canvas.width, fade), Image.Resampling.BILINEAR)
    canvas.paste(overlay, (0, 0), overlay)


def draw_headline(canvas: Image.Image, title: str, subtitle: str, y: int) -> None:
    draw = ImageDraw.Draw(canvas)
    title_font = fit_font(BALOO, title, int(canvas.width * .88), int(canvas.width * .085), int(canvas.width * .052))
    sub_font = fit_font(NUNITO, subtitle, int(canvas.width * .82), int(canvas.width * .036), int(canvas.width * .026))
    stroke = max(4, canvas.width // 260)
    draw.text(
        (canvas.width // 2, y),
        title,
        font=title_font,
        anchor="mm",
        align="center",
        fill=GOLD,
        stroke_width=stroke,
        stroke_fill=DEEP,
    )
    title_box = draw.textbbox((canvas.width // 2, y), title, font=title_font, anchor="mm", stroke_width=stroke)
    draw.text(
        (canvas.width // 2, title_box[3] + int(canvas.width * .025)),
        subtitle,
        font=sub_font,
        anchor="ma",
        align="center",
        fill=CREAM,
        stroke_width=max(1, stroke // 2),
        stroke_fill=DEEP,
    )


SLIDES = (
    ("vi", "menu", "01_vi_banks.png", "Bắn thẳng không tính"),
    ("en", "gameplay", "06_en_aim.png", "One shot. So many winning lines."),
    ("vi", "map", "03_vi_levels.png", "Mỗi sân là một câu đố mới"),
    ("en", "menu", "05_en_banks.png", "Direct hits do not count"),
    ("vi", "gameplay", "02_vi_aim.png", "Một cú bắn, nhiều đường thắng"),
    ("en", "map", "07_en_levels.png", "Every arena is a new puzzle"),
    ("vi", "gameplay", "04_vi_momentum.png", "Đủ lần dội, mục tiêu vỡ và bi xuyên qua"),
)


def marketing_set(
    prefix: str,
    source_prefix: str,
    size: tuple[int, int],
    screenshot_height_ratio: float,
    crop_to_region: bool = False,
) -> None:
    dest = OUT / prefix
    dest.mkdir(parents=True, exist_ok=True)
    for old_file in dest.glob("*.png"):
        old_file.unlink()
    key_art = Image.open(SOURCE / "karst_pangolin_key_art.png")
    for index, (locale, capture_name, title_name, subtitle) in enumerate(SLIDES, 1):
        canvas = cover(key_art, size, focus=(.28, .5)).convert("RGBA")
        tint = Image.new("RGBA", size, (0, 52, 49, 75))
        canvas.alpha_composite(tint)
        add_top_vignette(canvas)
        title = Image.open(SOURCE / "titles" / title_name).convert("RGBA")
        title_bbox = title.getchannel("A").getbbox()
        if title_bbox:
            title = title.crop(title_bbox)
        title = contain(title, (int(size[0] * .92), int(size[1] * .18)))
        title_x = (size[0] - title.width) // 2
        title_y = int(size[1] * .025)
        canvas.paste(title, (title_x, title_y), title)

        draw = ImageDraw.Draw(canvas)
        sub_font = fit_font(
            NUNITO,
            subtitle,
            int(size[0] * .82),
            int(size[0] * .036),
            int(size[0] * .025),
        )
        draw.text(
            (size[0] // 2, title_y + title.height + int(size[1] * .012)),
            subtitle,
            font=sub_font,
            anchor="ma",
            fill=CREAM,
            stroke_width=max(2, size[0] // 420),
            stroke_fill=DEEP,
        )

        shot = Image.open(
            CAPTURES / f"{source_prefix}_{locale}_{capture_name}.png"
        ).convert("RGB")
        max_h = int(size[1] * screenshot_height_ratio)
        max_w = int(size[0] * .78)
        shot = cover(shot, (max_w, max_h)) if crop_to_region else contain(shot, (max_w, max_h))
        x = (size[0] - shot.width) // 2
        y = size[1] - shot.height - int(size[1] * .025)
        rounded_paste(canvas, shot, (x, y), radius=max(28, size[0] // 28), border=max(10, size[0] // 95))
        canvas.convert("RGB").save(
            dest / f"{index:02d}_{locale}_{capture_name}.png", optimize=True
        )


def feature_graphic() -> None:
    dest = OUT / "google_play"
    dest.mkdir(parents=True, exist_ok=True)
    canvas = cover(Image.open(SOURCE / "karst_pangolin_key_art.png"), (1024, 500), focus=(.48, .5)).convert("RGBA")
    shade = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    for x in range(620):
        alpha = round(175 * (1 - x / 620) ** 1.6)
        sd.line((x, 0, x, 500), fill=(1, 39, 40, alpha))
    canvas.alpha_composite(shade)

    logo = contain(Image.open(ROOT / "assets/images/brand/cu_doi_logo_galaxy_v1.png").convert("RGBA"), (480, 230))
    canvas.paste(logo, (56, 112), logo)
    draw = ImageDraw.Draw(canvas)
    font = fit_font(BALOO, "BẮN THẲNG KHÔNG TÍNH", 470, 43, 31)
    draw.text((286, 372), "BẮN THẲNG KHÔNG TÍNH", font=font, anchor="mm", fill=CREAM, stroke_width=3, stroke_fill=DEEP)
    canvas.convert("RGB").save(dest / "feature_graphic_1024x500.png", optimize=True)


def listing_icon() -> None:
    dest = OUT / "google_play"
    icon = Image.open(ROOT / "assets/icon/app_icon.png").convert("RGBA").resize((512, 512), Image.Resampling.LANCZOS)
    icon.save(dest / "listing_icon_512x512.png", optimize=True)


def main() -> None:
    feature_graphic()
    listing_icon()
    marketing_set(
        "google_play/phone_1080x1920",
        "iphone_69",
        (1080, 1920),
        .72,
        crop_to_region=True,
    )
    marketing_set(
        "app_store/iphone_6_9_1320x2868",
        "iphone_69",
        (1320, 2868),
        .72,
    )
    marketing_set(
        "google_play/tablet_7in_1080x1920",
        "google_tablet_7",
        (1080, 1920),
        .68,
    )
    marketing_set(
        "google_play/tablet_1440x2560",
        "google_tablet",
        (1440, 2560),
        .70,
    )
    marketing_set(
        "app_store/ipad_13_2064x2752",
        "ipad_13",
        (2064, 2752),
        .70,
    )


if __name__ == "__main__":
    main()
