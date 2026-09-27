from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

root = Path(r"D:\flutterProject\guangheng\tmp\pdfs\v32_render")
files = sorted(root.glob("page-*.jpg"))
thumb_w = 300
cols = 4
font = ImageFont.truetype(r"C:\Windows\Fonts\arial.ttf", 16)
thumbs = []
for i, p in enumerate(files, 1):
    im = Image.open(p).convert("RGB")
    h = int(im.height * thumb_w / im.width)
    im = im.resize((thumb_w, h))
    tile = Image.new("RGB", (thumb_w, h + 28), "#E8EEF6")
    tile.paste(im, (0, 28))
    ImageDraw.Draw(tile).text((8, 5), f"V3.2 page {i}", font=font, fill="#14233C")
    thumbs.append(tile)
rows = (len(thumbs) + cols - 1) // cols
tile_h = max(t.height for t in thumbs)
sheet = Image.new("RGB", (cols * thumb_w, rows * tile_h), "#DDE6F2")
for i, tile in enumerate(thumbs):
    sheet.paste(tile, ((i % cols) * thumb_w, (i // cols) * tile_h))
sheet.save(root.parent / "v32_contact.jpg", quality=88)
print(len(files))
