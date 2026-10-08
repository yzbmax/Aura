# 「Aura · 同频」UI/UX 交互与多感官设计全链路深度质检报告

> **审计执行角色**：Aura UI/UX & Sensory Codebase Inspector (体验法官与感官代码质检员)  
> **审计基准**：HarmonyOS NEXT (API 24 / 6.1.1 Release)、ArkUI V2 规范、尼尔森十大人机交互原则 (Nielsen's 10 Heuristics)、WCAG 2.1 AA 标准、全球标杆竞品体验模型（Things 3, Sunsama, Endel, Cron, Motion）  
> **审计代码路径**：`/Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/`  
> **完成时间**：2026-09-20  

---

## Executive Summary (审计核心摘要)

本报告基于严苛的产品体验法官与感官交互专家视角，对「Aura · 同频」的 ArkTS/ArkUI 代码实现进行了逐行深度审查。

审查结论：产品在宏观上构建了“暖科技·柔和光感”的视觉心智，但在**代码微交互落地、感官闭环容错、多端响应式工程、WCAG 对比度合规**等方面存在多处重大“体验断层”与“设计假说落空”。
- **严重阻断点（P0）**：`TodayFlowView` 遗漏了核心的 `ParkingLotInputBar` 实例；`FloatingDeckDrawer` 的快捷装箱点击无法持久化至数据库；`AudioService` 与 `HapticService` 完全脱钩用户设置且使用媒体音频流，在静音会议下产生社交灾难；`MistMorphingCard` 缺失原位形变与停留微脉动，被生硬的全屏模态完全打断；`TaskMatrixView` 四象限无任何拖拽交互（阻力为无穷大）；`SettingsView` 的核心工作时段完全写死不可配置。
- **视觉与感官硬伤（P1）**：`ColorConstants.LIGHT_TEXT_TERTIARY` 在米色底色下的对比度仅为 **3.27:1**，严重违反 WCAG AA（≥4.5:1）；昼夜节律双模色彩在主干页面中完全未启用深色模式；留白缓冲卡以高密度有界卡片形式插入，伴随反问句英文文案（`15min of free time?`），反而产生节奏割裂与心理反噬。
- **多端与系统层级缺失（P2）**：全套 UI 仅硬编码单列手机竖屏排版，在折叠屏展开态与平板/PC 宽屏下出现荒漠式留白与巨大拉伸失真，缺乏断点矩阵适配。

---

## 第一部分：核心组件与视图代码级深度诊断

### 1. `TodayFlowView`（今日心流主轴）与纵向脊柱

#### 1.1 关键代码观测 (Observations)
- **文件位置**：`entry/src/main/ets/views/TodayFlowView.ets` (第 13 行, 第 66~126 行, 第 177~185 行)
- **现象 1：杂念输入框入口遗漏 (Ghost Import)**  
  `TodayFlowView.ets` 第 13 行引入了 `ParkingLotInputBar`，并在第 177 行实现了 `handleParkingLotSubmit(text: string)`，但在核心 `build()` 结构中（第 66~126 行）完全未实例化 `ParkingLotInputBar`！
- **现象 2：当前进行中任务突显度为 0 (Zero Prominence for Current Slot)**  
  在 `components/FlowSpineAxis.ets`（第 83~178 行）中，时间轴遍历 `timelineSlots` 时，仅根据时长（`< 35m` vs `≥ 35m`）区分长短节点，**完全未判定当前现实时间戳与 `startMs / endMs` 的关系**，没有为正在进行中的任务提供呼吸边框、高亮徽标或“当前进行中 / NOW”指示线。
- **现象 3：时间轴可视密度与留白缓冲卡的视觉压迫感 (Visual Density & Buffer Card Pressure)**  
  `engine/BinPackingScheduler.ets`（第 164~178 行）在每个任务后强制插入 15 分钟缓冲带（`SlotType.BUFFER`）。`components/CushionCard.ets` 为其渲染带有圆角、背景模糊、投影和边框的实体卡片，并硬编码英文反问文本：
  ```typescript
  // CushionCard.ets: 40 行
  if (m < 60) {
    return `${m}min of free time?`;
  }
  ```
  在一次 4 小时工作流中，5 个任务之间插入 4~5 张实体 CushionCard，占据纵向 200~300vp 的面积。

#### 1.2 体验与心理缺陷剖析
- **【体验断层 UX Break】**：PRD 5.3.1 承诺的“主界面顶端常驻 36vp 杂念快录微胶囊”落空，用户必须进入全屏专注页才能停泊杂念，晨间排期与主轴浏览时闪现灵感无处安放。
- **【认知过载 Cognitive Overload】**：由于没有当前进行中任务的高光聚焦，用户每次切回 App 都必须在密集的时间轴列表中从头扫读时刻刻度，无法一秒捕捉当前心流锚点（违背尼尔森原则 #1：系统状态可见性）。
- **【反向心理压力 Negative Psychological Pressure】**：留白缓冲带本意是“让呼吸自然发生”。然而，将其显式渲染为实体卡片并标注 `15min of free time?`（带着英文问号），让用户产生“我是不是被浪费了 15 分钟？”或“我必须为这 15 分钟做点什么”的潜意识焦虑；且与整体中文界面产生语言撕裂（违背尼尔森原则 #4：一致性与标准）。
- **标杆竞品对照 (Things 3 & Structured)**：
  - *Things 3* 绝不显式画出“空闲卡片”，仅通过列表组之间的自然留白（Negative Space）实现呼吸感；
  - *Structured* 的空闲时间为半透明无边框细虚线，文案为极其克制的 `Gap (15m)`，绝不喧宾夺主。

---

### 2. `MistMorphingCard`（雾化开合卡片）

#### 2.1 关键代码观测 (Observations)
- **文件位置**：`entry/src/main/ets/components/MistMorphingCard.ets` (第 1~144 行)
- **现象 1：3.5s 视口停留微脉动彻底缺失**  
  代码中完全没有引入 `onVisibleAreaApproximateChange`、定时器或 `AppConstants.VIEWPORT_HOVER_THRESHOLD_MS`（3500ms），卡片处于纯静态状态。
- **现象 2：原位沙漏形变降级为暴力全屏跳转**  
  卡片点击事件（第 86~90 行）：
  ```typescript
  .onClick(() => {
    if (this.item.status !== TodoStatus.COMPLETED) {
      this.onContinueFocus(this.item);
    }
  })
  ```
  点击后沿着 `onContinueFocus` -> `TodayFlowView` -> `Index.ets`，将 `activeFocusItem` 置为当前 item，触发全屏模态 `FocusImmersionPage` 盖住整个主界面。

#### 2.2 体验与架构推演（为什么不能生硬实现 3.5s 脉动与原位沙漏？）
- **电池与 GPU 渲染开销 (Render Overhead & Thermal)**：
  若在 ArkUI 滚动列表项中监听视口停留 ≥3.5s 并启动 0.8Hz 循环呼吸动效：
  1. 用户在浏览时间轴或停顿思考时，视口内同时存在 3~5 张卡片，多组件并发启动循环属性动画，GPU 频繁重绘（Draw Call 激增），直接破坏鸿蒙 NEXT 的能效规范；
  2. 弱视或多任务用户在阅读某项任务时，旁边卡片不断“脉动喘气”，产生极其严重的**视觉感官噪音 (Sensory Noise)**。
- **布局抖动与形变硬伤 (Layout Jitter)**：
  原设计假说让卡片“原位形变为流体融化沙漏”。在 `FlowSpineAxis.ets` 中，卡片高度被时间槽严格限定在 58~125vp。若在 58vp 的窄槽内强行塞入沙漏动画、控制按钮与杂念输入框，会导致高度突变引起时间轴整体剧烈回流抖动（Reflow）；若不改变高度，内部元素则极度拥挤重叠。
- **当前粗暴全屏替代的副作用**：
  直接全屏弹出 `FocusImmersionPage` 破坏了用户的整体时间知觉，剥夺了对全天日程的掌控感（违背尼尔森原则 #3：用户控制与自由度）。

---

### 3. `ParkingLotInputBar` 与 `FloatingDeckDrawer`（停机坪与机动备选池）

#### 3.1 关键代码观测 (Observations)
- **文件位置**：
  - `entry/src/main/ets/components/ParkingLotInputBar.ets`
  - `entry/src/main/ets/components/FloatingDeckDrawer.ets`
  - `entry/src/main/ets/views/TodayFlowView.ets` (第 201~204 行)
- **现象 1：点击快速装箱未入库落盘 (Data Persistence Drop)**  
  在 `TodayFlowView.ets` 中：
  ```typescript
  // 第 201~204 行
  private async handleQuickSchedule(item: TodoItem): Promise<void> {
    item.scheduledStartAt = Date.now();
    await this.runAutoSchedule();
  }
  ```
  该方法修改了内存对象的 `scheduledStartAt`，但**完全没有调用 `TodoDao.update(item)`**！随后 `runAutoSchedule()` 触发 `refreshData()`，直接从 SQLite 中重新读取数据。因为数据库中仍为 `scheduled_start_at = 0`，点击 `+` 按钮后任务依然停留在机动池，产生**操作无响应假死假象**！
- **现象 2：杂念强制硬编码 25 分钟**  
  在 `ParkingLotInputBar` 提交时（`FocusImmersionPage.ets` 第 215 行与 `TodayFlowView.ets` 第 178 行），所有杂念均被硬编码初始化为 `25 分钟` 预估时长。用户记下“买咖啡”、“回邮件”等微琐事，全部被赋予 25 分钟高认知占位。
- **现象 3：机动池召回与整理认知负担过重 (Recall & Triage Blindspot)**  
  `FloatingDeckDrawer.ets` 仅渲染平铺卡片与一个 `+` 号。用户无法对杂念进行编辑、删除、调整时长、左滑归档，更无批量流转功能。当用户一天记录 10 个杂念时，底部抽屉变成无法清空的臃肿长清单。

#### 3.2 体验与心理缺陷剖析
- **【体验断层 UX Break - 严重级 Critical】**：用户点击 `+` 号期待任务进入时间轴，界面无任何变化，违反直接操作与即时反馈原则。
- **【认知过载 Cognitive Overload】**：把琐碎杂念与 25 分钟深度任务同等对待，直接打乱自适应装箱算法（4.5h 脑力硬上限迅速被 25 分钟的微杂念挤爆），迫使关键任务被排挤出今日时间轴。
- **标杆竞品对照 (Linear & Sunsama)**：
  - *Sunsama* 的 Backlog 允许将闪现杂念归类为 "Today", "Tomorrow" 或 "Later"，并有专属快捷键设定预估时长；
  - *Linear* 的 Triage 机制将未评估事项放在隔离池，需确认后方可排期，避免非计划事项污染主看板。

---

### 4. `TaskMatrixView`（四象限矩阵与冷冻舱）

#### 4.1 关键代码观测 (Observations)
- **文件位置**：`entry/src/main/ets/views/TaskMatrixView.ets` (第 246~285 行, 第 334~356 行, 第 374~505 行)
- **现象 1：四象限逻辑重叠与集合混乱 (Flawed Matrix Partition)**  
  代码中的四象限划分逻辑如下：
  ```typescript
  // 第 253 行: 核心攻坚 -> priority === Priority.HIGH
  // 第 262 行: 沉浸远景 -> priority === Priority.MEDIUM
  // 第 274 行: 琐碎轻量 -> priority === Priority.LOW
  // 第 283 行: 机动探索 -> scheduledStartAt === 0
  ```
  第四象限“机动探索”是以 `scheduledStartAt` 状态划分，而前三个象限以 `priority` 划分！如果一个任务既是 `HIGH` 又未排期（`scheduledStartAt === 0`），它会同时出现在第一象限与第四象限，造成数据冗余与认知错乱。
- **现象 2：物理阻力无穷大 (Zero Interactivity & Manipulation Resistance)**  
  四象限视图内的卡片完全是**只读展示**（没有 `onDrag`、没有长按菜单、没有右键/点击弹窗更改优先级）。用户看着“琐碎轻量”里的任务想提拔为“核心攻坚”，在当前界面上没有任何交互手段可以移动它！
- **现象 3：展示数量硬截断为 3 项**  
  每个象限容器高度固定 160vp，代码使用 `items.slice(0, 3)` 强行截断，其余任务仅显示不可交互的微文本 `+ 还有 X 项`。
- **现象 4：冷冻舱沦为“数字垃圾场” (Freezing Chamber as a Digital Graveyard)**  
  冷冻舱视图（第 374~505 行）仅显示简单的列表与“解冻唤醒”按钮。
  1. 没有任务冻结时间（已休眠多少天）；
  2. 没有任务分类、搜索与批量清理（删除/唤醒）；
  3. `SunsetCeremonyPage` 和每日晨间排期从未提醒用户回顾冷冻舱。
  根据认知心理学中的“逃避强化效应”（Avoidance Reinforcement），用户一旦把拖延任务扔进冷冻舱，就永远不再打开该 Tab，冷冻舱彻底变成死数据停尸房。

#### 4.2 违背设计原则
- 违背尼尔森原则 #3（用户控制与自由度）、#6（识别胜过回忆）。

---

### 5. `FocusImmersionPage` 与 `SunsetCeremonyPage`（专注场域与打烊仪式）

#### 5.1 关键代码观测 (Observations)
- **文件位置**：
  - `entry/src/main/ets/views/FocusImmersionPage.ets` (第 82~110 行, 第 178~190 行)
  - `entry/src/main/ets/views/SunsetCeremonyPage.ets` (第 36~56 行, 第 235~250 行)
  - `entry/src/main/ets/views/SettingsView.ets` (第 42~44 行)
- **现象 1：打着禅意旗号的数字催命倒数 (Hypocritical Zen Hourglass)**  
  PRD 5.2 宣称：“默认隐藏刺眼倒计时的数字，改用半透明沙漏粒子沉降与光晕消融展现时间流淌，消灭数字紧迫感”。
  然而在 `FocusImmersionPage.ets` 第 104 行：
  ```typescript
  Text(`${Math.floor(this.elapsedSeconds / 60)}m ${this.elapsedSeconds % 60}s`)
    .fontSize(13)
    .fontColor(ColorConstants.ACCENT_CORAL)
  ```
  沙漏中心**每秒钟跳动一次数字**！`setInterval(..., 1000)` 每秒刷新组件状态，直接将紧张感推向极致。
- **现象 2：5 分钟破冰船结算逻辑落空**  
  代码中完全没有 300 秒（5 分钟）触达检测，没有等权双选弹窗（`[ 🔥 状态不错，继续！ ]` 与 `[ ✋ 先到这里 ]`），只是一个无限正计时的普通跑表。
- **现象 3：晚间打烊仪式的“不可抗拒打断”与加班/夜班刚性死板**  
  在 `SettingsView.ets` 中，“工作时段 09:30 ~ 18:30 (打烊)”是不可点击修改的纯静态文本！
  若用户是程序员夜间攻坚、医生轮班、或因突发危机加班至 22:00，打烊页面依然死板地写着：“彻底物理断电 · 安心入睡”。用户如果此时还有紧迫要事未完，面对该页面会产生强烈的**挫败感与道德审判压力 (Moralizing UX)**。

---

## 第二部分：多感官反馈系统评估 (Audio & Haptics)

### 1. 声音反馈系统 (`AudioService.ets`)

#### 1.1 关键代码观测
- **音频流类型配置硬伤**：
  ```typescript
  // AudioService.ets: 36~39 行
  const audioRendererInfo: audio.AudioRendererInfo = {
    usage: audio.StreamUsage.STREAM_USAGE_MEDIA,
    rendererFlags: 0
  };
  ```
  在 HarmonyOS NEXT 中，`STREAM_USAGE_MEDIA` 归属于媒体音量通道。**当用户开启系统静音模式或震动模式时，媒体通道并不会被静音！**
- **设置开关完全脱钩 (Disconnected Settings Toggle)**：
  在 `SettingsView.ets` 中虽然提供了 `isChordAudioEnabled` 开关，但全工程中调用 `AudioService.getInstance().playChordStep()` 的地方（`TodayFlowView.ets:193`, `FocusImmersionPage.ets:207`, `CreateTodoDialog.ets:162`），**没有任何一处先检查 `settings.isChordAudioEnabled`**！
- **荒谬的触发时机 (Pavlovian Conditioning Pollution)**：
  在 `CreateTodoDialog.ets` 第 162 行，用户点击“保存并排期”**新建一个待办时**，系统竟然播放了和弦阶梯音效（`playChordStep`）！把“完成成就”的奖励音效提前透支给“创建待办”，破坏了条件反射的奖励机制。

#### 1.2 听觉耐受度与公私场域冲突
- **社交社死风险 (Social Risk in Meetings)**：高管/职场人在会议室静音开会时，勾选了一项待办，手机扬声器以 90% 音量爆发出清脆的高八度 `Do'` 纯音，产生灾难级用户体验。
- **高频打勾听觉疲劳**：连续勾选 5 个子任务时，音阶无节制高频轰鸣，缺乏淡入淡出（Duck/Fade）与动态节流（Throttle/Debounce）。

---

### 2. 触觉反馈系统 (`HapticService.ets`)

#### 2.1 关键代码观测
- **老旧粗暴的方波延时震动**：
  ```typescript
  // HapticService.ets: 45 行
  const effect: vibrator.VibrateEffect = {
    type: 'time',
    duration: durationMs // 35ms / 70ms
  };
  ```
  使用的是最底层的 `type: 'time'` 机械式震动，在大部分手机马达上表现为沉闷粗糙的“嗡嗡”声，完全不是宣称的“捏破泡泡纸般清脆解压的微触感”。
- **设置开关同样脱钩**：
  调用 `HapticService.getInstance().triggerClick()` 的所有地方均未校验 `settings.isHapticEnabled`，用户在设置中关闭触感后依然持续震动。

---

## 第三部分：视觉层级、WCAG 对比度与多端响应式

### 1. 色彩对比度检测 (WCAG 2.1 AA Compliance)

我们在代码中对 `ColorConstants.ets` 针对画布背景色进行了严苛的相对亮度（Relative Luminance）与对比度数学计算：
- 画布基色：`LIGHT_BG_CANVAS` = `#F7F5F0` (燕麦米白，相对亮度 $L_1 \approx 0.915$)
- 辅助文字：`LIGHT_TEXT_TERTIARY` = `#8F867D` (暖砂灰，相对亮度 $L_2 \approx 0.245$)

**对比度计算**：
$$\text{Contrast Ratio} = \frac{0.915 + 0.05}{0.245 + 0.05} = \frac{0.965}{0.295} \approx \mathbf{3.27 : 1}$$

- **审计判定**：
  - **严重违反 WCAG 2.1 AA 标准**（正文及小字号文本要求最低 **4.5:1**）。
  - 该颜色在整个应用中被大量用于 10~11fp 的超小字体（时间刻度标尺、子任务进度 `1/3`、任务副标题、空状态说明）。在室外强光或低亮度环境下几乎完全不可读！

### 2. 昼夜节律双模色彩假说落空

- 代码中定义了完整的 `DARK_BG_DEEP`、`DARK_BG_CANVAS`、`DARK_TEXT_*` 语义 Token；
- 但在 `Index.ets`、`TodayFlowView.ets`、`TaskMatrixView.ets`、`SettingsView.ets` 中，所有的页面背景与文字颜色**硬编码绑定为 `LIGHT_*`**；
- 系统切换为夜间深色模式时，主界面依然刺眼亮白，仅打烊弹窗是深色。昼夜节律机制在主干架构中形同虚设。

### 3. 多端响应式断点 (Breakpoint Matrix) 审计

- **断点代码为 0**：全工程搜索 `breakpoint`、`gridCol`、`mediaquery`，结果为 **0 项**；
- **大屏灾难**：在平板（MatePad）或折叠屏展开态（Mate X5/X6）等宽屏设备上：
  1. `HdsFloatingDock` 宽度硬编码为 236vp，悬浮在 1000vp+ 宽度的屏幕底端中央，比例严重失调；
  2. 单列时间轴强行撑满全宽，一行任务卡片被拉扯成 1000vp 宽的长条，左边是小字，右边是勾选环，视觉横向跨度过大，眼球扫读极度疲劳；
  3. PRD 所规划的“左侧控制舱 + 右侧双列画板 (时间轴 + 机动池)”完全未开发。

---

## 第四部分：战术级重构落地方案与优先级路线图

### 1. 结构化缺陷清单 (Defect Catalog)

| 编号 | 缺陷定位与场景 | 缺陷类型 | 级别 | 违背的人机交互原则 / 负面心理 | 竞品对标与改进思路 |
|---|---|---|---|---|---|
| **D01** | `TodayFlowView.ets` 缺少 `ParkingLotInputBar` | 体验断层 UX Break | **Critical (P0)** | 违背启发式 #1。晨间排期与主轴浏览无法秒级捕获杂念。 | 对标 Things 3 全局魔术加号，主屏常驻 36vp 微胶囊。 |
| **D02** | `TodayFlowView.ets:201` 快捷装箱未调用 DAO 更新 | 体验断层 UX Break | **Critical (P0)** | 违背直接操作反馈。点击 `+` 无响应，用户产生系统假死挫败感。 | 补充 `TodoDao.update`，增加轻量落盘位移动画。 |
| **D03** | `AudioService` / `HapticService` 脱钩用户开关且使用媒体音 | 感官噪音 Sensory Noise | **Critical (P0)** | 违背用户控制权。会议室静音下扬声器外放和弦造成社交尴尬。 | 绑定设置开关；改用系统音效流或检测静音模式自动降级为静音。 |
| **D04** | `SettingsView.ets:42` 工作时段不可修改 | 逻辑与心理漏洞 Logic Flaw | **High (P0)** | 违背包容性设计。加班、轮班、自由职业者遭遇道德审判。 | 改为可点击 `TimePicker`，支持自定义工作起止与弹性延后。 |
| **D05** | `ColorConstants.LIGHT_TEXT_TERTIARY` 对比度仅 3.27:1 | 视觉噪音 / 易读性硬伤 | **High (P1)** | 严重违反 WCAG 2.1 AA（最低 4.5:1），户外强光下刻度与状态不可读。 | 将颜色从 `#8F867D` 调整为 `#6B6259`，使对比度提升至 ≥ 5.2:1。 |
| **D06** | `FlowSpineAxis.ets` 缺失当前任务呼吸突显 | 体验断层 UX Break | **High (P1)** | 违背启发式 #1（系统状态可见性）。无法一秒确认当前该做什么。 | 计算现实时刻落在哪个 Slot，为当前任务增加微光环与“NOW”浮标。 |
| **D07** | `CushionCard.ets` 实体方框与英文反问句压力 | 视觉噪音 Sensory Noise | **Medium (P1)** | 违背一致性与优雅留白。密集的实体缓冲卡让时间线割裂焦虑。 | 对标 Things 3/Structured，化实体卡片为轻柔虚线与中文克制标签。 |
| **D08** | `MistMorphingCard` 粗暴切全屏替代原位沙漏 | 认知过载 Cognitive Overload | **High (P1)** | 违背启发式 #3。强行切入全屏打断对全天节奏的宏观掌控。 | 采用底部半屏展开 Sheet 或微沙漏胶囊展开，保留时间轴背板。 |
| **D09** | `TaskMatrixView.ets` 四象限无拖拽与集合交叉重叠 | 逻辑漏洞 Logic Flaw | **High (P1)** | 违背直接操作。物理阻力无穷大，机动探索与前三象限冲突。 | 规范为经典紧迫/重要二维矩阵，支持长按拖拽卡片调整象限。 |
| **D10** | 冷冻舱缺乏时间标记、批处理与定期复盘 | 认知过载 Cognitive Overload | **Medium (P2)** | 违背防内疚初衷。冷冻舱变成只进不出的“数字停尸房”。 | 显示休眠天数，提供批量唤醒/清理，在打烊仪式中增加温和回顾。 |
| **D11** | 全局硬编码手机排版，缺失多端断点适配 | 体验断层 UX Break | **Medium (P2)** | 违背 HarmonyOS 一开发多端部署准则，平板与折叠屏严重拉伸失真。 | 引入 `mediaquery` 与断点矩阵，大屏切为“左导航+右双列看板”。 |
| **D12** | `WeekCalendarBar.ets` 硬编码英文与假 Mock 状态点 | 视觉噪音 / 一致性破损 | **Low (P2)** | 违背启发式 #4（一致性）。中英文混杂，状态圆点欺骗用户。 | 切换为系统语言自适应日期，接入真实已排期日程统计。 |

---

### 2. 核心战术级代码重构方案示例

#### 方案 1：修复音效静音模式适配与设置开关联动 (`AudioService.ets`)
```typescript
// common/media/AudioService.ets 重构
import { audio } from '@kit.AudioKit';

export class AudioService {
  // ...
  public async playChordStep(isEnabled: boolean = true): Promise<void> {
    if (!isEnabled || !this.soundPool || this.soundIds.length === 0) {
      return;
    }

    // 检查系统当前情景模式 (静音/免打扰时不强制外放)
    const audioManager = audio.getAudioManager();
    const volumeGroupManager = audioManager.getVolumeGroupManagerSync(audio.DEFAULT_VOLUME_GROUP_ID);
    const ringMode = volumeGroupManager.getRingerModeSync();

    if (ringMode === audio.AudioRingMode.RINGER_MODE_SILENT ||
        ringMode === audio.AudioRingMode.RINGER_MODE_VIBRATE) {
      // 静音会议模式下自动静默，严防社死
      return;
    }

    const targetSoundId = this.soundIds[this.currentStepIndex % this.soundIds.length];
    this.currentStepIndex++;

    const playParams: media.PlayParameters = {
      loop: 0,
      rate: audio.AudioRendererRate.RENDER_RATE_NORMAL,
      leftVolume: 0.6, // 降低默认刺激度
      rightVolume: 0.6,
      priority: 1
    };
    this.soundPool.play(targetSoundId, playParams);
  }
}
```

#### 方案 2：修复 WCAG AA 文本对比度与自然虚线留白缓冲带 (`CushionCard.ets`)
```typescript
// components/CushionCard.ets 重构：去实体边框、去英文反问、强化 WCAG 达标
// 将 ColorConstants.LIGHT_TEXT_TERTIARY 调为 #6B6259 (对比度 5.2:1)
Row({ space: 8 }) {
  // 左侧时间标尺
  Text(TimeUtils.formatTime(this.startMs))
    .fontSize(11)
    .fontColor('#6B6259') // 满足 WCAG AA ≥ 4.5:1
    .fontWeight(FontWeight.Medium)

  // 极简自然呼吸线（取代原有的厚重实体大卡片）
  Row() {
    Line()
      .width('100%')
      .height(1)
      .strokeDashArray([4, 4])
      .stroke('rgba(85, 70, 50, 0.20)')
  }
  .layoutWeight(1)

  // 克制纯净中文提示
  Text(`留白 ${this.freeMinutes}m`)
    .fontSize(11)
    .fontColor('#6B6259')
}
.height(28) // 从臃肿的 50~100vp 紧凑缩敛为 28vp
.width('100%')
```

#### 方案 3：修复机动备选池快速装箱落盘 (`TodayFlowView.ets`)
```typescript
// views/TodayFlowView.ets: handleQuickSchedule 重构
private async handleQuickSchedule(item: TodoItem): Promise<void> {
  // 1. 更新内存状态
  item.scheduledStartAt = Date.now();
  item.isDirty = true;
  
  // 2. 必须写入本地 SQLite 持久层！
  await TodoDao.update(item);
  
  // 3. 触发即时触感与重新装箱排期
  HapticService.getInstance().triggerClick();
  await this.refreshData();
}
```

---

### 3. P0 / P1 / P2 实施优先级路线图 (Implementation Roadmap)

```
[ 阶段一：P0 核心止血与合规防线 (48h 内) ]
├── D01. 在 TodayFlowView 顶端补齐 ParkingLotInputBar 实例与落盘监听
├── D02. 修复 FloatingDeckDrawer 快速装箱无法持久化至数据库的硬伤
├── D03. 彻底重构 AudioService / HapticService：挂接设置开关与静音模式检测
└── D04. 解锁 SettingsView 中的工作时段，实现可配置起止时间与加班延后

[ 阶段二：P1 心流深化与视觉降噪 (1 周内) ]
├── D05. 调整 ColorConstants 浅色与深色次级字体色值，100% 通过 WCAG 2.1 AA
├── D06. FlowSpineAxis 接入现实时间监听，高亮正在进行中的任务并渲染呼吸微光
├── D07. CushionCard 彻底去实体框化，改用 Things 3 风格虚线与克制中文
├── D08. 优化 MistMorphingCard 与专注态切换，提供半屏 Sheet 避免全屏打断
└── D09. 重构 TaskMatrixView 四象限逻辑，支持拖拽移动与优先级快速变更

[ 阶段三：P2 生态亮点与多端扩展 (2 周内) ]
├── D10. 冷冻舱增加时间感知标签、批量整理与打烊周期性温和唤醒
├── D11. 建立基于 mediaquery 的多端断点系统，平板与折叠屏展开双列 Soft-Bento
└── D12. 统一全 App 语言体系（去除夹杂的英文残片），接入真实日程统计微粒
```
