# "Now Only" 单线程极简推力 UI 与交互架构重构调研报告
**文档路径**: `.agents/explorer_survey_2/ui_interaction_survey.md`  
**执行角色**: Explorer 2 (UI & Interaction Explorer)  
**日期**: 2026-09-22  
**状态**: 完成 (Survey Completed)

---

## 1. 执行摘要 (Executive Summary)

根据 2026-09-22T08:35:22Z 最新权威需求，「Aura · 同频」正从传统的“时间排期与纵向时间轴装箱（Time Blocking & Flow Spine）”旧范式，全面蜕变为以**「单线程极简推力（Now Only）」**为核心灵魂的纯粹心流待办管家。

本调研对当前工程全部 UI 视图、核心组件、动画曲线、多感官反馈（`soundPool` 与 `vibrator`）以及时间刻度渲染进行了地毯式源码排查，形成了面向“Now Only”单任务微晶主舞台的完整技术重构蓝图：
1. **旧范式清零**：全面识别并规划废弃纵向时间轴导轨（`FlowSpineAxis`）、留白缓冲卡（`CushionCard`）、时刻刻度标尺（`42vp HH:mm`）及装箱算法依赖，彻底抹杀清单压力与时间焦虑。
2. **主舞台重构**：构建屏幕中央独占呈现的「当前微动作卡片」（`NowActionCard`），底层以拟物叠层形式物理露出 12~16vp 的「下一项」卡片微边缘（`NextPeekCard`）。
3. **物理弹簧微交互**：建立基于 `PanGesture` 的物理阻尼拖拽体系，实现“右滑完成”（伴随 C4-E4-G4-C5 阶梯和弦与 35ms 泡泡纸微震，下一项卡片弹簧吸附跃升）与“左滑跳过/稍后”（下一项卡片平滑滑入），并联动 `GlobalUndoCapsule` 实现 5 秒无痛防错。
4. **极简流转辅助系统**：保留并升级 36vp 杂念快录胶囊（`ParkingLotInputBar`），增设默认收起、零视觉干扰的轻量级折叠抽屉（`QueueDrawer`）。
5. **ArkUI V2 全面合规**：所有组件采用 `@ComponentV2`、`@ObservedV2`、`@Trace`、`@Local`、`@Param`，杜绝 V1 装饰器与 `any`，确保 Local-First 本地优先与工程纯净性。

---

## 2. 现有 UI 架构与核心组件深度审计 (Current UI Architecture Audit)

### 2.1 主视图 `TodayFlowView.ets` 现状分析
- **文件路径**: `entry/src/main/ets/views/TodayFlowView.ets` (314 行)
- **现有结构**:
  - 顶层使用 `Stack({ alignContent: Alignment.BottomEnd })` 包裹滚动内容区与浮动操作按钮。
  - 内容区使用 `Scroll()` 包裹纵向 `Column`，内嵌：
    1. 顶部占位垫高：`Blank().height(102 + topAvoidHeight)`；
    2. 离线连胜护盾卡片：`StreakFreezeRevivalCard`；
    3. **核心时间轴导轨**：`FlowSpineAxis({ timelineSlots: this.timelineSlots, ... })`（行 154-169）；
    4. 备选池：`FloatingDeckDrawer({ floatingItems: this.floatingItems, ... })`（行 172-179）；
    5. 底部呼吸间距垫高：`Blank().height(150)`。
  - 顶部常驻：`WeekCalendarBar`（行 192-205，含有 7 天水平日历与 `+ AI 智排` 按钮）。
  - 右下角常驻：52vp 悬浮新建圆形按钮（FAB `+`）。
- **状态与排期绑定**:
  - 行 40：`@Local timelineSlots: TimeSlot[] = [];`
  - 行 42：`@Local scheduledMinutes: number = 0;`
  - 行 245-253：在 `refreshData()` 中强制调用 `BinPackingScheduler.schedule(...)` 进行时间装箱计算，生成 `TimeSlot[]`。
- **痛点与问题**:
  - 用户打开今日界面，直接面临全天多项任务的时刻表堆叠，产生强烈的“日程表压迫感”；
  - 视线必须在时间刻度、轴线节点、卡片之间反复来回扫描，认知负荷显著超标。

### 2.2 纵向时间轴导轨 `FlowSpineAxis.ets` 现状分析
- **文件路径**: `entry/src/main/ets/components/FlowSpineAxis.ets` (270 行)
- **三列排版与刻度机制**:
  1. **左侧 42vp 时间刻度标尺**（行 120-147）：
     - 当前活动项显示 `NOW` 胶囊徽标（红点 + 8fp 粗体文字）；
     - 使用 `TimeUtils.formatTime(slot.taskItem.scheduledStartAt)` 渲染绝对时刻 `HH:mm`（如 `09:30`）。
  2. **中间 28vp 纵向轴线导轨**（行 149-202）：
     - 长任务（≥35m）：纵向延伸胶囊，内含图标与垂直连线 `Line().width(2)`；
     - 短任务（<35m）：28vp 圆形节点 + 垂直连线 `Line().width(2)`；
     - 节点根据分类/优先级渲染不同主题色（珊瑚橙、牛仔蓝、鼠尾草绿、琥珀黄）。
  3. **右侧卡片主体**（行 204-222）：
     - 嵌套 `MistMorphingCard`，卡片高度由预估分钟数动态决定（`m * 1.4`，范围 58~125vp）。
  4. **实时时刻流动红线 (Live Now Indicator)**（行 227-259）：
     - 计算 `nowProgress`（当前时间在任务起止区间的百分比）；
     - 在导轨与卡片上方叠加绝对定位的水平渐变微光红线（`accentCoral` 渐变）。
  5. **留白缓冲卡 `CushionCard`**（行 109-115）：
     - 当槽位类型为 `SlotType.BUFFER` 时渲染，计算空闲分钟并显示“30m 留白蓄力”。
- **痛点与问题**:
  - 强烈的“时间监控”暗示，用户容易产生“我落后于时刻表了”的自责内疚；
  - 动态高度导致长任务占用大面积，短任务被挤压，视觉节奏杂乱。

### 2.3 任务卡片 `MistMorphingCard.ets` 现状分析
- **文件路径**: `entry/src/main/ets/components/MistMorphingCard.ets` (188 行)
- **内部布局**:
  - 顶部元信息行：显示 `${item.estimatedMinutes} min`、原地微调手柄 `-15` / `+15`、锁定手柄（`isPinned`）、`45m 切片` 标签；
  - 标题文本：单行或双行折行，完成态添加中划线；
  - 子任务摘要：`${doneCount}/${totalCount}`；
  - 右侧打卡圆环：22vp 几何圆环，点击切换完成态。
- **触控与动画**:
  - 使用 `.onTouch(...)` 监听 `TouchType.Down` / `Move` / `Up`；
  - 驱动 `LiquidGlassState` 进行按压微缩（0.97）与非线性橡皮筋位移拉伸（`dx * 0.28, dy * 0.28`）；
  - 松手使用 `CurveConstants.SPRING_LIQUID_SNAP` 回弹；
  - **核心缺失**：当前**完全没有横向滑动手势（Swipe / PanGesture）**，不支持滑动完成或滑动跳过，卡片位移仅用于按压回弹，无法驱动流水线出队推入！

---

## 3. 时间刻度与排期元素全量清单 (Inventory of Temporal UI Artifacts)

为实现“彻底抹除具体时刻显示（无 `HH:mm`、无倒计时钟表、无时间轴线）”，下表列出代码库中所有涉及时间渲染的位置及处置策略：

| 序号 | 所在文件 | 行号范围 | 渲染的具体元素 | 处置建议与重构方案 |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `FlowSpineAxis.ets` | L120-147 | 左侧 42vp 时间标尺与 `TimeUtils.formatTime` (HH:mm)、`NOW` 标 | **彻底淘汰**。主舞台移除整列时间标尺与具体时刻显示。 |
| 2 | `FlowSpineAxis.ets` | L149-202 | 28vp 纵向导轨脊柱节点与纵向连接线 `Line()` | **彻底淘汰**。移除轴线导轨，由中心卡片叠层替代。 |
| 3 | `FlowSpineAxis.ets` | L227-259 | 穿透卡片的实时流动红线 (Live Now Indicator) | **彻底淘汰**。消灭时刻游标，消除时间流逝的催促感。 |
| 4 | `CushionCard.ets` | 全文 (L1-112) | 留白时间缓冲卡，计算 `freeMinutes` 并渲染 `${m}m 留白蓄力` | **淘汰出主视图**。无排期后不再有区间空隙，改为完成全部后的禅意空态。 |
| 5 | `TodayFlowView.ets` | L40, L154 | `@Local timelineSlots: TimeSlot[]` 与 `FlowSpineAxis` 实例 | **替换为单线程队列**：`currentTask: TodoItem` 与 `nextTask: TodoItem`。 |
| 6 | `TodayFlowView.ets` | L245-253 | `BinPackingScheduler.schedule(...)` 装箱排期计算 | **移除运行时调用**。对接 `SingleThreadFlowEngine.getActiveQueue()`。 |
| 7 | `WeekCalendarBar.ets` | L99-122 | `+ AI 智排` 胶囊按钮（触发装箱算法） | **移除智排按钮**。更换为温和从容的无压力日历或精简状态头。 |
| 8 | `WeekCalendarBar.ets` | L144-188 | 7 天横向日历周条（含日程密度彩色微粒点） | **降级精简**。在主舞台上方改为极简的“今日日期微字”，不强调预知全周日程。 |
| 9 | `MistMorphingCard.ets` | L36-56 | 原地排期微调手柄 `-15` / `+15` | **保留或优化为动作预估标签**。去掉锁定时段属性，保留任务自身时长微调。 |
| 10 | `MistMorphingCard.ets` | L59-74 | 原地排期锁定手柄 `isPinned`（锁定禁止算法重排） | **淘汰**。单线程流水线无需排期锁定，仅有置顶或调整顺序。 |
| 11 | `MobileTopBar.ets` | L54 | `4.5h 脑力负荷微晶罗盘` (`scheduledMinutes / maxDeepWorkMinutes`) | **脱敏精简**。主视图已不再使用该组件，确认完全解耦。 |
| 12 | `TvAmbientFocusView.ets` | L218 | `TimeUtils.formatSlotRange(slot.startMs, slot.endMs)` | **标记后续重构项**。客厅端后续同步为大屏单卡展示。 |

---

## 4. 多感官反馈系统深度审计 (Sensory & Feedback Audit)

### 4.1 音频反馈体系 (`AudioService.ets`)
- **实现机制**: 使用 HarmonyOS `@kit.MediaKit` 的 `media.SoundPool`（最大并发流 4 路），绑定 `audio.StreamUsage.STREAM_USAGE_NOTIFICATION`。
- **预加载音频采样**:
  1. `audio/sound_chord_c4.wav` (Root C4, 261.63Hz)
  2. `audio/sound_chord_e4.wav` (Major 3rd E4, 329.63Hz)
  3. `audio/sound_chord_g4.wav` (Perfect 5th G4, 392.00Hz)
  4. `audio/sound_chord_c5.wav` (Octave High C5, 523.25Hz)
- **多巴胺和弦阶梯算法 (`playChordStep`)**:
  - 维护 `currentStepIndex`，每次触发递增并取模：`soundIds[currentStepIndex % 4]`；
  - 形成著名的“Do -> Mi -> Sol -> High Do'”正向增强心理闭环；
  - 设置开关检测：`settings.isChordAudioEnabled`。
- **在 "Now Only" 阶段的集成规划**:
  - 当主卡片被右滑或点击“完成”时，**必须第一时间触发 `playChordStep()`**；
  - 阶梯计数在完成连续动作时逐级攀升，当用户清空当日全部微动作或进入晚间打烊时，触发 High C5 或钟鸣 `playSunsetGong()`；
  - 跳过/稍后操作则**不触发**和弦音频，保持听觉层级的纯净与正负反馈分明。

### 4.2 触觉马达反馈体系 (`HapticService.ets`)
- **实现机制**: 使用 HarmonyOS `@kit.SensorServiceKit` 的 `vibrator.startVibration`，用途指定为 `physicalFeedback`。
- **震感等级与应用场景**:
  - `triggerClick()` (35ms)：仿生泡泡纸破裂微震，干脆利落。
    - *Now Only 映射*：右滑完成、点击打勾环、抽屉开关。
  - `triggerTick()` (18ms)：轻柔气雾微脉冲，阻尼极低。
    - *Now Only 映射*：卡片拖拽过临界阈值、左滑跳过/推迟、杂念停机坪秒存。
  - `triggerHeavy()` (70ms)：厚重仪式感微震。
    - *Now Only 映射*：晚间打烊仪式落锁、一键清空归档。
- **设置开关**: 严格尊重 `settings.isHapticEnabled`，静音模式或用户关闭时静默降级。

### 4.3 物理动力学曲线库 (`CurveConstants.ets`)
现有曲线资源极其完备，可直接用于单任务舞台动画：
- `SPRING_LIQUID_SNAP = curves.springMotion(0.28, 0.58)`：用于拖拽未达阈值时的弹性归位；
- `SPRING_TOUCH_BOUNCE = curves.responsiveSpringMotion(0.28, 0.72)`：按压下沉响应；
- `SPRING_BOTTOM_SHEET = curves.springMotion(0.42, 0.85)`：用于底部待办队列折叠抽屉的升起与收拢；
- `SPRING_UNDO_BOUNCE = curves.springMotion(0.35, 0.75)`：用于撤销微胶囊弹出；
- **重构新增建议**:
  - `SPRING_STAGE_ADVANCE = curves.springMotion(0.38, 0.78)`：专用于下一项卡片自下而上跃升吸附就位的高阶弹簧曲线。

---

## 5. "Now Only" 单任务微晶主舞台技术架构方案

### 5.1 整体空间视觉拓扑 (Spatial Composition)

主舞台摒弃列表与轴线，采用**沉浸式空间三层叠层（Microcrystal Deck Layering）**：

```
+-------------------------------------------------------------+
|  [NowStageHeader] 9月22日 · 周二  |  已完成 3 步  | [打烊] [设置] |
+-------------------------------------------------------------+
|                                                             |
|                                                             |
|        +-------------------------------------------+        |
|        |   [NextPeekCard] (下一项微露边缘 14vp)       |        |
|     +--+-------------------------------------------+--+     |
|     |                                                 |     |
|     |            [NowActionStageCard]                 |     |
|     |          (屏幕中央独占当前唯一动作卡片)                |     |
|     |                                                 |     |
|     |  * 优先徽标 / 25 min 探索切片                      |     |
|     |  * 核心任务标题 (20fp 中粗体，视觉绝对锚点)           |     |
|     |  * 微步清单 (SubTasks 交互微复选)                  |     |
|     |                                                 |     |
|     |  [ 稍后推迟 ]      [ 专注沉浸 ]      [ 完成此项 ]   |     |
|     +-------------------------------------------------+     |
|                                                             |
|                                                             |
|  [ParkingLotInputBar] ⚡ 闪现杂念？轻触快录 (36vp 呼吸胶囊)     |
|                                                             |
|  [QueueDrawer Handle] 待办序列 · 还有 4 项 ▾ (超低认知负荷)     |
|                                                             |
|  ================= [HdsFloatingDock] =====================  |
+-------------------------------------------------------------+
```

### 5.2 核心组件一：当前动作微晶卡片 (`NowActionStageCard.ets`)
- **视觉定位**: 位于屏幕光学居中偏上（黄金视觉分割点），卡片宽度 92%，最小高度 220vp，最大高度 380vp。
- **设计细节**:
  - **背景与光泽**: 白玉微晶材质（`#FFFFFF`），圆角 24vp，双层柔暖环境阴影：
    ```typescript
    .shadow({
      radius: 24,
      color: 'rgba(85, 70, 50, 0.08)',
      offsetY: 8
    })
    .border({ width: 1, color: 'rgba(255, 255, 255, 0.95)' })
    ```
  - **信息层级**:
    1. **顶部状态栏**: 优先级柔和色块药丸（如珊瑚粉“高优核心”、鼠尾草绿“轻微行动”） + 预估时长胶囊（`25 min`）；无任何时刻戳！
    2. **中央大标题**: 20fp~22fp 粗体文字，行高 28vp，文字居中或左对齐，呈现绝对确定性与掌控感；
    3. **子步骤微清单**: 若存在 `subTasks`，原位呈现 1~3 个轻量复选行，鼓励“只走一小步”；
    4. **底部轻量操作组**:
       - 左侧：`[ 稍后 ‹ ]` 轻量次级按钮，触发跳过并后置；
       - 中间：`[ 进入专注沙漏 ]` 触发全屏沉浸；
       - 右侧：`[ 完成打勾 ✓ ]` 醒目珊瑚色圆环或实心胶囊。

### 5.3 核心组件二：底部拟物叠层微露卡片 (`NextPeekCard.ets`)
- **物理隐喻**: 像实体卡牌堆叠一样，底部微微露出一张卡片边缘，给大脑确信感——“下一步已经被妥善安排，不用慌张翻找列表，做完这张自然就有下一步”。
- **叠层几何参数 (Stack Geometry)**:
  - **Card 0 (Now Card)**: `scale: 1.0`, `translate: { x: currentX, y: 0 }`, `zIndex: 10`
  - **Card 1 (Next Peek Card)**:
    - `scale: 0.94`
    - `translate: { y: 28 }`（由于缩放与垂直位移差，卡片底部或顶部精确露出一道 **12~16vp** 的微边缘）
    - `opacity: 0.82`
    - `zIndex: 5`
    - 微露边缘呈现微弱的分类彩色细条与微字：“下一项：准备评审材料...”；
  - **Card 2 (Queue Depth Hint - 可选)**:
    - `scale: 0.88`, `translate: { y: 44 }`, `opacity: 0.35`, `zIndex: 1`；
    - 仅露出模糊底托微阴影，营造精致物理纵深感。

### 5.4 核心交互三：弹簧物理阻尼与流转动画 (Physics Spring Dynamics)
- **手势引擎 (`PanGesture`)**:
  - 绑定于 `NowActionStageCard`：
    ```typescript
    PanGesture({ direction: PanDirection.Horizontal })
      .onActionUpdate((event: GestureEvent) => {
        this.cardTranslateX = event.offsetX;
        // 仿生扑克牌微倾角：每 100vp 位移倾斜约 4 度
        this.cardRotateZ = event.offsetX * 0.04;
        
        // 临界震感反馈：首次突破 ±100vp 阈值时触发轻柔 micro-tick
        if (Math.abs(event.offsetX) > 100 && !this.hasTriggeredThresholdHaptic) {
          HapticService.getInstance().triggerTick();
          this.hasTriggeredThresholdHaptic = true;
        } else if (Math.abs(event.offsetX) <= 100) {
          this.hasTriggeredThresholdHaptic = false;
        }
      })
      .onActionEnd((event: GestureEvent) => {
        if (this.cardTranslateX > 100 || event.velocityX > 800) {
          this.executeSwipeComplete();
        } else if (this.cardTranslateX < -100 || event.velocityX < -800) {
          this.executeSwipeSkip();
        } else {
          this.executeSpringSnapBack();
        }
      })
    ```
- **右滑完成动效序列 (`executeSwipeComplete`)**:
  1. 当前卡片向右极速滑出屏幕（`translateX: 450, opacity: 0`），耗时约 240ms；
  2. 同步并发：
     - `AudioService.getInstance().playChordStep()` 阶梯和弦奏响；
     - `HapticService.getInstance().triggerClick()` 35ms 泡泡纸干脆微震；
     - `UndoService.getInstance().showUndo('已完成「' + item.title + '」', ...)` 5 秒防错胶囊涌出；
  3. **下一项卡片跃升**:
     - `NextPeekCard` 立即应用 `CurveConstants.SPRING_STAGE_ADVANCE`；
     - 从 `scale: 0.94, translateY: 28` 无缝吸附变倍至 `scale: 1.0, translateY: 0`，成为新的主舞台卡片；
  4. 底层补充新的下一项微边缘，数据层调用 `flowEngine.completeCurrent()`。
- **左滑跳过动效序列 (`executeSwipeSkip`)**:
  1. 当前卡片向左滑出或原地向下消隐；
  2. `HapticService.getInstance().triggerTick()` 18ms 极轻微震；
  3. 数据层调用 `flowEngine.skipCurrent()`（当前任务重新入队到机动队列末尾或次席）；
  4. 下一项卡片同样以弹簧阻尼平滑跃升成为主动作；
  5. 弹窗或微文本提示：“已为你暂放稍后，先专注眼前这项”。
- **未达阈值回弹 (`executeSpringSnapBack`)**:
  - 调用 `animateTo({ curve: CurveConstants.SPRING_LIQUID_SNAP }, () => { this.cardTranslateX = 0; this.cardRotateZ = 0; })`；
  - 卡片像被磁铁吸附般归位，伴随微微过冲震荡，带来解压的手感质感。

### 5.5 核心组件四：极简快录胶囊与折叠待办抽屉
- **36vp 杂念快录胶囊 (`ParkingLotInputBar.ets`)**:
  - 平时态高度规范为标准 36vp（圆角 18vp），文案为“⚡ 闪现杂念？轻触快录”；
  - 点击原地柔和展开输入框，输入完毕按下回车或点击“停泊”；
  - 任务**秒级滑入机动队列（Parking Lot Backlog）**，完全不打断当前正在进行的中央卡片，提示“已安全停泊，放心专注”；
  - 彻底切断杂念与当前心流的干扰。
- **轻量折叠抽屉 (`QueueDrawer.ets`)**:
  - 替换原笨重的 `FloatingDeckDrawer`；
  - 默认状态仅呈现极简胶囊句柄：`待办队列 · 4 项 ▾`（高度 32vp，浅灰半透明，视线 0 干扰）；
  - 点击或上拉时，通过 `SPRING_BOTTOM_SHEET` 展开半屏微晶面板；
  - 用户可在此查看所有后续待办序列、调整先后顺序或长按一键“放入冷冻舱”；
  - 关闭后立即回归纯净的单线程专注状态。

### 5.6 边界空状态：心流澄澈 (Zen All-Clear State)
- 当流水线队列中全部任务完成（`activeQueue.length === 0`）时：
  - 中央主舞台不再显示空白或报错，而是呈现精致的 **「心流澄澈 · 留白蓄力」** 禅意白玉微晶卡：
    - 0.8Hz 仿生慢节律呼吸光晕（鼠尾草绿与温润珊瑚微光）；
    - 嫩芽微标 (`app.media.ic_sprout`)；
    - 温暖文案：“今日所有步调已妥善完成，心流澄澈”、“不必焦虑寻找新事情，享受眼前的平静”；
    - 次级操作：提供“⚡ 录入新动作”与“提前开启晚间打烊仪式”两个轻量按钮。

---

## 6. ArkUI V2 响应式与状态管理重构设计

全量遵循 HarmonyOS NEXT 严格模式与强类型规范，彻底告别 V1 旧语法：

```typescript
/*
 * Architecture Blueprint: NowOnlyStageView (ArkUI V2)
 */
import { ColorConstants } from '../common/constants/ColorConstants';
import { CurveConstants } from '../common/constants/CurveConstants';
import { TodoItem, TodoStatus } from '../models/TodoItem';
import { SingleThreadFlowEngine } from '../engine/SingleThreadFlowEngine';
import { AudioService } from '../common/media/AudioService';
import { HapticService } from '../common/media/HapticService';
import { UndoService } from '../common/utils/UndoService';

@ComponentV2
export struct TodayFlowView {
  // 单向外部入参
  @Param topAvoidHeight: number = 0;
  @Param bottomAvoidHeight: number = 0;
  @Param isPaperMode: boolean = false;
  
  // 事件派发
  @Event onOpenFocus: (item: TodoItem) => void = () => {};
  @Event onOpenSunset: () => void = () => {};
  @Event onOpenSettings: () => void = () => {};

  // 本地响应式状态
  @Local private currentTask: TodoItem | null = null;
  @Local private nextTask: TodoItem | null = null;
  @Local private queueLength: number = 0;
  @Local private completedTodayCount: number = 0;
  @Local private isQueueDrawerOpen: boolean = false;

  // 手势与物理动力学状态
  @Local private cardTranslateX: number = 0;
  @Local private cardRotateZ: number = 0;
  @Local private nextCardScale: number = 0.94;
  @Local private nextCardTranslateY: number = 28;

  aboutToAppear(): void {
    this.refreshStageData();
  }

  // 纯粹的单线程队列刷新，完全不跑 BinPacking
  public async refreshStageData(): Promise<void> {
    const engine = SingleThreadFlowEngine.getInstance();
    await engine.loadQueue();
    this.currentTask = engine.getCurrentTask();
    this.nextTask = engine.getNextTask();
    this.queueLength = engine.getRemainingQueueCount();
    this.completedTodayCount = engine.getCompletedTodayCount();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 1. 顶部极简无压心流导航栏
      // ...
      
      // 2. 中央物理叠层主舞台 (Now Only Stage)
      Stack({ alignContent: Alignment.Center }) {
        if (this.nextTask) {
          // 下一项卡片微露层 (14vp Peek Layer)
          NextPeekCard({ item: this.nextTask })
            .scale({ x: this.nextCardScale, y: this.nextCardScale })
            .translate({ y: this.nextCardTranslateY })
            .zIndex(1)
        }

        if (this.currentTask) {
          // 当前主动作卡片 (Now Action Card)
          NowActionCard({
            item: this.currentTask,
            onComplete: () => { this.handleActionComplete(); },
            onSkip: () => { this.handleActionSkip(); },
            onFocus: () => { this.onOpenFocus(this.currentTask!); }
          })
          .translate({ x: this.cardTranslateX })
          .rotate({ angle: this.cardRotateZ })
          .zIndex(2)
          .gesture(
            PanGesture({ direction: PanDirection.Horizontal })
              // 绑定阻尼拖拽与阈值吸附动效
          )
        } else {
          // 心流澄澈禅意空态卡片
          ZenAllClearCard({
            completedCount: this.completedTodayCount,
            onOpenSunset: () => { this.onOpenSunset(); }
          })
          .zIndex(2)
        }
      }
      .width('100%')
      .layoutWeight(1)

      // 3. 底部极简停机坪与折叠抽屉
      // ...
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConstants.LIGHT_BG_CANVAS)
  }
}
```

---

## 7. 实施路线图与验证方法 (Implementation & Verification Roadmap)

### 7.1 分阶段重构演进路线 (Phased Migration Plan)

```
[Phase A: 废弃物剥离与依赖解耦]
   ├─ 确认 FlowSpineAxis 与 CushionCard 不被其他业务视图反向依赖
   ├─ 将 getTaskVisual 提取至 common/utils/TaskVisualHelper.ets (保护 MistMorphingCard 等复用)
   └─ TodayFlowView 移除 BinPackingScheduler 引用与 timelineSlots 变量

[Phase B: 主舞台组件开发]
   ├─ 构建 NowActionCard.ets (中央微晶动作卡、无时间戳排版、大字号、子任务微复选)
   ├─ 构建 NextPeekCard.ets (12~16vp 拟物叠层微露卡片、分类色条微标)
   └─ 构建 ZenAllClearCard.ets (全部完成时的呼吸空态)

[Phase C: 物理手势与动效联调]
   ├─ 植入 PanGesture 横向滑动手势引擎 (实时位移、倾角阻尼、阈值震感)
   ├─ 联动 AudioService.playChordStep() 与 HapticService.triggerClick()
   ├─ 适配 GlobalUndoCapsule 5 秒无痛撤销
   └─ 调试下一项卡片自下而上跃升吸附物理曲线 (SPRING_STAGE_ADVANCE)

[Phase D: 辅助流转系统升级]
   ├─ 改造 ParkingLotInputBar 为 36vp 标准快录胶囊
   ├─ 重构 QueueDrawer.ets (默认折叠 32vp，展开微晶抽屉)
   └─ 调整 TodayFlowView 顶栏为极简日期与心流步数计数器
```

### 7.2 风险排查与防御措施 (Risk & Mitigation)

1. **手势冲突风险 (Gesture Conflict)**:
   - *风险*: `PanGesture` 在水平滑动时可能与外层 `Index.ets` 的 `Swiper(3 Tab)` 发生竞争。
   - *对策*: 
     - 在 `NowActionCard` 的 `gesture` 中采用 `GestureMask.Normal`，并严格限制垂直滑动穿透；
     - 或者在卡片处于拖拽态（`isDragging === true`）时，通过父级回调临时禁用 `Swiper.disableSwipe(true)`，松手后恢复。
2. **多端响应式与折叠屏适配**:
   - *风险*: 折叠屏展开态或平板/2in1 宽屏下，卡片过宽显得松散。
   - *对策*: 卡片容器强制设置 `.constraintSize({ maxWidth: 520 })`，在宽屏下保持优雅的书本/卡牌黄金比例，两侧辅以温润的留白。
3. **撤销一致性 (Undo Consistency)**:
   - *风险*: 用户右滑完成下一项已跃升，如果此时点击“撤销”，界面如何回退？
   - *对策*: `UndoService` 触发回调时，通知 `SingleThreadFlowEngine.undoLastComplete()`，当前卡片以逆向弹簧动效（向右滑回并淡入）重新回到主舞台中央，下一项卡片重新落回 14vp 叠层。

---

## 8. 调研结论 (Conclusion)

通过本次深度调研，确认重构为「Now Only」单任务主舞台不仅在交互心理学上彻底清除了时间焦虑与时刻表压迫，在工程技术上也完全契合 HarmonyOS NEXT 的声明式组件机制与物理动效体系。
所有旧版时间轴与装箱算法代码已精确定位，解耦路径清晰，组件依赖边界分明。UI 架构已完全具备向单线程推力模型平滑迁移的充分条件！
