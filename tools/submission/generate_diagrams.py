from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

OUT = Path(r"C:\Users\bandu\Desktop\黑客松比赛材料\assets\generated")
OUT.mkdir(parents=True, exist_ok=True)
W, H = 1800, 1000
NAVY = "#0B1F3A"
BLUE = "#2478F3"
GREEN = "#16B77A"
ORANGE = "#F5A623"
INK = "#17263D"
MUTED = "#66758B"
PALE = "#F4F7FB"
WHITE = "#FFFFFF"
LINE = "#DDE6F1"
RED = "#E65B55"

FONT_PATH = r"C:\Windows\Fonts\msyh.ttc"
FONT_BOLD = r"C:\Windows\Fonts\msyhbd.ttc"

def font(size, bold=False):
    return ImageFont.truetype(FONT_BOLD if bold else FONT_PATH, size)

def base(title, subtitle):
    im = Image.new("RGB", (W, H), WHITE)
    d = ImageDraw.Draw(im)
    d.rounded_rectangle((70, 55, 1730, 175), 28, fill=NAVY)
    d.text((120, 78), title, font=font(54, True), fill=WHITE)
    d.text((120, 190), subtitle, font=font(27), fill=MUTED)
    return im, d

def box(d, xy, title, body="", color=BLUE, fill=WHITE, title_size=32, body_size=24):
    d.rounded_rectangle(xy, 28, fill=fill, outline=color, width=4)
    x1,y1,x2,y2=xy
    d.text((x1+28,y1+24), title, font=font(title_size, True), fill=INK)
    if body:
        yy=y1+78
        for line in body.split("\n"):
            d.text((x1+28,yy), line, font=font(body_size), fill=MUTED)
            yy += body_size+14

def arrow(d, a, b, color=BLUE, width=6):
    d.line((a,b), fill=color, width=width)
    import math
    ang=math.atan2(b[1]-a[1],b[0]-a[0])
    for da in (2.55,-2.55):
        p=(b[0]+24*math.cos(ang+da), b[1]+24*math.sin(ang+da))
        d.line((b,p), fill=color, width=width)

def pill(d, xy, text, color, fill):
    d.rounded_rectangle(xy, 24, fill=fill)
    x1,y1,x2,y2=xy
    bb=d.textbbox((0,0), text, font=font(24,True))
    d.text(((x1+x2-(bb[2]-bb[0]))/2,(y1+y2-(bb[3]-bb[1]))/2-3),text,font=font(24,True),fill=color)

def save(im, name):
    im.save(OUT/name, quality=95)

# 01 Problem / Before–After
im,d=base("从“看数据”到“替用户持续做判断”", "光衡解决的是 Decision Burden，而不是再增加一个能源 Dashboard")
box(d,(90,300,800,850),"传统家庭能源 App","数据展示\n用户理解曲线\n用户自行判断\n手动逐台控制",color="#9AA8BA",fill="#F8FAFC",title_size=38,body_size=30)
box(d,(1000,300,1710,850),"光衡 GuangHeng","持续观察与预测\n确定性优化与决策\n只在需要时请求确认\n执行、回读并验证结果",color=GREEN,fill="#F1FBF7",title_size=38,body_size=30)
arrow(d,(820,575),(980,575),ORANGE,8)
pill(d,(690,885,1110,945),"Reactive → Predictive / Autonomous",NAVY,"#EAF1FB")
save(im,"01_problem_before_after.png")

# 02 architecture
im,d=base("完整产品架构", "Backend / Control Plane 统一管理业务真相、权限、执行与验证")
box(d,(70,285,390,500),"Flutter App","深度管理\n策略 / 报表 / 设备",BLUE,"#F4F8FF",32,23)
box(d,(70,570,390,785),"ESP32-S3 Companion","Ambient / 配对\n物理长按确认",GREEN,"#F1FBF7",30,23)
box(d,(555,300,1245,780),"GuangHeng Control Plane","Energy State + Decision Context\nAutonomy + Deterministic Optimizer\nProposal / Action Set / Approval\nSafety / Execution / Readback / L3 Verify",NAVY,"#F7F9FC",38,27)
box(d,(1410,260,1730,450),"Hermes","Reasoning / Intent\nExplanation",ORANGE,"#FFF8EC",32,23)
box(d,(1410,520,1730,710),"Home Assistant","Entity / History\nService Control",BLUE,"#F4F8FF",30,23)
box(d,(1410,765,1730,935),"SOLIX + Meter","Simulator E2E\nDevice capabilities",GREEN,"#F1FBF7",28,22)
for a,b in [((390,390),(555,390)),((390,675),(555,675)),((1245,380),(1410,350)),((1245,600),(1410,610)),((1570,710),(1570,765))]: arrow(d,a,b)
pill(d,(650,820,1140,885),"AI can reason · AI cannot freely execute",RED,"#FFF1F0")
save(im,"02_full_product_architecture.png")

# 03 business loop
im,d=base("家庭能源 Autopilot", "持续运行：没有必要动作时保持安静；需要动作时才生成 Proposal")
steps=[("Observe","HA / Meter / Device"),("Predict","Weather / PV / Load"),("Optimize","Strategy + Constraints"),("Decide","Action required?"),("Propose","Explain impact"),("Verify","Readback + Meter")]
xs=[80,365,650,935,1220,1505]
colors=[BLUE,BLUE,ORANGE,ORANGE,GREEN,GREEN]
for i,(t,b) in enumerate(steps):
    box(d,(xs[i],360,xs[i]+220,620),t,b,colors[i],"#FFFFFF",30,20)
    if i<len(steps)-1: arrow(d,(xs[i]+220,490),(xs[i+1]-15,490),colors[i],5)
pill(d,(720,690,1080,755),"NO ACTION → STAY QUIET",MUTED,"#EEF2F6")
pill(d,(690,790,1110,855),"ACTION REQUIRED → PROPOSAL",GREEN,"#EAF9F3")
save(im,"03_backend_business_loop.png")

# 04 AI authority boundary
im,d=base("AI 智能与执行权限分离", "Hermes 负责理解与解释；数值决策、安全和写入由确定性链路治理")
box(d,(85,310,825,780),"Hermes · 可以","读取上下文\n理解用户目标\nWhat-if 与原因解释\n生成结构化 Intent\n辅助创建 PENDING Proposal",ORANGE,"#FFF9EF",38,28)
box(d,(975,310,1715,780),"Hermes · 不可以","Approve / Execute\n直接调用 Home Assistant 写入\n绕过 Safety\n自行发明 Reserve 数值\n把 HTTP 200 当作执行成功",RED,"#FFF3F2",38,28)
pill(d,(545,835,1255,915),"14 MCP Tools：查询 / 评估 / 提案 · 无 approve / execute / HA write",NAVY,"#EAF1FB")
save(im,"04_ai_safety_boundary.png")

# 05 action set
im,d=base("跨设备 Action Set", "一次确认、分步执行、逐项回读；失败即停，未执行动作标记 SKIPPED")
box(d,(80,350,350,650),"1 · Meter","发现光伏余电\n形成机会",BLUE,"#F4F8FF",31,24)
box(d,(470,350,740,650),"2 · Storage","调整充放电\nL2 状态回读",GREEN,"#F1FBF7",31,24)
box(d,(860,350,1130,650),"3 · Flexible Load","调度柔性负载\nL2 状态回读",ORANGE,"#FFF8EC",29,23)
box(d,(1250,350,1520,650),"4 · Meter","执行后观测\nL3 结果验证",BLUE,"#F4F8FF",31,24)
box(d,(1580,350,1730,650),"结果","VERIFIED\n或\nPARTIAL",GREEN,"#F1FBF7",28,22)
for a,b in [((350,500),(470,500)),((740,500),(860,500)),((1130,500),(1250,500)),((1520,500),(1580,500))]: arrow(d,a,b)
pill(d,(520,760,1280,830),"Sequential + Fail-stop · no unverified rollback",RED,"#FFF1F0")
save(im,"05_action_set.png")

# 06 verification levels
im,d=base("命令成功 ≠ 家庭目标达成", "只有 L3 Household Outcome Verification 通过，界面才显示“已验证”")
box(d,(100,340,550,760),"L1 · Command Accepted","请求被接收\n仅证明命令进入系统",BLUE,"#F4F8FF",36,27)
box(d,(675,340,1125,760),"L2 · Device Readback","设备状态与目标一致\n逐项验证执行结果",ORANGE,"#FFF8EC",36,27)
box(d,(1250,340,1700,760),"L3 · Household Outcome","Smart Meter 前后对比\n证明家庭能源目标实现",GREEN,"#F1FBF7",34,27)
arrow(d,(550,550),(675,550)); arrow(d,(1125,550),(1250,550))
pill(d,(1160,820,1790,885),"SUCCEEDED + VERIFIED → 已验证",GREEN,"#EAF9F3")
save(im,"06_l1_l2_l3.png")

# 07 end-to-end
im,d=base("24 小时可演示的完整业务闭环", "核心不是堆功能，而是让一次家庭能源决策从观察走到可证明的结果")
labels=["HA / Simulator","Energy State","Decision Context","Optimizer","Proposal","User Approval","Safety","Execution","Readback","Smart Meter Verify"]
coords=[]
for row in range(2):
    items=labels[row*5:(row+1)*5]
    for col,t in enumerate(items):
        x=80+(col if row == 0 else 4-col)*345; y=330+row*300
        coords.append((x,y))
        box(d,(x,y,x+260,y+155),t,"",[BLUE,BLUE,ORANGE,ORANGE,GREEN][col],"#FFFFFF",27,20)
for i in range(4): arrow(d,(coords[i][0]+260,coords[i][1]+78),(coords[i+1][0]-15,coords[i+1][1]+78))
# Proposal drops to approval; the second row then advances left-to-right.
arrow(d,(coords[4][0]+130,coords[4][1]+155),(coords[5][0]+130,coords[5][1]-10),GREEN)
for i in range(5,9): arrow(d,(coords[i][0]-15,coords[i][1]+78),(coords[i+1][0]+260,coords[i+1][1]+78),GREEN)
pill(d,(590,850,1210,915),"Companion 是加分实体入口，不是第二套执行链",NAVY,"#EAF1FB")
save(im,"07_end_to_end_flow.png")

print("generated", len(list(OUT.glob("0*.png"))), "diagrams in", OUT)
