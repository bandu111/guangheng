<div align="center">

<img src="assets/branding/guangheng_app_icon.png" width="112" alt="光衡 App 图标">

# 光衡 GuangHeng

### Autonomous Home Energy Agent  
### 自主家庭能源智能体

**持续理解家庭“发电—储能—用电—电网”的完整能量流，在真正值得行动时主动提出方案，获得授权后安全执行，并用真实设备回读与 Smart Meter 证明结果。**

[![Flutter](https://img.shields.io/badge/Flutter-3.44.1-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.12.1-0175C2?logo=dart)](https://dart.dev/)
![Version](https://img.shields.io/badge/version-1.4.0%2B9-2468D4)
![Android](https://img.shields.io/badge/Android-supported-3DDC84?logo=android)
![iOS](https://img.shields.io/badge/iOS-supported-000000?logo=apple)
![Tests](https://img.shields.io/badge/Flutter_tests-23_passed-18A66A)

</div>

---

## 项目简介

传统家庭能源 App 主要负责展示数据。用户仍然需要自己查看光伏、家庭负载、电池 SOC、电价和天气，再决定什么时候充电、放电或调整负载。

光衡不是增加一块更复杂的 Dashboard，而是把家庭能源管理升级为完整闭环：

```text
持续观察
→ 预测变化
→ 主动判断
→ 生成方案
→ 用户授权
→ 安全执行
→ 设备回读
→ Smart Meter 验证家庭结果
```

没有必要动作时，系统保持安静；真正值得行动时，光衡才向用户解释原因、涉及设备和预计效果。

---

## 光衡解决什么问题

| 用户问题 | 光衡的解决方式 |
| --- | --- |
| 数据很多，但不知道下一步该做什么 | 综合光伏、负载、电池、电网、天气和策略，主动判断是否值得行动 |
| 只能看到现在，很难提前规划 | 使用未来光伏、负载与天气信息生成 24 小时计划 |
| 一个家庭目标往往涉及多台设备 | 使用 Action Set 把多个设备动作组合成一套方案 |
| AI 直接控制真实设备存在风险 | 将 AI 理解与设备执行权限分离，由 Backend 完成权限和安全检查 |
| 接口返回成功不代表家庭目标实现 | 通过命令确认、设备回读和 Smart Meter 家庭结果进行三级验证 |
| 设备控制路径复杂 | 支持 Flutter 深度管理与 Energy Companion 即时交互两个入口 |
| 历史数据只记录结果，无法解释原因 | 将决策、批准、执行、回读和验证放在同一时间线上 |

---

## 核心功能

### 1. 家庭能源 Autopilot

光衡持续读取家庭能源状态，并结合：

- 当前光伏发电
- 家庭负载
- 电池 SOC
- 电网购电与反送
- 天气与未来光伏预测
- 未来负载趋势
- 用户选择的 SAVE / AUTO / BACKUP 策略

系统判断当前是否存在值得执行的能源机会。

具体目标值由确定性优化逻辑计算，保证结果可重复、受约束；Hermes 负责理解用户目标、解释原因和回答自然语言问题，不凭感觉生成设备功率。

---

### 2. 跨设备 Action Set

一个家庭能源目标通常需要多台设备协同完成。

例如“减少光伏反送”可能同时包含：

```text
Solarbank 提高充电功率
+
Smart Plug 开启柔性负载
+
Smart Meter 验证反送功率下降
```

光衡把这些动作组合成一个 Action Set：

- 用户只确认一次
- 系统逐项执行
- 每一步执行前重新检查设备状态、权限和安全边界
- 每一步完成后读取真实设备状态
- 任一步失败，立即停止后续动作
- 最后由 Smart Meter 验证家庭目标是否实现

---

### 3. 三级结果验证

光衡不会把“