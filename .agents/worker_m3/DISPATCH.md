## 2026-09-22T09:15:30Z
You are Worker 3 (teamwork_preview_worker) for Milestone 3 of the "Now Only" Single-Thread Minimal Flow refactoring project.
Your working directory is: /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/worker_m3
Workspace root: /Users/qiuhaiqin/DevEcoStudioProjects/Aura

MANDATORY FIRST STEP:
Read the authoritative user request at:
/Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/ORIGINAL_REQUEST.md
Pay special attention to the latest section ## 2026-09-22T08:35:22Z.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Context & Reference Documents:
Read:
1. /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/orchestrator_now_only/PROJECT.md
2. /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/explorer_survey_3/persistence_test_survey.md
3. /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/worker_m2/handoff.md

Your Exclusive Write Ownership:
You own exclusively and may create/edit these files:
- `entry/src/main/ets/components/ParkingLotInputBar.ets`
- `entry/src/main/ets/components/QueueDrawer.ets` (new file)
- `entry/src/main/ets/views/TodayFlowView.ets` (mount ParkingLotInputBar & QueueDrawer)
- `entry/src/main/ets/pages/SunsetCeremonyPage.ets`
- `entry/src/test/LocalUnit.test.ets`
Do NOT modify other files during this milestone.

Implementation Tasks:
1. **Upgrade `ParkingLotInputBar.ets`**:
   - Standardize collapsed height to exact **36vp** (`.height(this.isExpanded ? 44 : 36)`).
   - Quick-capture capsule visual: pill shape (`borderRadius: 18`), frosted acrylic surface, prompt placeholder "记下此刻杂念，稍后处理...".
   - Fast ingestion: submitting content emits `onParkingSubmit(content)`.
   - Toast/Feedback: '已停泊入机动序列，当前心流不受打扰'.
   - Zero focus stealing: after submitting, input box automatically clears and collapses back to 36vp, keeping the central microcrystalline stage focused.

2. **Create `QueueDrawer.ets`**:
   - Create `entry/src/main/ets/components/QueueDrawer.ets` using ArkUI V2 `@ComponentV2`:
     - `@Param nextQueue: TodoItem[] = [];`
     - `@Param parkingQueue: TodoItem[] = [];`
     - `@Event onPromote: (id: string) => void = () => {};`
     - `@Event onTriageCryo: (id: string) => void = () => {};`
   - Visual & UX Design:
     - Default state: **Collapsed** (height: 32vp bar pinned near bottom with a clean drag handle `—` and subtle text "待办序列 (${this.nextQueue.length + this.parkingQueue.length})").
     - **0 Visual Distraction**: keeps the screen focused strictly on the "Now Only" active card unless intentionally opened.
     - Expanded state: smooth slide-up drawer showing upcoming queue items and parking lot items.
     - In list item: displays title, priority badge, and quick action buttons: "置顶 (Top)" and "冷冻 (Cryo)".
     - Free from any schedule-box calculations or calendar timeline labels.

3. **Mount in `TodayFlowView.ets`**:
   - Mount `ParkingLotInputBar` (36vp capsule) above the bottom bar or within the view.
   - When submitted: creates a `TodoItem` (with `source = TodoSource.PARKING_LOT`, `scheduledStartAt = 0`), calls `this.engine.pushToParking(newTodo)`, and asynchronously persists with `TodoDao.insert(newTodo)`.
   - Mount `QueueDrawer` at the bottom:
     - Bound to `this.engine.nextQueue` and `this.engine.parkingQueue`.
     - `onPromote: (id: string) => { this.engine.promoteToTop(id); }`
     - `onTriageCryo: (id: string) => { this.engine.triageToCryo(id); }`

4. **Refactor `SunsetCeremonyPage.ets`**:
   - Reorient from hours-based comparison to "Today's Micro-Flow Trajectory (今日微步心流轨迹)":
     - Title / Slogan: "今日微步心流轨迹 · 每一步都算数"
     - Subtitle: "告别时间焦虑，沉淀今日每一次前行的微小推力。"
     - Milestones trajectory: render chronological bead trajectory of completed micro-steps (e.g. from `completedToday` / `completedTasks`), each showing completion tick, title, and gentle checkmark.
     - Guilt-Free queue continuation: display count of remaining queue tasks with reassuring copy: "剩余待办已在明天机动就绪，无需补卡，今晚安心休息。"
     - Batch rollover button: "安心打烊，开启明天" -> closes sunset ceremony.
     - Preserve native `SaveButton` for Polaroid card generation with zero sensitive permissions.

5. **Sync `LocalUnit.test.ets`**:
   - In `testAdversarialParkingItemActiveTriageToCryo` and `testChallenger2CryoParkingResurrectionAnomaly`:
     - Update assertions: change `expect(leakedInParking).assertEqual(true)` to `expect(leakedInParking).assertEqual(false)`, proving that the bug is genuinely resolved.
   - Add/verify test case for `pushToParking` fast non-stealing ingestion.
   - Run `hvigorw test` to ensure ALL unit tests pass with 0 failures.

6. **Build & Test Verification**:
   - Run:
     ```bash
     export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
     export PATH=$JAVA_HOME/bin:$PATH
     export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
     /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp
     /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p module=entry@ohosTest -p product=default assembleHap
     /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw test
     ```
   - Ensure all 3 commands return `BUILD SUCCESSFUL` with 0 errors and all unit tests pass.

7. **Handoff**:
   Write your detailed handoff report to:
   `/Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/worker_m3/handoff.md`
   Then send a message to parent summarizing your deliverables.
