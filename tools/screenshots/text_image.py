"""Renders plain text (terminal output, folder trees) as a clean PNG that looks
like a dark terminal window, so it can be embedded in the report and slides."""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

BG = (30, 30, 30)
FG = (212, 212, 212)
TITLE_BG = (60, 60, 60)
COLORS = {  # line prefix -> colour
    "PS ": (78, 201, 176),
    "Build succeeded": (106, 153, 85),
    "Done": (106, 153, 85),
    "Applying": (86, 156, 214),
    "info:": (156, 220, 254),
    "#": (106, 153, 85),
}


def _font(size):
    for name in ("consola.ttf", "cour.ttf"):
        try:
            return ImageFont.truetype(str(Path("C:/Windows/Fonts") / name), size)
        except OSError:
            continue
    return ImageFont.load_default()


def render(lines, out_path, title="Terminal", font_size=17, min_width=900):
    font = _font(font_size)
    line_h = int(font_size * 1.45)
    pad = 18
    title_h = 34
    width = max(min_width, max(int(font.getlength(l)) for l in lines) + pad * 2)
    height = title_h + pad * 2 + line_h * len(lines)

    img = Image.new("RGB", (width, height), BG)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, width, title_h], fill=TITLE_BG)
    for i, c in enumerate([(255, 95, 86), (255, 189, 46), (39, 201, 63)]):
        d.ellipse([12 + i * 22, 11, 24 + i * 22, 23], fill=c)
    d.text((90, 8), title, font=_font(15), fill=(220, 220, 220))

    y = title_h + pad
    for line in lines:
        color = FG
        for prefix, c in COLORS.items():
            if line.lstrip().startswith(prefix):
                color = c
                break
        d.text((pad, y), line, font=font, fill=color)
        y += line_h
    img.save(out_path)
    print("saved", Path(out_path).name)
