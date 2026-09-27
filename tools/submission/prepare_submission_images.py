from pathlib import Path
from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(r"C:\Users\bandu\Desktop\黑客松比赛材料\assets")
OUT = ROOT / "generated"
FONT = r"C:\Windows\Fonts\msyh.ttc"
FONT_B = r"C:\Windows\Fonts\msyhbd.ttc"

def ft(n,b=False): return ImageFont.truetype(FONT_B if b else FONT,n)

def phone_panel(path, title, crop=None):
    im=Image.open(path).convert("RGB")
    if crop:
        im=im.crop((0,crop[0],im.width,min(im.height,crop[1])))
    # standard panel area preserving ratio
    im.thumbnail((430,1380),Image.Resampling.LANCZOS)
    panel=Image.new("RGB",(500,1540),"#F4F7FB")
    x=(500-im.width)//2
    panel.paste(im,(x,95))
    d=ImageDraw.Draw(panel)
    d.text((28,25),title,font=ft(28,True),fill="#17263D")
    return panel

flutter_dir=ROOT/"flutter真实功能页面"
panels=[
    phone_panel(flutter_dir/"微信图片_2026-09-26_200918_493.jpg","策略与自治权限",(0,4300)),
    phone_panel(flutter_dir/"微信图片_2026-09-26_200839_834.jpg","跨设备 Action Set",(0,2700)),
    phone_panel(flutter_dir/"微信图片_2026-09-26_200844_802.jpg","参考基线报表",(0,2700)),
]
canvas=Image.new("RGB",(1640,1660),"white")
d=ImageDraw.Draw(canvas)
d.text((70,35),"Flutter 真实产品页面",font=ft(46,True),fill="#0B1F3A")
d.text((70,95),"深度管理 · Action Set · 可审计报表",font=ft(26),fill="#66758B")
for i,p in enumerate(panels): canvas.paste(p,(55+i*530,145))
canvas.save(OUT/"08_flutter_product_evidence.png",quality=95)

hw_dir=ROOT/"设备"
imgs=[
    (hw_dir/"微信图片_20260926201045_292_41.jpg","Ambient 家庭能源"),
    (hw_dir/"微信图片_20260926201046_293_41.jpg","六位安全配对"),
    (hw_dir/"微信图片_20260926201048_296_41.jpg","L1 / L2 / L3 验证"),
]
canvas=Image.new("RGB",(1800,1120),"white")
d=ImageDraw.Draw(canvas)
d.text((70,35),"ESP32-S3 Energy Companion · REAL HIL",font=ft(46,True),fill="#0B1F3A")
d.text((70,95),"真实 AMOLED / Touch / HTTPS / Pairing；能源设备侧为 Simulator E2E",font=ft(26),fill="#66758B")
for i,(p,title) in enumerate(imgs):
    im=Image.open(p).convert("RGB")
    # square-ish crop around watch
    w,h=im.size
    if i==0:
        crop=im.crop((0,0,w,h))
    else:
        crop=ImageOps.fit(im,(480,820),method=Image.Resampling.LANCZOS,centering=(0.5,0.5))
    crop.thumbnail((480,820),Image.Resampling.LANCZOS)
    x=80+i*570
    panel=Image.new("RGB",(520,900),"#F4F7FB")
    panel.paste(crop,((520-crop.width)//2,20))
    pd=ImageDraw.Draw(panel)
    pd.rounded_rectangle((0,0,519,899),24,outline="#DDE6F1",width=3)
    pd.text((24,850),title,font=ft(28,True),fill="#17263D")
    canvas.paste(panel,(x,160))
canvas.save(OUT/"09_companion_hil_evidence.png",quality=95)

print("submission composites ready")
