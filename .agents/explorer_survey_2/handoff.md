# Handoff Report: UI & Interaction Survey ("Now Only" Single-Thread Minimal Flow)

**Working Directory**: `.agents/explorer_survey_2/`  
**Agent**: Explorer 2 (UI & Interaction Explorer)  
**Parent Agent**: `91a055fa-ed83-4e5f-987b-510453b6ad9d`  
**Date**: 2026-09-22T08:44:50Z  
**Type**: Hard Handoff  

---

## 1. Observation (直接观察)

通过直接阅读与符号检索源码，获取到以下客观事实：

1. **`TodayFlowView.ets` 强依赖装箱调度与时间轴**:
   - 行 8：`import { TimeSlot } from '../models/TimeSlot';`
   - 行 12：`import { FlowSpineAxis } from '../components/FlowSpineAxis';`
   - 行 14：`import { BinPackingScheduler } from '../engine/BinPackingScheduler';`
   - 行 40：`@Local timelineSlots: TimeSlot[] = [];`
   - 行 154-169：展开纵向时间轴组件 `FlowSpineAxis({ timelineSlots: this.timelineSlots, ... })`
   - 行 245-253：`const result = BinPackingScheduler.schedule(this.settings, activeTodos, [], this.selectedDateTimestamp); this.timelineSlots = result.scheduledSlots;`

2. **`FlowSpineAxis.ets` 的具体时刻表与轴线结构**:
   - 行 120-147：渲染左侧 42vp 时间刻度标尺，包含 `NOW` 胶囊标与 `Text(TimeUtils.formatTime(slot.taskItem.scheduledStartAt))`（如 `09:30`）。
   - 行 149-202：渲染中间 28vp 纵向脊柱导轨节点与纵向连接线 `Line().width(2)`。
   - 行 227-259：渲染穿透卡片的实时流动红线游标 `Live Now Indicator`，位置计算为 `position({ y: Math.round(this.getSlotHeight(slot.taskItem) * this.getNowProgress(slot)) - 7 })`。
   - 行 109-115：渲染留白缓冲卡 `CushionCard`（显示诸如 `30m 留白蓄力`）。

3. **`MistMorphingCard.ets` 手势与动效现状**:
   - 行 163-179：仅监听 `.onTouch(...)`，在 `TouchDown`、`TouchMove`、`TouchUp` 中驱动 `LiquidGlassState` 进行按压变形（`scale: 0.97`）和橡皮筋拉伸（`dx * 0.28, dy * 0.28`）。
   - **完全缺乏横向滑动/滑动手势（Swipe / PanGesture）**，无滑动完成、无滑动推迟，卡片松手即以 `CurveConstants.SPRING_LIQUID_SNAP` 归位。
   - 行 30：渲染硬编码耗时文本 `Text('${this.item.estimatedMinutes} min')`。
   - 行 36-56：渲染 `-15` / `+15` 原地时长微调手柄。
   - 行 59-74：渲染原地锁定排期手柄 `isPinned`。

4. **多感官反馈系统已齐备**:
   - `AudioService.ets`（行 73-103）：`SoundPool` 已预加载 C4, E4, G4, C5 四个和弦阶梯采样，`playChordStep()` 会自动按顺序循环播放多巴胺阶梯和弦，受 `settings.isChordAudioEnabled` 控制。
   - `HapticService.ets`（行 25-41）：已封装 `triggerClick()`（35ms 泡泡纸干脆微震）、`triggerTick()`（18ms 轻柔气雾脉冲）、`triggerHeavy()`（70ms 仪式震感）。
   - `CurveConstants.ets`：已定义 `SPRING_LIQUID_SNAP`、`SPRING_TOUCH_BOUNCE`、`SPRING_BOTTOM_SHEET`、`SPRING_UNDO_BOUNCE` 等基于 `@kit.ArkUI` `curves.springMotion` 的高精度物理弹簧曲线。

5. **`WeekCalendarBar.ets` 与 `FloatingDeckDrawer.ets`**:
   - `WeekCalendarBar.ets`（行 99-122）：包含 `+ AI 智排` 按钮。
   - `FloatingDeckDrawer.ets`：占据今日主页底部较大区域，含有 `Inbox · 机动备选池` 徽标。
   - `GlobalUndoCapsule.ets`：已独立存在于 `components/`，通过 `@ComponentV2` 与 `UndoService` 实现 5 秒浮动倒计时撤销。

---

## 2. Logic Chain (推理链)

1. **观察 1 与观察 2 证明**：现有主界面是以“日程时刻表（Schedule-based Time Blocking）”为核心设计的，时间轴线、时刻文本（`09:30`）、活动时间指示游标和装箱算法强行推给用户一个全天预知视图，这正是产生清单压迫与时间焦虑的直接原因。
2. **推论 1**：要实现“Now Only”无压力心流，必须从 `TodayFlowView` 中彻底移除 `FlowSpineAxis`、`CushionCard`、`TimeSlot` 与 `BinPackingScheduler`。
3. **观察 3 证明**：现有卡片仅有点击和原位按压水膜动效，缺失单线程流水线推力交互的核心载体——滑动手势（Swipe）。
4. **推论 2**：重构方案必须引入基于 `PanGesture` 的物理阻尼交互，右滑触发完成、左滑触发跳过/推迟。
5. **观察 4 证明**：底层音频 `SoundPool` 和马达 `vibrator` 基础设施已经成熟，可以直接无缝绑定到新的卡片滑动手势和完成事件中，右滑完成触发 `playChordStep()` + `triggerClick()`，左滑跳过触发 `triggerTick()`。
6. **推论 3（舞台空间架构）**：
   - 屏幕中央独占当前主动作卡片 `NowActionCard`（无时间戳、字号 20~22fp、呈现微步清单）；
   - 底层以 3D 物理叠层（`scale: 0.94, translateY: 28`）微露 12~16vp 的 `NextPeekCard`，给予用户“下一步已有安排”的安心感；
   - 完成或跳过时，配合弹簧阻尼曲线，下一项卡片自下而上无缝吸附跃升；
   - 杂念输入通过 36vp `ParkingLotInputBar` 秒级滑入队列不打断焦点；
   - 队列查看通过默认折叠的 `QueueDrawer`（高度 32vp，按需展开）承载。

---

## 3. Caveats (局限性与考量)

1. **手势冲突防护**：`NowActionCard` 的水平 `PanGesture` 在左右滑动时可能会与外层 `Index.ets` 的 `Swiper(3 Tab)` 发生手势竞争。实装时建议在拖拽激活期间通知父级临时禁用 `Swiper.disableSwipe(true)`，或者限制水平拖拽触发角与手势掩码。
2. **多端宽屏约束**：在平板、2in1 或折叠屏展开态下，主舞台卡片若拉伸到全屏会失焦。建议主卡片容器严格增加 `.constraintSize({ maxWidth: 520 })`。
3. **未涉及非 UI 代码修改**：本调研严格遵守只读原则，未修改任何工程源码文件。

---

## 4. Conclusion (调研结论)

1. **旧架构剥离范围明确**：完全隔离并淘汰 `FlowSpineAxis` 与 `CushionCard`；解耦 `WeekCalendarBar` 中的装箱触发。
2. **新舞台设计定型**：
   - 中央独占 `NowActionCard`；
   - 拟物叠层微露 `NextPeekCard`（12~16vp 边缘）；
   - 结合 `PanGesture` + `CurveConstants.SPRING_LIQUID_SNAP` / `SPRING_STAGE_ADVANCE`；
   - 联动 `AudioService.playChordStep()` 与 `HapticService.triggerClick()`；
   - 36vp 快录胶囊 + 默认折叠的 `QueueDrawer`；
   - 全部采用 ArkUI V2 强类型规范。
3. 详细架构规格说明已记录于：
   `/Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/explorer_survey_2/ui_interaction_survey.md`

---

## 5. Verification Method (独立验证方法)

1. **检查调研产物与路径**:
   - 查看报告文件：`cat /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/explorer_survey_2/ui_interaction_survey.md`
   - 查看交接文件：`cat /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/explorer_survey_2/handoff.md`
2. **代码位置验证**:
   - 验证 `FlowSpineAxis.ets` L120-147 是否为 42vp 时间刻度与 `formatTime`；
   - 验证 `MistMorphingCard.ets` L163-179 是否仅有 `onTouch` 而缺乏 `PanGesture`；
   - 验证 `AudioService.ets` L73-103 是否为 4 阶和弦阶梯算法。
3. **失效条件 (Invalidation Conditions)**:
   - 若产品决策要求恢复全天多时间块纵向排列日程表，则本单任务主舞台方案失效；
   - 若系统降级至 ArkUI V1，则基于 V2 的响应式重构设计需调整。
