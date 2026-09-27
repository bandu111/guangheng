from pathlib import Path
from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.utils import ImageReader
from reportlab.lib import colors
from PIL import Image
import textwrap

ROOT=Path(r"C:\Users\bandu\Desktop\黑客松比赛材料")
IMG=ROOT/"assets"/"generated"
OUT=ROOT/"光衡_GuangHeng_Anker黑客松预赛提交材料.pdf"
pdfmetrics.registerFont(TTFont('YaHei',r'C:\Windows\Fonts\msyh.ttc'))
pdfmetrics.registerFont(TTFont('YaHeiB',r'C:\Windows\Fonts\msyhbd.ttc'))
W,H=letter
NAVY=colors.HexColor('#0B1F3A'); BLUE=colors.HexColor('#2478F3'); GREEN=colors.HexColor('#16B77A'); ORANGE=colors.HexColor('#F5A623'); INK=colors.HexColor('#17263D'); MUTED=colors.HexColor('#66758B'); PALE=colors.HexColor('#F4F7FB'); LINE=colors.HexColor('#DDE6F1'); RED=colors.HexColor('#E65B55'); WHITE=colors.white
c=canvas.Canvas(str(OUT),pagesize=letter)
c.setTitle('光衡 GuangHeng｜Anker 黑客松预赛提交材料')

def page_base(index,label):
    c.setFillColor(WHITE); c.rect(0,0,W,H,fill=1,stroke=0)
    c.setFillColor(GREEN); c.setFont('YaHeiB',7); c.drawRightString(W-42,H-32,label.upper())
    c.setStrokeColor(LINE); c.line(42,30,W-42,30)
    c.setFillColor(MUTED); c.setFont('YaHei',6.5); c.drawCentredString(W/2,18,f'GUANGHENG × ANKER HACKATHON  ·  {index}')

def title(text,y=735,size=22,color=NAVY):
    c.setFillColor(color); c.setFont('YaHeiB',size); c.drawString(42,y,text)
    return y-size-10

def wrap(text,max_chars):
    out=[]
    for para in text.split('\n'):
        while len(para)>max_chars:
            cut=max_chars
            for punc in '，。；：、 ':
                pos=para.rfind(punc,0,max_chars+1)
                if pos>max_chars*.55: cut=pos+1; break
            out.append(para[:cut]); para=para[cut:]
        out.append(para)
    return out

def para(text,x,y,width=520,size=9.2,color=INK,bold=False,leading=None):
    chars=max(12,int(width/(size*.92)))
    lines=wrap(text,chars); leading=leading or size*1.55
    c.setFillColor(color); c.setFont('YaHeiB' if bold else 'YaHei',size)
    for line in lines:
        c.drawString(x,y,line); y-=leading
    return y

def takeaway(text,y):
    c.setFillColor(colors.HexColor('#EAF1FB')); c.roundRect(42,y-34,W-84,42,12,fill=1,stroke=0)
    c.setFillColor(NAVY); c.setFont('YaHeiB',10.5); c.drawString(58,y-18,text)
    return y-50

def bullets(items,x,y,width=510,size=8.8,leading=14):
    for item in items:
        c.setFillColor(GREEN); c.circle(x+4,y+4,2.4,fill=1,stroke=0)
        y=para(item,x+14,y,width-14,size,INK,False,leading)-3
    return y

def image(name,x,y,w,h):
    p=IMG/name; im=Image.open(p); iw,ih=im.size; scale=min(w/iw,h/ih); dw,dh=iw*scale,ih*scale
    c.drawImage(ImageReader(im),x+(w-dw)/2,y+(h-dh)/2,dw,dh,preserveAspectRatio=True,mask='auto')

def simple_table(rows,x,y,widths,row_h=28,font_size=7.5,header=True):
    yy=y
    for i,row in enumerate(rows):
        fill=NAVY if i==0 and header else (PALE if i%2==0 else WHITE)
        c.setFillColor(fill); c.rect(x,yy-row_h,sum(widths),row_h,fill=1,stroke=0)
        xx=x
        for j,val in enumerate(row):
            c.setStrokeColor(LINE); c.rect(xx,yy-row_h,widths[j],row_h,fill=0,stroke=1)
            c.setFillColor(WHITE if i==0 and header else INK); c.setFont('YaHeiB' if i==0 and header else 'YaHei',font_size)
            lines=wrap(str(val),max(6,int(widths[j]/(font_size*.78))))[:2]
            ly=yy-11
            for line in lines: c.drawString(xx+6,ly,line); ly-=font_size+2
            xx+=widths[j]
        yy-=row_h
    return yy

def next_page(): c.showPage()

# P1
page_base(1,'COVER')
c.setFillColor(GREEN); c.setFont('YaHeiB',9); c.drawCentredString(W/2,742,'ANKER 首届黑客松挑战赛 · 充电储能赛道')
c.setFillColor(NAVY); c.setFont('YaHeiB',36); c.drawCentredString(W/2,680,'光衡 GuangHeng')
c.setFillColor(BLUE); c.setFont('YaHeiB',14); c.drawCentredString(W/2,648,'AUTONOMOUS HOME ENERGY AGENT')
c.setFillColor(MUTED); c.setFont('YaHeiB',12); c.drawCentredString(W/2,610,'家庭能源管理真正缺少的不是更多数据')
c.drawCentredString(W/2,590,'而是从数据到行动的持续决策能力')
image('01_problem_before_after.png',50,265,512,285)
simple_table([['家庭能源 Autopilot','受治理的 AI 安全执行','一个 Agent · 两种入口'],['Observe · Predict · Optimize','Approval · Safety · Verify','Flutter + ESP32-S3']],48,230,[172,172,172],36,7.2)
c.setFillColor(MUTED); c.setFont('YaHeiB',7.2); c.drawCentredString(W/2,90,'SOLIX 设备闭环：SIMULATOR_E2E  ·  ESP32-S3：REAL_HIL')
next_page()

# P2
page_base(2,'01 · PRELIMINARY INFORMATION')
y=title('一、预赛信息卡')
y=simple_table([['项目','内容'],['队名','【待填写】'],['意向赛道','充电储能'],['一句话摘要','自主家庭能源 Agent：持续预测与优化，只在需要时请求授权，并用回读和 Smart Meter 证明结果。'],['队长','【待填写：姓名 / 邮箱 / 手机号】'],['成员介绍 & 分工','【待填写】']],42,y,[95,433],34,7.4)
y-=15; y=title('二、方案成果展示',y,19); y=title('1. 赛题理解',y,15,BLUE); y=takeaway('核心矛盾：Decision Burden，而不是 Data Visibility。',y)
y=para('现有能源 App 已能展示 PV、负载、SOC 与电网功率；普通家庭仍需反复判断何时充放电、留多少备电、天气如何影响明天，以及多个设备怎样协同。',42,y,528,9.2)
y-=5; y=bullets(['数据多但行动门槛高：用户被迫理解复杂曲线和设备边界。','控制响应式且单设备化：缺少预测和跨设备计划。','命令成功不等于家庭目标达成：缺少写后回读和结果证明。'],46,y,520)
y-=6; para('目标用户：拥有或计划拥有光伏、储能、智能电表和可控负载，希望提高光伏自用、合理使用储能并减少重复操作的家庭。',42,y,528,9.2,NAVY,True)
next_page()

# P3
page_base(3,'02 · CORE FEATURE 1'); y=title('2. 具体方案说明（突出 AI 能力）'); y=title('核心功能一｜家庭能源 Autopilot',y,16,BLUE); y=takeaway('系统持续观察和判断；No Action 时保持安静，需要行动时才生成 Proposal。',y)
image('03_backend_business_loop.png',45,332,522,290)
y=simple_table([['环节','实现'],['Observe','HA 状态、历史、设备能力与 Smart Meter'],['Predict','Weather、Solar Forecast、Load Forecast、参考电价'],['Optimize','Deterministic Optimizer + SAVE / AUTO / BACKUP'],['Decide','已满足则不打扰；需要行动则生成 Proposal']],42,310,[88,440],31,7.2)
y-=12; c.setFillColor(NAVY); c.setFont('YaHeiB',10); c.drawString(42,y,'AI 的角色'); y-=17
para('Hermes 理解用户目标、进行 What-if、解释“为什么现在”并生成结构化意图；Reserve、功率等数值由确定性 Optimizer 计算，避免 LLM 发明目标。',42,y,528,8.8)
next_page()

# P4
page_base(4,'03 · CORE FEATURE 2'); y=title('核心功能二｜受治理的 AI 安全执行闭环',735,19); y=takeaway('AI can reason. AI can propose. AI cannot freely execute.',y)
image('04_ai_safety_boundary.png',45,365,522,290)
y=bullets(['14 个 MCP Tools：查询、评估、提案；无 approve、execute、HA write。','执行前重新读取 Runtime，检查 control、online、capability、verified、范围、步长与审批。','Action Set 顺序执行、逐项回读、失败即停；后续动作标记 SKIPPED。','只有 SUCCEEDED + VERIFIED 才显示“已验证”。'],46,345,520,8.3,13)
y-=4; simple_table([['验证','证明什么'],['L1 · Command Accepted','请求进入系统'],['L2 · Device Readback','设备状态与目标一致'],['L3 · Household Outcome','Smart Meter 证明家庭目标实现']],42,y,[170,358],30,7.5)
next_page()

# P5
page_base(5,'04 · CORE FEATURE 3'); y=title('核心功能三｜一个 Agent，两种产品入口',735,19); y=takeaway('Flutter 深度管理 + ESP32-S3 Ambient Interaction，共享同一 Backend Truth。',y)
image('08_flutter_product_evidence.png',52,190,508,460)
simple_table([['入口','产品职责'],['Flutter','主要产品端：策略、报表、设备、审批、执行和验证'],['ESP32-S3 Companion','Ambient 状态、配对、解释与物理长按确认'],['Shared Truth','Backend 统一管理 Proposal、Execution 与 Verification']],42,172,[125,403],30,7.2)
next_page()

# P6
page_base(6,'05 · VALUE & MVP'); y=title('3. 方案价值与预期效果'); y=simple_table([['价值','预期改善'],['降低认知负担','系统持续观察，只在必要时打扰'],['预测式管理','天气、光伏与负载预测进入当前决策'],['多设备协同','Storage + Meter + Flexible Load'],['结果可证明','设备回读 + Smart Meter before/after']],42,y,[120,408],31,7.4)
y-=14; y=title('24 小时可演示 MVP',y,16,BLUE)
image('07_end_to_end_flow.png',45,245,522,290)
y=220; para('ESP32-S3 Companion 作为加分实体入口；真实 Anker 家庭硬件和长期节省效果留到赛后实机阶段。',42,y,528,8.3,MUTED)
y=175; y=title('4. 方案优势 / 创新点',y,15,BLUE); bullets(['Dashboard → Autonomous Home Energy Agent','Deterministic Optimization + Agent Reasoning','AI Intelligence 与 Execution Authority 分离','Cross-device Action Set + Fail-stop','L1 / L2 / L3 Unified Verification'],46,y,520,8.1,12)
next_page()

# P7
page_base(7,'06 · FREE DISPLAY / ARCHITECTURE'); y=title('三、自由展示区'); y=title('完整产品架构｜Control Plane 是业务真相',y,16,BLUE)
image('02_full_product_architecture.png',45,350,522,290)
simple_table([['层','真实职责'],['GuangHeng Backend','Control Plane：决策、权限、执行与验证'],['Home Assistant','Device Integration Layer'],['Hermes','Reasoning / Intent / Explanation；无自由执行权'],['Optimizer','可复现数值目标与硬约束'],['Companion','Ambient Interface；不是第二套执行链']],42,330,[140,388],34,7.4)
next_page()

# P8
page_base(8,'07 · FREE DISPLAY / REAL PRODUCT'); y=title('真实产品｜Agent 进入家庭空间',735,19); y=takeaway('ESP32-S3 本体按 REAL_HIL；Anker 能源设备闭环按 SIMULATOR_E2E。',y)
image('09_companion_hil_evidence.png',44,285,524,320)
simple_table([['证据','状态'],['ESP32-S3 rev 0.2 / 16 MB Flash / 8 MB PSRAM','REAL_HIL'],['AMOLED / Touch / Wi-Fi / SNTP / TLS / Pairing','REAL_HIL'],['物理 1.4 s 长按审批','REAL_HIL'],['SOLIX 多设备写入 / 回读 / Smart Meter L3','SIMULATOR_E2E'],['真实 Anker 家庭硬件','NOT_VERIFIED']],42,260,[385,143],31,7.1)
next_page()

# P9
page_base(9,'08 · EVIDENCE & ROADMAP'); y=title('工程证据与真实性边界',735,19)
y=simple_table([['分类','当前证据'],['REAL_HIL','ESP32-S3、AMOLED / Touch、Wi-Fi / SNTP / TLS、配对、物理长按'],['SIMULATOR_E2E','SOLIX Capability、Action Set、Safety、回读、Smart Meter L3'],['SOFTWARE_IMPLEMENTED','Backend 1.6.0；Flutter 1.4.0+9；14 MCP Tools；Autonomy / Optimizer / Voice'],['PARTIAL / HIL_PENDING','Lift 校准；ESP32-S3 Voice；Verification 最终视觉验收'],['PLANNED P2','TMAG5273 / Magnetic Context'],['NOT_VERIFIED','真实 Anker 家庭硬件、长期节省、准确率、用户规模']],42,y,[120,408],42,6.8)
y-=12; y=title('当前回归证据（2026-09-26）',y,13,BLUE); y=para('Backend：156 passed｜Flutter：15 passed｜Firmware host tests 与 ESP-IDF esp32s3 build 通过。测试数量仅作为本次工程审计记录。',42,y,528,8)
y-=8; y=title('团队与后续',y,14,BLUE); y=simple_table([['队名','【待填写】'],['队长','【待填写：姓名 / 邮箱 / 手机号】'],['成员与分工','【待填写】']],42,y,[110,418],29,7.6,False)
y-=10; y=bullets(['P0：真实 Anker SOLIX 硬件逐项完成写入、回读与 L3 验证。','P1：完成 ESP32-S3 Voice HIL 与 Lift-to-Explain 校准。','P2：再引入 TMAG5273 / Magnetic Context。'],46,y,520,8.0,12)
c.setFillColor(colors.HexColor('#FFF1F0')); c.roundRect(42,50,W-84,55,10,fill=1,stroke=0); c.setFillColor(RED); c.setFont('YaHeiB',7.5); c.drawString(55,82,'真实性声明'); c.setFont('YaHei',6.8); c.drawString(55,66,'无虚构用户数、准确率、节省比例或 Anker 实机结果；费用为参考基线估算。')

c.save(); print(OUT)
