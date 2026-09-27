from pathlib import Path

import pdfplumber
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(r"D:\flutterProject\guangheng")
PDF = Path(r"C:\Users\bandu\Desktop\光衡_PRD_V3.1_开发冻结版.pdf")


def extract_pdf() -> None:
    chunks: list[str] = []
    with pdfplumber.open(PDF) as document:
        for number, page in enumerate(document.pages, 1):
            chunks.append(f"\n===== PAGE {number} =====\n")
            chunks.append(page.extract_text(layout=True) or "")
    (ROOT / "tmp/pdfs/v31.txt").write_text("\n".join(chunks), encoding="utf-8")


def contact_sheet(paths: list[Path], output: Path, columns: int, labeler) -> None:
    if not paths:
        return
    font = ImageFont.load_default()
    opened = [Image.open(path).convert("RGB") for path in paths]
    thumb_width = 270
    thumbs: list[Image.Image] = []
    for index, source in enumerate(opened):
        height = round(source.height * thumb_width / source.width)
        thumb = source.resize((thumb_width, height))
        canvas = Image.new("RGB", (thumb_width, height + 28), "white")
        canvas.paste(thumb, (0, 28))
        ImageDraw.Draw(canvas).text((8, 8), labeler(index, paths[index]), fill="black", font=font)
        thumbs.append(canvas)
    cell_height = max(image.height for image in thumbs)
    rows = (len(thumbs) + columns - 1) // columns
    sheet = Image.new("RGB", (columns * thumb_width, rows * cell_height), "#dfe5ec")
    for index, thumb in enumerate(thumbs):
        sheet.paste(thumb, ((index % columns) * thumb_width, (index // columns) * cell_height))
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output, quality=88)


extract_pdf()
page_paths = sorted((ROOT / "tmp/pdfs/v31_pages").glob("*.jpg"))
contact_sheet(page_paths, ROOT / "tmp/pdfs/v31_contact.jpg", 4, lambda i, _: f"PRD page {i + 1}")
frames = sorted((ROOT / "tmp/video_frames").glob("*.jpg"))
for sheet_number, start in enumerate(range(0, len(frames), 12), 1):
    batch = frames[start : start + 12]
    contact_sheet(
        batch,
        ROOT / f"tmp/video_contact_{sheet_number}.jpg",
        4,
        lambda i, _: f"t={(start + i) * 8:03d}s",
    )
