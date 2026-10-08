# Handoff Report: Sensory Feedback Deduplication (Milestone M1)

- **Agent**: `explorer_card_deck_sensory_r2` (Roles: Sensory Feedback Investigator, ArkTS/ArkUI Sensory Architecture Analyst)
- **Target Files**:
  - `entry/src/main/ets/components/NowActionCard.ets`
  - `entry/src/main/ets/views/TodayFlowView.ets`
- **Related Report**: `/Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/explorer_card_deck_sensory_r2/report.md`

---

## 1. Observation

1. **NowActionCard.ets (lines 43-48)**:
   In `executeFlyout(isComplete: boolean)`:
   ```typescript
   43:     if (isComplete) {
   44:       AudioService.getInstance().playChordStep();
   45:       HapticService.getInstance().triggerClick();
   46:     } else {
   47:       HapticService.getInstance().triggerTick();
   48:     }
   ```
   This code executes synchronously at $t = 0\text{ms}$ upon user commit (either gesture release or button click), immediately before initiating `animateTo({ curve: CurveConstants.SPRING_CARD_FLYOUT, ... })`.

2. **TodayFlowView.ets (lines 147-148 & line 168)**:
   In `handleComplete()`:
   ```typescript
   146:     // 1. 多感官即时反馈
   147:     AudioService.getInstance().playChordStep();
   148:     HapticService.getInstance().triggerClick();
   ```
   In `handleSkip()`:
   ```typescript
   168:     HapticService.getInstance().triggerTick();
   ```
   These methods are invoked by `onComplete()` and `onSkip()` respectively, which are dispatched from `NowActionCard`'s `animateTo.onFinish` callback (~260ms after flyout starts).

3. **AudioService.ets (lines 87-89)**:
   ```typescript
   87:     const targetSoundId = this.soundIds[this.currentStepIndex % this.soundIds.length];
   88:     this.currentStepIndex++;
   ```
   `AudioService` advances its internal chord ladder index by $+1$ on each invocation of `playChordStep()`. There are 4 samples in total (`C4`, `E4`, `G4`, `C5`).

4. **Call Hierarchy & Exclusivity**:
   - `grep_search` across `entry/src` shows that `TodayFlowView.handleComplete()` is only called at line 326: `onComplete: () => { this.handleComplete(); }`.
   - `TodayFlowView.handleSkip()` is only called at line 329: `onSkip: () => { this.handleSkip(); }`.
   - In `TodayFlowView.ets`, `AudioService` is imported on line 18 and used nowhere else except line 147.

---

## 2. Logic Chain

1. **Step 1 (Tracing the duplicate execution path)**:
   - When a user releases a card to the right or taps "完成", `NowActionCard.executeFlyout(true)` fires Observation 1 (`playChordStep()` call #1, `triggerClick()` call #1).
   - `animateTo` animates the card off-screen for 260ms.
   - Upon completion, `onFinish` invokes `this.onComplete()`, which delegates to `ParallaxCardDeck.onComplete()`, which calls `TodayFlowView.handleComplete()`.
   - `handleComplete()` executes Observation 2 (`playChordStep()` call #2, `triggerClick()` call #2).
   - Therefore, a single task completion triggers two audible chord steps and two haptic clicks separated by 260ms.

2. **Step 2 (Assessing sensory damage)**:
   - By Observation 3, each call to `playChordStep()` increments `currentStepIndex`.
   - Calling it twice per task causes a single task to play two chord tones (e.g. C4 then E4) and burns through the 4-stage progression in only 2 tasks instead of 4 tasks.
   - The delayed second vibration (260ms later) creates a perceptible tactile stutter.
   - For skipped tasks, `triggerTick()` is fired twice.

3. **Step 3 (Determining the Single Source of Truth)**:
   - If feedback is kept in `TodayFlowView.handleComplete()` (delayed by 260ms):
     - The user experiences a 260ms latency gap between releasing the card / tapping the button and receiving feedback.
     - The card flies across the screen in total silence and numbness, and the sound/vibration fires only after the card is gone. This violates human tactile expectations (feedback threshold $\le 50\text{ms}$).
   - If feedback is kept in `NowActionCard.executeFlyout()` ($t = 0\text{ms}$):
     - Sensory feedback matches the exact physical moment of commitment and button press.
     - `isAnimatingTransition` provides reentrancy protection against double clicks.
     - `TodayFlowView` remains a clean domain orchestrator focused on queue transitions, database persistence (`TodoDao.update`), and Undo capsule management.

4. **Step 4 (Impact on Imports & Linter)**:
   - By Observation 4, `AudioService` in `TodayFlowView.ets` is only used on line 147. Removing line 147 allows removing the line 18 import, avoiding unused import warnings in ArkTS.
   - `HapticService` is still used in `TodayFlowView` for other interactions (FAB, settings, sunset, parking submit, queue promote) and must be retained.

---

## 3. Caveats

- **No Caveats regarding deduplication logic**: The call chain is fully traced, deterministic, and isolated.
- **Assumptions**: The 260ms duration of `SPRING_CARD_FLYOUT` is intentional and tuned for smooth visual exit; sensory feedback must align with the initiation of this transition rather than its completion.

---

## 4. Conclusion

1. **Single Source of Truth**: `NowActionCard.executeFlyout` (lines 43-48).
2. **Remediation**:
   - In `entry/src/main/ets/views/TodayFlowView.ets`:
     - Delete line 18 (`import { AudioService } ...`).
     - Delete lines 146-148 in `handleComplete()` (`AudioService.playChordStep()` and `HapticService.triggerClick()`).
     - Delete line 168 in `handleSkip()` (`HapticService.triggerTick()`).
   - In `entry/src/main/ets/components/NowActionCard.ets`:
     - Retain lines 43-48 as the single authoritative sensory trigger.
     - Update comments to document it as the single source of truth.

---

## 5. Verification Method

1. **Automated Unit Tests**:
   ```bash
   export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
   export PATH=$JAVA_HOME/bin:$PATH
   export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
   /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw test
   ```
   *Expected Result*: 31/31 unit tests pass (`BUILD SUCCESSFUL`).

2. **HAP Build Verification**:
   ```bash
   /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --no-daemon --mode module -p module=entry -p product=default assembleHap
   ```
   *Expected Result*: `BUILD SUCCESSFUL`, 0 errors, no unused import warnings.

3. **Code Inspection**:
   - `grep -rn "playChordStep" entry/src/main/ets/views/TodayFlowView.ets` must return 0 results.
   - `grep -rn "playChordStep" entry/src/main/ets/components/NowActionCard.ets` must return exactly 1 result (line 44).
   - In `AudioService.ets`, each completed task advances `currentStepIndex` by exactly 1.
