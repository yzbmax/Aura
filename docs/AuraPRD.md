# 「Aura · 同频」产品需求文档 (PRD)

> **基于鸿蒙分布式能力的多设备自适应时间块与反内疚待办管家**
>
> 版本：v1.6 (心流感官与全链路闭环版) · 日期：2026-09-16 · 创作者：罗欣童
>
> 核心灵魂：**"白天，算法替你排期的理性；专注，感官喂饱多巴胺的沉浸；晚上，仪式帮你断电的温柔。"**
>
> 品牌 Slogan：**"万物互联，心意同频。" / "In sync with your flow."**

---

## 目录

1. [产品概述与核心差异化](#1-产品概述与核心差异化)
2. [目标用户与全天候使用场景](#2-目标用户与全天候使用场景)
3. [技术基准与开发约束](#3-技术基准与开发约束)
4. [合规红线总纲（华为应用市场）](#4-合规红线总纲华为应用市场)
5. [核心功能需求清单](#5-核心功能需求清单)
 - 5.1 P0：有边界的自适应时间块与未知时长弹性应对
 - 5.2 P0：5 分钟破冰船与禅意融化沙漏
 - 5.3 P0：杂念停机坪与多巴胺和弦阶梯（抗干扰与即时奖赏）
 - 5.4 P0：晚间打烊仪式与反过载心理学（Sunset Ceremony）
 - 5.5 P0：核心待办 CRUD 与独立子任务体系
 - 5.6 P1：全域心流广播与实况窗交互（Live View Kit）
 - 5.7 P1：零输入意图捕获与 Share Kit 甩单
 - 5.8 P2：习惯镜像与端侧精力统计
6. [信息架构与页面结构](#6-信息架构与页面结构)
7. [数据模型与持久化设计](#7-数据模型与持久化设计)
 - 7.1 核心响应式实体（ArkUI V2）
 - 7.2 数据库物理 Schema（RelationalStore）
 - 7.3 数据库版本迁移策略
 - 7.4 列表分页与内存缓存策略
8. [自适应时间块装箱算法与同步架构](#8-自适应时间块装箱算法与同步架构)
 - 8.1 贪心区间装箱与弹性调度算法
 - 8.2 存算分离：持久层与瞬时状态层
 - 8.3 分布式同步管线（Sync Pipeline）
 - 8.4 冲突解决（LWW + 墓碑机制 + 冲突感知 UI）
9. [权限矩阵与隐私合规设计](#9-权限矩阵与隐私合规设计)
10. [多设备适配与降级策略](#10-多设备适配与降级策略)
11. [非功能性需求（性能、触感与音效）](#11-非功能性需求性能触感与音效)
12. [版本演进路线图（V1.0α 与 V1.0β）](#12-版本演进路线图v10α-与-v10β)
13. [设计决策清单（定稿）](#13-设计决策清单定稿)
14. [提审前合规自检清单](#14-提审前合规自检清单)

---

## 1. 产品概述与核心差异化

### 1.1 产品定位

「Aura · 同频」是一款基于 HarmonyOS NEXT 全场景分布式生态与端侧情境感知的**自适应时间块与反内疚轻量待办管家**。它不充当高压严苛的冷血监工，而是通过**算法装箱的理性、感官设计的激励、打烊仪式的温柔**，为知识工作者与拖延倾向人群构筑健康的心流护城河。

### 1.2 核心差异化：消灭传统待办的四大死穴

| 传统待办痛点 | 市面方案缺陷 | Aura 的终极解法 | 对应核心模块 |
|---|---|---|---|
| **排期繁重与时长未知**<br>（满屏清单不知何时做；复杂任务无法预估耗时导致全盘撞车） | Motion：强行排满全天，把人当机器使，稍有拖延连环崩溃 | **有边界的自适应时间块 + 弹性切片**：像俄罗斯方块一样自动装箱，坚守**每日脑力上限 ≤4.5h** 与 **强制 15m 留白**；未知任务采用 **45m 探索切片**，承诺投入而非承诺搞定。 | 5.1 自适应时间块与弹性切片 |
| **启动瘫痪与选择疲劳**<br>（面对大任务习惯性逃避；看着清单不知先做哪个） | 传统番茄钟：动辄 25~45 分钟门槛过高；清单列表选择过载 | **5 分钟破冰船 + 视口微脉动**：视口停留 3.5s 触发“做 5 分钟随时可停”，以不可抗拒的极微步击穿阻力。 | 5.2 破冰微沙漏 |
| **专注中途极易走神**<br>（刚开始做事就想去搜八卦、查快递） | 离开应用去记笔记，顺手滑进短视频彻底沦陷 | **杂念停机坪（The Parking Lot）**：专注界面一行胶囊，秒级收纳杂念入机动池，承诺打烊时提醒，堵死走神任意门。 | 5.3 杂念停机坪 |
| **完成缺乏快感与下班焦虑**<br>（打勾枯燥无味；做不完满屏红字，带着罪恶感入睡） | 传统打勾只划横线；晚上下班依然弹逾期警报 | **和弦多巴胺阶梯 + 晚间打烊仪式**：打勾触发 `Do-Mi-Sol-Do'` 逐级爬升音阶与泡泡纸微震；18:30 打烊宽容三选一，彻底物理断电。 | 5.3 多巴胺和弦 & 5.4 打烊仪式 |

---

## 2. 目标用户与全天候使用场景

### 2.1 目标用户画像

1. **高负荷知识工作者**：频繁被突发会议打断，需要算法自适应重排，渴望工作与生活的清晰界限；
2. **ADHD 倾向 / 深度拖延者**：执行功能障碍严重，面对大任务容易瘫痪，极度依赖即时多巴胺激励与低压环境；
3. **多设备鸿蒙生态用户**：在手机、平板与 2in1 PC 之间无缝流转，追求高质感系统级原生体验。

### 2.2 核心全天沉浸旅程（A Day with Aura）

- **09:00 晨间开工**：扫一眼桌面卡片，Aura 结合日历会议已将今日任务拼装入自适应时间轴，脑力负荷控制在 3.5h，舒适留白；
- **10:15 破冰攻坚**：面对复杂 Bug，视口微脉动提示“试试 5 分钟？”，卡片原位平滑形变为**禅意融化沙漏**（无催命数字倒数）；
- **10:20 走神阻断**：构思中大脑突然冒出“买猫粮”，随手在屏幕底部的**【杂念停机坪】**输入回车，杂念安全停泊，心流零打断；
- **10:45 听觉与触感多巴胺**：完成攻坚第一阶段，勾选卡片，系统发出清脆纯净的 `Do (C)` 纯音伴随泡泡纸解压微震，即时满足感拉满；
- **11:30 突发会议拖堂**：会议超时 30 分钟，算法毫秒级顺延后续任务，排不下的事项自动收拢回机动池，并弹温和微 Toast：“装不下啦，不要内疚 ”；
- **18:30 晚间打烊与心理关机**：打烊全屏层弹出，展示今日累计专注 150 分钟，SaveButton 零权限存入相册；未做完事项一键选“明天一早排”；实况窗销毁，手机进入静谧夜间模式，安心享受私人时光。

---

## 3. 技术基准与开发约束

| 项目 | 规范 | 说明 |
|---|---|---|
| **操作系统** | HarmonyOS NEXT (AOSP-free) | 纯血鸿蒙统一底座 |
| **SDK 版本** | API 24 Release (HarmonyOS 6.1.1) | 生产基线 |
| **DevEco Studio** | 6.1.1 Release (6.1.1.280) | 官方集成开发环境 |
| **编程语言** | 纯 ArkTS | 严格模式，严禁 `any`，严禁动态属性增删 |
| **UI 框架** | ArkUI V2 | `@ComponentV2`, `@ObservedV2`, `@Trace`, `@Local` |
| **核心算法** | 本地离线区间装箱算法 | 纯数学逻辑，耗时 <2ms，零电量消耗，零网络依赖 |
| **音频与触感** | `soundPool` 低延迟音频池 + `vibrator` 线性微振动 | 原生无感调用，无需敏感权限，即时多巴胺反馈 |
| **状态管理** | ArkUI V2 响应式装饰器 + `AppStorageV2` + `PersistenceV2` | 官方原生状态框架 |
| **架构红线** | 坚决不使用后台常驻死循环，严禁申请违规保活权限 `KEEP_BACKGROUND_RUNNING` |

---

## 4. 合规红线总纲（华为应用市场）

1. **Local-First（本地优先）**：未登录状态下，基础待办、时间块排期、杂念停机坪、破冰船、打烊仪式完全可用，数据持久化于本地 SQLite；
2. **隐私双清单内建**：设置页提供真实的“已收集个人信息清单”与“第三方共享清单”；
3. **零权限保存相册**：打烊成就卡使用 ArkUI 原生安全控件 **`SaveButton`**，无需声明 `WRITE_IMAGEVIDEO` 权限；
4. **权限动态按需申请**：严禁首启一揽子索权，用户拒绝日历权限后，自适应排期自动降级为应用内可用时段装箱，应用不闪退、不强退；
5. **商业化合规**：V1 完全免费、不含广告，避开广告标识符与商业合规审核雷区。

---

## 5. 核心功能需求清单

### 5.1 【P0】有边界的自适应时间块与未知时长弹性应对

> 核心差异化 #1 — 用算法的理智消灭排期的繁重，用弹性的时间箱包容现实的不确定性。

#### 5.1.1 自动装箱与区间调度逻辑
- **可用时段输入**：用户配置每日工作起止时间（默认 09:30~18:30），自动扣除午休与外部日历会议；
- **综合加权调度**：综合加权计算得分：$\text{Score} = (\text{Priority} \times 0.4) + (\text{DueUrgency} \times 0.4) + (\text{AgeFactor} \times 0.2)$，优先将最高分任务填入最早空闲缝隙；
- **大任务防饥饿策略（Starvation Prevention）**：若高优先级任务预估时长大于当前所有连续可用 Slot 时，算法严禁直接跳过该任务。算法自动触发“智能切片保底”，将该任务转为 45m 探索切片装入首个 $\ge 45\text{m}$ 的空闲槽，并在时间块上标明 `[ 切片装箱 ]`，确保核心要事每日均有实质推进。

#### 5.1.2 人性化“反压迫”三大边界（Aura 护城河）
1. **每日脑力硬上限（Anti-Overload Cap）**：每日高认知专注时间块**累计不超过 4.5 小时（270 分钟）**，超额部分强制留白或归入机动池；
2. **强制呼吸缓冲带（Mandatory Buffer）**：任务块之间强制插入 **10~15 分钟** 的无任务空白带；
3. **超时自动顺延与溢出保护**：任务超时后续任务顺次后推；顺延触碰 18:30 打烊线时，末尾低优任务自动滑入机动池，弹出温和安慰 Toast；
4. **手动锁定保护（Pin Block）**：用户锁定的关键时间块在自动重排时保持锚定不动。

#### 5.1.3 未知复杂度与弹性任务的应对机制
1. **时间箱探索切片（Focus Slice）**：未知复杂度大任务无需预估完工时间，分配 45m/60m 探索定额；到期提供 `[ 追加 25m ]` 与 `[ 今天先到这 ]` 双选，记录实际投入，绝不判定逾期；
2. **流体正计时模式（Stopwatch Mode）**：支持一键切为正计时（`timing_mode = STOPWATCH`）。晨间排期时，系统统一以 **25 分钟弹性时间块** 为其预留槽位；实际进行中从 00:00 静默正数，停止时精准回填实际消耗，超出或少于 25m 部分毫秒级弹性顺延/拉齐后续时间块；
3. **机动备选池（Floating Deck）**：琐碎等待型事务 `scheduled_start_at = 0`，不占时间轴格子，仅在会议缝隙做轻量磁吸提示。

---

### 5.2 【P0】5 分钟破冰船与禅意融化沙漏

- **视口微脉动**：视口停留某待办 ≥3.5 秒，卡片边缘产生 0.8Hz 极柔和呼吸脉动：“做 5 分钟就可以停，试试看？”；
- **禅意融化沙漏**：
 - 卡片原位形变为流体微沙漏，**默认隐藏刺眼倒计时的数字**，改用半透明沙漏粒子沉降与光晕消融展现时间流淌，消灭数字紧迫感；
- **结算选择**：5 分钟到期弹出等权双选：`[ 状态不错，继续！ ]` 无缝接续时间块，`[ 先到这里 ]` 赞赏投入 5 分钟。

---

### 5.3 【P0】杂念停机坪与多巴胺和弦阶梯（抗干扰与即时奖赏）

> 针对 ADHD 与拖延症核心软肋量身打造的心流守护体系。

#### 5.3.1 杂念停机坪（The Parking Lot）
- **交互入口**：在主界面顶端与专注沙漏场域下方，常驻一行 36vp 高度的极简微胶囊输入栏；
- **功能机制**：专注中心血来潮闪现杂念（如“想买鞋”、“查快递”）时，无需跳出应用，敲下文字按回车；
- **闭环归宿与生命周期管理（防垃圾场机制）**：
 - 数据静默落盘至本地 SQLite，`source = PARKING_LOT`, `scheduled_start_at = 0`（自动归入机动备选池）；
 - 屏幕中央温和浮现 1.5 秒微胶囊确认：*“已安全停泊，放心专注 ”*；
 - **打烊集中复盘**：晚间打烊仪式中，集中展示今日停靠的所有杂念供用户处理（转明日待办、放入冷冻舱、或一键划掉）；
 - **48 小时自动温和沉底**：停泊超过 48 小时且未处理的杂念，自动标记为灰度休眠，避免机动池成为堆积如山的第二拖延清单。

#### 5.3.2 和弦多巴胺阶梯与触感反馈（Chords of Accomplishment）
- **听觉阶梯**：用户勾选完成子任务或推进时间块时，系统调用 `soundPool` 播放纯净乐器采样音阶：
 - 当日完成第 1 个任务：清脆纯净的 `Do (C)`；
 - 完成第 2 个任务：温暖舒展的 `Mi (E)`；
 - 完成第 3 个任务：明亮开朗的 `Sol (G)`；
 - 完成第 4 个任务：高八度的 `Do (C')`，屏幕绽放微粒子消散动效；
 - 循环梯级激励，将完成任务重塑为弹奏即兴治愈乐章；
- **触觉微反馈**：配合鸿蒙线性马达（`vibrator`），提供如捏破泡泡纸般清脆解压的微触感震动，让勾选反馈具备强烈的物理质感。

---

### 5.4 【P0】晚间打烊仪式与反过载心理学（Sunset Ceremony）

#### 5.4.1 打烊三部曲
1. **完成庆祝与沉浸认可**：18:30 准时弹出暗色打烊层；统计专注时长，针对长任务展示：*“今天在【架构攻坚】上累计沉浸 90 分钟，非常了不起 ”*；ArkUI 原生 **`SaveButton`** 零权限一键存相册；
2. **宽容三选一（底层字段流转闭环）**：未完成任务绝无红字警示，提供宽容流转操作：
 - `[ 明天一早排 ]`：更新 `scheduled_start_at = 0, scheduled_end_at = 0, is_pinned = 0, is_dirty = 1`，任务归入机动池，等待次日早晨装箱算法重新分配；
 - `[ 放入冷冻舱休眠 ]`：更新 `status = TodoStatus.FROZEN, is_frozen = 1, scheduled_start_at = 0, is_dirty = 1`，移入任务视界折叠冷冻舱，不再参与日常调度，保留随时一键解冻；
 - `[ ️ 这事算了 ]`：更新 `status = TodoStatus.CANCELLED, is_deleted = 1, deleted_at = now(), is_dirty = 1`，赋予分布式删除墓碑，移入回收归档，30 天后自动物理清理；
3. **物理断电**：实况窗销毁，桌面卡片切换暗色夜间模式，直到次日 09:00 前保持静谧场域。

#### 5.4.2 温和老化（Mild Aging）与冷冻舱
- 逾期 1~3 天褪淡 20%，4~7 天变秋叶黄沉底，8+ 天归入“冷冻舱”静默休眠，支持一键解冻。

---

### 5.5 【P0】核心待办 CRUD 与独立子任务体系

- 基础属性完整，子任务独立表 `sub_task_items`（外键级联，独立更新时间戳与墓碑）；
- 分布式软删除墓碑 `is_deleted = 1, deleted_at = now()`，30 天物理清理；
- 同步脏标记 `is_dirty = 1, last_synced_at = now()`。

---

### 5.6 【P1】全域心流广播与实况窗交互（Live View Kit）

- TIMER 场景，前置申请 AGC 实况窗权益；
- 锁屏大卡片配置 `ServiceButton`（`[ 暂停 ]` 与 `[ 完成 ]`），用户无需解锁直接在锁屏通过 `WantAgent` 交互闭环；
- 2in1 PC 端降级为应用内窗口顶部 **32vp 毛玻璃微状态条 / 独立悬浮微窗**。

---

### 5.7 【P1】零输入意图捕获与 Share Kit 甩单

- 调起系统原生 Share Kit（华为分享）隔空甩单；
- Calendar Kit 融合：V1.0α 纯自建日程装箱；V1.0β 获批 ACL 后接入系统全局会议日程。

---

### 5.8 【P2】习惯镜像与端侧精力统计

- 本地 14 天待办完成频次直方图微调优先级，纯端侧极低算力开销。

---

## 6. 信息架构与页面结构

```
App Root (Navigation + NavPathStack, NavigationMode.Auto 自动多端分栏)
├── 主界面 Tabs（黄金 3 Tab 结构）
│ ├── 1.「今日心流」（Today Focus）
│ │ ├── 顶部：今日概况 · 脑力负荷进度条（已排 X 小时 / 上限 4.5h）· 打烊倒计时
│ │ ├── 中部：【自适应时间轴看板】（ArkUI V2 Repeat 虚拟滚动）
│ │ │ ├── 锁定会议日程块（灰色锚定）
│ │ │ ├── 算法自适应时间块（动态色块，显示耗时、起止时间与切片状态）
│ │ │ ├── 强制留白缓冲带（轻透明虚线）
│ │ │ └── 已完成项目（柔和半透明沉底，附带和弦音阶图标）
│ │ ├── 下部折叠区：【机动备选池（Floating Deck）】（放置 scheduled_start_at = 0 的弹性待办与停靠杂念）
│ │ └── 悬浮极简入口：5 分钟破冰船微沙漏 + 一键智能重排按钮
│ │
│ ├── 2.「任务视界」（Task Matrix / All）
│ │ ├── 视界切换：未排期备选池 / 四象限视图 / 标签归类
│ │ ├── 待办列表（支持拖入今日时间轴）
│ │ └── 底部折叠区：「冷冻舱」（放置逾期 ≥8 天的温和老化任务）
│ │
│ └── ️ 3.「偏好与合规」（Settings）
│ ├── 排期偏好（工作起止时段、每日脑力上限、留白缓冲时长）
│ ├── 感官反馈（和弦音阶开关、触感反馈强弱）
│ ├── 晚间打烊设置（打烊时间、成就卡主题）
│ ├── 分布式设备与同步日志
│ └── 隐私合规（双清单、撤回同意、注销入口）
│
└── 沉浸式独立路由（NavDestination / Modal 流）
 ├── 「专注沙漏场域」（全屏禅意融化沙漏 / 开放正计时，锁屏流转实况窗）
 │ ├── 顶部：当前任务名与阶段切片状态
 │ ├── 中央：无数字压迫的物理流体微沙漏（Canvas / 属性动画）
 │ ├── 底部常驻：【杂念停机坪】极简胶囊输入框（回车秒存机动池）
 │ └── 操作栏：暂停 / 完成 / 叫停
 │
 └── 「晚间打烊仪式」（全屏暗色结算，停靠杂念集中复盘，未完成三选一，SaveButton 存图）
```

---

## 7. 数据模型与持久化设计

### 7.1 核心响应式实体（ArkUI V2）

```typescript
export enum Priority { HIGH = 3, MEDIUM = 2, LOW = 1 }
export enum TodoStatus { PENDING = 0, IN_PROGRESS = 1, COMPLETED = 2, FROZEN = 3, CANCELLED = 4 } // 4: 取消/这事算了
export enum TodoSource { MANUAL = 0, CALENDAR = 1, INTENT = 2, REMINDER = 3, DELEGATED = 4, PARKING_LOT = 5 }
export enum TimingMode { COUNTDOWN = 0, STOPWATCH = 1 } // 0: 预估倒计时, 1: 开放流体正计时

@ObservedV2
export class TodoItem {
 @Trace id: string = '' // UUID (主键)
 @Trace title: string = '' // 标题
 @Trace description: string = '' // 描述
 @Trace priority: Priority = Priority.MEDIUM // 优先级 (1-低, 2-中, 3-高)
 @Trace status: TodoStatus = TodoStatus.PENDING // 状态
 @Trace dueDate: number = 0 // 截止时间戳
 @Trace createdAt: number = 0 // 创建时间戳
 @Trace updatedAt: number = 0 // 毫秒级时间戳 (LWW 裁决基准)
 @Trace completedAt: number = 0 // 完成时间戳
 @Trace estimatedMinutes: number = 25 // 预估耗时 / 探索切片时长
 @Trace actualMinutes: number = 0 // 实际累计耗时 (分钟)
 @Trace timingMode: TimingMode = TimingMode.COUNTDOWN // 计时模式
 @Trace source: TodoSource = TodoSource.MANUAL // 来源 (含 PARKING_LOT 杂念停机坪)
 @Trace agingLevel: number = 0 // 老化等级 0~4
 @Trace isFrozen: boolean = false // 是否冷冻

 // 【自适应时间块与机动池核心字段】
 @Trace scheduledStartAt: number = 0 // 算法排期起始时间戳 (0 表示在机动备选池)
 @Trace scheduledEndAt: number = 0 // 算法排期结束时间戳
 @Trace isPinned: boolean = false // 用户是否手动钉住（锁定禁止算法重排）

 @Trace tags: string[] = [] // 标签
 @Trace subTasks: SubTaskItem[] = [] // 独立子任务实体列表
 @Trace assignedTo: string = '' // 甩单接收设备
 @Trace deviceId: string = '' // 来源设备标识

 // 分布式删除墓碑
 @Trace isDeleted: boolean = false
 @Trace deletedAt: number = 0

 // 同步状态脏标记
 @Trace isDirty: boolean = true
 @Trace lastSyncedAt: number = 0
}

@ObservedV2
export class SubTaskItem {
 @Trace id: string = '' // UUID (主键)
 @Trace todoId: string = '' // 所属待办 ID (外键)
 @Trace title: string = '' // 标题
 @Trace done: boolean = false // 完成标记
 @Trace sortOrder: number = 0 // 排序
 @Trace updatedAt: number = 0 // 独立更新时间戳 (LWW)
 @Trace isDeleted: boolean = false // 独立墓碑
 @Trace deletedAt: number = 0
 @Trace isDirty: boolean = true
 @Trace lastSyncedAt: number = 0
}
```

### 7.2 数据库物理 Schema（RelationalStore）

```sql
-- 1. 待办主表（含时间块、计时模式、来源与墓碑）
CREATE TABLE IF NOT EXISTS todo_items (
 id TEXT PRIMARY KEY,
 title TEXT NOT NULL,
 description TEXT DEFAULT '',
 priority INTEGER DEFAULT 2,
 status INTEGER DEFAULT 0,
 due_date INTEGER DEFAULT 0,
 created_at INTEGER NOT NULL,
 updated_at INTEGER NOT NULL,
 completed_at INTEGER DEFAULT 0,
 estimated_minutes INTEGER DEFAULT 25,
 actual_minutes INTEGER DEFAULT 0,
 timing_mode INTEGER DEFAULT 0,
 scheduled_start_at INTEGER DEFAULT 0,
 scheduled_end_at INTEGER DEFAULT 0,
 is_pinned INTEGER DEFAULT 0,
 source INTEGER DEFAULT 0,
 aging_level INTEGER DEFAULT 0,
 is_frozen INTEGER DEFAULT 0,
 tags TEXT DEFAULT '[]',
 assigned_to TEXT DEFAULT '',
 device_id TEXT DEFAULT '',
 is_deleted INTEGER DEFAULT 0,
 deleted_at INTEGER DEFAULT 0,
 is_dirty INTEGER DEFAULT 1,
 last_synced_at INTEGER DEFAULT 0
);

-- 核心高性能索引
CREATE INDEX IF NOT EXISTS idx_todo_schedule ON todo_items(scheduled_start_at, is_deleted);
CREATE INDEX IF NOT EXISTS idx_todo_status ON todo_items(status, is_deleted);
CREATE INDEX IF NOT EXISTS idx_todo_dirty ON todo_items(is_dirty);
CREATE INDEX IF NOT EXISTS idx_todo_deleted ON todo_items(is_deleted);

-- 2. 子任务从表
CREATE TABLE IF NOT EXISTS sub_task_items (
 id TEXT PRIMARY KEY,
 todo_id TEXT NOT NULL,
 title TEXT NOT NULL,
 done INTEGER DEFAULT 0,
 sort_order INTEGER DEFAULT 0,
 updated_at INTEGER NOT NULL,
 is_deleted INTEGER DEFAULT 0,
 deleted_at INTEGER DEFAULT 0,
 is_dirty INTEGER DEFAULT 1,
 last_synced_at INTEGER DEFAULT 0,
 FOREIGN KEY (todo_id) REFERENCES todo_items(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_subtask_todo ON sub_task_items(todo_id);
CREATE INDEX IF NOT EXISTS idx_subtask_dirty ON sub_task_items(is_dirty);
CREATE INDEX IF NOT EXISTS idx_subtask_deleted ON sub_task_items(is_deleted);

-- 3. 版本元数据表
CREATE TABLE IF NOT EXISTS schema_version (
 version INTEGER PRIMARY KEY,
 upgraded_at INTEGER NOT NULL
);
```

### 7.3 数据库版本迁移策略

- `relationalStore.getRdbStore` 初始化指定 `version = 1`，`onUpgrade` 中实现表结构变更与 DDL 记录；
- **30 天墓碑定时清理**：每日打烊仪式或冷启动执行 `DELETE FROM todo_items WHERE is_deleted = 1 AND deleted_at < (? - 30 * 86400 * 1000)`。

---

## 8. 自适应时间块装箱算法与同步架构

### 8.1 贪心区间装箱与弹性调度算法规格

```
输入：
 - 当日可用窗口：[WorkDayStart, WorkDayEnd]（默认 09:30 ~ 18:30）
 - 锁定不可排时段：[LunchStart, LunchEnd] + 外部会议日程块
 - 候选待办池：未完成且未冷冻的 TodoItem 数组
 - 用户设定：MAX_DEEP_WORK = 270 分钟，BUFFER = 15 分钟

步骤：
 1. 计算空闲时间片集合 FreeSlots = WorkDay - LockedEvents;
 2. 对候选待办打分排序：Score = (Priority * 40) + (Urgency * 40) + (Aging * 20);
 - 特殊规则：若 timing_mode == STOPWATCH，预排期时 duration 统一以 25 分钟弹性占位计算；
 3. 当前已排专注总时长 TotalScheduled = 0;
 4. 遍历 FreeSlots 中的每个空槽 Slot：
 a. 当前 Slot 起始插入 15m 留白（若前序有任务）；
 b. 从候选池挑出预估时长/切片时长 <= Slot.remaining 且 TotalScheduled + duration <= MAX_DEEP_WORK 的最高分任务；
 c. 若找到：分配 scheduledStartAt 与 scheduledEndAt，TotalScheduled += duration，从未排池扣除；
 d. 【防饥饿兜底】：若当前最高分任务的 duration > Slot.remaining，但 Slot.remaining >= 45m 且该任务 priority == HIGH，则自动将该任务切出 45m 探索切片装入当前 Slot，剩余部分保留在候选池，杜绝大任务被碎片空隙永久饿死；
 e. 若槽位剩余不足以容纳任何任务或超脑力上限：结束当前槽位装箱，流转下一 Slot；
 5. 剩余未分配任务保留 scheduledStartAt = 0（归入今日视界底部的【机动备选池】）；
 6. 本地 SQLite 批量写入，更新 is_dirty = 1，UI 渲染完成。
```

### 8.2 存算分离：持久层与瞬时状态层

- **持久数据（待办、子任务、时间块、停机坪杂念）**：写入本地 `relationalStore`，通过软总线 P2P 增量同步；
- **瞬时心流（沙漏倒计时、正计时状态）**：通过 `distributedDataObject` 在多端同步流转（单对象 <5KB，生命周期随专注结束而销毁）。

### 8.3 冲突解决与感知 UI

- **行级 LWW**：以毫秒级 `updated_at` 统一裁决；
- **并发提示**：检测到双端 5 秒内冲突覆盖，弹出微 Toast：“已同步其他设备最新更新 ”，并在偏好设置中提供“同步流水日志”。

---

## 9. 权限矩阵与隐私合规设计

| 权限名称 | 授权方式 | 关联功能 | 审核合规分类 | 拒绝后优雅降级方案 |
|---|---|---|---|---|
| `ohos.permission.INTERNET` | system_grant | 局域网协同通信 | 通用权限 | — |
| `ohos.permission.DISTRIBUTED_DATASYNC` | user_grant | 分布式软总线协同 | 受限敏感权限 | 降级为纯单机使用，入口显示引导 |
| `ohos.permission.READ_CALENDAR` | user_grant | 缝隙感知（自建日程） | 普通用户授权 | 降级为仅依据应用内设定的工作起止时间装箱；若用户从系统设置撤回权限，`onForeground` 自动探测并立即清空内存与视图中旧的外部日历占位，毫秒级触发纯本地重排 |
| `ohos.permission.READ_WHOLE_CALENDAR` | user_grant (ACL) | 系统级全局日程读取 | **受限特权权限 (ACL)** | **V1.0α 坚决不声明**；V1.0β 获批后启用 |

*️ 零权限免申请说明：*
*• **相册保存**：打烊成就卡保存全面集成 ArkUI 原生 **`SaveButton`** 控件，免声明 `WRITE_IMAGEVIDEO` 权限；*
*• **触觉微反馈**：调用系统 `vibrator` 标准触感接口，系统自动授权，零弹窗骚扰。*

---

## 10. 多设备适配与降级策略

| 设备形态 | 布局策略 | 时间轴与专注表现 |
|---|---|---|
| **Phone** | `NavigationMode.Stack` 单列流转 | 屏幕锁定后启动锁屏实况窗大卡片 + 状态栏胶囊 |
| **Tablet** | `NavigationMode.Split` 左右双栏 | 左侧机动备选池 + 右侧自适应时间轴看板 |
| **2in1 PC** | `NavigationMode.Split` 宽屏看板 | **实况窗降级方案**：窗口顶部展开 32vp 毛玻璃微状态条 / 一键最小化桌面独立微浮窗 |

---

## 11. 非功能性需求（性能、触感与音效）

| 指标领域 | 生产指标要求 | 架构保障措施 |
|---|---|---|
| **冷启动耗时** | ≤ 1.0 秒 | 零冗余 SDK，首屏数据分页加载（50 条），异步初始化非关键组件 |
| **排期算法耗时** | 50 条任务自适应装箱耗时 ≤ 5 毫秒 | 本地离线纯数学贪心调度，零网络往返 |
| **音频响应延迟** | 和弦播放延迟 ≤ 20 毫秒 | 采用 `soundPool` 预加载音频采样，避免 `AVPlayer` 初始化卡顿 |
| **触感反馈响应** | 触觉与音效同步偏差 ≤ 10 毫秒 | 系统级 `vibrator.startVibration` 与音效原子级并行触发 |
| **滑动流畅度** | 稳定 60fps（高刷 120fps） | ArkUI V2 原生 `Repeat` 虚拟滚动组件模板复用 |
| **内存峰值** | 前台活跃峰值 ≤ 80MB | 扁平数据模型，冷冻舱懒加载，音效资源包 ≤ 200KB |

---

## 12. 版本演进路线图（V1.0α 与 V1.0β）

```
┌─────────────────────────────────────────────────────────────────────────┐
│ V1.0α（单机自适应与多巴胺心流核心版）—— 周期：4~5 周 │
├─────────────────────────────────────────────────────────────────────────┤
│ • 核心待办 CRUD + 子任务独立表（sub_task_items） │
│ • 有边界的自适应时间块（本地装箱 + 强制留白 + 脑力上限 ≤4.5h） │
│ • 未知时长弹性应对（45m 探索切片 + 流体正计时 + 机动备选池） │
│ • 杂念停机坪（专注界面 32vp 胶囊输入，回车秒收纳进机动池） │
│ • 和弦多巴胺阶梯（Do-Mi-Sol-Do' 音阶爬升 + 泡泡纸微触感振动） │
│ • 5 分钟破冰船与禅意融化沙漏（视口微脉动 + 消除数字焦虑） │
│ • 晚间打烊仪式与拍立得成就卡（SaveButton 零权限保存 + 沉浸时长认可 + 宽容三选一）│
│ • 温和老化阶梯与冷冻舱折叠区（绝无红字催命） │
│ • Local-First 纯本地持久化（RelationalStore + 墓碑机制 + 脏标记） │
│ • 隐私合规全套体系（首启强校验弹窗 + 双清单 + 注销承诺） │
│ • Phone + Tablet + 2in1 PC 响应式自适应布局 │
│ 目标：0 分布式风险、0 ACL 审核阻塞、0 AGC 权益卡点，极速上架华为应用市场 │
└─────────────────────────────────────────────────────────────────────────┘
 │
 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ V1.0β（分布式协同与生态旗舰版）—— 周期：4~5 周 │
├─────────────────────────────────────────────────────────────────────────┤
│ • 华为账号接入（Account Kit） │
│ • 局域网分布式多设备同步（软总线 P2P + 关系表增量同步 + 冲突感知 Toast） │
│ • 全域心流广播（Live View Kit 实况窗 + ServiceButton 锁屏直接交互） │
│ • 2in1 PC 状态栏悬浮微条降级方案落地 │
│ • 系统全局日历缝隙融合（READ_WHOLE_CALENDAR ACL 申请获批后上线） │
│ • Share Kit 华为分享隔空甩单 │
│ 目标：打透鸿蒙生态多端流转标杆体验，确立“白天理性排期、晚上温柔解绑”护城河 │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 13. 设计决策清单（定稿）

| 编号 | 决策主题 | 最终拍板选项 | 选型落地与防踩坑理由 |
|---|---|---|---|
| **A** | 时间块调度逻辑 | **A2：有边界装箱 + 弹性切片** | 坚守 ≤4.5h 脑力上限与 15m 留白；未知时长采用探索切片与正计时，兼顾秩序与弹性。 |
| **B** | 专注防走神机制 | **B1：杂念停机坪（回车秒收纳）** | 专注界面底部胶囊直接落盘机动备选池，零跳出率，彻底切断走神任意门。 |
| **C** | 完成正反馈形式 | **C2：和弦音阶 + 泡泡纸触感** | 规避枯燥勾选；通过 `Do-Mi-Sol-Do'` 逐级爬升音阶与线性马达解压振动，即时喂饱多巴胺。 |
| **D** | 破冰时长设计 | **C1：严格固定 5 分钟** | 杜绝二次选择困难，打造“只要 5 分钟随时可停”的极低门槛心理暗示。 |
| **E** | 未完成任务处理 | **B2：打烊宽容三选一 + 沉浸认可** | 拒绝血红 Overdue；打烊时提供宽容流转，对长任务肯定沉浸时长，彻底消灭下班焦虑。 |
| **F** | 跨端甩单交互 | **D3：Share Kit 原生分享** | 唤起系统原生面板隔空投送，免去自研私有通信协议负担。 |
| **G** | 数据同步介质 | **E2：关系表分布式同步 + 瞬时 DataObject** | 严格遵循官方场景规范：持久关系走关系表，瞬时倒计时走数据对象。 |
| **H** | 子任务模型 | **F1：独立关系表 sub_task_items** | 废除 JSON 反范式，赋予子任务独立时间戳与墓碑，消灭 LWW 吞数据致命缺陷。 |
| **I** | 商业化模式 | **零广告、完全免费** | 纯粹效率口碑优先，避开广告合规审核雷区，确保极速首发。 |
| **J** | 版本发布节奏 | **拆分为 V1.0α 与 V1.0β** | 先用无风险的单机闭环过审上架，再迭代分布式与实况窗旗舰体验。 |

---

## 14. 提审前合规自检清单

```markdown
[ ] 1. APP 备案已在工信部完成核准，包名与软著主体完全一致
[ ] 2. 启动无闪退、无白屏、UI 显示完整（涵盖深浅色、折叠屏及 2in1 PC 横屏自适应）
[ ] 3. 所有交互卡片均支持点击与手势反馈，空列表有温馨兜底插画，无空壳页面
[ ] 4. 首屏隐私弹窗提供对等权重的“同意”与“不同意”，点击不同意安全退出不卡死
[ ] 5. 用户同意前绝对零权限调用、零数据存储、零后台线程启动
[ ] 6. module.json5 中所有 user_grant 权限均配置有明晰准确的 reason 与 usedScene
[ ] 7. 权限执行动态按需申请，用户拒绝后不重复弹窗骚扰，自适应时间块与机动池优雅降级
[ ] 8. 绝对未声明 KEEP_BACKGROUND_RUNNING 等后台长时违规保活权限
[ ] 9. 绝对践行 Local-First 原则：离线未登录状态下基础待办、时间块排期、正计时与破冰船 100% 顺畅可用
[ ] 10. 打烊成就卡保存使用 ArkUI 原生 SaveButton 控件，免索取敏感相册写入权限
[ ] 11. 和弦音频采样采用 soundPool 低延迟加载，音频文件总大小 ≤200KB
[ ] 12. 列表渲染全量采用 ArkUI V2 原生 Repeat 虚拟滚动组件，无 LazyForEach 历史遗留
[ ] 13. 设置页内建真实有效的“已收集个人信息清单”与“第三方共享清单”
[ ] 14. 设置页提供无障碍的“账号注销”入口，承诺并在后台支持 ≤15 工作日内清退数据
[ ] 15. 设置页提供“撤回隐私政策同意”入口，撤回后重置标记并重登首屏
[ ] 16. 【若发布 V1.0β】AGC 控制台已成功获批“实况窗（Live View Kit）TIMER 场景权益”
[ ] 17. 【若发布 V1.0β】已在开发者联盟取得 READ_WHOLE_CALENDAR 的 ACL 正式授权
[ ] 18. 2in1 PC 端已验证实况窗优雅降级（应用内顶部悬浮挂件正常渲染）
[ ] 19. 分布式软删除墓碑记录在 30 天后执行安全清理的 SQL 逻辑验证无误
[ ] 20. 数据库版本升级脚本 onUpgrade 经过跨版本测试，升级无崩溃无数据丢失
[ ] 21. 构建模式已切换为 Release 模式（debuggable: false, 混淆 ArkGuard 已启用）
[ ] 22. IPv6 网络环境下数据收发通过验证
[ ] 23. 准备至少 3 张不同页面的真实设备高保真无水印截图
[ ] 24. 开发者联系方式（工单/邮箱）真实可用，响应时效已在应用内公示
```

---

> **文档状态**：Approved v1.6 (心流感官与全链路闭环版) — 在确立“有边界自适应时间块”与“打烊仪式”双支柱的基础上，补齐了“未知复杂度任务弹性应对机制（45m探索切片 + 流体正计时 + 机动备选池 + 沉浸时长认可）”，彻底解决真实世界研发与创作工作不可精确预估时长的痛点；新增【杂念停机坪】与【和弦多巴胺阶梯】，完成从抗干扰输入到即时正反馈感官的完美闭环。数据模型零冗余扩展，已完全具备直接编写第一行生产代码的标准。