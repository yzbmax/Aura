# Project: Aura "Now Only" Single-Thread Minimal Flow Refactoring

## Architecture
全面颠覆「Aura · 同频」的时间排期旧范式，彻底剥离具体时刻表、时间轴与区间装箱算法，重构为以「单线程极简推力（Now Only）」为核心灵魂的纯粹心流待办管家：
1. **Engine Layer**: `SingleThreadFlowEngine` (@ObservedV2) 替代 `BinPackingScheduler` 与 `TimeSlot`。管理 `activeTask`（屏幕中央独占）、`nextQueue`（就绪队列，[0]在底部拟物微露）、`parkingQueue`（杂念快录机动池）、`frozenTasks`（冷冻舱）、`completedToday`（今日微步心流轨迹）。
2. **Visual Helper**: 提取 `TaskVisualHelper` 承接 `TaskBlockVisual` 与 `getTaskVisual`，解耦 `FlowSpineAxis` 与其它组件的公共导出依赖。
3. **UI / Presentation Layer**:
   - `TodayFlowView`：清空所有具体时刻（`HH:mm`）、倒计时钟表、纵向导轨线、`CushionCard` 留白缓冲卡。
   - `NowActionCard`：屏幕中央独占当前唯一动作卡片，展示 20~22fp 大标题与微步清单。
   - `NextPeekCard`：屏幕底部以拟物卡片叠层微露 12~16vp 边缘与分类色条，给用户“下一步已有安排”的定心丸。
   - 物理手势与动效：`PanGesture` 右滑完成（阶梯和弦 + 35ms 泡泡纸微震 + 5s 撤销胶囊）、左滑跳过（推迟至队尾 + 18ms 微脉冲）。`curves.springMotion(0.38, 0.78)` 物理弹簧吸附跃升下一项卡片。
   - `ParkingLotInputBar`：升级为 36vp 快录胶囊，180ms 内安全停泊入队列，不夺焦当前主动作。
   - `QueueDrawer`：轻量折叠抽屉（默认 32vp 收起，零视线干扰），需要时低认知负荷查看/调整待办序列。
4. **Sunset Ceremony Layer**: `SunsetCeremonyPage` 重构为以“今日微步心流轨迹”为核心的无负罪感总结，消灭“理性排期”等时间压迫文案，未完成事项温和留存明天。
5. **Persistence & Integrity**: Local-First 架构，保持 SQLite `aura_flow.db` 结构无损兼容（`scheduled_start_at = 0`），ArkTS 严格类型检查无 `any`，无敏感权限。

## Feature Inventory
| # | Feature | Description | Milestone | Source | Status |
|---|---------|-------------|-----------|--------|--------|
| 1 | Extract TaskVisualHelper | Extract TaskBlockVisual & getTaskVisual from FlowSpineAxis to prevent broken imports | M1 | Survey | DONE |
| 2 | SingleThreadFlowEngine Implementation | ObservedV2 pipeline engine managing active, next, parking, frozen, completedToday | M1 | R1, AC1 | DONE |
| 3 | BinPacking & TimeSlot Decoupling | Decouple BinPackingScheduler and TimeSlot runtime dependencies across the engine & domain | M1 | R1, AC1 | DONE |
| 4 | Automated Unit Test Suite for Engine | Comprehensive 23-case unit test suite verifying init, complete, skip, promote, parking, aging, cryo | M1 | AC3 | DONE |
| 5 | Wipe Timestamps & Axis from TodayFlowView | Remove HH:mm, countdown clocks, timeline rails, FlowSpineAxis, CushionCard from TodayFlowView | M2 | R2, AC2 | DONE |
| 6 | NowActionCard Central Stage | Screen-centered exclusive card for the single active micro-action | M2 | R2, AC2 | DONE |
| 7 | NextPeekCard Physical Layered Peek | Bottom 3D layered card peeking 12~16vp with classification color stripe | M2 | R2, AC2 | DONE |
| 8 | PanGesture & Spring Physics Snapping | Swipe right to complete (chord audio + haptic + undo), swipe left to skip, springMotion advance | M2 | R2, AC2 | DONE |
| 9 | TvAmbientFocusView Decoupling | Remove BinPackingScheduler and TimeSlot references from TvAmbientFocusView | M2 | AC1 | DONE |
| 10 | 36vp ParkingLotInputBar Capsule | Standardize 36vp quick-capture capsule, mount in TodayFlowView, fast ingestion without stealing focus | M3 | R3, AC2 | DONE |
| 11 | Lightweight Collapsible Queue Drawer | Replace FloatingDeckDrawer with default-collapsed (32vp) queue drawer, 0 visual distraction | M3 | R3 | DONE |
| 12 | Sunset Ceremony Micro-Flow Trajectory | Redesign SunsetCeremonyPage from hours-based reflection to chronological micro-step trail | M3 | R3 | DONE |
| 13 | Dual Track Verification & Build Check | Full test run, assembleApp & assembleHap passing, strict type check | M4 | AC3 | DONE |
| 14 | Adversarial & Forensic Integrity Audit | Challenger verification and independent forensic integrity audit | M4 | Guidelines | DONE |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Engine & Domain Decoupling | Features 1, 2, 3, 4: TaskVisualHelper, SingleThreadFlowEngine, LocalUnit.test suite | none | DONE |
| M2 | UI Now Only Main Stage & Physical Stacking | Features 5, 6, 7, 8, 9: NowActionCard, NextPeekCard, PanGesture & Spring snap, TodayFlowView & TvAmbientFocusView | M1 | DONE |
| M3 | ParkingLot Capsule, Queue Drawer & Sunset Flow | Features 10, 11, 12: 36vp ParkingLot, lightweight QueueDrawer, SunsetCeremony trajectory | M1, M2 | DONE |
| M4 | Dual Track Verification & Forensic Audit | Features 13, 14: Test execution, build checks, Challenger review, Auditor verification | M1, M2, M3 | DONE |

## Code Layout
- `entry/src/main/ets/engine/SingleThreadFlowEngine.ets` — Core push/flow engine (DONE)
- `entry/src/main/ets/engine/MildAgingEngine.ets` — Gentle aging & cryo rules (reused)
- `entry/src/main/ets/components/TaskVisualHelper.ets` — Visual block color/badge mapping (DONE)
- `entry/src/main/ets/components/NowActionCard.ets` — Central exclusive micro-action card (DONE)
- `entry/src/main/ets/components/NextPeekCard.ets` — Bottom 12~16vp peeking layered card (DONE)
- `entry/src/main/ets/components/QueueDrawer.ets` — Lightweight collapsible queue drawer (DONE)
- `entry/src/main/ets/components/ParkingLotInputBar.ets` — 36vp quick-capture thought capsule (DONE)
- `entry/src/main/ets/views/TodayFlowView.ets` — Now Only single-thread main stage (DONE)
- `entry/src/main/ets/views/TvAmbientFocusView.ets` — Decoupled TV focus view (DONE)
- `entry/src/main/ets/views/SunsetCeremonyPage.ets` & `pages/SunsetCeremonyPage.ets` — Micro-flow trajectory sunset reflection (DONE)
- `entry/src/test/LocalUnit.test.ets` — Strictly-typed automated test suite (23/23 passing) (DONE)
