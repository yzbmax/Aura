# Handoff Report: Domain Models & Scheduler Transition to SingleThreadFlowEngine

## 1. Observation

1. **`BinPackingScheduler` 与 `TimeSlot` 的引用分布范围极小**：
   - 经 `grep_search` 检索，`BinPackingScheduler` 仅存在于：
     - `entry/src/main/ets/engine/BinPackingScheduler.ets` (定义)
     - `entry/src/main/ets/views/TodayFlowView.ets` (第 14、245 行)
     - `entry/src/main/ets/views/TvAmbientFocusView.ets` (第 12、43 行)
     - `entry/src/test/LocalUnit.test.ets` (第 7、79、96、115、132、155、159 行)
   - `TimeSlot` 仅存在于：
     - `entry/src/main/ets/models/TimeSlot.ets` (定义)
     - `entry/src/main/ets/engine/BinPackingScheduler.ets`
     - `entry/src/main/ets/components/FlowSpineAxis.ets` (第 7、51、70、78、108 行)
     - `entry/src/main/ets/views/TodayFlowView.ets` (第 8、40 行)
     - `entry/src/main/ets/views/TvAmbientFocusView.ets` (第 9、20、21、208 行)
     - `entry/src/test/LocalUnit.test.ets` (第 13、102、156、160 行)
2. **隐藏公共导出依赖**：
   - `entry/src/main/ets/components/FlowSpineAxis.ets` 第 13~47 行导出了 `TaskBlockVisual` 与 `getTaskVisual(item: TodoItem)`。
   - `MistMorphingCard.ets`（第 10 行）与 `FloatingDeckDrawer.ets`（第 8 行）均直接 `import { getTaskVisual } from './FlowSpineAxis'`。若盲目删除 `FlowSpineAxis.ets` 将导致两处组件编译中断。
3. **温和老化与冷冻舱具备独立性**：
   - `entry/src/main/ets/engine/MildAgingEngine.ets` 中 `evaluateAging`、`freeze`、`unfreeze` 完全依据 `dueDate`、`createdAt` 与当前自然日跨度计算，不依赖任何时刻或装箱排期逻辑。
   - 逾期天数判断（`AppConstants.FROZEN_DAYS_THRESHOLD = 8`）：逾期 1~3 天为 Level 1，4~7 天为 Level 2，8+ 天自动设置为 `isFrozen = true`，状态切换为 `TodoStatus.FROZEN`。
4. **数据库存储结构与兼容性**：
   - `AuraDatabaseSchema.ets` 中 `todo_items` 表定义包含 `scheduled_start_at` 与 `scheduled_end_at`，以及索引 `idx_todo_schedule`。
   - `TodoDao.ets` 中对上述字段进行读写映射；`queryFloatingDeck()` 依靠 `scheduled_start_at == 0` 查询机动池。
   - 保留字段并赋予缺省值 0 可完全避免 SQLite DDL 破坏性升级与兼容风险。

## 2. Logic Chain

1. 由 **Observation 1** 可知，`BinPackingScheduler` 与 `TimeSlot` 仅被主视图 `TodayFlowView`、电视大屏视图 `TvAmbientFocusView` 以及测试用例 `LocalUnit.test.ets` 依赖，没有任何复杂跨包或深层系统绑定。因此，将其替换为 `SingleThreadFlowEngine` 的工程影响范围高度可控，且可在单一迭代内干净完成。
2. 由 **Observation 2** 可知，`FlowSpineAxis.ets` 兼具“时间轴渲染”与“任务视觉辅助分类”双重职责。在移除时间轴导轨前，必须首先提取 `TaskBlockVisual` 和 `getTaskVisual` 至独立的 `TaskVisualHelper.ets`，避免级联破坏 `MistMorphingCard` 和 `FloatingDeckDrawer` 的编译。
3. 由 **Observation 3** 可知，`MildAgingEngine` 的老化阶梯与冷冻舱逻辑是业务核心且逻辑自闭环。在 `SingleThreadFlowEngine` 中，只需在 `load()` 与状态刷新时调用 `MildAgingEngine.evaluateAging()`，并将 Level 3（逾期 8+ 天）的事项自动拦截进 `frozenTasks`，即可无缝延续“反内疚、防拖延压力”的心理学设计初心。
4. 由 **Observation 4** 可知，Local-First 架构下保持 SQLite 表结构兼容是最高效稳健的路径（遵循 Ponytail 极简法则）。无需修改 SQLite DDL，只需让 `SingleThreadFlowEngine` 掌管内存中流水线状态（`activeTask`、`nextQueue`、`parkingQueue`、`frozenTasks`、`completedToday`），即可实现“0 视线时刻干扰”与“单线程极简推力”。

## 3. Caveats

1. **多端协同同步协议兼容性**：`WatchSyncModel.ets` 和 `LiveViewService.ets` 依赖 `estimatedMinutes` 驱动倒计时/正计时。虽然主舞台抹除了全天日历时刻表（`HH:mm`），但单任务卡片内的单次专注耗时预估仍建议保留，供专注沙漏与实况窗使用。
2. **大任务探索切片策略演进**：原 `StarvationProtector.shouldSlice` 是在装箱时间槽不够时触发；在单线程模型下，无需物理切割槽位，但大任务启动阻力（ADHD 启动困难）依然存在，建议保留其 45m 探索切片标记作为微步破冰的心流引导。

## 4. Conclusion

1. **废弃旧排期体系可行性 100%**：已具备立即将 `BinPackingScheduler` 及 `TimeSlot` 彻底淘汰解耦的所有技术条件。
2. **架构方案定稿**：采用响应式 `@ObservedV2` 的 `SingleThreadFlowEngine`：
   - 核心状态：`activeTask` (当前主动作)、`nextQueue` (后继就绪队列，[0]在底部微露 12~16vp)、`parkingQueue` (杂念机动池)、`frozenTasks` (冷冻舱)、`completedToday` (今日心流轨迹)。
   - 核心方法：`load()`, `completeActive()`, `skipActive()`, `promoteToTop()`, `pushToParking()`, `triageToCryo()`, `reviveFromCryo()`, `calculatePriorityScore()`。
3. **分阶段实施保证零构建中断**：
   - 步骤一：提取 `TaskVisualHelper.ets` 并向后兼容重导出。
   - 步骤二：实现 `SingleThreadFlowEngine.ets`。
   - 步骤三：重构单元测试，为流水线推力、跳过、置顶、老化建立完备的断言防护网。
   - 步骤四：在 `TodayFlowView` 与 `TvAmbientFocusView` 抹除时刻轴与装箱调用，对接单线程主舞台。

## 5. Verification Method

1. **代码引用排查验证**：
   - 执行 `grep_search` 确认 `BinPackingScheduler` 与 `TimeSlot` 在业务工程中除适配层外无残留。
2. **公共工具依赖解耦验证**：
   - 检查 `MistMorphingCard.ets` 与 `FloatingDeckDrawer.ets` 引用 `TaskVisualHelper.ets` 正常，无未解析符号。
3. **单元测试与流水线断言验证**：
   - 单元测试运行覆盖 `SingleThreadFlowEngine` 的 6 大关键路径（初始化排序、完成就位推入、跳过放回队尾、置顶提升、杂念快录不夺焦、8天逾期自动冷冻）。
