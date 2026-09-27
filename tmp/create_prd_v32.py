from pathlib import Path
from datetime import datetime
from reportlab.lib import colors
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_LEFT, TA_CENTER, TA_RIGHT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, PageTemplate, Frame, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, Image, Flowable
)
from reportlab.graphics.shapes import Drawing, Rect, String, Line, Circle, Polygon


ROOT = Path(r"D:\flutterProject\guangheng")
OUT_DIR = ROOT / "output" / "pdf"
OUT_DIR.mkdir(parents=True, exist_ok=True)
OUT = OUT_DIR / "光衡_PRD_V3.2_设备与电站价值闭环增强版.pdf"

pdfmetrics.registerFont(TTFont("CN", r"C:\Windows\Fonts\msyh.ttc"))
pdfmetrics.registerFont(TTFont("CNB", r"C:\Windows\Fonts\msyhbd.ttc"))

NAVY = HexColor("#0B1F3A")
BLUE = HexColor("#2579E8")
CYAN = HexColor("#18A7C8")
GREEN = HexColor("#22B77A")
MINT = HexColor("#EAF8F2")
ORANGE = HexColor("#F3A52B")
RED = HexColor("#D95C5C")
INK = HexColor("#17243A")
SLATE = HexColor("#66758A")
LIGHT = HexColor("#F4F7FB")
LINEC = HexColor("#DCE5F0")
WHITE = colors.white

PAGE_W, PAGE_H = A4
MARGIN_X = 16 * mm
TOP = 17 * mm
BOTTOM = 15 * mm


def esc(s):
    return str(s).replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")


styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="BodyCN", fontName="CN", fontSize=8.5, leading=13, textColor=INK, spaceAfter=4))
styles.add(ParagraphStyle(name="SmallCN", fontName="CN", fontSize=7, leading=10, textColor=SLATE))
styles.add(ParagraphStyle(name="TinyCN", fontName="CN", fontSize=6.2, leading=8.4, textColor=SLATE))
styles.add(ParagraphStyle(name="H1CN", fontName="CNB", fontSize=18, leading=23, textColor=NAVY, spaceAfter=8))
styles.add(ParagraphStyle(name="H2CN", fontName="CNB", fontSize=12, leading=16, textColor=NAVY, spaceBefore=3, spaceAfter=6))
styles.add(ParagraphStyle(name="H3CN", fontName="CNB", fontSize=9.5, leading=13, textColor=INK, spaceBefore=3, spaceAfter=3))
styles.add(ParagraphStyle(name="CoverTitle", fontName="CNB", fontSize=30, leading=37, textColor=WHITE))
styles.add(ParagraphStyle(name="CoverSub", fontName="CN", fontSize=12, leading=18, textColor=HexColor("#D8E8FF")))
styles.add(ParagraphStyle(name="WhiteBody", fontName="CN", fontSize=8.5, leading=13, textColor=WHITE))
styles.add(ParagraphStyle(name="Callout", fontName="CN", fontSize=9, leading=14, textColor=NAVY))
styles.add(ParagraphStyle(name="Cell", fontName="CN", fontSize=6.7, leading=9, textColor=INK))
styles.add(ParagraphStyle(name="CellB", fontName="CNB", fontSize=6.8, leading=9, textColor=INK))
styles.add(ParagraphStyle(name="CellWhite", fontName="CNB", fontSize=6.7, leading=9, textColor=WHITE))
styles.add(ParagraphStyle(name="Metric", fontName="CNB", fontSize=14, leading=17, textColor=BLUE, alignment=TA_CENTER))
styles.add(ParagraphStyle(name="CenterSmall", fontName="CN", fontSize=7.2, leading=10, textColor=SLATE, alignment=TA_CENTER))


def P(text, style="BodyCN"):
    return Paragraph(esc(text).replace("\n", "<br/>"), styles[style])


def PR(text, style="BodyCN"):
    return Paragraph(text, styles[style])


def pill(text, bg=MINT, fg=GREEN):
    t = Table([[P(text, "SmallCN")]], colWidths=[None])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, -1), bg),
        ("TEXTCOLOR", (0, 0), (-1, -1), fg),
        ("BOX", (0, 0), (-1, -1), 0.5, bg),
        ("LEFTPADDING", (0, 0), (-1, -1), 6), ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
    ]))
    return t


def table(headers, rows, widths=None, font=6.7, header_bg=NAVY, repeat=1, row_bgs=True):
    data = [[Paragraph(esc(x), styles["CellWhite"]) for x in headers]]
    for row in rows:
        data.append([Paragraph(esc(x).replace("\n", "<br/>"), ParagraphStyle(
            name=f"c{font}", parent=styles["Cell"], fontSize=font, leading=font+2.2
        )) for x in row])
    t = Table(data, colWidths=widths, repeatRows=repeat, hAlign="LEFT")
    cmd = [
        ("BACKGROUND", (0, 0), (-1, 0), header_bg),
        ("GRID", (0, 0), (-1, -1), 0.35, LINEC),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 4), ("RIGHTPADDING", (0, 0), (-1, -1), 4),
        ("TOPPADDING", (0, 0), (-1, -1), 4), ("BOTTOMPADDING", (0, 0), (-1, -1), 4),
    ]
    if row_bgs:
        for i in range(1, len(data)):
            if i % 2 == 0:
                cmd.append(("BACKGROUND", (0, i), (-1, i), LIGHT))
    t.setStyle(TableStyle(cmd))
    return t


def callout(title, body, color=BLUE, bg=HexColor("#EEF5FF")):
    t = Table([[P(title, "H3CN"), P(body, "BodyCN")]], colWidths=[38*mm, 137*mm])
    t.setStyle(TableStyle([
        ("BACKGROUND", (0,0), (-1,-1), bg),
        ("BOX", (0,0), (-1,-1), 0.7, color),
        ("LINEBEFORE", (0,0), (0,-1), 3, color),
        ("VALIGN", (0,0), (-1,-1), "TOP"),
        ("LEFTPADDING", (0,0), (-1,-1), 7), ("RIGHTPADDING", (0,0), (-1,-1), 7),
        ("TOPPADDING", (0,0), (-1,-1), 7), ("BOTTOMPADDING", (0,0), (-1,-1), 7),
    ]))
    return t


def section(title, subtitle=None):
    items = [P(title, "H1CN")]
    if subtitle:
        items.append(P(subtitle, "SmallCN"))
        items.append(Spacer(1, 2*mm))
    return items


class AccentRule(Flowable):
    def __init__(self, width=177*mm):
        super().__init__(); self.width=width; self.height=3*mm
    def draw(self):
        self.canv.setFillColor(BLUE); self.canv.roundRect(0, 1*mm, self.width*0.7, 1.5*mm, 0.75*mm, fill=1, stroke=0)
        self.canv.setFillColor(GREEN); self.canv.roundRect(self.width*0.71, 1*mm, self.width*0.29, 1.5*mm, 0.75*mm, fill=1, stroke=0)


def flow_diagram(labels, colors_=None):
    w, h = 177*mm, 27*mm
    d = Drawing(w, h)
    n = len(labels); gap = 3*mm; bw = (w-gap*(n-1))/n
    cols = colors_ or [BLUE, CYAN, GREEN, ORANGE, BLUE, GREEN, CYAN, NAVY]
    for i, label in enumerate(labels):
        x = i*(bw+gap)
        d.add(Rect(x, 6*mm, bw, 13*mm, 3*mm, fillColor=HexColor("#F5F8FC"), strokeColor=cols[i%len(cols)], strokeWidth=1))
        d.add(String(x+bw/2, 12.4*mm, label, fontName="CNB", fontSize=6.8, textAnchor="middle", fillColor=INK))
        if i < n-1:
            ax = x+bw+0.5*mm
            d.add(Line(ax, 12.5*mm, ax+2*mm, 12.5*mm, strokeColor=SLATE, strokeWidth=1))
            d.add(Polygon([ax+2*mm,12.5*mm,ax+0.8*mm,13.4*mm,ax+0.8*mm,11.6*mm], fillColor=SLATE, strokeColor=SLATE))
    return d


def metric_cards(items):
    cells=[]
    for value, label, note, color in items:
        cells.append([PR(f'<font color="{color.hexval()}"><b>{esc(value)}</b></font>', "Metric"), P(label, "CenterSmall"), P(note, "TinyCN")])
    t=Table([cells], colWidths=[177*mm/len(cells)])
    t.setStyle(TableStyle([
        ("BACKGROUND",(0,0),(-1,-1),LIGHT),("BOX",(0,0),(-1,-1),0.5,LINEC),("INNERGRID",(0,0),(-1,-1),0.5,LINEC),
        ("VALIGN",(0,0),(-1,-1),"MIDDLE"),("ALIGN",(0,0),(-1,-1),"CENTER"),
        ("TOPPADDING",(0,0),(-1,-1),7),("BOTTOMPADDING",(0,0),(-1,-1),7),
    ])); return t


def page_header_footer(canvas, doc):
    canvas.saveState()
    if doc.page > 1:
        canvas.setFont("CN", 6.5); canvas.setFillColor(SLATE)
        canvas.drawString(MARGIN_X, PAGE_H-9*mm, "光衡 | PRD V3.2 | 设备与电站价值闭环增强版")
        canvas.drawRightString(PAGE_W-MARGIN_X, PAGE_H-9*mm, "Autonomous Energy Agent")
        canvas.setStrokeColor(LINEC); canvas.line(MARGIN_X, PAGE_H-11*mm, PAGE_W-MARGIN_X, PAGE_H-11*mm)
        canvas.setFont("CN", 6.3)
        canvas.drawString(MARGIN_X, 8*mm, "基于 V3.1 开发冻结版增量修订 | 内部产品与研发基线")
        canvas.drawRightString(PAGE_W-MARGIN_X, 8*mm, str(doc.page))
    canvas.restoreState()


doc = BaseDocTemplate(str(OUT), pagesize=A4, leftMargin=MARGIN_X, rightMargin=MARGIN_X, topMargin=TOP, bottomMargin=BOTTOM,
                      title="光衡 PRD V3.2 设备与电站价值闭环增强版", author="GuangHeng Product Team")
frame = Frame(MARGIN_X, BOTTOM, PAGE_W-2*MARGIN_X, PAGE_H-TOP-BOTTOM, id="main")
doc.addPageTemplates([PageTemplate(id="p", frames=[frame], onPage=page_header_footer)])

story=[]

# Cover
cover = Drawing(177*mm, 245*mm)
cover.add(Rect(0,0,177*mm,245*mm,fillColor=NAVY,strokeColor=None))
cover.add(Circle(148*mm,218*mm,40*mm,fillColor=HexColor("#123C70"),strokeColor=None))
cover.add(Circle(151*mm,218*mm,27*mm,fillColor=HexColor("#126F91"),strokeColor=None))
cover.add(Circle(151*mm,218*mm,15*mm,fillColor=GREEN,strokeColor=None))
cover.add(Rect(0,0,177*mm,26*mm,fillColor=HexColor("#08172C"),strokeColor=None))
story += [cover]
# Overlay title using negative-ish layout is difficult; use absolute canvas via a cover table placed after drawing? Drawing consumed page.
story[-1] = Table([[
    PR("<font color='#77E7BC'><b>光衡</b></font><br/><font size='11' color='#A8C8F2'>Autonomous Energy Agent</font><br/><br/>"
       "<font size='29' color='white'><b>产品需求文档 PRD V3.2</b></font><br/>"
       "<font size='15' color='#D8E8FF'>设备与电站价值闭环增强版</font><br/><br/>"
       "<font size='10' color='white'>在 V3.1 安全执行主线之上，补齐电站、储能、家庭负载、多设备与运维闭环</font><br/><br/><br/>"
       "<font size='12' color='#77E7BC'><b>核心叙事</b></font><br/>"
       "<font size='10' color='white'>看懂能源系统 → 发现高价值问题 → 给出可验证方案 → 安全控制 → 回读证明 → 价值复盘</font><br/><br/><br/>"
       "<font size='9' color='#A8C8F2'>基线：光衡 PRD V3.1 开发冻结版<br/>输入：用户提供的 4:06 对标产品交互视频、现有 GuangHeng 前后端与 SOLIX 能力矩阵<br/>版本日期：2026-09-23<br/>状态：产品扩展评审稿，可用于功能拆解、原型修订和研发排期</font>", "CoverSub")
]], colWidths=[177*mm], rowHeights=[245*mm])
story[-1].setStyle(TableStyle([
    ("BACKGROUND",(0,0),(-1,-1),NAVY),("VALIGN",(0,0),(-1,-1),"MIDDLE"),
    ("LEFTPADDING",(0,0),(-1,-1),16*mm),("RIGHTPADDING",(0,0),(-1,-1),14*mm),
    ("TOPPADDING",(0,0),(-1,-1),12*mm),("BOTTOMPADDING",(0,0),(-1,-1),12*mm),
]))
story.append(PageBreak())

# 0 Executive summary
story += section("0. 执行摘要", "V3.2 是 V3.1 的增量增强，不改写安全架构，不把产品退化成设备遥控器。")
story.append(callout("产品决定", "保留 V3.1 的 Agent 主闭环为最高优先级；新增的电站、储能、负载、设备能力都必须进入同一条证据链。任何远程控制都继续经过能力探测、权限、Proposal/Approval、Safety、Execution 和 Readback Verification。", GREEN, MINT))
story.append(Spacer(1,4*mm))
story.append(metric_cards([
    ("5", "高价值闭环", "电站、储能、负载、多设备、运维", BLUE),
    ("4", "能力状态", "已具备 / 可开发 / 依赖接入 / 不承诺", GREEN),
    ("3", "核心对象", "家庭、电站、设备", CYAN),
    ("1", "可信主线", "V3.1 执行与验证链", ORANGE),
]))
story.append(Spacer(1,5*mm))
story.append(P("V3.2 解决的根本问题", "H2CN"))
story.append(table(["用户问题", "过去的体验", "V3.2 的解决方式", "验证结果"], [
    ["看见很多数据，但不知道该做什么", "首页像仪表盘，信息彼此割裂", "把异常、机会和下一步行动放在能源拓扑上，点击节点进入原因与建议", "用户能从状态直接到 Proposal"],
    ["电池有 SOC，却不知道能撑多久", "只显示百分比", "显示额定/当前/保护/可调度电量、关键负载、备电时长区间与假设", "Reserve 变化可映射到 Backup Hours"],
    ["家庭用电高，却不知道谁在耗电", "只有总负载", "用 HA Area + Smart Plug/开关构建房间/回路视图，标记高耗与待机异常", "控制后真实回读功率和节省"],
    ["设备多，能力不一致", "为单型号硬编码页面", "动态发现设备并按 Capability Profile 渲染；没有能力就不出现控制", "UI 与真实 Entity 能力一致"],
    ["远程控制不敢用", "点击后只显示成功 Toast", "审批、二次安全检查、幂等执行、读回验证、失败恢复、完整时间线", "HTTP 200 不等于成功"],
], widths=[32*mm,38*mm,68*mm,39*mm]))
story.append(Spacer(1,4*mm))
story.append(P("一句话升级", "H2CN"))
story.append(callout("从“看数”到“解决问题”", "光衡不是把更多设备卡片塞进 App，而是把每个设备能力转换成可理解、可控制、可验证、可复盘的家庭能源价值。", BLUE))
story.append(PageBreak())

# 1 version boundaries
story += section("1. 版本边界与冻结原则", "V3.1 是框架与大方向；V3.2 只做增量扩展和信息架构修订。")
story.append(table(["保持不变", "V3.2 新增", "明确不做"], [[
    "Control Plane 是唯一业务真相源\nHermes 不直接算功率、不写设备\nOptimizer 数值确定性\nConfirm 为默认模式\nProposal/Execution 双状态机\nSafety 与 Readback 不降级\nReal/Mock/Replay 同 Schema",
    "电站总览与节点钻取\n电池容量与备电时长\n房间/回路/插座视图\n多设备能力目录\n设备健康与运维闭环\n功能价值和数据就绪度报表\n跨页面统一交互模型",
    "不把未经验证的 Entity 标成可控\n不凭空推断家庭开关位置\n不承诺所有 SOLIX 型号全部字段\n不伪造 MPPT 分路或动态电价\n不复制对标 App 的视觉资产\n不以 LLM 替代安全和优化算法"
]], widths=[59*mm,59*mm,59*mm], font=7.1))
story.append(Spacer(1,5*mm))
story.append(P("能力状态标签", "H2CN"))
story.append(table(["状态", "定义", "UI 规则", "发布规则"], [
    ["A 已具备", "后端已有真实字段或稳定同 Schema Replay", "显示来源、时间和 Real/Replay 标识", "可以进入 P0"],
    ["B 可直接开发", "数据可从现有字段可靠派生", "显示公式、假设与估算置信度", "完成单测即可发布"],
    ["C 依赖接入", "需要 HA Area、设备 Registry 或额外 Entity", "显示接入引导，不显示假数据", "满足接入条件后启用"],
    ["D 暂不承诺", "官方集成未提供或未验证", "隐藏控制，必要时说明限制", "不得进入发布承诺"],
], widths=[27*mm,55*mm,58*mm,37*mm]))
story.append(Spacer(1,5*mm))
story.append(P("V3.2 成功标准", "H2CN"))
story.append(flow_diagram(["看懂", "定位", "决策", "确认", "执行", "回读", "复盘"]))
story.append(P("任何新增功能至少推进上面两个阶段；只有覆盖“决策 - 执行 - 回读 - 复盘”的能力，才属于高价值闭环。纯展示功能必须服务于定位问题或验证结果。", "BodyCN"))
story.append(PageBreak())

# 2 video research
story += section("2. 对标视频研究与设计转译", "素材：用户提供的 4:06 移动端录屏。结论来自交互路径观察，不把视频中的产品文案当作光衡需求。")
imgs=[]
for idx, cap in [(6,"约 00:40｜总览能量拓扑"),(13,"约 01:36｜统计与价值"),(17,"约 02:08｜设备列表"),(27,"约 03:28｜运维工单")]:
    p=ROOT/"tmp"/"video_frames"/f"frame_{idx:03d}.jpg"
    if p.exists():
        im=Image(str(p), width=30*mm, height=66*mm)
        imgs.append(Table([[im],[P(cap,"TinyCN")]], colWidths=[37*mm]))
story.append(Table([imgs], colWidths=[44*mm]*4, hAlign="CENTER", style=TableStyle([
    ("VALIGN",(0,0),(-1,-1),"TOP"),("ALIGN",(0,0),(-1,-1),"CENTER"),
    ("LEFTPADDING",(0,0),(-1,-1),2),("RIGHTPADDING",(0,0),(-1,-1),2),
])))
story.append(Spacer(1,3*mm))
story.append(table(["视频中的有效模式", "为什么有效", "光衡的转译", "不能照搬的部分"], [
    ["总览先呈现能量关系", "用户先判断系统是否正常", "首页 3D 能源拓扑 + 电站总览共享同一数据模型", "不使用无意义装饰线；流向必须与功率一致"],
    ["从总览钻取到设备详情", "减少一次展示全部信息的拥挤感", "点击光伏/电池/家庭/电网进入专属详情", "不把所有传感器平铺为长列表"],
    ["设备控制和统计在同一上下文", "控制前能看见依据", "控制入口旁显示当前值、影响、风险和验证状态", "控制不绕过 Proposal/Safety"],
    ["设备列表、详情、网络、运维分层", "复杂系统仍然可定位问题", "设备中心增加健康、连接、固件、诊断和事件", "不承诺厂商云端工单能力"],
    ["统计、收益、碳价值有独立页面", "结果可被理解和分享", "报表保留 Baseline 公平比较，并关联每次决策证据", "不使用无法核验的收益数字"],
], widths=[37*mm,39*mm,58*mm,43*mm]))
story.append(Spacer(1,4*mm))
story.append(callout("设计原则", "借鉴层级、节奏与反馈，不复制皮肤。光衡的差异化必须来自 Agent 主动决策、确定性优化、安全执行与价值验证，而不是做另一个设备厂商 App。", ORANGE, HexColor("#FFF7E9")))
story.append(PageBreak())

# 3 personas pains
story += section("3. 目标用户、场景与高价值问题", "优先服务已有光伏/储能、愿意接入 Home Assistant、需要降低成本或提高备电韧性的家庭。")
story.append(table(["角色", "高频场景", "核心焦虑", "V3.2 承诺"], [
    ["家庭决策者", "每天查看光伏、储能和电费", "数据太多，不知道今天是否需要行动", "首页给出系统状态、机会、下一步和不行动后果"],
    ["能源进阶用户", "调 Reserve、充放电窗口、用电模式", "担心设错、担心自动化越权", "能力边界透明，重要动作确认，执行后可验证和回退"],
    ["备电敏感用户", "极端天气、停电预警、夜间备电", "SOC 不等于真实可用时长", "关键负载模型 + Backup Hours 区间 + 备电缺口"],
    ["多设备家庭", "储能、智能表、智能插座并存", "设备散落在不同页面，无法理解协同关系", "按家庭/电站/设备三层组织，能力驱动统一呈现"],
    ["维护者", "网络异常、离线、固件和数据异常", "不知道是设备、网络还是集成故障", "健康诊断、数据新鲜度、恢复建议与完整事件线"],
], widths=[30*mm,43*mm,50*mm,54*mm]))
story.append(Spacer(1,5*mm))
story.append(P("五个高价值闭环", "H2CN"))
story.append(table(["闭环", "触发", "行动", "回读与价值"], [
    ["1 电站感知", "功率失衡、预测变化、异常", "定位光伏/家庭/电池/电网节点", "解释当前流向，形成机会或告警"],
    ["2 储能保障", "备电时长不足、SOC 偏轨、天气变化", "生成 Reserve/计划 Proposal", "读回 Reserve/SOC，验证增加的 Backup Hours"],
    ["3 家庭负载", "总负载高、待机异常、峰时用电", "定位 Area/Plug，用户确认关闭或移峰", "读回开关与功率，计算实际节省"],
    ["4 多设备适配", "新增设备或实体变化", "发现型号、能力、权限和数据质量", "页面只暴露真实能力，审计能力变化"],
    ["5 健康运维", "离线、stale、读回失败、固件问题", "分级诊断、恢复指引、必要时停止执行", "确认恢复并记录 MTTR/失败原因"],
], widths=[31*mm,47*mm,51*mm,48*mm]))
story.append(PageBreak())

# 4 IA
story += section("4. 信息架构与导航", "沿用首页、策略、报表、设备四个主入口；设置从首页/设备页进入，避免底部导航继续膨胀。")
story.append(table(["一级入口", "第一屏任务", "二级页面", "关键动作"], [
    ["首页", "现在发生什么，是否需要行动", "电站总览、光伏详情、电池详情、家庭负载、电网详情", "旋转 3D、点节点、看详情、进入待确认方案"],
    ["策略", "为什么这样计划，是否批准", "Proposal、24h 计划、证据、策略偏好、自治级别", "批准/拒绝、查看原因、回放执行"],
    ["报表", "结果是否真实，有何价值", "费用日历、节省趋势、碳减排、备电、决策时间线", "切周期、点数据、追溯决策"],
    ["设备", "有哪些设备，是否健康，能否控制", "设备列表、设备详情、能力、连接、诊断", "筛选、绑定、控制、查看健康"],
], widths=[25*mm,44*mm,64*mm,44*mm]))
story.append(Spacer(1,5*mm))
story.append(P("统一钻取路径", "H2CN"))
story.append(flow_diagram(["家庭", "电站", "节点", "设备", "能力", "执行", "证据"]))
story.append(P("同一个对象在不同页面只改变任务视角，不改变数据语义。例如电池在首页展示 SOC 与流向，在电池详情展示容量和时长，在策略页展示计划，在报表页展示执行结果；所有页面引用同一 device_id、capability_id 和 observed_at。"))
story.append(Spacer(1,4*mm))
story.append(P("跨页面一致性规则", "H2CN"))
story.append(table(["规则", "冻结要求"], [
    ["状态颜色", "蓝=信息/选中，绿=正常/完成，橙=待确认/注意，红=阻断/严重；必须同时配文字和图标"],
    ["可交互提示", "节点必须有标签、数值、轻微呼吸或按压反馈；首次进入显示一次性引导"],
    ["动效", "300-450ms 页面过渡；数值补间；流线速度映射功率；Reduce Motion 时关闭位移与连续动画"],
    ["数据来源", "Real/Mock/Replay、observed_at、quality 在详情可见；stale 时不继续播放正常流线"],
    ["控制反馈", "提交后进入执行进度，不用 Toast 代替结果；失败显示原因、是否回退和下一步"],
], widths=[31*mm,146*mm]))
story.append(PageBreak())

# 5 station overview
story += section("5. 电站总览与光伏详情", "目标：让用户在 5 秒内判断“系统是否正常、能量去哪了、今天表现如何、下一步是否要行动”。")
story.append(table(["模块", "展示", "交互", "数据要求"], [
    ["实时拓扑", "PV、家庭、电池、电网、可选智能表/插座聚合", "点节点钻取；双指/拖动旋转 3D", "功率方向、单位、observed_at、quality"],
    ["今日概览", "发电、用电、购电、送电、自用率、独立率", "点指标进入日曲线", "服务器持续采样/聚合，不依赖 App 打开"],
    ["未来 24h", "PV/负载预测、Reserve 轨迹、计划阶段", "拖动时间游标；查看证据", "forecast version + confidence"],
    ["异常与机会", "预测下降、负载突升、数据断流、设备离线", "查看原因；进入 Proposal 或诊断", "Trigger + evidence_id"],
], widths=[30*mm,51*mm,48*mm,48*mm]))
story.append(Spacer(1,4*mm))
story.append(P("光伏详情", "H2CN"))
story.append(table(["优先级", "功能", "用户价值", "边界"], [
    ["P0", "当前功率、今日/本周/本月发电、预测与实际、峰值时段", "看出今天发电是否符合预期", "使用真实可用聚合字段"],
    ["P0", "发电去向：家庭直用、充电、送电", "理解自用率和能源流向", "缺少分项时展示估算并标明"],
    ["P1", "天气影响解释与异常偏差", "判断阴云还是设备问题", "解释必须引用天气与预测证据"],
    ["P2", "组件/MPPT 分路", "定位串级故障", "仅当官方集成真实提供各路 Entity 才显示"],
], widths=[19*mm,53*mm,57*mm,48*mm]))
story.append(Spacer(1,4*mm))
story.append(callout("关键限制", "当前官方集成并不保证暴露所有 MPPT 分路。V3.2 不把“组件级电站视图”写成默认承诺；没有真实 Entity 时只展示站级 PV 总览。", RED, HexColor("#FFF1F1")))
story.append(PageBreak())

# 6 battery
story += section("6. 电池详情与备电保障", "电池详情不以 SOC 结束，而要回答“有多少电、能用多久、哪些电受保护、现在是否需要调整”。")
story.append(metric_cards([
    ("77%", "当前 SOC", "实时读数示例", BLUE),
    ("7.7 kWh", "当前储能", "10.0 × 77%", GREEN),
    ("8.0 kWh", "备电目标", "Reserve 80%", ORANGE),
    ("0.3 kWh", "备电缺口", "示例，需补足", RED),
]))
story.append(Spacer(1,4*mm))
story.append(table(["区块", "内容", "用户问题", "动作"], [
    ["能量环", "SOC、额定容量、当前能量、保护能量、可调度能量", "我现在真正能用多少？", "查看计算说明"],
    ["备电时长", "全屋/关键负载两种时长区间、效率与负载假设", "停电能撑多久？", "编辑关键负载"],
    ["功率状态", "充/放电功率、状态、温度/健康（若可用）", "电池现在在做什么？", "查看实时曲线"],
    ["边界设置", "Reserve、充电上限、放电下限、功率边界", "系统会不会把电用光？", "仅 verified 能力可写"],
    ["计划与建议", "未来 24h SOC 轨迹、下一动作、Proposal", "今晚是否需要提前充？", "批准或拒绝"],
    ["身份健康", "型号、序列号脱敏、固件、连接、数据新鲜度", "读数可靠吗？", "诊断"],
], widths=[31*mm,59*mm,48*mm,39*mm]))
story.append(Spacer(1,4*mm))
story.append(P("冻结公式", "H2CN"))
story.append(table(["指标", "公式", "展示要求"], [
    ["当前储能", "rated_capacity_kwh × SOC / 100", "容量缺失时不计算"],
    ["保护能量", "rated_capacity_kwh × reserve_soc / 100", "Reserve 来自当前读回值"],
    ["可调度能量", "max(0, 当前储能 - max(保护能量, 放电下限能量))", "不可为负"],
    ["Backup Hours", "可用备电量 × discharge_efficiency / 关键负载预测功率", "显示区间、负载清单、效率和置信度"],
    ["备电缺口", "max(0, reserve_energy - current_energy)", "触发建议时关联天气/停电风险"],
], widths=[34*mm,83*mm,60*mm]))
story.append(Spacer(1,3*mm))
story.append(P("示例数据仅用于说明计算关系，不作为真实家庭承诺。若当前 SOC 低于 Reserve 但设备正在充电，UI 显示“正在补足备电”，而不是误报故障。", "SmallCN"))
story.append(PageBreak())

# 7 home load
story += section("7. 家庭负载、房间与远程控制", "“家庭开关位置”必须来自 Home Assistant Area/楼层/设备关系，不允许系统凭空猜测。")
story.append(flow_diagram(["HA Area", "楼层/房间", "设备", "实时功率", "异常", "确认控制", "功率回读"]))
story.append(Spacer(1,3*mm))
story.append(table(["层级", "展示", "可控条件", "降级"], [
    ["家庭", "总负载、当前峰值、今日用电、主要来源", "无直接控制", "只有总表时只展示总负载"],
    ["楼层/房间", "Area 聚合功率、在线设备数、异常标签", "Area 内存在 verified 开关/插座", "无法分项时显示设备列表，不显示虚假房间功率"],
    ["智能插座", "开关、当前功率、累计电量、在线状态", "Entity 可写、权限允许、在线、可读回", "未验证写能力时只读"],
    ["固定负载", "设备状态和用电趋势", "只有明确允许的 HA Service", "不可控设备不显示开关"],
], widths=[29*mm,58*mm,55*mm,35*mm]))
story.append(Spacer(1,4*mm))
story.append(P("远程控制闭环", "H2CN"))
story.append(table(["步骤", "系统行为", "用户反馈"], [
    ["1 识别", "设备功率异常或用户主动点选", "显示设备、位置、当前功率、数据时间"],
    ["2 影响", "估算关闭后的影响与风险", "例如“预计减少 0.8 kW；冰箱等关键设备不可推荐关闭”"],
    ["3 确认", "普通动作确认；重大/关键动作强确认", "展示将控制的准确设备与状态"],
    ["4 执行", "后端调用白名单 Adapter", "进度：准备/安全检查/写入/验证"],
    ["5 回读", "验证开关状态和功率变化", "成功、部分成功、失败/回退"],
    ["6 复盘", "计算实际减少的功率/电量", "进入报表和 Decision Timeline"],
], widths=[24*mm,79*mm,74*mm]))
story.append(Spacer(1,3*mm))
story.append(callout("安全边界", "智能插座接入不等于可以自动关断。冰箱、医疗设备、网络设备、安防和用户标记的关键负载默认禁止 Agent 自动关闭；完全访问模式也必须遵守硬限制。", RED, HexColor("#FFF1F1")))
story.append(PageBreak())

# 8 multi device
story += section("8. 多设备中心与能力驱动架构", "从“一个 YAML 对应一个设备”升级为“设备发现 + 型号 Profile + Entity 映射 + 运行时 CapabilitySnapshot”。")
story.append(table(["设备族", "主要展示", "候选控制", "V3.2 状态"], [
    ["Solarbank 4 E5000 Pro", "SOC、容量、PV/负载/电网、充放电、状态、固件", "Reserve 已验证；其他控制需逐项验证", "P0 主设备"],
    ["Solarbank Max AC / Max", "储能、电网、PV、状态和能力", "按官方 Entity 与 capability bit 暴露", "P1 接入验证"],
    ["SOLIX XE AC / XE", "储能、功率、状态和身份", "同上，不按名称推断能力", "P1 接入验证"],
    ["Smart Meter Gen 2", "CT 分组、购售电、功率因数、累计电量（视版本）", "默认监测，不假设可写", "P1 负载可观测"],
    ["Smart Plug Gen 2", "开关、功率、累计电量、在线", "on/off；必须 readback", "P1 负载控制"],
    ["Smart Plug 旧型号", "以官方集成实际支持为准", "不承诺", "D 暂不承诺"],
], widths=[39*mm,61*mm,50*mm,27*mm], font=6.5))
story.append(Spacer(1,4*mm))
story.append(P("后台对象模型", "H2CN"))
story.append(table(["对象", "关键字段", "作用"], [
    ["DeviceProfile", "manufacturer, model_family, integration_min_version, region", "定义型号级候选字段，不代表运行时可用"],
    ["DiscoveredDevice", "ha_device_id, model, serial_hash, area_id, online", "HA Registry 中的真实设备"],
    ["CapabilitySnapshot", "capability_id, entity_id, access, verified, min/max/step", "决定 UI 与 Safety，可版本化审计"],
    ["Observation", "value, unit, observed_at, last_reported, quality, source_mode", "区分读取时间与值变化时间"],
    ["ControlPolicy", "approval_level, allowlist, critical_load, verify_rule", "统一控制权限和读回规则"],
], widths=[38*mm,84*mm,55*mm]))
story.append(Spacer(1,4*mm))
story.append(P("发现流程", "H2CN"))
story.append(flow_diagram(["HA Registry", "识别型号", "匹配 Profile", "映射 Entity", "验证读写", "保存快照", "渲染 UI"]))
story.append(P("新增设备、Integration 升级或 Entity 变化时重新发现并生成新快照。若能力从可写变为只读，所有未执行 Proposal 立即失效；不得沿用旧缓存继续写入。", "BodyCN"))
story.append(PageBreak())

# 9 detailed capabilities
story += section("9. Solarbank 4 E5000 Pro 功能基线", "根据用户提供的 HA 截图与当前能力矩阵整理；最终以运行时发现结果为准。")
story.append(table(["类别", "能力", "当前样例", "状态", "产品用法"], [
    ["实时", "SOC", "77%", "A 已具备", "首页、电池、备电时长"],
    ["实时", "Solar / Home Load", "3.7 / 2.5 kW", "A 已具备", "拓扑与流向"],
    ["实时", "Battery charge/discharge", "1.2 / 0 kW", "A 已具备", "充放电状态与验证"],
    ["实时", "Grid import/export, AC output", "0 / 0 / 0 W", "A 已具备", "电网节点和能量平衡"],
    ["累计", "PV generation", "24.8 kWh", "A 已具备", "今日/周期发电"],
    ["累计", "Battery charging/discharge energy", "123.4 / 98.7 kWh", "A 已具备", "吞吐量与健康参考"],
    ["身份", "Capacity / model / firmware / status", "10.0 kWh / SIM-1.0.0 / Charging", "A 已具备", "设备详情与诊断"],
    ["控制", "Backup Reserve", "80%", "A 已验证可写", "P0 Proposal + Safety + Readback"],
    ["控制", "Charging / Discharge Limit", "90% / 10%", "C 待验证", "验证前只读"],
    ["控制", "Operating Mode / Grid Flow / Power", "Third-Party / G2B / 0 W", "C 待验证", "验证后按枚举/范围开放"],
], widths=[19*mm,52*mm,43*mm,29*mm,34*mm], font=6.4))
story.append(Spacer(1,4*mm))
story.append(callout("数据口径", "Anker App 的云端统计与 Home Assistant 的本地原始读数可能采用不同聚合周期。光衡报表必须标注来源、采样覆盖率和聚合方法，不能把差异直接判定为设备故障。", ORANGE, HexColor("#FFF7E9")))
story.append(Spacer(1,4*mm))
story.append(P("能力开放规则", "H2CN"))
story.append(table(["条件", "必须满足"], [
    ["展示数据", "当前 HA 请求成功；capability available；单位可标准化；observed_at 来自本次 observation"],
    ["展示控制", "access=read_write；verified=true；control_enabled=true；设备在线；范围和 step 已知"],
    ["允许执行", "有效 Proposal + 用户/自治授权 + Safety 全部通过 + 执行前实时 observation"],
    ["判定成功", "目标 Entity 按验证规则回读成功；HTTP 200 只记录为 apply response"],
], widths=[35*mm,142*mm]))
story.append(PageBreak())

# 10 health
story += section("10. 设备健康与运维闭环", "从“设备离线”单一提示，升级为可定位、可恢复、可追踪的健康体系。")
story.append(table(["等级", "示例", "产品行为", "是否阻断控制"], [
    ["正常", "在线、Observation 新鲜、能力可用", "显示最近同步时间", "否"],
    ["提示", "稳定值 last_reported 较旧，但本次 HA observation 成功", "作为诊断警告，不误判整机离线", "单独不阻断"],
    ["注意", "部分 Entity unavailable、功率平衡残差持续偏大", "降级相关功能，提示检查接线/集成", "阻断依赖该数据的动作"],
    ["严重", "HA 请求失败、设备 offline、能力变更、读回失败", "停止写入、发送告警、提供恢复路径", "是"],
], widths=[24*mm,58*mm,62*mm,33*mm]))
story.append(Spacer(1,4*mm))
story.append(P("诊断页面结构", "H2CN"))
story.append(table(["区块", "内容"], [
    ["连接", "HA 可达性、Integration 版本、设备在线、最近 observation、网络路径"],
    ["数据", "available 数、unavailable 数、last_reported 年龄、采样覆盖率、功率平衡残差"],
    ["控制", "verified 能力、最近执行、最近读回、失败原因、回退结果"],
    ["身份", "型号、固件、序列号脱敏、Area、首次/最近发现时间"],
    ["恢复", "刷新发现、重新验证、打开 HA 设备页、导出脱敏诊断包"],
], widths=[32*mm,145*mm]))
story.append(Spacer(1,4*mm))
story.append(flow_diagram(["发现异常", "确定范围", "禁止风险动作", "给出恢复", "重新观测", "恢复能力", "记录结果"]))
story.append(PageBreak())

# 11 agent integration
story += section("11. Agent、策略与新增功能的协同", "新增设备功能不建立第二套决策逻辑；Hermes 仍只负责观察、工具编排和解释。")
story.append(table(["场景", "Hermes/规则", "Optimizer/Domain", "Proposal", "执行"], [
    ["未来 PV 下跌", "识别天气与预测证据", "计算 Reserve/SOC 轨迹", "提前补能", "经批准写 Reserve/模式"],
    ["备电时长不足", "解释关键负载与缺口", "计算满足目标时长的 Reserve", "增加备电", "读回并更新 Backup Hours"],
    ["家庭负载异常", "指出 Area/Plug 与证据", "估算影响，不由 LLM 编造", "关闭/移峰建议", "用户确认后控制并读回功率"],
    ["设备能力变化", "解释为什么控制消失", "不生成不可执行计划", "使旧提案 superseded", "禁止写入"],
    ["设备离线", "提供诊断步骤", "计划降级或 infeasible", "不生成虚假收益", "阻断"],
], widths=[34*mm,42*mm,42*mm,34*mm,25*mm], font=6.3))
story.append(Spacer(1,4*mm))
story.append(P("权限模式命名", "H2CN"))
story.append(table(["模式", "用户可见名称", "行为", "重大动作"], [
    ["Observe", "观察", "只展示和解释", "不可执行"],
    ["Shadow", "影子运行", "生成方案但不执行，事后比较", "不可执行"],
    ["Confirm", "确认后执行", "每个可执行 Proposal 由用户批准", "必须确认"],
    ["Autopilot", "完全访问", "白名单低风险动作可自动执行", "Reserve 大幅变化、关键负载、越界风险仍确认"],
], widths=[28*mm,34*mm,67*mm,48*mm]))
story.append(Spacer(1,4*mm))
story.append(callout("完全访问不是无限权限", "用户开启时必须经过独立风险弹窗并明确授权范围、有效期、可撤销性和仍需确认的动作。Safety、设备硬限制、关键负载保护和 Readback 永远不能关闭。", RED, HexColor("#FFF1F1")))
story.append(PageBreak())

# 12 data and api
story += section("12. 数据、服务与 API 增量", "P0 优先复用现有 Domain Services；扩展接口只承载真实设备和聚合数据。")
story.append(table(["模块", "新增/调整", "关键输出"], [
    ["Device Discovery", "从单一 YAML 改为 Profile Catalog + HA Device/Entity Registry", "devices[], capability_snapshots[]"],
    ["Telemetry Ingestion", "服务端常驻采样和聚合，不依赖 Flutter 打开", "observations, hourly/daily aggregates, coverage"],
    ["Home Graph", "Area/楼层/设备关系与关键负载标签", "home_graph, room_loads, controllable_nodes"],
    ["Station Summary", "统一 PV/Battery/Home/Grid 站级语义", "flow, day_metrics, anomalies"],
    ["Battery Service", "容量、保护能量、可调度能量、Backup Hours", "battery_insight + assumptions"],
    ["Health Service", "连接、数据、能力、执行健康", "health_status, diagnostics, recovery_actions"],
], widths=[37*mm,86*mm,54*mm]))
story.append(Spacer(1,4*mm))
story.append(P("建议 API", "H2CN"))
story.append(table(["方法", "路径", "说明"], [
    ["GET", "/api/v1/stations/current", "电站总览、实时流向、今日指标和质量"],
    ["GET", "/api/v1/stations/current/history?range=day", "服务器聚合曲线与覆盖率"],
    ["GET", "/api/v1/devices", "动态发现的设备列表与健康摘要"],
    ["GET", "/api/v1/devices/{id}", "身份、Telemetry、Capability 与健康"],
    ["GET", "/api/v1/devices/{id}/battery-insight", "容量、Reserve、Backup Hours 与假设"],
    ["GET", "/api/v1/home-graph", "楼层、Area、设备和关键负载"],
    ["POST", "/api/v1/control-intents", "创建控制意图；后端决定是否转 Proposal"],
    ["GET", "/api/v1/health/summary", "HA/Integration/设备/数据/执行健康"],
], widths=[20*mm,75*mm,82*mm]))
story.append(Spacer(1,3*mm))
story.append(P("控制 API 不直接接受任意 entity_id 或 service。客户端提交 device_id + capability_id + target；后端从当前 CapabilitySnapshot 解析白名单动作。", "SmallCN"))
story.append(PageBreak())

# 13 screen specs
story += section("13. 核心页面与交互验收", "以下为产品级交互要求，视觉稿可继续细化，但信息优先级和状态反馈不得削弱。")
story.append(table(["页面", "第一屏", "关键交互", "异常态"], [
    ["首页", "天气、Agent、3D 拓扑、四节点、待确认 Proposal", "旋转 3D；热点；上滑不与模型手势冲突", "stale 灰线；模型静态降级"],
    ["电站总览", "站级拓扑、今日指标、24h 预测", "点节点、时间游标、指标钻取", "字段缺失显示不可用，不补 0"],
    ["电池详情", "SOC 环、容量、Backup Hours、Reserve", "切全屋/关键负载；编辑假设；申请调整", "容量未知时隐藏派生值"],
    ["家庭负载", "楼层/房间地图、负载排名、异常", "点房间、点插座、确认控制", "无 Area 时使用设备分组"],
    ["设备中心", "设备卡、类型、在线、健康、能力数", "筛选、搜索、进入详情", "集成离线时整体告警"],
    ["设备详情", "身份、状态、能力、历史、控制", "只对 verified 控件开放", "控制能力变化时解释原因"],
    ["执行进度", "目标、步骤、当前状态、时间线", "查看 Safety 原因、读回样本、回退", "失败不能只弹 Toast"],
], widths=[27*mm,55*mm,58*mm,37*mm], font=6.3))
story.append(Spacer(1,4*mm))
story.append(P("首页手势冲突规则", "H2CN"))
story.append(table(["手势", "模型区域", "页面滚动"], [
    ["单指短拖", "水平位移优先时旋转模型", "垂直位移超过阈值后交给 ScrollView"],
    ["双指", "缩放/旋转模型", "不触发页面滚动"],
    ["单击热点", "打开详情", "不触发滚动"],
    ["惯性结束", "模型动画 250-350ms", "滚动保持系统惯性"],
], widths=[33*mm,72*mm,72*mm]))
story.append(Spacer(1,4*mm))
story.append(P("动效语义", "H2CN"))
story.append(table(["动效", "触发", "语义"], [
    ["能量流线", "实时功率有效", "方向=能量方向；速度/粗细=功率区间"],
    ["数值补间", "新 observation 到达", "避免跳变，但不得掩盖数据时间"],
    ["Plan Morph", "旧计划切到新计划", "帮助用户理解哪一段改变"],
    ["执行时间线", "状态机推进", "每一步可追踪，可停在失败节点"],
    ["报表入场", "图表进入可视区域", "一次性绘制，不循环抢注意力"],
], widths=[34*mm,48*mm,95*mm]))
story.append(PageBreak())

# 14 priority framework
story += section("14. 功能优先级", "评分维度：用户价值 30%、闭环贡献 25%、Demo 证明力 20%、数据就绪度 15%、研发成本反向 10%。满分 100。")
priority_rows = [
    ["P0", "V3.1 主闭环回归", "100", "一切新增功能的可信基础", "已有"],
    ["P0", "电站实时拓扑与节点钻取", "92", "高频入口 + Demo 直观", "已有大部分字段"],
    ["P0", "电池容量/备电时长/Reserve 缺口", "91", "直接解决备电焦虑", "可派生"],
    ["P0", "服务器端 Telemetry 常驻采样与聚合", "90", "保证图表不是手机开着才有数据", "需完善"],
    ["P0", "设备详情与能力状态", "88", "让可控边界透明", "已有基础"],
    ["P0", "Reserve 控制完整闭环", "88", "唯一已验证写能力", "已有"],
    ["P0.5", "设备健康与诊断", "82", "提高可靠性和演示抗风险", "部分已有"],
    ["P1", "动态多设备发现与 Profile Catalog", "81", "从单机 Demo 走向平台", "需改造"],
    ["P1", "HA Area 家庭负载视图", "78", "定位家庭耗电来源", "依赖 Area/实体"],
    ["P1", "Smart Plug Gen 2 控制闭环", "76", "形成负载侧执行价值", "依赖实机验证"],
    ["P1", "Smart Meter Gen 2 细分计量", "74", "提升负载和电网可观测性", "依赖设备/版本"],
    ["P2", "更多储能型号写能力", "62", "扩展覆盖", "验证成本高"],
    ["P2", "MPPT/组件级视图", "48", "运维价值高但数据未保证", "暂不承诺"],
    ["P2", "厂商工单/售后闭环", "42", "完整运维体验", "缺少正式接口"],
]
story.append(table(["优先级", "功能", "得分", "原因", "就绪度"], priority_rows,
                   widths=[18*mm,67*mm,18*mm,49*mm,25*mm], font=6.2))
story.append(Spacer(1,4*mm))
story.append(callout("排期原则", "先让已有真实数据形成完整洞察与控制闭环，再扩设备数量。多接入十个只读设备，不如把一个 Reserve 调整从原因、批准、安全、执行、读回到 Backup Hours 价值证明做完整。", GREEN, MINT))
story.append(PageBreak())

# 15 feature report
story += section("15. 功能价值报表", "每项功能都绑定痛点、数据、动作、指标与发布门槛；用于产品评审和迭代验收。")
feature_rows = [
    ["电站拓扑", "不知道能量去哪", "PV/Load/Grid/Battery", "钻取节点", "首屏理解率、详情到达率", "P0"],
    ["发电表现", "无法判断发电是否正常", "实际+预测+天气", "查看偏差", "预测误差、异常确认率", "P0"],
    ["电池洞察", "SOC 不等于可用价值", "SOC/容量/Reserve/负载", "调整关键负载或 Reserve", "Backup Hours 可解释率", "P0"],
    ["Reserve 提案", "手动设置难且有风险", "Optimizer+能力+上下文", "批准/拒绝", "验证成功率、拒绝原因", "P0"],
    ["服务端历史", "手机未开就缺图表", "后台采样/聚合", "切换日周月", "采样覆盖率、数据完整率", "P0"],
    ["设备健康", "故障无法定位", "连接/数据/能力/执行", "诊断/刷新", "MTTR、重复故障率", "P0.5"],
    ["房间负载", "总用电高但找不到来源", "HA Area+Meter/Plug", "钻取房间", "可归因负载比例", "P1"],
    ["插座控制", "无法远程减少浪费", "Switch+Power+Readback", "确认关闭", "读回成功率、实际节电", "P1"],
    ["多设备目录", "设备扩展需改代码", "Registry+Profile", "发现/绑定", "自动识别率、能力映射率", "P1"],
    ["组件级诊断", "串级故障难定位", "MPPT Entity", "查看分路", "故障定位时长", "P2"],
]
story.append(table(["功能", "解决痛点", "输入", "用户动作", "核心 KPI", "优先级"], feature_rows,
                   widths=[27*mm,42*mm,41*mm,28*mm,27*mm,12*mm], font=5.9))
story.append(Spacer(1,4*mm))
story.append(P("北极星与护栏指标", "H2CN"))
story.append(table(["类型", "指标", "定义"], [
    ["北极星", "可验证价值闭环完成率", "进入执行的 Proposal 中，完成 readback 且产生价值结果的比例"],
    ["理解", "决策理解率", "用户在不展开技术详情时能回答原因、变化、风险和收益"],
    ["可靠性", "控制验证成功率", "Verified / 已开始真实执行；分型号与能力统计"],
    ["数据", "Telemetry 覆盖率", "有效 observation 时间片 / 应有时间片"],
    ["安全", "越权写入数", "必须恒为 0；包括无批准、无能力、无读回规则"],
    ["打扰", "无效提案率", "用户拒绝或后续证明收益低于阈值的提案占比"],
    ["价值", "实际节省/备电提升", "与公平 Baseline 比较；不能使用前端本地累计替代"],
], widths=[25*mm,53*mm,99*mm]))
story.append(PageBreak())

# 16 roadmap
story += section("16. 研发里程碑与依赖", "不按页面切割，而按可演示、可验证的业务切片推进。")
story.append(table(["里程碑", "范围", "退出条件", "依赖"], [
    ["M0 可信基线", "回归 V3.1 主闭环；服务器采样和历史聚合", "历史不依赖 App；64+ 测试通过；Replay 稳定", "现有后端"],
    ["M1 电站与电池", "总览、光伏、电池、Backup Hours、Reserve", "真实数据可钻取；Reserve 从提案到读回完成", "Solarbank 4 能力"],
    ["M2 设备平台", "Profile Catalog、动态发现、健康与能力详情", "新增设备无需改核心 UI；能力变化可审计", "HA Registry"],
    ["M3 家庭负载", "Area/房间、Smart Meter/Plug、关键负载", "至少一个 Plug 控制完成读回与节省验证", "设备/Area 配置"],
    ["M4 扩展型号", "Max/XE/更多设备验证", "逐型号发布 Capability Contract", "实机与官方版本"],
], widths=[29*mm,61*mm,58*mm,29*mm]))
story.append(Spacer(1,5*mm))
story.append(P("关键依赖清单", "H2CN"))
story.append(table(["依赖", "需要确认", "未满足时"], [
    ["Anker SOLIX Official Integration", "版本、型号、固件、地区、Entity 和可写 Service", "只读或 Replay，不猜能力"],
    ["Home Assistant Registry", "Device/Entity/Area 关系、更新事件", "退化为设备列表"],
    ["服务器常驻任务", "采样频率、时区、持久化、重启补偿", "报表标明覆盖缺口"],
    ["实机验证", "范围、step、状态变化、读回时延、失败模式", "verified=false"],
    ["关键负载配置", "设备标签、优先级、不可中断标记", "Backup Hours 仅给全屋粗估"],
], widths=[49*mm,82*mm,46*mm]))
story.append(PageBreak())

# 17 acceptance
story += section("17. 验收标准", "在 V3.1 的 14 项验收上追加设备与电站能力；原有任何安全项不得回退。")
accept_rows = [
    ["A1", "电站拓扑", "节点数值、方向、单位和动画与同一 observation 一致；stale 灰化"],
    ["A2", "节点钻取", "光伏、电池、家庭、电网均可进入详情；返回后保持上下文"],
    ["A3", "电池计算", "当前/保护/可调度能量和 Backup Hours 单测覆盖边界条件"],
    ["A4", "服务端历史", "App 关闭 2 小时后重新打开仍有期间数据；展示覆盖率"],
    ["A5", "多设备发现", "设备数量、型号、Area、Capability 来自 HA Registry 和 Profile"],
    ["A6", "能力驱动 UI", "verified=false 或 unavailable 时控制不可见/不可用且解释原因"],
    ["A7", "负载位置", "房间/楼层只来自 HA Area；无映射不猜测"],
    ["A8", "设备控制", "每次写入都有权限、Safety、幂等、读回和审计；HTTP 200 不算完成"],
    ["A9", "关键负载保护", "关键设备不被 Agent 自动关闭；完全访问也不绕过"],
    ["A10", "异常恢复", "HA 失败、设备离线、能力变化、读回失败均有可复现阻断与恢复"],
    ["A11", "跨端", "Android/iOS Safe Area、触控区、字体 130%、Reduce Motion 合规"],
    ["A12", "性能", "3D 低性能可降级；页面仍保留数据、热点和控制入口"],
]
story.append(table(["编号", "验收项", "通过条件"], accept_rows, widths=[18*mm,39*mm,120*mm], font=6.5))
story.append(Spacer(1,4*mm))
story.append(P("发布 Go / No-Go", "H2CN"))
story.append(table(["Go 条件", "No-Go 条件"], [[
    "主闭环连续 5 次一致\n设备控制均有读回\nTelemetry 覆盖率达标\nReal/Mock/Replay 标识清楚\n跨端无阻断性 UI 问题",
    "任一越权写入\n把 unavailable 当 0\n依赖 App 打开才记录历史\n未验证能力可控制\n收益未绑定 Baseline 或数据来源"
]], widths=[88.5*mm,88.5*mm], font=7.2))
story.append(PageBreak())

# 18 risks decisions
story += section("18. 风险、取舍与待决策项", "所有待决策项都有默认保守行为，避免阻塞主线。")
story.append(table(["风险/决策", "默认方案", "影响", "负责人建议"], [
    ["不同型号字段不一致", "Capability 驱动，不按型号名称硬编码", "页面可能字段较少但不误导", "Backend + Device"],
    ["历史数据缺口", "显示 coverage，不插值成真实值", "曲线可能断点", "Data"],
    ["备电时长误差", "展示区间和关键负载假设", "减少“精确但错误”", "Optimizer"],
    ["家庭位置未配置", "设备分组替代房间图", "定位体验降低", "App 引导用户配置 Area"],
    ["写能力无实机", "read-only + Replay", "真实控制范围有限", "必须实机验证后开放"],
    ["对标功能过多", "先闭环后覆盖", "暂不做工单/组件级", "Product"],
    ["完全访问误解", "明确权限边界和仍需确认项", "减少自动化卖点的夸张", "UX + Safety"],
], widths=[43*mm,61*mm,43*mm,30*mm], font=6.5))
story.append(Spacer(1,5*mm))
story.append(P("需要用户/项目方提供的资料", "H2CN"))
story.append(table(["资料", "用途", "安全提示"], [
    ["真实设备 HA Entity 列表与属性（脱敏）", "校准 Profile 和单位/范围", "删除 token、地址、完整序列号"],
    ["目标设备型号与固件版本", "确定验证矩阵", "无需账号密码"],
    ["HA Area/楼层配置截图或导出（脱敏）", "设计家庭负载位置", "隐藏家庭地址"],
    ["Smart Plug/Meter 实机读写样本", "验证控制、采样频率和回读", "仅提供结果，不提供 Secret"],
], widths=[70*mm,65*mm,42*mm]))
story.append(PageBreak())

# 19 traceability
story += section("19. V3.1 → V3.2 追踪矩阵", "确保新增内容有根，不推翻冻结版。")
story.append(table(["V3.1 条款", "V3.2 延伸", "兼容性"], [
    ["产品主线：预测、决策、执行、解释、验证", "设备功能必须进入价值闭环", "完全兼容"],
    ["Capability Discovery", "升级为多设备 Profile + 运行时快照", "增强，不改安全语义"],
    ["统一能源模型", "加入站级聚合、设备 observation、采样覆盖率", "向后兼容"],
    ["Backup Hours", "进入电池第一屏和 Reserve 价值验证", "产品化落地"],
    ["首页 3D", "与电站/设备详情统一节点模型", "保持原 UI 方向"],
    ["报表与复盘", "服务器常驻采样，增加设备和控制结果", "修复数据生命周期"],
    ["Shadow/Confirm/Autopilot", "用户文案改为观察/影子/确认后执行/完全访问", "安全边界不变"],
    ["P2 FlexibleLoad", "Smart Plug/Area 作为 P1 受控切片", "在验证能力后提前"],
], widths=[56*mm,80*mm,41*mm]))
story.append(Spacer(1,5*mm))
story.append(callout("最终产品判断", "V3.2 的价值不在于比设备厂商 App 多几个传感器，而在于：它能把跨设备状态变成有证据的家庭能源决策，并在用户授权与硬安全约束下完成真实执行和价值证明。", GREEN, MINT))
story.append(Spacer(1,6*mm))
story.append(P("文档结束", "H2CN"))
story.append(P("下一步建议：先冻结 P0 数据契约和设备 Profile，再用 Solarbank 4 E5000 Pro 跑通“电站总览 → 电池洞察 → Reserve Proposal → Safety → 执行 → Readback → Backup Hours 提升”的黄金路径。", "BodyCN"))
story.append(Spacer(1,5*mm)); story.append(AccentRule())
story.append(P("参考输入", "H2CN"))
story.append(P("1. 光衡 PRD V3.1 开发冻结版（2026-09-17）\n2. 用户提供的 4:06 对标产品交互录屏\n3. 当前 GuangHeng Flutter / Backend 结构与 SOLIX capability matrix\n4. Anker SOLIX Official Home Assistant Integration 的公开设备与配置能力说明", "SmallCN"))

doc.build(story)
print(OUT)
