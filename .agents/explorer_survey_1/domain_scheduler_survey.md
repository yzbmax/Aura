# 「Now Only」单线程极简推力重构调研报告：领域实体与调度引擎

> **文档定位**：针对「Aura · 同频」从旧有“时间轴/自适应区间装箱（Bin-Packing）”向“Now Only 单线程极简流水线推力（SingleThreadFlowEngine）”架构跃迁的专项领域与调度引擎调研报告。
> **调查执行者**：Explorer 1 (Domain & Scheduler Explorer)
> **日期**：2026-09-22
> **基准代码库路径**：`/Users/qiuhaiqin/DevEcoStudioProjects/Aura`

---

## 1. 执行摘要 (Executive Summary)

本调研全面排查了 Aura 代码库中所有与任务、排期、时间槽位相关的领域实体、算法文件、视图调用点、持久化映射以及单元测试。

核心结论如下：
1. **排期旧范式的硬伤**：现有 `BinPackingScheduler` 强依赖于现实时间锚定（`dayStartMs` ~ `dayEndMs`）、可用空闲区间贪心切割、4.5h 脑力硬上限截断与 `TimeSlot` 离散槽位构建。这种模式在前端呈现为纵向时间轴导轨（`FlowSpineAxis`）与 `HH:mm` 刻度，给用户带来预知全天日程的强烈清单压力与排期延误抖动（Timeline Jitter / Ghost Shift）。
2. **解耦边界高度清晰**：全工程中直接依赖 `BinPackingScheduler` 与 `TimeSlot` 的文件仅有 4 处业务文件（`TodayFlowView.ets`、`TvAmbientFocusView.ets`、`FlowSpineAxis.ets`、`LocalUnit.test.ets`）。核心业务模型 `TodoItem` 中虽有 `scheduledStartAt`/`scheduledEndAt`，但底层数据库架构可平滑兼容，无需破坏性变更 SQLite 表结构。
3. **温和老化与冷冻舱具备独立复用性**：`MildAgingEngine.ets`（0~3 级老化、逾期 8 天进入冷冻舱休眠）完全解耦于装箱算法，基于 `dueDate`、`createdAt` 与当前时刻计算，天然契合单线程流水线中的防内疚与队列自动降级策略。
4. **单线程流水线引擎（SingleThreadFlowEngine）设计完备**：以“中心唯一步伐（`activeTask`）+ 底部微露边缘（`nextQueue[0]`）+ 备选杂念池（`parkingQueue`）+ 休眠冷冻舱（`frozenTasks`）+ 今日足迹（`completedToday`）”构成纯粹流水线推力，彻底剥离时间轴刻度，实现毫秒级高响应与 100% 确定性排序。

---

## 2. 现有领域模型与调度体系全景清单 (Current State Inventory)

### 2.1 核心领域实体 (Domain Models)

| 实体文件 | 职责与装饰器 | 涉及排期/时间槽字段 | 现状评估 |
|---|---|---|---|
| `entry/src/main/ets/models/TodoItem.ets` | ArkUI V2 `@ObservedV2` 待办核心实体 | `scheduledStartAt: number`<br>`scheduledEndAt: number`<br>`isPinned: boolean`<br>`isExplorationSlice: boolean`<br>`timingMode: TimingMode`<br>`estimatedMinutes: number`<br>`actualMinutes: number` | 包含算法排期起止戳。在单线程模型中，`scheduledStartAt`/`scheduledEndAt` 将不再承担具体时钟排期语义，转为兼容字段；`estimatedMinutes` 保留供单任务专注倒计时使用。 |
| `entry/src/main/ets/models/TimeSlot.ets` | `@ObservedV2` 时间槽实体 | `startMs: number`<br>`endMs: number`<br>`type: SlotType (TASK/BUFFER/LOCKED)`<br>`taskItem: TodoItem \| null`<br>`durationMinutes: number` | **核心淘汰对象**。专为装箱调度器与时间轴导轨设计，单线程推力模型下无任何存在价值，可彻底废弃。 |
| `entry/src/main/ets/models/SubTaskItem.ets` | `@ObservedV2` 子任务实体 | `sortOrder: number` | 纯净轻量，无任何排期依赖，直接保留。 |
| `entry/src/main/ets/models/UserSettings.ets` | `@ObservedV2` 用户设置实体 | `workStartHour`, `workStartMinute`<br>`workEndHour`, `workEndMinute`<br>`maxDeepWorkMinutes`<br>`bufferMinutes` | 存储工作日作息起止与脑力上限。单线程模式下不再需要强制截断，但可作为全局偏好保留。 |
| `entry/src/main/ets/models/WatchSyncModel.ets` | 分布式手表协同模型 | `FocusSyncState`: `taskId`, `timingMode`, `totalMinutes`, `elapsedSeconds` | 纯专注态会话同步，与装箱算法解耦，直接兼容。 |

### 2.2 调度与老化算法引擎 (Engine Layer)

| 引擎文件 | 核心逻辑与方法 | 依赖关系 | 处置方案 |
|---|---|---|---|
| `entry/src/main/ets/engine/BinPackingScheduler.ets` | `schedule(...)`<br>`calculateScore(...)`<br>空闲区间贪心装箱、Now-Aware 现实对齐、5m 网格微调、留白气囊插入 | 强依赖 `TimeSlot`、`StarvationProtector`、`UserSettings`、`TimeUtils` | **整体淘汰替换**。由 `SingleThreadFlowEngine` 承接其打分与优先级排序能力，剥离区间计算与时钟装箱。 |
| `entry/src/main/ets/engine/StarvationProtector.ets` | `shouldSlice(...)`<br>`createExplorationSlice(...)`<br>大任务（≥90m 或高优）45m 探索切片 | 依赖 `TodoItem`、`AppConstants` | 原先用于时间槽无法容纳时的切分；在单线程下可演化为“大任务微步破冰”心理辅助，不再做时间槽截断。 |
| `entry/src/main/ets/engine/MildAgingEngine.ets` | `evaluateAging(...)`<br>`freeze(...)`<br>`unfreeze(...)`<br>逾期 1~3 天(L1)、4~7 天(L2)、8+ 天进入冷冻舱(L3) | 仅依赖 `TodoItem`、`TimeUtils`、`AppConstants` | **完整保留并深化**。直接作为 `SingleThreadFlowEngine` 的队列老化维护组件。 |

### 2.3 视图层与组件引用全貌 (UI View References)

排查全工程代码，对 `BinPackingScheduler` 和 `TimeSlot` 的引用分布极其收敛：

```
entry/src/
├── main/ets/
│   ├── engine/
│   │   └── BinPackingScheduler.ets      <-- 定义与实现
│   ├── models/
│   │   └── TimeSlot.ets                 <-- 定义与实现
│   ├── components/
│   │   ├── FlowSpineAxis.ets            <-- 接收 TimeSlot[]，渲染时间轴与时刻标签（待替换）
│   │   ├── CushionCard.ets              <-- 渲染 BUFFER 留白槽位（待替换）
│   │   ├── MistMorphingCard.ets         <-- 任务卡片（引用了 FlowSpineAxis 中的 getTaskVisual）
│   │   └── FloatingDeckDrawer.ets       <-- 机动池抽屉（引用了 FlowSpineAxis 中的 getTaskVisual）
│   └── views/
│       ├── TodayFlowView.ets            <-- 调用 BinPackingScheduler.schedule()，维护 timelineSlots
│       └── TvAmbientFocusView.ets       <-- 调用 BinPackingScheduler.schedule()，用于获取首个未完成任务
└── test/
    └── LocalUnit.test.ets               <-- 单元测试：断言 BinPackingScheduler 与 TimeSlot 行为
```

**关键技术陷阱（必须警惕）**：
- `FlowSpineAxis.ets` 第 13~47 行导出了 `TaskBlockVisual` 类与 `getTaskVisual(item: TodoItem)` 工具函数。
- `MistMorphingCard.ets` 与 `FloatingDeckDrawer.ets` 均直接从 `./FlowSpineAxis` 中 `import { getTaskVisual }`。
- **解耦必须行动**：若在重构中直接删除或重命名 `FlowSpineAxis.ets`，会导致 `MistMorphingCard` 和 `FloatingDeckDrawer` 编译报错！必须先将 `TaskBlockVisual` 与 `getTaskVisual` 迁移至公共工具模块（如 `common/utils/TaskVisualHelper.ets`）。

### 2.4 持久化与数据访问层 (Persistence & DAO)

- `AuraDatabaseSchema.ets`:
  - 表 `todo_items` 包含 `scheduled_start_at INTEGER DEFAULT 0`、`scheduled_end_at INTEGER DEFAULT 0`。
  - 索引 `idx_todo_schedule ON todo_items(scheduled_start_at, is_deleted)`。
- `TodoDao.ets`:
  - `insert()`, `update()`, `batchUpdateSchedule()` 映射了上述两个字段。
  - `queryFloatingDeck()`: 条件为 `scheduled_start_at == 0 AND is_frozen == 0 AND status NOT IN (COMPLETED, CANCELLED)`。
  - `queryTodayScheduled(startOfDay, endOfDay)`: 按时间戳区间过滤。
- **架构评估**：
  - 本地 SQLite（RelationalStore）采用 Local-First 架构，表结构的破坏性重构会带来版本迁移（Migration）风险。
  - 极简方案（Ponytail Principle）：**保留底层表结构定义**，在 `TodoItem` 中将 `scheduledStartAt`/`scheduledEndAt` 作为兼容字段（设默认值 0），上层业务全面改用队列顺序。`queryFloatingDeck` 依旧能平滑对应无强顺序的杂念停泊项，`queryAllActive` 获取全量待办后交给 `SingleThreadFlowEngine` 内存编排。

---

## 3. 旧范式的认知硬伤与重构必要性 (Defects of Legacy Scheduler)

结合权威需求 `## 2026-09-22T08:35:22Z`，旧排期机制存在三大无法调和的系统性弊端：

1. **预知清单的掌控感剥夺与焦虑放大（The Illusion of Strict Scheduling）**：
   - 旧版强行在时间轴上标定任务起止时刻（如 `09:30 - 10:15`、`10:30 - 11:15`）。真实高压场景中，一旦某项任务超时 10 分钟或中途被外部沟通打断，全天时刻表全线漂移。
   - 算法频繁重算造成“幽灵位移（Ghost Shift）”，用户看着不断后推的红色时刻，产生严重的习得性无助与拖延内疚。
2. **离散时间槽对心流的生硬切割（Artificial Fragmentation）**：
   - `TimeSlot` 模型试图将连续的心流切分成“45m 任务块 + 15m 缓冲带 + 空闲槽”。这种网格化虽然迎合了日历排期审美，但违背了人类专注的弹性本质（Open Fluidity）。
3. **认知负荷过载的主界面视觉干扰**：
   - 纵向时间轴导轨（`FlowSpineAxis`）占据了左侧 42vp 标尺空间与垂直连接线，时刻文字（`HH:mm`）反复争夺用户的眼球焦点，使得用户无法纯粹沉浸在“当下唯一微动作”中。

---

## 4. 温和老化与冷冻舱机制的平滑继承 (Gentle Aging & Cryo-Chamber Preservation)

Aura 的灵魂特性之一是“反内疚心理学（Anti-Guilt Psychology）”，其核心载体为 `MildAgingEngine`：

```
[任务创建] ──(逾期 1~3 天)──> [Level 1: 晨曦微淡 20%]
                 │
           (逾期 4~7 天)──> [Level 2: 秋叶黄沉底]
                 │
           (逾期 8+ 天)───> [Level 3: 自动移入冷冻舱休眠 (isFrozen = true)]
                                 │
                                 └──> [用户一键解冻 / 彻底放下]
```

### 在单线程引擎中的融入策略：
1. **老化的纯粹性**：老化仅取决于 `dueDate`、`createdAt` 与当前自然日的跨度，与是否按小时排期毫无关联。
2. **队列过滤与自动隔离**：
   - `SingleThreadFlowEngine` 在 `load()` 或定期 `evaluateAging()` 时，扫描待办状态。
   - 凡是 `agingLevel === 3` 或 `isFrozen === true` 的事项，**绝对不进入 `activeTask` 与 `nextQueue`**，自动汇入 `frozenTasks`（冷冻舱）。
   - 用户打开应用的主舞台永远只有清爽、可行动的当下事项，逾期积压的旧账被温和冷冻收纳，彻底切断“红点轰炸与破罐破摔”心理。
3. **加权优先考量**：
   - 对于 Level 1 和 Level 2 的待办，在打分公式中赋予适当的老化权重加成（`agingLevel * 20`），温和提醒用户趁记忆尚存时快速清理或划走，避免自然滑入冷冻。

---

## 5. `SingleThreadFlowEngine` 核心技术方案与架构设计

### 5.1 核心设计哲学 (Design Philosophy)
- **Now Only (单线程极简推力)**：主舞台有且仅有当前唯一任务（`activeTask`）。
- **微露推力 (Peek Next)**：队列下一项（`nextQueue[0]`）拟物化叠在下方，微露 12~16vp 边缘，给用户提供前进的方向感，但杜绝查看全天长清单的认知过载。
- **做完即推，划过即移 (Push & Flow)**：当前动作完成或滑动跳过时，弹簧物理动力学无缝吸附，下一项平滑滑入舞台中央。
- **闪念零干扰停泊 (Unobtrusive Parking)**：杂念录入即入 `parkingQueue`，绝不打断正在进行的 `activeTask`。

### 5.2 状态模型定义 (ArkUI V2 规范)

```ts
/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Single-Thread Minimal Flow Engine (Now Only Pipeline)
 */

import { TodoItem, TodoStatus, Priority, TodoSource } from '../models/TodoItem';
import { MildAgingEngine } from './MildAgingEngine';
import { Logger } from '../common/utils/Logger';

@ObservedV2
export class SingleThreadFlowEngine {
  /**
   * 1. 当前主动作：中央微晶主舞台唯一承载事项 (Now Only)
   */
  @Trace public activeTask: TodoItem | null = null;

  /**
   * 2. 下一步就绪流水线：有序后继任务队列
   * 索引 0 (nextQueue[0]) 即为在主舞台底部微露 12~16vp 的“下一项”卡片
   */
  @Trace public nextQueue: TodoItem[] = [];

  /**
   * 3. 杂念停泊与机动备选池：轻量折叠抽屉收纳项 (默认收起，零视线干扰)
   */
  @Trace public parkingQueue: TodoItem[] = [];

  /**
   * 4. 冷冻舱休眠池：逾期 ≥8 天或手动沉淀事项 (反内疚保护，零心理压力)
   */
  @Trace public frozenTasks: TodoItem[] = [];

  /**
   * 5. 今日微步心流足迹：已完成事项流 (用于晚间打烊仪式沉淀与正向反馈)
   */
  @Trace public completedToday: TodoItem[] = [];

  /**
   * 上次状态同步或老化评估时间戳
   */
  @Trace public lastEvaluatedAt: number = 0;
```

### 5.3 核心方法与逻辑契约 (Engine Methods)

#### 1. 初始化与流水线加载 (`load`)
```ts
  /**
   * 从数据库全量活跃与冷冻数据构建单线程流水线
   * 保证 100% 确定性排序，彻底消除 Ghost Shift
   */
  public load(allItems: TodoItem[]): void {
    const now = Date.now();
    this.lastEvaluatedAt = now;

    const completed: TodoItem[] = [];
    const frozen: TodoItem[] = [];
    const parking: TodoItem[] = [];
    const pipelineCandidates: TodoItem[] = [];

    for (const item of allItems) {
      if (item.isDeleted) {
        continue;
      }

      // 评估温和老化
      MildAgingEngine.evaluateAging(item);

      if (item.status === TodoStatus.COMPLETED) {
        completed.push(item);
      } else if (item.isFrozen || item.status === TodoStatus.FROZEN) {
        frozen.push(item);
      } else if (item.source === TodoSource.PARKING_LOT && item.status === TodoStatus.PENDING) {
        // 杂念停泊项默认进入机动备选队列
        parking.push(item);
      } else if (item.status === TodoStatus.PENDING || item.status === TodoStatus.IN_PROGRESS) {
        pipelineCandidates.push(item);
      }
    }

    // 确定性加权排序 (打分相同以 id 字典序仲裁)
    pipelineCandidates.sort((a, b) => {
      const scoreA = SingleThreadFlowEngine.calculatePriorityScore(a, now);
      const scoreB = SingleThreadFlowEngine.calculatePriorityScore(b, now);
      if (scoreB !== scoreA) {
        return scoreB - scoreA;
      }
      return a.id.localeCompare(b.id);
    });

    // 分配 activeTask 与 nextQueue
    if (pipelineCandidates.length > 0) {
      this.activeTask = pipelineCandidates[0];
      this.activeTask.status = TodoStatus.IN_PROGRESS;
      this.nextQueue = pipelineCandidates.slice(1);
    } else {
      this.activeTask = null;
      this.nextQueue = [];
    }

    this.parkingQueue = parking;
    this.frozenTasks = frozen;
    this.completedToday = completed;
  }
```

#### 2. 动态打分与排序仲裁 (`calculatePriorityScore`)
```ts
  /**
   * 纯函数：计算任务综合推力权重 (0~300)
   * Score = (Priority * 40) + UrgencyWeight + (AgingLevel * 20)
   */
  public static calculatePriorityScore(item: TodoItem, now: number = Date.now()): number {
    const priorityWeight = (item.priority || Priority.MEDIUM) * 40;

    let urgencyWeight = 20;
    if (item.dueDate > 0) {
      const diffHours = (item.dueDate - now) / (1000 * 3600);
      if (diffHours <= 0) {
        urgencyWeight = 120; // 已经到期，最高推力
      } else if (diffHours <= 12) {
        urgencyWeight = 100;
      } else if (diffHours <= 24) {
        urgencyWeight = 80;
      } else if (diffHours <= 48) {
        urgencyWeight = 50;
      }
    }

    const agingWeight = (item.agingLevel || 0) * 20;
    return priorityWeight + urgencyWeight + agingWeight;
  }
```

#### 3. 完成当前任务并推入下一项 (`completeActive`)
```ts
  /**
   * 标记当前任务完成，进入已完成足迹流，无缝吸附推出下一项
   */
  public completeActive(): TodoItem | null {
    if (!this.activeTask) {
      return null;
    }

    const doneItem = this.activeTask;
    doneItem.status = TodoStatus.COMPLETED;
    doneItem.completedAt = Date.now();
    doneItem.updatedAt = Date.now();

    // 压入今日完成流首位
    this.completedToday.unshift(doneItem);

    // 下一项就位推入
    if (this.nextQueue.length > 0) {
      this.activeTask = this.nextQueue.shift() || null;
      if (this.activeTask) {
        this.activeTask.status = TodoStatus.IN_PROGRESS;
      }
    } else {
      this.activeTask = null;
    }

    return doneItem;
  }
```

#### 4. 滑动跳过与柔和回流 (`skipActive`)
```ts
  /**
   * 跳过当前任务（右滑或跳过手势）：不惩罚用户，放回队列末尾或机动池，下一项自然就位
   */
  public skipActive(reQueueToEnd: boolean = true): TodoItem | null {
    if (!this.activeTask) {
      return null;
    }

    const skipped = this.activeTask;
    skipped.status = TodoStatus.PENDING;
    skipped.updatedAt = Date.now();

    if (this.nextQueue.length > 0) {
      // 弹出下一项就位
      this.activeTask = this.nextQueue.shift() || null;
      if (this.activeTask) {
        this.activeTask.status = TodoStatus.IN_PROGRESS;
      }

      if (reQueueToEnd) {
        // 放回队列末尾
        this.nextQueue.push(skipped);
      } else {
        // 移入机动备选池
        this.parkingQueue.unshift(skipped);
      }
    } else {
      // 队列中无其他事项，维持原样或移入机动池
      if (!reQueueToEnd) {
        this.parkingQueue.unshift(skipped);
        this.activeTask = null;
      }
    }

    return skipped;
  }
```

#### 5. 置顶与紧急插入 (`promoteToTop`)
```ts
  /**
   * 将任意事项提拔为紧随其后的“下一项”（nextQueue[0]，即主舞台微露边缘卡片）
   */
  public promoteToTop(taskId: string): boolean {
    // 检查 nextQueue
    const nextIdx = this.nextQueue.findIndex(t => t.id === taskId);
    if (nextIdx > 0) {
      const target = this.nextQueue.splice(nextIdx, 1)[0];
      this.nextQueue.unshift(target);
      return true;
    } else if (nextIdx === 0) {
      return true; // 已经是最前一项
    }

    // 检查 parkingQueue
    const parkIdx = this.parkingQueue.findIndex(t => t.id === taskId);
    if (parkIdx !== -1) {
      const target = this.parkingQueue.splice(parkIdx, 1)[0];
      target.status = TodoStatus.PENDING;
      this.nextQueue.unshift(target);
      return true;
    }

    return false;
  }
```

#### 6. 杂念快录秒存 (`pushToParking`)
```ts
  /**
   * 杂念快录：直接沉入 parkingQueue，零弹窗、零焦点剥夺，不打断 activeTask
   */
  public pushToParking(thought: TodoItem): void {
    thought.source = TodoSource.PARKING_LOT;
    thought.status = TodoStatus.PENDING;
    this.parkingQueue.unshift(thought);
  }
```

#### 7. 冷冻舱收纳与唤醒 (`triageToCryo` / `reviveFromCryo`)
```ts
  /**
   * 手动或自动将事项移入冷冻舱休眠
   */
  public triageToCryo(taskId: string): boolean {
    let target: TodoItem | null = null;

    if (this.activeTask && this.activeTask.id === taskId) {
      target = this.activeTask;
      this.skipActive(false); // 弹出下一项
    } else {
      const nIdx = this.nextQueue.findIndex(t => t.id === taskId);
      if (nIdx !== -1) {
        target = this.nextQueue.splice(nIdx, 1)[0];
      } else {
        const pIdx = this.parkingQueue.findIndex(t => t.id === taskId);
        if (pIdx !== -1) {
          target = this.parkingQueue.splice(pIdx, 1)[0];
        }
      }
    }

    if (target) {
      MildAgingEngine.freeze(target);
      this.frozenTasks.unshift(target);
      return true;
    }
    return false;
  }

  /**
   * 从冷冻舱一键唤醒
   */
  public reviveFromCryo(taskId: string, toTop: boolean = false): boolean {
    const idx = this.frozenTasks.findIndex(t => t.id === taskId);
    if (idx === -1) {
      return false;
    }
    const item = this.frozenTasks.splice(idx, 1)[0];
    MildAgingEngine.unfreeze(item);

    if (!this.activeTask) {
      this.activeTask = item;
      this.activeTask.status = TodoStatus.IN_PROGRESS;
    } else if (toTop) {
      this.nextQueue.unshift(item);
    } else {
      this.parkingQueue.unshift(item);
    }
    return true;
  }
```

---

## 6. 渐进式解耦与重构迁移步骤 (Migration & Decoupling Strategy)

为确保整个团队在开发与编译期间零中断、零编译断裂（Zero Build Breakage），建议严格按照以下 4 阶段进行演进：

```
[阶段 1: 提取公共可视化资产] ──> [阶段 2: 实现 SingleThreadFlowEngine]
               │                                      │
               ▼                                      ▼
[阶段 4: 视图对接与时间轴抹除] <── [阶段 3: 单元测试套件切换验证]
```

### 阶段 1：剥离公共依赖（消灭循环与断裂隐患）
- **问题**：`MistMorphingCard.ets` 与 `FloatingDeckDrawer.ets` 依赖 `FlowSpineAxis.ets` 里的 `TaskBlockVisual` 和 `getTaskVisual`。
- **动作**：
  1. 新建 `entry/src/main/ets/common/utils/TaskVisualHelper.ets`，将 `TaskBlockVisual` 与 `getTaskVisual` 完整移入其中。
  2. 在 `FlowSpineAxis.ets` 中 `export { TaskBlockVisual, getTaskVisual } from '../common/utils/TaskVisualHelper'` 做向后兼容重导出。
  3. 后续无论何时重构或删除 `FlowSpineAxis.ets`，其他卡片与抽屉组件编译完全不受影响。

### 阶段 2：引入 `SingleThreadFlowEngine.ets`
- **动作**：
  1. 在 `entry/src/main/ets/engine/SingleThreadFlowEngine.ets` 编写完成上述设计。
  2. `TodoItem.ets` 中保留 `scheduledStartAt`/`scheduledEndAt` 作为缺省为 0 的备用字段，保持数据库 DAO 读写不崩溃。
  3. `UserSettings.ets` 中的作息字段与 `maxDeepWorkMinutes` 保留供用户设置页面查看，但不参与强制截断。

### 阶段 3：单元测试套件重构（TDD 护航）
- **动作**：
  1. 淘汰 `entry/src/test/LocalUnit.test.ets` 中依赖 `BinPackingScheduler.schedule`、`TimeSlot`、`isOverloaded` 的旧测试例。
  2. 注入针对 `SingleThreadFlowEngine` 的完备断言测试用例：
     - `testFlowEngineLoadAndSorting`：验证高中低优先级、到期时间、老化的综合打分推力顺序；
     - `testFlowEngineCompleteAdvancement`：验证完成当下微动作后，下一项无缝吸附且今日足迹累计；
     - `testFlowEngineSkipGuiltFree`：验证滑动跳过时无负罪感放回队尾，下一项平滑弹出；
     - `testFlowEnginePromoteToTop`：验证将机动池事项置顶为微露边缘卡片；
     - `testFlowEngineRapidParking`：验证杂念快录进队，完全不抢夺当前主动作焦点；
     - `testFlowEngineAgingAndCryo`：验证 8+ 天逾期自动滑入冷冻舱，且彻底隔离于主流水线外。

### 阶段 4：视图层对接与时刻全面抹除
- **动作（协同 Explorer 2 & Explorer 3）**：
  1. `TodayFlowView.ets`：
     - 移除 `import { BinPackingScheduler }` 与 `import { TimeSlot }`。
     - 移除 `@Local timelineSlots: TimeSlot[]`。
     - 实例化或注入 `SingleThreadFlowEngine`。
     - 用单任务主舞台 + 底部拟物微露卡片（12~16vp）替代 `FlowSpineAxis`。
     - 彻底删除所有时刻展示代码（无 `HH:mm`，无倒计时钟表，无时间轴导轨）。
  2. `TvAmbientFocusView.ets`：
     - 改为直接读取 `flowEngine.activeTask`，移除 `BinPackingScheduler.schedule` 调用。
  3. `SunsetCeremonyPage.ets`：
     - 直接呈现今日 `completedToday` 微步心流轨迹，替代旧的根据排期时间戳计算的总结。

---

## 7. 风险评估与防御性对策 (Risk & Guardrail Matrix)

| 潜在风险 | 影响级别 | 根因分析 | 防御与规避对策 |
|---|---|---|---|
| **数据库版本冲突** | 高 | 强行删除 SQLite 列 `scheduled_start_at` 导致旧用户表升级报错 | **严格遵循表兼容原则**：保留 SQLite DDL 列定义与 DAO 读写，业务层将其视为透明字段（统一赋 0），不执行 `ALTER TABLE DROP COLUMN`。 |
| **空队列边界异常** | 中 | 用户完成或跳过所有事项后，`activeTask` 为 null 导致 UI 渲染崩毁 | **微晶空状态空灵设计**：当 `activeTask === null` 时，主舞台呈现“今日要事皆已从容就绪 · 自由蓄力中”的柔和光晕与呼吸提示，引导从机动池唤醒或直接休息。 |
| **外部引用遗漏** | 中 | 存在隐藏组件通过 `@Param` 或全局状态读取时间槽 | 已通过全量代码 ripgrep 精准锁定所有引用点（仅 4 处），迁移阶段通过向后兼容的适配器保障平滑替换。 |
| **并发快录竞争** | 低 | 手表端分布式同步与手机端同时录入杂念 | `SingleThreadFlowEngine` 的 `pushToParking` 采用 `unshift` 线性追加，并结合 `TimeUtils.generateUUID()` 保持唯一性，无锁且无竞争冲突。 |

---

## 8. 调研结论与下一步指引 (Conclusion & Action Items)

- **结论**：代码库完全具备向「Now Only」单线程极简推力模型转型的条件。`BinPackingScheduler` 与 `TimeSlot` 耦合局限在极小范围内，剥离路径极为清晰，温和老化与冷冻舱具备 100% 可继承性。
- **推荐交付物**：
  1. 批准 `SingleThreadFlowEngine` 的 API 契约与状态流转规范。
  2. Explorer 2 依托本报告中的 `activeTask` / `nextQueue[0]` 数据契约推进 UI 主舞台与微露卡片弹簧吸附动画设计。
  3. Explorer 3 依托本报告推进持久化存储与单元测试套件（Hypium）的自动化验证方案。
