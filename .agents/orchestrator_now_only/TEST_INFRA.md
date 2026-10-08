# E2E & Automated Test Infra: Aura "Now Only" Refactoring

## Test Philosophy
- Requirement-driven, opaque-box & unit-level verification.
- ArkTS strict typing compliance: no `any`, explicit types, correct relative imports (`../main/ets/`).
- Verifies functional correctness of `SingleThreadFlowEngine`: ordering, completion, skip to tail, parking lot non-stealing ingestion, gentle aging, and cryo-chamber lifecycle.

## Feature Inventory Test Mapping
| # | Feature | Test Tier | Verification Criteria |
|---|---------|-----------|------------------------|
| 1 | Priority Initialization | Tier 1 | `load()` sorts by priority score (high priority & older items top) |
| 2 | Active Task Completion | Tier 1 | `completeActive()` moves active to completedToday, nextQueue[0] becomes active |
| 3 | Active Task Skip | Tier 2 | `skipActive()` moves active to nextQueue tail, nextQueue[0] becomes active |
| 4 | Task Top / Promote | Tier 2 | `promoteToTop(id)` elevates target item directly to activeTask |
| 5 | ParkingLot Thought Ingestion | Tier 1 | `pushToParking(item)` adds to parkingQueue/tail without mutating activeTask |
| 6 | Mild Aging Level Progression | Tier 2 | Aging engine evaluates overdue days (0 -> 1 -> 2) |
| 7 | Cryo-Chamber Auto-Freezing | Tier 3 | Tasks overdue ≥ 8 days automatically enter frozenTasks |
| 8 | Cryo-Chamber Revival | Tier 3 | `reviveFromCryo(id)` restores frozen task back to nextQueue with reset aging |
| 9 | Main App Build Check | Tier 4 | `hvigorw assembleApp` succeeds with BUILD SUCCESSFUL |
| 10| Test HAP Build Check | Tier 4 | `hvigorw ... assembleHap` succeeds with BUILD SUCCESSFUL |

## Test Execution Commands
- Build Main App:
  ```bash
  export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
  export PATH=$JAVA_HOME/bin:$PATH
  export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw assembleApp
  ```
- Build Test HAP:
  ```bash
  export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
  export PATH=$JAVA_HOME/bin:$PATH
  export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
  /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --mode module -p module=entry@ohosTest -p product=default assembleHap
  ```
