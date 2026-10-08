## 2026-09-22T08:49:17Z
You are Worker 1 (teamwork_preview_worker) for Milestone 1 of the "Now Only" Single-Thread Minimal Flow refactoring project.
Your working directory is: /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/worker_m1
Workspace root: /Users/qiuhaiqin/DevEcoStudioProjects/Aura

MANDATORY FIRST STEP:
Read the authoritative user request at:
/Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/ORIGINAL_REQUEST.md
Pay special attention to the latest section ## 2026-09-22T08:35:22Z.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Context & Reference Documents:
Read the survey reports and project architecture:
1. /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/orchestrator_now_only/PROJECT.md
2. /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/orchestrator_now_only/TEST_INFRA.md
3. /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/explorer_survey_1/domain_scheduler_survey.md
4. /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/explorer_survey_3/persistence_test_survey.md

Your Exclusive Write Ownership:
You own exclusively and may create/edit these files:
- `entry/src/main/ets/components/TaskVisualHelper.ets` (new file)
- `entry/src/main/ets/components/FlowSpineAxis.ets` (re-export TaskBlockVisual and getTaskVisual from TaskVisualHelper)
- `entry/src/main/ets/engine/SingleThreadFlowEngine.ets` (new file)
- `entry/src/test/LocalUnit.test.ets` (update test cases and fix strict typing & import paths)
Do NOT modify other files during this milestone.

Implementation Tasks:
1. **Extract `TaskVisualHelper.ets`**:
   - Create `entry/src/main/ets/components/TaskVisualHelper.ets`. Extract `TaskBlockVisual` interface and `getTaskVisual(item: TodoItem): TaskBlockVisual` from `FlowSpineAxis.ets`.
   - Update `FlowSpineAxis.ets` to import and re-export `TaskBlockVisual` and `getTaskVisual` from `./TaskVisualHelper` so existing callers (`MistMorphingCard.ets`, `FloatingDeckDrawer.ets`) do not break.
2. **Implement `SingleThreadFlowEngine.ets`**:
   - Create `entry/src/main/ets/engine/SingleThreadFlowEngine.ets`.
   - Implement `@ObservedV2` class `SingleThreadFlowEngine`:
     - `@Trace activeTask: TodoItem | null = null`
     - `@Trace nextQueue: TodoItem[] = [];`
     - `@Trace parkingQueue: TodoItem[] = [];`
     - `@Trace frozenTasks: TodoItem[] = [];`
     - `@Trace completedToday: TodoItem[] = [];`
     - `load(allItems: TodoItem[]): void`: filters out tombstones and completed; delegates aging to `MildAgingEngine.evaluateAging()`; isolates frozen items (Level 3 / overdue 8+ days) into `frozenTasks`; sorts remaining active items by priority score (`calculatePriorityScore`); first becomes `activeTask`, remainder becomes `nextQueue`.
     - `completeActive(): TodoItem | null`: marks `activeTask` as completed, pushes to `completedToday`, advances `nextQueue.shift()` to `activeTask`. Returns completed item.
     - `skipActive(): TodoItem | null`: moves current `activeTask` to the tail of `nextQueue`, advances `nextQueue.shift()` to `activeTask`. Returns skipped item.
     - `promoteToTop(id: string): boolean`: finds item in `nextQueue` or `parkingQueue`, removes it, puts current `activeTask` into `nextQueue[0]`, and sets found item as `activeTask`.
     - `pushToParking(item: TodoItem): void`: appends item to `parkingQueue` and `nextQueue` without changing `activeTask`.
     - `triageToCryo(id: string): boolean`: moves task to `frozenTasks` with `isFrozen = true`, `status = TodoStatus.FROZEN`.
     - `reviveFromCryo(id: string): boolean`: revives task from `frozenTasks` back to `nextQueue` with `isFrozen = false`, `status = TodoStatus.TODO`, resetting overdue state.
     - `calculatePriorityScore(item: TodoItem): number`: calculates score based on priority enum (HIGH > MEDIUM > LOW), star status, and overdue days.
   - Strict ArkTS compliance: strong types, no `any`, `@ObservedV2` and `@Trace`.
3. **Fix and Expand `LocalUnit.test.ets`**:
   - Fix import paths (must be `../main/ets/...` not `../../main/ets/...`).
   - Fix all ArkTS strict typing errors (explicit types, no untyped or `any` variables).
   - Implement 8 comprehensive test cases testing `SingleThreadFlowEngine`:
     1. `testPriorityInitializationAndSorting`: verify sorting by priority and age on `load()`.
     2. `testCompleteActiveAdvancesQueue`: verify active becomes completedToday, next becomes active.
     3. `testSkipActiveRequeuesToTail`: verify active moves to end of nextQueue, new next becomes active.
     4. `testPromoteToTop`: verify promoting a queued item displaces active without data loss.
     5. `testParkingLotIngestionPreservesActive`: verify `pushToParking` does not steal `activeTask`.
     6. `testMildAgingProgression`: verify aging levels evaluation on overdue items.
     7. `testCryoChamberAutoFreezing`: verify tasks overdue >= 8 days are automatically placed into `frozenTasks`.
     8. `testCryoChamberRevival`: verify revival clears frozen status and returns item to `nextQueue`.
4. **Build & Test Verification**:
   Run the following verification commands using `run_command`:
   ```bash
   export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
   export PATH=$JAVA_HOME/bin:$PATH
   export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
   /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp
   ```
   and
   ```bash
   export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
   export PATH=$JAVA_HOME/bin:$PATH
   export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
   /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p module=entry@ohosTest -p product=default assembleHap
   ```
   Ensure both pass with 100% BUILD SUCCESSFUL.
5. **Handoff**:
   Write your complete report to `/Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/worker_m1/handoff.md` with:
   - What was implemented
   - Verbatim build and test results
   - Files created and modified
   Then send a message to parent with your completion status and report path.
