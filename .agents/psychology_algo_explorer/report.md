# 「Aura · 同频」心理学闭环与调度算法深度审计报告
### Product Psychology, Algorithmic Agency & Boundary Stress-Testing (R2 & R4 Focus)

> **审计执行人**：Psychology & Algorithm Specialist (Teamwork Explorer)  
> **审计对象**：Aura · 同频 (HarmonyOS NEXT v1.6 / API 24)  
> **基线代码库**：`entry/src/main/ets/` (`engine/`, `models/`, `views/`, `components/`, `database/`)  
> **依据规范**：`docs/AuraPRD.md`, `docs/DESIGN.md`, `TODO.md`, `ORIGINAL_REQUEST.md`  
> **交付日期**：2026-09-20  

---

## 1. 执行摘要与核心裁决 (Executive Summary & Verdict)

「Aura · 同频」以“白天算法排期的理性、专注感官沉浸的多巴胺、晚上仪式断电的温柔”为差异化核心主张，试图在传统待办应用的“催命压迫感”与无序拖延之间开辟第三条道路。这一愿景极具人文关怀与市场辨识度。

然而，经过对项目全量设计文档与 ArkTS/ArkUI 生产级源码的深度审计，审计组发现其**核心假说在心理学机制与算法工程落地之间存在严重的脱节与自相矛盾**。如果不加重构直接推向市场，产品将陷入“既得罪高绩效专业人士，又放任重度拖延症患者，并在现实日程扰动下频繁翻车”的尴尬境地：

1. **自主感剥夺与逆反/习得性无助 (Agency Stripping)**：纯贪心装箱算法直接替用户裁决全天每一分钟，违背自决理论（SDT）。用户沦为算法排期的被动执行者；更致命的是，算法每次重排都引发全时间线剧烈跳动，导致用户产生“反正排了也会被打乱”的习得性无助。
2. **反内疚文案的“毒性鸡汤化”与数据造假 (Toxic Positivity & Falsification)**：诸如“装不下啦，不要内疚”等文案对高压专业用户构成居高临下的情感冒犯；更为恶劣的是，系统在打烊与统计中硬编码虚假数据（如无专注时长时强行兜底显示“累计沉浸 90 分钟，非常了不起”），彻底摧毁了工具的基本诚实度。
3. **致命的“过去时间排期”算法硬伤 (Temporal Blindness Bug)**：`BinPackingScheduler` 缺乏对现实当前物理时间（`Date.now()`）的动态锚定，下午 14:00 触发排期依然从早上 09:30 开始装箱，导致任务被大量排在“过去时”，造成严重的认知灾难。
4. **全天候动机断层与疲劳衰竭 (Daily Journey Friction)**：晨间被历史积压霸屏、专注页充斥秒级倒数引发时钟焦虑、打烊仪式在疲惫的深夜强推“10+ 任务逐个三选一决策”，严重违反自我损耗理论（Ego Depletion）。
5. **极端状态崩溃与全无撤销安全网 (Zero Undo & Edge Case Fragility)**：50+ 微任务引发 150 分钟留白卡片通胀爆炸；断开 5 天后产生“再登入耻辱墙”；删除任务、打烊取消无任何二次确认与 Undo 撤销机制。

---

## 2. R2 深度审查：产品定位与心理学核心闭环 (Product Architecture & Psychology Loop Audit)

### 2.1 算法排期的自主感剥夺：自决理论 (SDT) 与心理逆反 (Psychological Reactance)

#### 2.1.1 理论根基与心理机制诊断
自决理论（Self-Determination Theory, Deci & Ryan, 2000）指出，人类维持内在动机与心理健康依赖三大基本心理需求：**自主感 (Autonomy)**、**胜任感 (Competence)** 和 **归属/联结感 (Relatedness)**。
在个人生产力领域，**自主感是心流发生的绝对前提**。当工具越俎代庖，利用“黑盒算法”强行替用户决定 09:30 该做什么、10:15 该做什么时，用户的心理防御机制将被瞬间激活：

1. **心理逆反 (Psychological Reactance, Brehm, 1966)**：当用户感到行动自由被剥夺时，会产生强烈的反抗情绪。用户心理独白往往是：“凭什么算法让我现在攻坚架构？我现在就想先回邮件！”进而拒绝打开应用。
2. **习得性无助 (Learned Helplessness, Seligman, 1975)**：当现实中的突发状况（领导临时交办、会议超时）发生时，算法粗暴地将后续时间块全盘顺延或截断。用户发现自己制定的节奏毫无意义，最终放弃时间管理，回归原始混乱。

#### 2.1.2 现有代码证据与机制漏洞
- **源码出处**：[`entry/src/main/ets/engine/BinPackingScheduler.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/engine/BinPackingScheduler.ets) (第 78~82 行，第 92~179 行)
- **代码实现**：
  ```typescript
  // 5. 对候选任务进行综合加权排序打分
  pool.sort((a: TodoItem, b: TodoItem) => {
    const scoreA = BinPackingScheduler.calculateScore(a);
    const scoreB = BinPackingScheduler.calculateScore(b);
    return scoreB - scoreA;
  });
  ...
  for (const interval of freeIntervals) {
    let pointer = interval.startMs;
    while (pointer < interval.endMs && totalScheduledMinutes < maxDeepWork) {
      // 贪心填入最高分任务，强制插入 15m 缓冲带
      ...
    }
  }
  ```
- **病理剖析**：
  - **排期权力完全垄断**：只要任务未打上 `isPinned = true`，算法就会在每次刷新时重新计算打分，彻底覆盖原有时段。用户在界面上无法自由拖拽调整时间块顺序（`TodayFlowView.ets` 仅支持点击 `+` 加入排期，不支持拖拽重排）。
  - **无情境感知 (Context-Blindness)**：算法完全忽略任务的物理场景与设备情境（例如：是否在工位、是否需要大屏、是否需要安静环境）。即使某个任务被标记为 `assignedTo = PC`，算法依然强行塞进早晨手机端的第一槽位。
  - **与标杆竞品对比**：
    - **Motion（负面教训）**：被全球用户广为诟病为“机械监工（Robotic Overlord）”，一处延误导致整周日历雪崩，产生极高焦虑。
    - **Sunsama（正面标杆）**：坚守**“辅助规划而非替人规划”**哲学。Sunsama 从不自动替用户决定时间点，而是提供右侧日历视窗与今日清单，由用户**主动拖拽 (User-Guided Drag & Drop)** 至指定时段，系统仅在侧边做容量提示（“已排 3.5h，建议留白”）。**掌控感始终在人手中，算法只做标尺，不做主宰。**

---

### 2.2 反内疚机制的真实反噬：毒性正能量 (Toxic Positivity) 与虚假放任 (Procrastination Licensing)

#### 2.2.1 情绪调节 vs 拖延合理化
待办管理中的内疚感本质上是一种警示信号。Sirois & Pychyl (2013) 的拖延心理学研究表明：**拖延不是时间管理障碍，而是即时情绪调节（Mood Regulation）障碍。**
健康的心理干预应当是**真正的自我同情 (Self-Compassion, Kristin Neff)**：包含对现实局限的接纳（Common Humanity）、对当下阻力的正念觉察（Mindfulness），以及负责任的行动重定向（Constructive Action）。

#### 2.2.2 Aura 当前反内疚设计的严重硬伤

1. **文案轻浮与居高临下的情感冒犯 (Patronizing & Infantilizing Copy)**：
   - PRD 79 行与 UI 提示：*“装不下啦，不要内疚 🌿”*。
   - **对于严肃职场用户**：下午有一场致命的客户交付，系统因为达到 4.5h 脑力上限，直接把交付任务踢出时间轴，并弹窗轻飘飘地说“装不下啦，不要内疚”。这极具讽刺意味，会让高压专业人士感到该应用幼稚、脱离生产实际、不可托付。
   - **对于重度拖延症 / ADHD 患者**：这句话提供了**“外部许可（External Licensing）”**，原本能够促成启动的适度张力被过早瓦解，用户名正言顺地放弃今天的所有推进。
2. **最为致命的硬伤：虚假数据与自欺欺人 (Data Falsification)**：
   - **源码出处 1**：[`entry/src/main/ets/views/SunsetCeremonyPage.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/views/SunsetCeremonyPage.ets) (第 286~293 行)
     ```typescript
     let totalMinutes = 0;
     for (const t of allActive) {
       totalMinutes += (t.actualMinutes || 0);
     }
     this.totalFocusedMinutes = totalMinutes > 0 ? totalMinutes : 90;
     ```
     并在界面直接渲染：
     ```typescript
     Text(`今日累计高效沉浸 ${this.totalFocusedMinutes} 分钟，非常了不起`)
     ```
   - **源码出处 2**：[`entry/src/main/ets/views/TaskMatrixView.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/views/TaskMatrixView.ets) (第 838 行)
     ```typescript
     this.todayFocusMinutes = minutes > 0 ? minutes : 135; // 演示温和默认 2.25h
     ```
   - **心理学死刑裁决**：
     当一个用户今天因为情绪崩溃、完全荒废了一整天，晚上打开打烊仪式时，Aura 竟然弹出一张精美卡片赫然写着：*“今日累计高效沉浸 90 分钟，非常了不起”*！
     用户的心智模型会瞬间崩塌：**“这软件根本不关心我做了什么，它在虚伪地哄骗我。”** 产品的专业信誉（Trustworthiness）与真实反馈机制瞬间降为负数。

---

### 2.3 生物节律与上下文盲区 (Chronotype & Arbitrary Brain Cap)

#### 2.3.1 4.5 小时“每日脑力硬上限”的机械教条
- **源码出处**：[`entry/src/main/ets/common/constants/AppConstants.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/common/constants/AppConstants.ets) (第 14 行)
  ```typescript
  public static readonly DEFAULT_MAX_DEEP_WORK_MINUTES: number = 270; // 4.5h
  ```
- **现实工况冲突**：
  - Cal Newport 提出的 4 小时深度工作上限，特指**高认知负荷的纯粹攻坚（Deep Work）**。
  - 知识工作者的日常由两部分组成：核心深度工作（2~4h）+ 事务性浅度协作（2~4h，如沟通、代码评审、填写周报、审批、杂务）。
  - 在 Aura 的排期逻辑中，只要任务总时长达到 270 分钟，后续所有任务统统拒绝装箱。
  - 更夸张的是：从 09:30 开始排，排满 4.5 小时后（大约在 14:00 结束），算法在 14:00~18:30 的整整 4.5 个小时内，**自动生成长达数小时的“自由心流留白 · 休憩充电”虚线占位卡**（`BinPackingScheduler.ets` 第 183~194 行）！
  - 没有任何一个现代职场环境允许员工在下午一点半之后全部显示“休憩充电”。这种非黑即白的时间切分，严重脱离工作常识。

#### 2.3.2 晨型人 vs 夜型人 (Chronotypes) 的全盲
- 算法固定从 `workStartHour`（09:30）向后线性装箱。
- 事实上，认知心理学与神经节律研究（Roenneberg, *Internal Time*）表明：夜型人（Night Owls）在早晨处于认知惰性期，适合处理低脑力行政杂务；其精力波峰出现在 15:00~18:00。
- Aura 将最高优先级的核心攻坚任务无差别塞进 09:30~10:15 的槽位，直接导致夜型用户在最昏沉的早晨遭遇最艰难的卡片，引发严重的启动阻抗（Task Paralysis）。

---

### 2.4 全天候沉浸旅程断层与动机流失点 (Journey Drop-Off Breakdown)

对照 Sunsama 与 Things 3，对用户典型一天的 5 大关键节点进行动机链路全景诊断：

| 时间节点 | 设计理想蓝图 (PRD Vision) | 现实代码实现与体验硬伤 (Code & UX Reality) | 心理反应与流失触发点 (Churn Trigger) | 对标竞品治愈解法 (Benchmark) |
|---|---|---|---|---|
| **09:00 晨间规划** | 打开应用，结合日历自动排期，脑力负荷舒适，从容开工。 | `BinPackingScheduler.ets` 将所有逾期任务加权 120 分强制置顶；未排期的历史逾期任务一开屏就砸在早晨主轴上。 | **开工焦虑堵塞**：一睁眼面对的是昨天的失败债务，而非崭新的开始，触发避难逃避。 | **Things 3**：过期待办不标红报警，优雅沉在 Today 顶部，允许用户一键右滑转入“今晚”或“改天”。 |
| **10:15 破冰攻坚** | 视口停留 3.5s 微脉动提示“试试 5 分钟”；原位形变溶化沙漏，无催命数字。 | `MistMorphingCard.ets` 根本没有实现 3.5s 脉动；点击直接路由到全屏 `FocusImmersionPage.ets`，且页面正中央赫然跳动着数字计时 `Text('${min}m ${sec}s')`！且无 5 分钟结算弹窗。 | **切页撕裂与时钟恐慌**：承诺的“原位沙漏”变成生硬全屏切页，催命数字倒数依然存在，未完成 5 分钟退出被直接归零。 | **Endel / Tiimo**：真正使用光斑水波扩散，绝对不显示秒级跳动数字，消除时钟神经压迫。 |
| **11:30 突发打断** | 会议拖堂 30m，算法毫秒级平滑顺延，从容包容现实。 | 算法没有当前时间锚定点；一旦重排，直接从早上 09:30 重新算起，把任务排到过去；或直接触发 4.5h 截断，下午任务瞬间蒸发。 | **失控慌乱**：用户发现时间线疯狂抖动，已做完的任务与未做任务位置混乱颠倒。 | **Sunsama**：提供“拖堂向后推 30 分钟”单点微调气泡，只影响当前块及其紧邻块，不搅动全盘。 |
| **15:00 杂念闪现** | 杂念停机坪秒级停泊，心流零打断，承诺打烊复盘。 | `ParkingLotInputBar.ets` 录入后存为 `source = PARKING_LOT`，但立即显示在主屏下方 `FloatingDeckDrawer` 中，用户只要一划主轴就能看到。 | **干扰回流**：刚扔进去的杂念又在眼前晃悠，注意力残留（Attention Residue）未被真正隔离。 | **Linear / Things**：快速捕获（Quick Capture）直接送入后台暂存箱，主工作区不可见，直到主动复盘。 |
| **18:30 晚间打烊** | 暮光合拢，回顾成就，未完成宽容三选一，物理断电安心入睡。 | 伪造 90m 专注时间；若待办池有 20 个琐事，打烊页要求逐个点击“明早排/冷冻舱/算了”，制造极高决策疲劳；点击断电仅关闭 Modal，无实质夜间模式切换。 | **收尾心智过载**：下班时刻被迫充当人肉数据清洗员，做完 20 次选择心力交瘁，索性直接杀进程退出。 | **Sunsama**：批量快捷归档；打烊完毕播放风铃舒缓声，全屏锁定为“明日待办待唤醒”静谧封板。 |

---

## 3. R4 深度审查：极端边界条件与异常状态压力测试 (Edge Cases & Failure States)

### 3.1 突发被打断与致命的“过去时间排期”算法漏洞 (Cascading Delays & Temporal Blindness)

#### 3.1.1 算法时间锚点缺失缺陷
- **源码定位**：[`entry/src/main/ets/engine/BinPackingScheduler.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/engine/BinPackingScheduler.ets) (第 38~66 行)
- **代码重现**：
  ```typescript
  const baseDate = new Date(dayTimestamp);
  const dayStartMs = new Date(
    baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate(),
    settings.workStartHour, settings.workStartMinute, 0, 0
  ).getTime();
  ...
  let cur = dayStartMs; // 致命漏洞：直接以工作日早晨 09:30 为装箱游标起点
  for (const locked of validLocked) {
    if (locked.startMs > cur) {
      freeIntervals.push({ startMs: cur, endMs: Math.min(locked.startMs, dayEndMs) });
    }
    cur = Math.max(cur, locked.endMs);
  }
  ```
- **严重事故场景还原**：
  1. 用户在下午 **14:30** 打开 Aura，刚刚开完一个长达两小时的突发紧急会议；
  2. 用户在 `WeekCalendarBar` 点击“AI 智能装箱”按钮（触发 `runAutoSchedule()`）；
  3. 调度算法启动：`baseDate` 为今天，`dayStartMs` 为今天上午 **09:30**；
  4. 算法寻找可用时间缝隙：发现 09:30~10:30 是空闲的（因为早上的任务还没被锁定或者已移出）；
  5. **算法将待办任务排在了今天上午 09:30 ~ 10:15！**
  6. 渲染到界面上：用户在 14:30 分，看着时间轴顶端排着今天早上 09:30 的任务，且卡片未完成；
  7. **逻辑荒谬性**：人不能穿越回过去工作。一个时间块管理软件将待办事项排在已经过去的客观物理时间上，属于最高等级的 **P0 致命逻辑缺陷**。

#### 3.1.2 连环延误下的“时间轴震荡 (Timeline Flutter)”
当用户的一个任务超时 45 分钟时，如果在当前算法中简单重新排期，后续所有时间块的开始时间、结束时间将全部发生离散突变。
- **心理学效应**：时间感是由空间锚点支撑的。当时间卡片在屏幕上跳动、消失或位移超过视域 30% 时，会诱发人类的视觉惊跳反射与控制感丧失，带来强烈的焦虑感。

---

### 3.2 数据与任务极端场景压力测试

#### 3.2.1 极限状态 1：单日 50+ 琐碎微任务 (Micro-Task Explosion)
- **场景**：用户并非只做高深攻坚的学者，而是需要处理 50 项琐事（报销、发短信、签收快递、代码小提交、找人核对）的运营或主管。
- **算法与 UI 翻车实录**：
  1. **留白卡片恶性通胀**：
     - `BinPackingScheduler.ets` 第 165~178 行：每个任务之后，**无条件强制插入 `bufferMinutes`（默认 15 分钟）的呼吸卡**！
     - 50 个微任务，哪怕每个只需 3 分钟（共 150 分钟），算法强行插入 50 × 15m = **750 分钟（12.5 小时）的留白卡**！
     - 加上任务时间，总时间高达 900 分钟，远超一日工作总时长（9 小时）。
  2. **脑力上限过早熔断**：
     - 调度算法在排到大约第 10 个微任务时，`totalScheduledMinutes` 就触碰了 270 分钟硬上限；
     - 剩下的 40 个微任务全部被暴击抛入机动池（`scheduledStartAt = 0`）；
  3. **视觉长廊灾难**：
     - `FlowSpineAxis.ets` 渲染出 10 个任务卡片与 10 个巨大的“留白透气 · 喝杯温水”虚线框，屏幕垂直高度超过 2000vp，用户需要疯狂滑动才能看清仅有的几个事项。
- **治理法则缺失**：缺少像 Things 3 的“清单内轻量勾选列表（Checklists）”或 Sunsama 的“上下文批处理（Task Batching / Context Grouping）”机制。

#### 3.2.2 极限状态 2：连续 3~7 天未打开应用的“幽灵积压与耻辱墙 (Ghost Backlog)”
- **场景**：用户生病、休假或出差一周，未曾打开 Aura。第 8 天早晨重新打开。
- **算法反噬实录**：
  1. **积分算法的报复性置顶**：
     - 查看 `BinPackingScheduler.calculateScore`（第 235~236 行）：
       ```typescript
       if (diffHours <= 0) {
         urgencyWeight = 120; // 已超期，高权重处理
       }
       ```
     - 7 天前积压的 15 个过期任务，其 `urgencyWeight` 全部被拉满至 120 分；
     - 结果：**算法在第 8 天早晨，自动将这 15 个陈旧甚至已经失效的过期任务，全部塞进今日 09:30~14:00 的黄金时间轴！**
  2. **冷冻舱规则的死板截断**：
     - `MildAgingEngine.ets`（第 38~44 行）将阈值设为绝对的 8 天（`FROZEN_DAYS_THRESHOLD = 8`）；
     - 逾期 7 天零 23 小时的任务依旧被当做极其紧急的事项疯狂排期；
     - 用户一打开软件，迎面撞上一堵巨型的“历史债务墙”。根据心理防卫机制，用户此时的第一选择绝不是逐个完成，而是直接**卸载软件**。
- **标杆解法**：Things 3 和 Sunsama 在检测到长时间未活跃后，会在首次唤醒时触发**“重返仪式（Welcome Back Reset）”**：“检测到你离开了一段时间，是否将历史积压一键归档或移入备选池，从零开始享受今天？”

#### 3.2.3 极限状态 3：离线多设备编辑与静默覆盖 (Silent LWW Conflict Hazard)
- **PRD 宣称**：PRD 8.3 宣称“行级 LWW (Last-Write-Wins) 以毫秒级 updated_at 统一裁决；并发提示检测到双端 5 秒内冲突覆盖，弹出微 Toast”。
- **代码真相**：
  - 全工程搜索 `LWW`、`conflict`、`distributedDataObject`，在当前生产代码中没有任何冲突感知管线或历史版本快照；
  - `TodoDao.ets` 更新逻辑仅为简单的单表 `update`；
  - 如果用户在平板离线补充了详尽的任务描述，而在手机端快速打了个勾，后同步的简单打勾操作会凭借微秒级 `updatedAt` 直接覆写平板端辛苦撰写的长篇描述，造成不可逆的**用户数据静默丢失**。

---

### 3.3 操作死胡同与撤销机制缺失审查 (Zero Undo & Accidental Operations)

尼尔森人机交互十项原则之第三条：**用户控制与自由 (User Control and Freedom)**。系统必须提供明显的“紧急出口”，支持撤销（Undo）与重做（Redo）。

Aura 当前代码在所有关键破坏性操作上均处于**“裸奔状态”**：

#### 3.3.1 误触任务删除：无二次确认，无 Undo 撤销
- **代码出处**：[`entry/src/main/ets/views/TaskMatrixView.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/views/TaskMatrixView.ets) (第 204~211 行，第 846~850 行)
- **实现**：
  ```typescript
  Button('删除')
    .onClick(() => {
      this.deleteTask(task.id);
    })
  ...
  private async deleteTask(id: string): Promise<void> {
    await TodoDao.deleteTombstone(id);
    HapticService.getInstance().triggerTick();
    await this.loadData();
  }
  ```
- **问题**：在触控滑动列表中，28vp 的“删除”文字按钮极易被大拇指误触。一旦误触，没有任何 ActionSheet、没有确认 Dialog，更没有底部的“任务已删除 · [ 撤销 ]”微胶囊，任务瞬间从界面完全消失。

#### 3.3.2 误触打烊仪式中的“算了 (Cancel)”：彻底取消且不可逆
- **代码出处**：[`entry/src/main/ets/views/SunsetCeremonyPage.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/views/SunsetCeremonyPage.ets) (第 215~220 行，第 315~319 行)
- **实现**：
  点击打烊卡片上的“算了”按钮，直接调用 `TodoDao.deleteTombstone(item.id)`，打上 `status = TodoStatus.CANCELLED, is_deleted = 1`。
- **问题**：打烊时刻用户处于疲劳状态，手指极易滑错选项。一旦点错，事项直接被视作放弃，且打烊页没有已撤销列表，用户甚至无法查证自己刚才误删了什么。

#### 3.3.3 误触进入全屏专注沙漏：退出强制污染实际投入统计
- **代码出处**：[`entry/src/main/ets/views/FocusImmersionPage.ets`](file:///Users/qiuhaiqin/DevEcoStudioProjects/Aura/entry/src/main/ets/views/FocusImmersionPage.ets) (第 192~198 行)
- **实现**：
  ```typescript
  private async handleExit(): Promise<void> {
    this.stopTimer();
    const addedMinutes = Math.round(this.elapsedSeconds / 60);
    this.item.actualMinutes += addedMinutes;
    await TodoDao.update(this.item);
    this.onClose();
  }
  ```
- **问题**：如果用户只是误点进卡片想看子任务，发现进错了立马退出来；只要停留超过 30 秒，`addedMinutes` 就会被四舍五入记为 1 分钟并写入数据库。没有任何“放弃本次记录/误触退出”选项。

---

## 4. 关键缺陷代码证据汇总表 (Code Evidence Matrix)

| 缺陷编号 | 缺陷分类 | 严重级别 | 所在文件与行号 | 核心代码特征与问题描述 | 违背的心理学与设计原则 |
|---|---|---|---|---|---|
| **DEF-01** | 【逻辑与算法漏洞】 | **Critical (P0)** | `engine/BinPackingScheduler.ets`: 38-66 | `let cur = dayStartMs;` 装箱起点锁死为 09:30，下午排期时导致任务被排在过去时间。 | 真实物理世界一致性原则 (Nielsen #2) |
| **DEF-02** | 【心理与伦理缺陷】 | **Critical (P0)** | `views/SunsetCeremonyPage.ets`: 290<br>`views/TaskMatrixView.ets`: 838 | `totalMinutes > 0 ? totalMinutes : 90;` 专注时间为 0 时硬编码兜底谎报 90 分钟。 | 系统可信度 (Trustworthiness) 与真诚反馈原则 |
| **DEF-03** | 【体验与交互断层】 | **High (P1)** | `views/TaskMatrixView.ets`: 204-211, 846-850 | `deleteTask` 瞬间执行软删除，无二次确认，无 Undo 撤销条。 | 用户控制与自由 (Nielsen #3: Emergency Exit) |
| **DEF-04** | 【认知过载与算法漏洞】 | **High (P1)** | `engine/BinPackingScheduler.ets`: 164-178 | 任务块后无条件插入 15m 留白；50 个微任务产生 750 分钟留白卡，界面崩溃。 | 认知负荷理论 (Cognitive Load Theory) |
| **DEF-05** | 【动机与心流断层】 | **High (P1)** | `views/FocusImmersionPage.ets`: 104<br>`components/MistMorphingCard.ets`: 86-90 | 原位 5m 微脉动未实现，点击跳全屏切页，屏幕中央跳动强刺眼数字秒数倒数。 | 视口连续性原则、时钟焦虑阻断原则 (Endel 模式) |
| **DEF-06** | 【心理与决策衰竭】 | **High (P1)** | `views/SunsetCeremonyPage.ets`: 283-284 | `queryAllActive()` 将所有未完成待办全量塞入打烊三选一，未排期任务也需逐项清洗。 | 自我损耗理论 (Ego Depletion, Baumeister) |
| **DEF-07** | 【算法与动机缺陷】 | **High (P1)** | `engine/BinPackingScheduler.ets`: 235-236 | 逾期任务 `urgencyWeight = 120` 强制置顶，多日未用重返应用遭遇“债务霸凌”。 | 蔡加尼克效应与启动瘫痪 (Task Paralysis) |
| **DEF-08** | 【体验断层与误导】 | **Medium (P2)** | `components/FloatingDeckDrawer.ets`: 115-118<br>`views/TodayFlowView.ets`: 201-204 | `handleQuickSchedule` 仅修改内存 `scheduledStartAt`，未持久化写入数据库，刷新后失效。 | 状态持久一致性 (State Persistence) |

---

## 5. 战术级落地方案与架构重构建议 (Tactical Redesigns & Actionable Roadmap)

### 5.1 战术重构方案 1：从“主宰装箱”走向“人机协同辅助规划” (Human-in-the-Loop Scheduling)

#### 5.1.1 核心理念转变
废除“算法单方面决定一切”的机械模式，吸纳 Sunsama 与 Things 3 的高口碑基因：**算法做建议者与容量标尺，用户保留最终排期裁决权。**

#### 5.1.2 算法核心代码重构 (解决过去时间排期与动态锚定)
修改 `BinPackingScheduler.schedule`，引入当前物理时间基准：

```typescript
// 战术修正：引入锚定游标 nowMs
const now = Date.now();
const isToday = TimeUtils.isSameDay(dayTimestamp, now);

// 游标起点：如果是今天，排期起点绝不能早于当前时刻；否则从 workStartMs 开始
let cur = isToday ? Math.max(dayStartMs, now) : dayStartMs;

// 向上规整到最近的 5 分钟整点，避免 14:23 这种碎散时刻
cur = Math.ceil(cur / (5 * 60000)) * (5 * 60000);
```

#### 5.1.3 交互重构：双态排期模式 (Auto-Propose vs Manual Drag)
1. **主轴拖拽与时段吸附**：允许用户长按时间卡片直接在纵向时间轴上上下滑动微调时段，松手时自动磁吸对齐到最近的 15 分钟空闲槽位；
2. **锁止与保护显性化**：被用户手动拖拽过的卡片自动打上 `isPinned = true`，旁边展示精致的小图钉徽标。下次执行智能装箱时，系统绝对绕开锁定块，只在缝隙处做“推荐填充”。

---

### 5.2 战术重构方案 2：反内疚文案重塑与数据诚实性守则 (Authentic Self-Compassion)

#### 5.2.1 彻底清除虚假伪造数据
1. **坚决删除硬编码兜底代码**：
   - 将 `SunsetCeremonyPage.ets` 的 `totalMinutes > 0 ? totalMinutes : 90` 改为真实统计：
     - 若 `totalMinutes === 0`，展示更加真诚、有温度的温和接纳文案：
       *“今天或许有些疲惫，但你已经安然度过。好好休息，明天太阳照常升起 🌅”*；
     - 坚决杜绝“明明做了 0 分钟却夸奖累计高效沉浸 90 分钟”的滑稽讽刺。
2. **文案矩阵重构表**：

| 原有反噬文案 | 心理学缺陷 | 重构后的真诚文案 (Neff 自我同情模型) |
|---|---|---|
| *“装不下啦，不要内疚 🌿”* | 居高临下、轻浮、放任拖延 | *“今日精力池已近饱和。留白不是怠惰，而是为了明日更清晰的聚焦。”* |
| *“太棒了！今日所有时间块均已安然完成”* | 幼态化夸奖 | *“今日计划圆满收官。卸下包袱，安心享受属于自己的夜晚。”* |
| *“这事算了”* (打烊选项) | 带有挫败与自我否定暗示 | *“放入归档 · 战略放弃”* (明确告知放弃是高级的优先级选择) |

---

### 5.3 战术重构方案 3：微任务批处理与弹性留白缓冲压缩 (Micro-Task Batching)

针对 50+ 碎片任务导致的 150 分钟留白爆炸：
1. **轻量清单模式 (Inline Checklist)**：
   - 时长 $\le 10$ 分钟且同属性的琐碎微任务，不占用独立时间块；
   - 算法自动聚类为一个 **25 分钟聚合块 `[ 📨 碎片杂务批处理 ]`**，内部以勾选子项形式收纳 3~5 个琐事；
2. **动态弹性留白 (Adaptive Buffer)**：
   - 两个时长 $\le 15$ 分钟的微任务之间，留白压缩为 0~5 分钟；
   - 仅当完成 $\ge 45$ 分钟的高认知深度攻坚块后，才强制插入 15 分钟的完整茶歇留白。

---

### 5.4 战术重构方案 4：重返应用与幽灵积压“破冰分流” (Welcome Back Triage Flow)

针对 3~7 天未打开应用的用户，建立防逃避保护屏障：
1. **冷启动沉睡检测**：
   - 在 `EntryAbility` 或 `Index.ets` 检测距离上次打开时间是否 $\ge 72$ 小时；
2. **唤醒引导卡 (Triage Dialog)**：
   - 弹出一张温润的半屏微晶卡：
     *“好久不见。过去几天的事项或许已有变动，想要如何开启今天？”*
     - `[ 🧹 历史一键归档 / 移入冷冻舱 ]`：将所有逾期未做事项清空排期、归入冷冻舱，今日时间轴彻底清爽；
     - `[ 🔍 快速挑 3 件最重要的排入今天 ]`：进入极简挑选视窗；
   - **杜绝算法报复性置顶历史债务**。

---

### 5.5 战术重构方案 5：全局 Undo 悬浮微胶囊与死胡同防线 (Universal Undo Safety Net)

1. **SnackBar 全局撤销管道**：
   - 在 `Index.ets` 根视图建立全局 `UndoManager`；
   - 任何地方触发“删除任务”、“打烊取消任务”、“误触冷冻”：
     - 先将待办加入内存墓碑缓存队列（暂不提交物理删除）；
     - 底部弹出 5 秒悬浮胶囊：`已删除「重构架构」 · [ 撤销 ]`；
     - 用户点击撤销，毫秒级恢复视图；5 秒未操作，才执行真正的数据库墓碑落盘。
2. **打烊仪式的“一键智能顺延”**：
   - 优化打烊页的交互负荷：顶部增加 `[ 一键将全部未做事项顺延至明日备选池 ]`；
   - 只有想特殊处理某一项的用户才去点击单个卡片，消灭 20+ 次机械点击的认知折磨。

---

## 6. P0 / P1 / P2 分级实施路线图 (Implementation Roadmap)

```
[P0: 核心止血项 (安全与算法硬伤)] ──────────► [P1: 心流深化项 (心理闭环与微交互)] ──────────► [P2: 生态亮点项 (多端与感官)]
• 修复过去时间排期 (cur = Math.max(now))    • 落地 3.5s 脉动与原位沙漏真实形变       • 华为 Share Kit 跨设备甩单
• 清除 90m 虚假数据与毒性鸡汤文案          • 实现全局 5 秒 Undo 撤销微胶囊           • 结合 Calendar Kit 读取系统日程
• 增加删除二次确认与打烊误触防线            • 上线重返应用 (Ghost Backlog) 分流       • 端侧精力节律直方图个性化排期
• 修复 FloatingDeck 快速排期数据落盘失效    • 微任务批处理合并 (Batching Box)         • 折叠屏展开态双列双向拖拽
```

- **P0 核心止血项（必须立即修复，阻断体验翻车）**：
  1. `BinPackingScheduler.ets` 增加当前物理时间判定，终结“任务排在过去”的逻辑灾难；
  2. `SunsetCeremonyPage.ets` 与 `TaskMatrixView.ets` 彻底删除 90m/135m 虚假保底数据，回归诚实心理学；
  3. `TaskMatrixView.ets` 与 `SunsetCeremonyPage.ets` 增加删除拦截确认或临时恢复机制；
  4. `FloatingDeckDrawer.ets` 的 `+` 排期增加真正的 `TodoDao.update(item)` 持久化。
- **P1 心流深化项（核心差异化落地，构筑体验壁垒）**：
  1. `MistMorphingCard.ets` 补全 3.5s 视口微脉动与卡片原位展开（消灭跳全屏切页与刺眼秒级数字）；
  2. 落地全局 Undo 撤销栈（5 秒安全气囊）；
  3. 引入轻量级微任务批处理（Merge Micro-tasks）机制，防止缓冲卡片通胀；
  4. 引入休假/断更重返引导流（Catch-up & Fresh Start）。
- **P2 生态与高级特性项（长期演进）**：
  1. Calendar Kit 外部日程感知联动；
  2. 真正的时间块主轴拖拽交互支持；
  3. Live View Kit 实况窗与多端软总线分布式同步冲突感知。

---

*报告编写完毕，全量证据链与重构代码提案已归档至 `.agents/psychology_algo_explorer/`。*
