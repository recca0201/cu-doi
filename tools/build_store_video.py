from __future__ import annotations

import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
STORE = ROOT / "store_listing"
SOURCE_FRAMES = STORE / "video" / "frames"
FINAL = STORE / "final" / "video"
KEY_ART = STORE / "source" / "karst_pangolin_key_art.png"
TITLE = STORE / "source" / "titles" / "02_vi_aim.png"
NUNITO = ROOT / "assets" / "fonts" / "Nunito-Variable.ttf"
SIZE = (1080, 1920)
FPS = 12


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    scale = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize(
        (round(image.width * scale), round(image.height * scale)),
        Image.Resampling.LANCZOS,
    )
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def background() -> Image.Image:
    art = cover(Image.open(KEY_ART).convert("RGB"), SIZE)
    art = art.filter(ImageFilter.GaussianBlur(12)).convert("RGBA")
    art.alpha_composite(Image.new("RGBA", SIZE, (0, 42, 43, 135)))
    return art


def intro_frame() -> Image.Image:
    canvas = cover(Image.open(KEY_ART).convert("RGB"), SIZE).convert("RGBA")
    canvas.alpha_composite(Image.new("RGBA", SIZE, (0, 39, 40, 105)))
    title = Image.open(TITLE).convert("RGBA")
    bbox = title.getchannel("A").getbbox()
    if bbox:
        title = title.crop(bbox)
    title.thumbnail((980, 520), Image.Resampling.LANCZOS)
    canvas.paste(title, ((SIZE[0] - title.width) // 2, 330), title)
    draw = ImageDraw.Draw(canvas)
    subtitle = ImageFont.truetype(str(NUNITO), 54)
    draw.text(
        (SIZE[0] // 2, 915),
        "2 CÚ BẮN · DỌN SẠCH MÀN 1",
        font=subtitle,
        anchor="mm",
        fill="#FFF7D6",
        stroke_width=4,
        stroke_fill="#012D30",
    )
    draw.text(
        (SIZE[0] // 2, 1000),
        "Bắn thẳng không tính — phải dội tường!",
        font=ImageFont.truetype(str(NUNITO), 39),
        anchor="mm",
        fill="#6DEBFF",
        stroke_width=3,
        stroke_fill="#012D30",
    )
    return canvas.convert("RGB")


def gameplay_frame(source: Path, backdrop: Image.Image) -> Image.Image:
    canvas = backdrop.copy()
    screen = Image.open(source).convert("RGB")
    screen.thumbnail((834, 1812), Image.Resampling.LANCZOS)
    x = (SIZE[0] - screen.width) // 2
    y = (SIZE[1] - screen.height) // 2
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle(
        (x - 15, y - 15, x + screen.width + 15, y + screen.height + 15),
        radius=44,
        fill="#B86B1C",
        outline="#FFC52C",
        width=8,
    )
    mask = Image.new("L", screen.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, screen.width - 1, screen.height - 1), radius=32, fill=255
    )
    canvas.paste(screen, (x, y), mask)
    return canvas.convert("RGB")


def main() -> None:
    FINAL.mkdir(parents=True, exist_ok=True)
    sources = sorted(SOURCE_FRAMES.glob("frame_*.png"))
    if len(sources) < 100:
        raise RuntimeError("Run the video capture golden test before building the video.")

    with tempfile.TemporaryDirectory(prefix="cu_doi_store_video_") as tmp:
        tmp_path = Path(tmp)
        index = 0
        intro = intro_frame()
        for _ in range(FPS):
            intro.save(tmp_path / f"frame_{index:04d}.jpg", quality=94)
            index += 1

        backdrop = background()
        strong_frame = None
        for source in sources:
            frame = gameplay_frame(source, backdrop)
            frame.save(tmp_path / f"frame_{index:04d}.jpg", quality=94)
            if source.name == "frame_0050.png":
                strong_frame = frame.copy()
            index += 1

        poster = strong_frame or intro
        poster.save(FINAL / "cu_doi_level_clear_poster_1080x1920.png", optimize=True)

        output = FINAL / "cu_doi_level_clear_vertical_1080x1920.mp4"
        audio = ROOT / "assets" / "audio"
        duration = index / FPS
        command = [
            "ffmpeg", "-y",
            "-framerate", str(FPS),
            "-i", str(tmp_path / "frame_%04d.jpg"),
            "-stream_loop", "-1", "-i", str(audio / "background_loop.mp3"),
            "-i", str(audio / "shoot.mp3"),
            "-i", str(audio / "shoot.mp3"),
            "-i", str(audio / "wall_impact.mp3"),
            "-i", str(audio / "comic_impact.mp3"),
            "-i", str(audio / "win.mp3"),
            "-i", str(audio / "polite_clap.mp3"),
            "-filter_complex",
            "[1:a]volume=0.16[bg];"
            "[2:a]adelay=1830|1830,volume=0.9[s1];"
            "[3:a]adelay=6330|6330,volume=0.9[s2];"
            "[4:a]adelay=3100|3100,volume=0.55[w1];"
            "[5:a]adelay=4800|4800,volume=0.7[p1];"
            "[6:a]adelay=11200|11200,volume=0.95[win];"
            "[7:a]adelay=11600|11600,volume=0.65[clap];"
            "[bg][s1][s2][w1][p1][win][clap]amix=inputs=7:duration=first:dropout_transition=1[a]",
            "-map", "0:v", "-map", "[a]",
            "-t", f"{duration:.3f}",
            "-c:v", "libx264", "-preset", "slow", "-crf", "18",
            "-pix_fmt", "yuv420p", "-movflags", "+faststart",
            "-c:a", "aac", "-b:a", "192k",
            str(output),
        ]
        subprocess.run(command, check=True)
        print(output)


if __name__ == "__main__":
    main()
