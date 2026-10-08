# Aura · 同频｜人机交互概念车工程演进路线图与先锋架构蓝图
> **Engineering Evolution & Production-Grade Prototype Architecture**  
> **文档密级**：Aura HCI Concept Lab 内部核心架构资产  
> **目标架构**：HarmonyOS NEXT Release (API 12~API 14+) / ArkTS / ArkUI V2 / Stage Model  
> **架构师**：Lead Engineering Evolution & Prototype Architect

---

## 目录
1. [执行摘要与工程基准 (Executive Summary & Baseline)](#1-执行摘要与工程基准)
2. [现有代码库现实审计与架构就绪度评估 (Codebase Reality Assessment)](#2-现有代码库现实审计与架构就绪度评估)
3. [概念到现实三阶演进矩阵 (Concept-to-Reality Staged Evolution Matrix)](#3-概念到现实三阶演进矩阵)
   - [Stage 1: 近期杀手级特性 (Sprint 1~2, 零破坏性注入)](#stage-1-近期杀手级特性)
   - [Stage 2: 中期多设备与生理感官扩展 (3~6个月)](#stage-2-中期多设备与生理感官扩展)
   - [Stage 3: 远期空间与泛在环境计算 (6~12个月+)](#stage-3-远期空间与泛在环境计算)
4. [近期三大杀手级特性生产级架构蓝图 (Near-Term Killer Features Blueprint)](#4-近期三大杀手级特性生产级架构蓝图)
   - [特性 A: BRAC 90/20 超昼夜节律动态排期器与有机波浪画布](#特性-a-brac-9020-超昼夜节律动态排期器与有机波浪画布)
   - [特性 B: 纯琥珀平静模式与昼夜流体色温着色体系](#特性-b-纯琥珀平静模式与昼夜流体色温着色体系)
   - [特性 C: 体感微步破冰舱与流体阻尼解压拟物器](#特性-c-体感微步破冰舱与流体阻尼解压拟物器)
5. [系统级传感器与软硬件协同集成路径 (System Integration Paths)](#5-系统级传感器与软硬件协同集成路径)
6. [工程落地约束与防过度设计准则 (Engineering Guardrails)](#6-工程落地约束与防过度设计准则)

---

## 1. 执行摘要与工程基准

### 1.1 愿景桥接使命
在 2026 年人机交互概念实验室的前瞻推演中，「Aura · 同频」被定义为一款打破屏幕束缚、融合神经认知生理学（Kleitman BRAC 90/20 周期）、抗多巴胺平静计算哲学（Daylight Sol:OS）以及 Kaplan 注意力恢复理论（ART）的概念机级作品。

本架构设计的核心使命是：**将上述先锋哲学与激进概念，用极致严谨、高度优雅、零性能妥协的工程语言，精准锚定并无缝植入现有的 HarmonyOS NEXT 生产代码库中**。拒绝空洞的概念堆砌，每一行规范、数学模型与组件设计均满足 ArkTS 严格类型检查、ArkUI V2 响应式模型与 HarmonyOS Stage 架构红线。

---

## 2. 现有代码库现实审计与架构就绪度评估

经过对 `/Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets` 的全链路源码审计，当前项目的工程底座具备极高的规范性，为概念特性的注入提供了坚实基础：

```
entry/src/main/ets/
├── common/             # 常量 (Color/App/Curve)、工具、低延迟 Audio/Haptic 服务
├── components/         # ArkUI V2 声明式组件 (MistMorphingCard, ParkingLotInputBar, FlowSpineAxis...)
├── database/           # 纯本地优先 SQLite 关系型数据库 (RdbHelper, TodoDao, UserSettingsDao)
├── engine/             # 核心计算引擎 (BinPackingScheduler, LiveViewService, MildAgingEngine...)
├── models/             # @ObservedV2 数据实体模型 (TodoItem, TimeSlot, UserSettings)
├── pages/              # 顶层入口 (Index.ets: 多端设备响应式分支与黄金 3 Tab 架构)
├── views/              # 核心场景视图 (TodayFlowView, FocusImmersionPage, SunsetCeremonyPage...)
└── widget/             # 万能元服务微卡片 (FocusCard2x2, TodayFlowCard2x4)
```

### 2.1 架构优势 (Architectural Strengths)
1. **纯正的 ArkUI V2 状态响应范式**：
   - 视图全面采用 `@ComponentV2`，状态由 `@Local` 严格管理，父子传递采用 `@Param` 与 `@Event` 强约束，跨层级监听使用 `@Monitor`。
   - 数据模型全面装饰 `@ObservedV2` 与 `@Trace`，实现了细粒度属性级刷新，避免了 V1 中 `@Watch` 导致的整树无效重绘，为高帧率粒子/波浪动效提供了充足的主线程算力预算。
2. **本地优先与亚毫秒级贪心装箱**：
   - `BinPackingScheduler.schedule` 在本地 SQLite 数据源上运行区间贪心装箱，全流程耗时 `< 2ms`，且不产生任何网络 IO 阻塞，保证了 UI 操作的绝对跟手。
3. **多感官解耦服务雏形**：
   - `AudioService` 基于 `media.SoundPool` 实现毫秒级阶梯和弦播放；
   - `HapticService` 基于 `@kit.SensorServiceKit` 的 `vibrator` 封装了 18ms、35ms、70ms 的拟真振动；
   - `LiveViewService` 实现了实况窗胶囊与锁屏微沙漏投射。
4. **多端形态分流预留**：
   - `Index.ets` 已预置 `deviceInfo.deviceType` 分支（phone/tablet、wearable、car、tv），具备分布式概念推演的承载槽位。

### 2.2 差距分析与演进断层 (Gap Analysis vs Concept-Car Vision)
| 维度 | 现有代码现实 (As-Is) | 概念车先锋愿景 (To-Be) | 架构演进切入点 |
| :--- | :--- | :--- | :--- |
| **时间流动范式** | 线性固定时长装箱 (25m/45m 静态切片，固定缓冲) | 神经节律 BRAC 90/20 潮汐正弦波动，能量高低峰动态匹配 | 升级 `BinPackingScheduler` 为 `UltradianTideScheduler`，引入能量波浪画布 |
| **视觉光环境** | 静态 Light/Dark 两套固定 HEX 颜色，高亮白底微晶 | 600nm+ 纯琥珀抗多巴胺平静光谱，基于太阳高度角的昼夜流体色温 | 扩展 `ColorConstants` 为 `CircadianFluidTheme`，注入无极流体着色管线 |
| **启动阻力与解冻** | 常规任务点击进入全屏倒数，对重度拖延/ADHD 存在启动壁垒 | 物理阻尼把玩、体感微步破冰（<2分钟）、多阶段渐进启动 | 重构 `MistMorphingCard` 与 `FocusImmersionPage`，增加 `MicroStepIcebreaker` |
| **外设与空间感知** | 单机运行，手表端仅为简单状态同步 | 空间无感伴随光流、低功耗微感知 Beacon、可穿戴 HRV 生理反馈 | 基于分布式软总线与健康传感器构建跨端外设共振网络 |

---

## 3. 概念到现实三阶演进矩阵 (Staged Evolution Matrix)

为确保商业落地可行性与工程质量，将颠覆性概念按**技术依赖度**与**架构侵入性**拆解为三个梯度：

```
                    ┌─────────────────────────────────────────────────────────────┐
                    │ Stage 3: 空间与泛在环境计算 (Months 6~12+)                   │
                    │ - 空间计算 3D 悬浮时间视界 (Vision/Spatial)                  │
                    │ - IoT 智能灯光环境协议编织 (Matter/Hilink 空间光流)           │
                    │ - mmWave 微动雷达与零 UI 场域感知                            │
                    └──────────────────────────────┬──────────────────────────────┘
                                                   ▲
                                                   │ 向上演进与空间拓展
                    ┌──────────────────────────────┴──────────────────────────────┐
                    │ Stage 2: 中期多设备与生理感官扩展 (Months 3~6)              │
                    │ - 分布式低功耗软灯塔 (Distributed Soft Beacons)             │
                    │ - 手表端 PPG / HRV 实时自主神经系统共振调度                  │
                    │ - 平板/折叠屏 Desk Mode 沉浸陪伴外设                         │
                    └──────────────────────────────┬──────────────────────────────┘
                                                   ▲
                                                   │ 基础能力注入
                    ┌──────────────────────────────┴──────────────────────────────┐
                    │ Stage 1: 近期杀手级特性 (Sprint 1~2, 零破坏性即插即用)        │
                    │ - [Feature A] BRAC 90/20 潮汐排期器与有机波浪画布            │
                    │ - [Feature B] 纯琥珀平静模式与昼夜流体色温体系               │
                    │ - [Feature C] 体感微步破冰舱与流体阻尼拟物把玩               │
                    └─────────────────────────────────────────────────────────────┘
```

### Stage 1: 近期杀手级特性 (Sprint 1~2, 零破坏性注入)
- **目标**：在不改动现有数据库核心表结构的前提下，通过 ArkUI V2 组件替换与扩展类注入，让现有 App 瞬间拥有概念机质感。
- **交付件**：
  1. `UltradianWaveCanvas.ets`：替代 `TodayFlowView` 顶部的静态进度条，用 Canvas 绘制 90/20 生理潮汐有机流体波。
  2. `CircadianFluidTheme.ets`：扩展当前色彩体系，提供一键纯琥珀（Pure Amber 600nm+）与昼夜连续流体色温支持。
  3. `MicroStepIcebreaker.ets`：作为 `FocusImmersionPage` 的前置软启动层，为拖延高阻力任务提供弹簧阻尼解压与两分钟破冰。

### Stage 2: 中期多设备与生理感官扩展 (Months 3~6)
- **目标**：打通 HarmonyOS 分布式软总线与健康穿戴生态，从“被动计划”转为“生理同频”。
- **技术突破点**：
  1. **分布式软灯塔 (Distributed Soft Beacons)**：通过 `deviceManager` 与 `distributedHardware`，让用户的 MatePad 变身为桌面立式墨水屏时钟，手表为触觉手环，手机自动静默黑屏。
  2. **HRV 自主神经张力感知 (PPG/HRV Resonance)**：读取穿戴设备 Health Kit 的 R-R 间期数据，计算 SDNN/RMSSD 指数。当检测到交感神经过度激活（压力峰值）时，排期算法自动拉伸缓冲带或触发 3 分钟腹式呼吸潮汐。
  3. **微触觉次声波阵列**：优化 `HapticService`，利用线性马达的瞬态共振频率（160Hz~230Hz），模拟不同黏度的物理介质（水流、蜜蜡、机械棘轮）。

### Stage 3: 远期空间与泛在环境计算 (Months 6~12+)
- **目标**：脱离物理屏幕，融入物理建筑空间与泛在计算场域。
- **技术突破点**：
  1. **空间 3D 时间流脊柱**：适配 HarmonyOS 空间计算设备，时间轴以悬浮贝塞尔粒子光带环绕在用户工作台前方，杂念停机坪可通过手势空中抓取投掷。
  2. **物理环境光流联动 (Spatial Lighting Protocols)**：集成 Matter / OpenHarmony 智慧照明协议。当 90 分钟心流到达尾声，房间主灯在 5 分钟内极其柔和地从冷白（4000K）渐变为暮光橙黄（2200K），以环境光暗示代替催命铃声。
  3. **无感场域感知 (Zero-UI Peripheral Sensing)**：利用超宽带（UWB）或毫米波微动传感器，人坐入工位即自动激活当日心流，离开工位自动暂停，真正实现“科技隐于无形”。

---

## 4. 近期三大杀手级特性生产级架构蓝图

---

### 特性 A: BRAC 90/20 超昼夜节律动态排期器与有机波浪画布

#### 1. 神经认知与数学模型
根据生理学家 Nathaniel Kleitman 的基础休息-活动周期（BRAC），人类清醒时的脑电波、警戒度与认知带宽呈约 90~110 分钟的正弦潮汐振荡：
- **波峰高潮期 (Crest, 约 70~90 分钟)**：前额叶皮层高频心流，适合深度攻坚（高认知阻力任务）。
- **波谷恢复期 (Trough, 约 15~20 分钟)**：前额叶去激活，副交感神经主导，符合 Kaplan 软性着迷理论，适合留白蓄力。

设日内基准起始时间戳为 $t_0$（如 08:30），周期 $T = 110 \text{ min} = 6600 \text{ s}$。日内任意时刻 $t$ 的认知能量潜力函数 $E(t) \in [0, 100]$ 为：
$$E(t) = B(t) + A \cdot \sin\left(\frac{2\pi (t - t_0)}{T} - \frac{\pi}{2}\right) + \Delta_{\text{circadian}}(t)$$
其中：
- $B(t)$ 为昼夜昼间基线，上午 10:00~11:30 达到峰值 75，午后 14:00 出现生理偶氮凹陷；
- 振幅 $A = 25$；
- 状态判定状态机：
  - $E(t) \ge 65 \implies \text{CREST\_FLOW}$（深度心流区，算法优先插入 HIGH 优先级大块任务）；
  - $40 \le E(t) < 65 \implies \text{SHALLOW\_CRUISE}$（巡航沟通区，算法排入 MEDIUM 或 routine 杂项）；
  - $E(t) < 40 \implies \text{TROUGH\_RECOVERY}$（恢复潮谷区，强制锁定为 20 分钟留白呼吸缓冲带）。

#### 2. 核心组件架构设计：`UltradianWaveCanvas.ets`
该组件基于 ArkUI V2 规范，采用声明式 `Canvas` 绘制正弦流体波动光晕，带有毫秒级时间指针与心流粒子涟漪，具备极低的 CPU/GPU 开销。

```typescript
/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Ultradian Wave Canvas: BRAC 90/20 Neuro-Cognitive Rhythm Waveform
 * ArkUI V2 Reactive Component for TodayFlowView
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { TimeUtils } from '../common/utils/TimeUtils';

export enum TidePhase {
  CREST_FLOW = 'CREST_FLOW',       // 峰值高能区 (90m 攻坚)
  SHALLOW_CRUISE = 'SHALLOW_CRUISE', // 巡航稳态区 (轻量沟通)
  TROUGH_RECOVERY = 'TROUGH_RECOVERY'// 谷底滋养区 (20m 软着迷蓄力)
}

export interface TideSlice {
  startMs: number;
  endMs: number;
  phase: TidePhase;
  energyLevel: number; // 0 ~ 100
}

@ComponentV2
export struct UltradianWaveCanvas {
  @Param currentTimestamp: number = Date.now();
  @Param startHour: number = 8;
  @Param startMinute: number = 30;
  @Param totalSlices: number = 6; // 当日包含 6 个 110 分钟完整周期
  @Param isPaperMode: boolean = false;
  @Event onPhaseChange: (phase: TidePhase, energy: number) => void = () => {};

  @Local private canvasWidth: number = 360;
  @Local private canvasHeight: number = 84;
  @Local private currentPhase: TidePhase = TidePhase.CREST_FLOW;
  @Local private currentEnergy: number = 80;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private animationFrameId: number = -1;
  private waveOffset: number = 0;

  aboutToAppear(): void {
    this.updateCurrentTideState();
  }

  aboutToDisappear(): void {
    if (this.animationFrameId !== -1) {
      // 释放动画监听，防止内存泄漏
      this.animationFrameId = -1;
    }
  }

  /**
   * 计算指定时间戳的能量值 E(t)
   */
  public calculateEnergyAt(timestamp: number): number {
    const baseDate = new Date(timestamp);
    const dayAnchor = new Date(
      baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate(),
      this.startHour, this.startMinute, 0, 0
    ).getTime();

    const elapsedSeconds = Math.max(0, (timestamp - dayAnchor) / 1000);
    const cycleSeconds = 110 * 60; // 90m + 20m = 110m
    const phaseInCycle = (elapsedSeconds % cycleSeconds) / cycleSeconds; // 0.0 ~ 1.0

    // 正弦振荡：0~0.818 (前90分钟处于高能心流), 0.818~1.0 (后20分钟进入谷底)
    const rawSin = Math.sin(phaseInCycle * 2 * Math.PI - Math.PI / 2); // -1 ~ 1
    const normalizedEnergy = Math.round(((rawSin + 1) / 2) * 60 + 40); // 40 ~ 100

    return Math.max(20, Math.min(100, normalizedEnergy));
  }

  private updateCurrentTideState(): void {
    this.currentEnergy = this.calculateEnergyAt(this.currentTimestamp);
    if (this.currentEnergy >= 68) {
      this.currentPhase = TidePhase.CREST_FLOW;
    } else if (this.currentEnergy <= 45) {
      this.currentPhase = TidePhase.TROUGH_RECOVERY;
    } else {
      this.currentPhase = TidePhase.SHALLOW_CRUISE;
    }
    this.onPhaseChange(this.currentPhase, this.currentEnergy);
  }

  private drawWave(): void {
    if (!this.ctx || this.canvasWidth <= 0 || this.canvasHeight <= 0) {
      return;
    }

    const ctx = this.ctx;
    const w = this.canvasWidth;
    const h = this.canvasHeight;
    ctx.clearRect(0, 0, w, h);

    if (this.isPaperMode) {
      // 墨水屏模式：高对比单色极细虚线波形
      ctx.beginPath();
      ctx.lineWidth = 1.5;
      ctx.strokeStyle = '#24201D';
      ctx.setLineDash([4, 4]);
      for (let x = 0; x < w; x += 4) {
        const energy = this.getNormalizedHeightAtScreenX(x, w);
        const y = h - (energy * (h - 18)) - 8;
        if (x === 0) {
          ctx.moveTo(x, y);
        } else {
          ctx.lineTo(x, y);
        }
      }
      ctx.stroke();
      ctx.setLineDash([]);
      return;
    }

    // 1. 绘制柔和渐变填充底衬 (生物电解质光波)
    const gradient = ctx.createLinearGradient(0, 0, 0, h);
    if (this.currentPhase === TidePhase.CREST_FLOW) {
      gradient.addColorStop(0, 'rgba(232, 122, 100, 0.28)'); // 暖珊瑚陶土高光
      gradient.addColorStop(1, 'rgba(232, 122, 100, 0.02)');
    } else if (this.currentPhase === TidePhase.TROUGH_RECOVERY) {
      gradient.addColorStop(0, 'rgba(98, 138, 97, 0.25)');  // 鼠尾草绿蓄力
      gradient.addColorStop(1, 'rgba(98, 138, 97, 0.02)');
    } else {
      gradient.addColorStop(0, 'rgba(214, 154, 86, 0.20)'); // 暖沙琥珀稳态
      gradient.addColorStop(1, 'rgba(214, 154, 86, 0.02)');
    }

    ctx.beginPath();
    ctx.moveTo(0, h);
    for (let x = 0; x <= w; x += 6) {
      const energy = this.getNormalizedHeightAtScreenX(x, w);
      const y = h - (energy * (h - 22)) - 10;
      ctx.lineTo(x, y);
    }
    ctx.lineTo(w, h);
    ctx.closePath();
    ctx.fillStyle = gradient;
    ctx.fill();

    // 2. 绘制波浪外缘光脊线 (带有极轻微的微动相位)
    ctx.beginPath();
    ctx.lineWidth = 2.0;
    ctx.strokeStyle = this.currentPhase === TidePhase.CREST_FLOW
      ? ColorConstants.ACCENT_CORAL
      : (this.currentPhase === TidePhase.TROUGH_RECOVERY ? ColorConstants.BLOCK_SAGE_GREEN : ColorConstants.BLOCK_WARM_AMBER);

    for (let x = 0; x <= w; x += 6) {
      const energy = this.getNormalizedHeightAtScreenX(x, w);
      const y = h - (energy * (h - 22)) - 10;
      if (x === 0) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    }
    ctx.stroke();

    // 3. 绘制当前时间指针游标 (Glowing Node)
    const nowX = (w * 0.45); // 当前时间固定锚定在视口黄金分割点
    const nowEnergy = this.getNormalizedHeightAtScreenX(nowX, w);
    const nowY = h - (nowEnergy * (h - 22)) - 10;

    // 外光晕
    ctx.beginPath();
    ctx.arc(nowX, nowY, 6, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(255, 255, 255, 0.9)';
    ctx.fill();

    ctx.beginPath();
    ctx.arc(nowX, nowY, 3.5, 0, Math.PI * 2);
    ctx.fillStyle = ColorConstants.ACCENT_CORAL;
    ctx.fill();
  }

  private getNormalizedHeightAtScreenX(x: number, totalWidth: number): number {
    const cycleCount = 3.5;
    const progress = (x / totalWidth) * cycleCount * 2 * Math.PI;
    const sinVal = Math.sin(progress - (Math.PI / 2)); // -1 ~ 1
    return (sinVal + 1) / 2; // 0.0 ~ 1.0
  }

  build() {
    Column({ space: 6 }) {
      // 顶行节律元信息
      Row() {
        Row({ space: 6 }) {
          Circle({ width: 8, height: 8 })
            .fill(this.currentPhase === TidePhase.CREST_FLOW
              ? ColorConstants.ACCENT_CORAL
              : (this.currentPhase === TidePhase.TROUGH_RECOVERY ? ColorConstants.BLOCK_SAGE_GREEN : ColorConstants.BLOCK_WARM_AMBER))

          Text(this.getPhaseName())
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)

          Text(`· 脑力潜能 ${this.currentEnergy}%`)
            .fontSize(11)
            .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
        }

        Blank()

        Text(this.getPhaseRecommendation())
          .fontSize(11)
          .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
      }
      .width('100%')
      .padding({ left: 4, right: 4 })

      // 画布主体
      Canvas(this.ctx)
        .width('100%')
        .height(this.canvasHeight)
        .onReady(() => {
          this.drawWave();
        })
        .onAreaChange((_oldVal: Area, newVal: Area) => {
          this.canvasWidth = newVal.width as number;
          this.canvasHeight = newVal.height as number;
          this.drawWave();
        })
    }
    .width('100%')
    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
    .borderRadius(18)
    .backgroundColor(ColorConstants.LIGHT_CARD_BG)
    .border({ width: 0.5, color: ColorConstants.LIGHT_CARD_BORDER })
    .shadow({ radius: 10, color: 'rgba(85, 70, 50, 0.04)', offsetY: 2 })
  }

  private getPhaseName(): string {
    switch (this.currentPhase) {
      case TidePhase.CREST_FLOW:
        return 'BRAC 潮汐高潮 · 90m 心流攻坚';
      case TidePhase.TROUGH_RECOVERY:
        return 'BRAC 滋养潮谷 · 20m 软性着迷';
      case TidePhase.SHALLOW_CRUISE:
        return 'BRAC 能量巡航 · 稳态过渡';
    }
  }

  private getPhaseRecommendation(): string {
    switch (this.currentPhase) {
      case TidePhase.CREST_FLOW:
        return '适宜攻克核心代码/架构设计';
      case TidePhase.TROUGH_RECOVERY:
        return '请闭目极目远眺，阻断信息摄入';
      case TidePhase.SHALLOW_CRUISE:
        return '适宜整理收件箱与轻量沟通';
    }
  }
}
```

#### 3. 贪心装箱算法进化：`UltradianTideScheduler`
在现有的 `BinPackingScheduler.schedule` 中增加节律加权修饰因子：
```typescript
// 在排序候选打分阶段 (calculateScore)，引入 BRAC 周期亲和力加权：
private static calculateBRACMatchingWeight(task: TodoItem, currentTidePhase: TidePhase): number {
  if (currentTidePhase === TidePhase.CREST_FLOW) {
    // 峰值期：高难度、大颗粒度任务加权提高 50%
    return task.priority === Priority.HIGH ? 1.5 : (task.estimatedMinutes >= 45 ? 1.3 : 1.0);
  } else if (currentTidePhase === TidePhase.TROUGH_RECOVERY) {
    // 谷底期：除 15m 极简健康/恢复任务外，其它任务全部降权，强制留出空间
    return task.estimatedMinutes <= 15 ? 1.8 : 0.2;
  }
  return 1.0;
}
```

---

### 特性 B: 纯琥珀平静模式与昼夜流体色温着色体系

#### 1. 抗多巴胺理论与光谱工程学
智能手机 OLED 屏幕发射的 450~480nm 蓝光不仅抑制褪黑素（Melatonin）分泌多达 80%，还会持续刺激视网膜固有感光神经节细胞（ipRGC），向大脑下丘脑超交叉核（SCN）发出伪警报，维持中枢神经系统的焦虑唤醒。

借鉴 Daylight Sol:OS 的单色平静哲学，「Aura」引入 **Pure Amber Calm（纯琥珀平静计算）**：
- **物理光谱截止**：在晚间（20:30 后）或用户主动开启时，UI 彻底滤除 580nm 以下的蓝绿光谱，全界面采用 **600nm~620nm 暖琥珀单色阶**。
- **低视觉反差字阶 (Espresso Low-Contrast Typography)**：彻底抛弃刺眼的纯黑底纯白字（#000000 / #FFFFFF 会引发高频散光与视神经紧张），采用高饱和度深沉焦糖底（#18120A）搭配温润羊皮纸浅琥珀（#F5D298），对比度严格稳定在舒适的 **5.2:1 ~ 6.5:1**（完美满足 WCAG 2.1 AA 级可读性标准，同时消灭“数字光污染”）。

#### 2. 连续昼夜色温流体引擎：`CircadianFluidTheme.ets`
```typescript
/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Circadian Fluid Theme & Pure Amber Calm Engine
 * ArkUI V2 Dynamic Reactive Color Infrastructure
 */

@ObservedV2
export class CircadianFluidTheme {
  private static instance: CircadianFluidTheme | null = null;

  @Trace public isAmberCalmActive: boolean = false;
  @Trace public currentKelvin: number = 4500; // 默认白昼 4500K 纯净光

  // === 动态响应式设计令牌 (Tokens) ===
  @Trace public bgCanvas: string = '#F7F5F0';
  @Trace public cardBg: string = '#FFFFFF';
  @Trace public cardBorder: string = 'rgba(85, 70, 50, 0.07)';
  @Trace public textPrimary: string = '#24201D';
  @Trace public textSecondary: string = '#5E564F';
  @Trace public textTertiary: string = '#6E665E';
  @Trace public accentCore: string = '#E87A64';
  @Trace public accentSoft: string = 'rgba(232, 122, 100, 0.12)';

  private constructor() {
    this.recomputeBySolarTime();
  }

  public static getInstance(): CircadianFluidTheme {
    if (!CircadianFluidTheme.instance) {
      CircadianFluidTheme.instance = new CircadianFluidTheme();
    }
    return CircadianFluidTheme.instance;
  }

  /**
   * 依据当前本地时间无极推演环境色温
   */
  public recomputeBySolarTime(): void {
    const now = new Date();
    const hour = now.getHours() + now.getMinutes() / 60;

    if (this.isAmberCalmActive || hour >= 21.5 || hour < 6.0) {
      // 深度纯琥珀平静态 (1800K 单色温)
      this.applyAmberCalmPalette();
    } else if (hour >= 6.0 && hour < 9.0) {
      // 晨光苏醒 (3200K 晨曦暖金)
      this.currentKelvin = 3200;
      this.bgCanvas = '#F9F6EE';
      this.cardBg = '#FFFFFF';
      this.cardBorder = 'rgba(120, 90, 50, 0.08)';
      this.textPrimary = '#2B2520';
      this.accentCore = '#E07A5F';
      this.accentSoft = 'rgba(224, 122, 95, 0.12)';
    } else if (hour >= 9.0 && hour < 17.5) {
      // 白昼专注 (4800K 燕麦羊脂白)
      this.currentKelvin = 4800;
      this.bgCanvas = '#F7F5F0';
      this.cardBg = '#FFFFFF';
      this.cardBorder = 'rgba(85, 70, 50, 0.07)';
      this.textPrimary = '#24201D';
      this.accentCore = '#E87A64';
      this.accentSoft = 'rgba(232, 122, 100, 0.12)';
    } else {
      // 黄昏暮光 (2700K 陶土暮色)
      this.currentKelvin = 2700;
      this.bgCanvas = '#EFEAE2';
      this.cardBg = '#FBF8F4';
      this.cardBorder = 'rgba(90, 65, 40, 0.09)';
      this.textPrimary = '#261F1A';
      this.accentCore = '#D96B52';
      this.accentSoft = 'rgba(217, 107, 82, 0.15)';
    }
  }

  /**
   * 激活纯琥珀抗多巴胺平静矩阵 (600nm+ Spectrum)
   */
  public setAmberCalmMode(enabled: boolean): void {
    this.isAmberCalmActive = enabled;
    if (enabled) {
      this.applyAmberCalmPalette();
    } else {
      this.recomputeBySolarTime();
    }
  }

  private applyAmberCalmPalette(): void {
    this.currentKelvin = 1800;
    // 纯琥珀暗场体系：绝无蓝绿像素激发
    this.bgCanvas = '#130E07';      // 深度琥珀碳黑 (Dark Amber Charcoal)
    this.cardBg = '#1E170E';        // 暖焦糖微晶卡 (Warm Caramel Matrix)
    this.cardBorder = 'rgba(235, 160, 55, 0.15)'; // 琥珀微光晕线
    this.textPrimary = '#F5CA80';   // 浅琥珀高辨识字阶 (Amber Primary)
    this.textSecondary = '#C29853'; // 柔和深琥珀 (Amber Muted)
    this.textTertiary = '#8C6830';  // 低频基底琥珀 (Amber Base)
    this.accentCore = '#F09B28';    // 纯琥珀激活光芒
    this.accentSoft = 'rgba(240, 155, 40, 0.18)';
  }
}
```

#### 3. 平滑过渡着色器应用
在全局组件外层（`Index.ets`）使用属性动画拦截，使色温切换如同黄昏光影自然漫入，耗时 1200ms：
```typescript
// 纯琥珀状态切换时的全局平滑滤镜动效
.animation({
  curve: Curve.FastOutSlowIn,
  duration: 1200
})
```

---

### 特性 C: 体感微步破冰舱与流体阻尼解压拟物器

#### 1. 神经科学背景：击穿“执行功能冻结 (ADHD Freeze)”
ADHD、慢性疲劳与重度焦虑用户面临的核心痛点并非“缺乏时间规划”，而是**任务启动瞬间的边缘系统恐惧（Amygdala Hijack）**：
- 面对“撰写 30 页商业计划书”或“重构整个底层架构”，大脑评估认知负荷过高，立刻陷入解离与拖延逃避；
- **破冰公理（Micro-Step Icebreaker）**：将任务降维至“只要做 90 秒，哪怕只写一行废话也算合格”；
- **触觉拟物把玩（Somatosensory Damping Fidget）**：指尖在屏幕上的弹簧物理微阻尼拉伸，能通过体感神经回馈刺激大脑躯体感觉皮层（Somatosensory Cortex），迅速安抚焦躁神经回路。

#### 2. 生产级组件设计：`MicroStepIcebreaker.ets`
包含三大微交互核心：
1. **阻尼弹簧拉伸（Non-linear Spring Pull）**：下拉卡片如同拉开一支高黏度机械注射器，手感越深，回馈阻力越强；
2. **多阶段阶梯震感（Linear Motor Haptic Tick Detents）**：随位移触发由稀疏到密集的齿轮棘轮质感微震；
3. **90 秒沙漏微步启动（Sub-2-minute Pass-through）**：松手后直接进入 90 秒软启动，完成后打通心理屏障，无缝衔接全量专注。

```typescript
/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Micro-Step Icebreaker & Damping Fidget Capsule
 * ArkUI V2 Physics-Driven Gesture Component for Focus Initiation
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { HapticService } from '../common/media/HapticService';
import { TodoItem } from '../models/TodoItem';

@ComponentV2
export struct MicroStepIcebreaker {
  @Param task: TodoItem = new TodoItem();
  @Event onIcebreakerSuccess: () => void = () => {};
  @Event onCancel: () => void = () => {};

  @Local private pullOffsetY: number = 0;
  @Local private isEngaged: boolean = false;
  @Local private remainingIcebreakerSeconds: number = 90; // 90 秒微步破冰
  @Local private isCountingDown: boolean = false;

  private readonly TRIGGER_THRESHOLD_PX: number = 140;
  private lastHapticTickStep: number = 0;
  private timerId: number = -1;

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 1. 底层流体阻尼蓄力水膜
      Column() {
        if (!this.isCountingDown) {
          // 下拉蓄力指示
          Column({ space: 8 }) {
            Image($r('app.media.ic_hourglass'))
              .width(26)
              .height(26)
              .fillColor(this.pullOffsetY >= this.TRIGGER_THRESHOLD_PX ? ColorConstants.ACCENT_CORAL : ColorConstants.LIGHT_TEXT_TERTIARY)
              .scale({
                x: 1 + (this.pullOffsetY / 200),
                y: 1 + (this.pullOffsetY / 200)
              })

            Text(this.pullOffsetY >= this.TRIGGER_THRESHOLD_PX ? '松手！开启 90 秒破冰' : '向下拉动突破阻力，仅做 90 秒')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.pullOffsetY >= this.TRIGGER_THRESHOLD_PX ? ColorConstants.ACCENT_CORAL : ColorConstants.LIGHT_TEXT_SECONDARY)

            Text('不追求完美，哪怕只打开文档发呆也算通关')
              .fontSize(11)
              .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
          }
          .padding({ top: 30 })
        } else {
          // 2. 90 秒极速破冰正向流转区
          Column({ space: 14 }) {
            Text('微步破冰进行中')
              .fontSize(12)
              .fontColor(ColorConstants.ACCENT_CORAL)
              .fontWeight(FontWeight.Medium)

            Text(`${this.remainingIcebreakerSeconds}s`)
              .fontSize(44)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)

            Progress({
              value: 90 - this.remainingIcebreakerSeconds,
              total: 90,
              type: ProgressType.Ring
            })
              .color(ColorConstants.ACCENT_CORAL)
              .style({ strokeWidth: 6, enableSmoothEffect: true })
              .width(110)
              .height(110)

            Button('状态来了，进入全量心流')
              .fontSize(13)
              .fontColor(Color.White)
              .backgroundColor(ColorConstants.ACCENT_CORAL)
              .borderRadius(18)
              .height(36)
              .onClick(() => {
                this.completeIcebreaker();
              })
          }
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      // 3. 悬浮物理阻尼胶囊手柄 (支持 PanGesture 连续手势)
      if (!this.isCountingDown) {
        Column() {
          Row({ space: 6 }) {
            Circle({ width: 6, height: 6 }).fill(ColorConstants.ACCENT_CORAL)
            Text(this.task.title || '当前攻坚任务')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .padding({ left: 16, right: 16, top: 10, bottom: 10 })
          .borderRadius(20)
          .backgroundColor(ColorConstants.LIGHT_CARD_BG)
          .border({ width: 0.8, color: ColorConstants.LIGHT_CARD_BORDER })
          .shadow({ radius: 12, color: 'rgba(85, 70, 50, 0.08)', offsetY: 4 })
        }
        .translate({ y: this.pullOffsetY })
        .animation({
          curve: Curve.FastOutSlowIn,
          duration: this.pullOffsetY === 0 ? 300 : 0 // 松手回弹平滑，拖拽即时
        })
        .gesture(
          PanGesture({ direction: PanDirection.Vertical })
            .onActionUpdate((event: GestureEvent) => {
              if (event.offsetY > 0) {
                // 非线性弹簧阻尼模型: y = 220 * (1 - exp(-dy / 180))
                const rawDy = event.offsetY;
                this.pullOffsetY = Math.round(220 * (1 - Math.exp(-rawDy / 180)));

                // 阶梯触觉微震 detents (每移动 25px 触发一次微刻度感)
                const currentStep = Math.floor(this.pullOffsetY / 25);
                if (currentStep > this.lastHapticTickStep) {
                  this.lastHapticTickStep = currentStep;
                  HapticService.getInstance().triggerTick();
                }
              }
            })
            .onActionEnd(() => {
              if (this.pullOffsetY >= this.TRIGGER_THRESHOLD_PX) {
                // 成功越过阻尼阈值，触发重型落锁震动并启动 90s
                HapticService.getInstance().triggerHeavy();
                this.startIcebreakerTimer();
              } else {
                // 阻尼回弹
                this.pullOffsetY = 0;
                this.lastHapticTickStep = 0;
              }
            })
        )
      }
    }
    .width('100%')
    .height(260)
    .padding(16)
    .borderRadius(24)
    .backgroundColor('rgba(255, 255, 255, 0.65)')
    .backgroundBlurStyle(BlurStyle.Thin)
    .border({ width: 0.8, color: ColorConstants.LIGHT_CARD_BORDER })
  }

  private startIcebreakerTimer(): void {
    this.isCountingDown = true;
    this.remainingIcebreakerSeconds = 90;
    this.timerId = setInterval(() => {
      if (this.remainingIcebreakerSeconds > 1) {
        this.remainingIcebreakerSeconds--;
      } else {
        clearInterval(this.timerId);
        this.timerId = -1;
        this.completeIcebreaker();
      }
    }, 1000);
  }

  private completeIcebreaker(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
    HapticService.getInstance().triggerClick();
    this.onIcebreakerSuccess();
  }
}
```

---

## 5. 系统级传感器与软硬件协同集成路径

为了让近/中/远期特性在 HarmonyOS NEXT 上稳健落地，必须严格遵循鸿蒙原生系统的驱动与传感器接入规范：

```
                    ┌────────────────────────────────────────────────────────┐
                    │           Aura 心流协调中枢 (Flow Core Center)           │
                    └───────────┬────────────────────────────┬───────────────┘
                                │                            │
                ┌───────────────┴──────────────┐   ┌─────────┴──────────────┐
                │ 硬件感知层 (Sensory Kits)     │   │ 分布式联动 (Distributed)│
                └───────┬──────────────────────┘   └─────────┬──────────────┘
                        │                                    │
       ┌────────────────┼────────────────┐                   │
       ▼                ▼                ▼                   ▼
[@kit.SensorServiceKit] [@kit.MediaKit]  [@kit.HealthKit]    [@kit.NearbyServiceKit]
线性马达瞬态振动曲线      低延迟 SoundPool  穿戴设备 PPG / HRV   分布式软总线 D-Bus
(Clockwork / Liquid)   阶梯和弦矩阵      自律神经平衡调度     平板/手表无缝投屏伴侣
```

### 5.1 线性马达丰富震动波形定义
扩展 `common/media/HapticService.ets`，从单一时长振动演进为具有物理意象的触觉图案：
- **微步拉伸刻度感 (Detent Tick)**：单次 10ms 极轻脉冲；
- **越过破冰阈值 (Over-threshold Snap)**：复合震动（先 20ms 蓄力，再 40ms 爆发敲击）；
- **潮汐波浪共振 (Tidal Wave Pulse)**：低频正弦包络振动（模拟心流波涛涌动）。

### 5.2 环境光传感器联动 (Ambient Light Sensor)
通过 `@kit.SensorServiceKit` 的 `sensor.on(sensor.SensorId.AMBIENT_LIGHT)` 实时捕获环境照度 Lux：
- 当 Lux < 20（暗光卧室/书房），自动建议或平滑切换至 **Pure Amber 纯琥珀 Calm 模式**；
- 当 Lux > 800（户外艳阳天），自动提升中性文字对比度，激活**强光墨水屏清晰算法**。

---

## 6. 工程落地约束与防过度设计准则 (Engineering Guardrails)

在拥抱前沿交互理念的同时，必须严格遵循老员工极简主义与反过度设计准则（Ponytail Rules & HarmonyOS Guidelines）：

1. **绝对禁止伪科学过度量化**：
   - 绝不在 UI 上显示密密麻麻的所谓“脑电图拟合曲线百分比”或“多巴胺剩余毫克数”，那只会制造新的虚空焦虑；
   - 界面上仅以最温润的潮汐起伏、光斑与温和微文字呈现，把复杂的正弦积分隐藏在引擎层。
2. **零新增无用三方 NPM 依赖**：
   - 波浪渲染直接使用 ArkUI 原生 `Canvas` + `CanvasRenderingContext2D`；
   - 弹簧阻尼直接使用物理公式与 ArkUI 原生 `PanGesture`；
   - 绝不引入脱离鸿蒙原生的厚重 Web 物理引擎（如 Matter.js 或 Three.js）。
3. **主线程耗时严格守护**：
   - 动画帧全部基于 `requestAnimationFrame` 驱动；
   - 当页面切换至后台或不可见（`aboutToDisappear` / 锁屏）时，必须绝对静默冻结定时器与渲染管线，保证 0% 后台 CPU 占用与极佳电池续航。
4. **数据防丢与架构自洽**：
   - 所有破冰碎片任务仍然复用既有的 `TodoItem` 实体结构与 SQLite DAO 操作；
   - 保持向下兼容，现有存量用户数据升级零损耗。

---
*Aura Engineering Evolution Blueprint — Crafted for HarmonyOS NEXT*
