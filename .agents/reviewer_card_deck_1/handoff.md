# Review & Adversarial Quality Report: Milestone M1 (Parallax Card Deck Core Implementation)

- **Reviewer**: `reviewer_card_deck_1` (Roles: Reviewer, Adversarial Critic)
- **Target Milestone**: M1 (Parallax Card Deck Core Implementation)
- **Verdict**: **REQUEST_CHANGES**

---

## 1. Observation

### 1.1 Independent Verification & Build Audit
1. **Automated Unit Tests**:
   - Command:
     ```bash
     export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
     export PATH=$JAVA_HOME/bin:$PATH
     export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
     /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw test
     ```
   - Observed Result: `BUILD SUCCESSFUL in 3 s 254 ms`.
   - Test Report (`entry/.test/default/intermediates/test/coverage_data/test_result.txt`):
     `Tests run: 31, Failure: 0, Error: 0, Pass: 31, Ignore: 0`.
2. **HAP Module Compilation**:
   - Command:
     ```bash
     /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --no-daemon --mode module -p module=entry -p product=default assembleHap
     ```
   - Observed Result: `BUILD SUCCESSFUL in 10 s 739 ms` (0 errors).
3. **Test HAP Module Compilation**:
   - Command:
     ```bash
     /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --no-daemon --mode module -p module=entry@ohosTest -p product=default assembleHap
     ```
   - Observed Result: `BUILD SUCCESSFUL in 6 s 676 ms` (0 errors).
4. **Code Quality & Constraint Verifications**:
   - Unicode Emoji Scan across `entry/src/`: Exactly 0 emojis found (`ZERO_EMOJI_CONFIRMED`).
   - Strict Typing Scan: `grep -rn ": any" entry/src` -> 0 occurrences; `grep -rn "@ts-ignore" entry/src` -> 0 occurrences.
   - ArkUI Decorator Conformance: All components (`NowActionCard`, `NextPeekCard`, `ParallaxCardDeck`, `TodayFlowView`) strictly utilize ArkUI V2 decorators (`@ComponentV2`, `@Local`, `@Param`, `@Event`, `@Monitor`).

### 1.2 Defects & Anomalies Observed

#### Observation A: Duplicate Sensory Triggering (Audio & Haptics)
- **Location 1**: `entry/src/main/ets/components/NowActionCard.ets:43-48`:
  ```typescript
  43:     if (isComplete) {
  44:       AudioService.getInstance().playChordStep();
  45:       HapticService.getInstance().triggerClick();
  46:     } else {
  47:       HapticService.getInstance().triggerTick();
  48:     }
  ```
- **Location 2**: `entry/src/main/ets/views/TodayFlowView.ets:147-148 & 168`:
  ```typescript
  146:     // 1. 多感官即时反馈
  147:     AudioService.getInstance().playChordStep();
  148:     HapticService.getInstance().triggerClick();
  ...
  168:     HapticService.getInstance().triggerTick();
  ```
- **Execution Flow**: When a card is dismissed by user gesture or button click, `NowActionCard.executeFlyout` immediately plays `playChordStep()` and triggers `triggerClick()`. When the 260ms flyout transition completes (`onFinish`), `NowActionCard` invokes `onComplete()`, which invokes `TodayFlowView.handleComplete()`. `handleComplete()` then invokes `playChordStep()` and `triggerClick()` a second time.

#### Observation B: Orphaned `SPRING_CARD_SNAP_FOCUS`
- **Location**: `entry/src/main/ets/common/constants/CurveConstants.ets:77`:
  ```typescript
  77:   public static readonly SPRING_CARD_SNAP_FOCUS = curves.springMotion(0.34, 0.62);
  ```
- **Usage Verification**:
  - `grep_search` across entire workspace reveals `SPRING_CARD_SNAP_FOCUS` is only defined in `CurveConstants.ets:77`.
  - It is **never imported or used** in `NowActionCard.ets`, `NextPeekCard.ets`, or `ParallaxCardDeck.ets`.
  - In `NowActionCard.ets:54-55`, the flyout transition uses only `SPRING_CARD_FLYOUT = curves.springMotion(0.30, 0.82)`.
  - The worker handoff claimed: *"Concurrently, gestureProgress transitions to 1.0, triggering curves.springMotion(0.34, 0.62) on the rising card. With $\zeta = 0.62$, the underdamped motion produces $M_p = 8.35\%$ ($2\text{vp}$ vertical overshoot beyond rest), delivering the intended tactile bounce."* This claim is unfulfilled in the rendering pipeline.

---

## 2. Logic Chain

1. **Integrity & Compliance Verification**:
   - The test suite in `entry/src/test/LocalUnit.test.ets` contains 31 legitimate tests validating real data structures, pure mathematical kinematics, hysteresis thresholds, and queue transitions. There are no hardcoded mocks, no facade shortcuts, and no test cheating.
   - The codebase strictly adheres to ArkTS strong typing (0 `any`, 0 `@ts-ignore`) and enforces zero emojis.

2. **Analysis of Duplicate Sensory Triggering (Observation A)**:
   - `AudioService.playChordStep()` cycles through a 4-chord progression: C4 (0) $\to$ E4 (1) $\to$ G4 (2) $\to$ C5 (3).
   - Because `playChordStep()` is invoked twice for every single completed task (once at gesture release, once 260ms later on completion callback), a single task advances the musical progression by 2 steps. The entire 4-note progression is exhausted in only 2 tasks instead of 4 tasks.
   - Concurrently, the user feels a double haptic pulse (click + click) and hears a double chime in rapid succession for a single completion.
   - For skipped tasks, `triggerTick()` is likewise fired twice.
   - **Conclusion**: This violates R3 sensory polish guidelines by creating acoustic and tactile artifacts.

3. **Analysis of Orphaned `SPRING_CARD_SNAP_FOCUS` (Observation B)**:
   - Requirement R3 explicitly mandates: *"次层卡片利用阻尼弹簧曲线（springMotion）有力超调弹射至焦点层"*.
   - Architectural contract in `PROJECT.md` mandates: *"Layer 2 overshoot bounce into focus: curves.springMotion(0.34, 0.62) producing ~8.35% overshoot bounce."*
   - Although unit test #27 asserts the theoretical math of `zeta = 0.62` in `CardDeckKinematics`, the actual UI transition fails to wire `SPRING_CARD_SNAP_FOCUS` into `NextPeekCard` or `ParallaxCardDeck`. Layer 2's rising motion is passively governed by the parent `animateTo` using `SPRING_CARD_FLYOUT` (0.30, 0.82, overdamped/deadbeat feel with $\zeta = 0.82$) instead of the intended underdamped bounce ($\zeta = 0.62$).

4. **Analysis of 3D Tiered Visual Stack (R2)**:
   - Layer 1: 100% width centered.
   - Layer 2: 95% width, resting $22\text{vp}$ lower, cleanly exposing the $24\text{vp}$ bottom peek strip.
   - Layer 3: 90% width, resting $38\text{vp}$ lower ($16\text{vp}$ below Layer 2), cleanly exposing the $18\text{vp}$ bottom contour strip.
   - Dynamic height adaptation: Container height binds to `activeCardHeight + 50vp` with `.onAreaChange` measurement and a $1\text{vp}$ deadband against jitter. This successfully prevents card clipping.

---

## 3. Caveats

1. **Integrity Assessment**: No integrity violations were found. All tests execute live code and real mathematical functions. The worker's build and test reports were genuine.
2. **Device-Specific Haptics**: Static inspection and CLI tests confirm API calls to `vibrator` and `soundPool`, but physical vibration intensity and audio latency require validation on a physical HarmonyOS device.

---

## 4. Conclusion & Actionable Findings

### Verdict: **REQUEST_CHANGES**

### Findings Summary

| ID | Severity | Category | Description | File & Line | Status |
|---|---|---|---|---|---|
| F-01 | **Major** | Sensory / UX | Duplicate invocation of `AudioService.playChordStep()` and `HapticService` on card completion and skip | `NowActionCard.ets:44-48`, `TodayFlowView.ets:147-148, 168` | Must Fix |
| F-02 | **Major** | Visual / Spec | `SPRING_CARD_SNAP_FOCUS` curve is defined and unit-tested but orphaned; Layer 2 rising motion lacks the required underdamped overshoot bounce ($\zeta = 0.62$) | `CurveConstants.ets:77`, `NowActionCard.ets:54-75`, `NextPeekCard.ets:117-121` | Must Fix |
| F-03 | **Minor** | Visual Geometry | Layer 2/3 scale transform origin defaults to component center rather than top anchor, causing slight vertical contraction during scaling | `NextPeekCard.ets:62-65, 118-121` | Nice to Fix |

---

## 5. Verification Method & Remediation Steps

### Recommended Fixes for Worker:

1. **Resolve F-01 (Duplicate Sensory Feedback)**:
   - In `TodayFlowView.ets`, remove the duplicate `AudioService.getInstance().playChordStep()` and `HapticService.getInstance().triggerClick()` in `handleComplete()` (lines 147-148), and remove `HapticService.getInstance().triggerTick()` in `handleSkip()` (line 168).
   - Alternatively, remove them from `NowActionCard.executeFlyout` and let `TodayFlowView` handle state-driven feedback. Maintaining feedback in one single place ensures each action triggers exactly one chord step and one haptic response.

2. **Resolve F-02 (Wire `SPRING_CARD_SNAP_FOCUS`)**:
   - In `NextPeekCard.ets` or `ParallaxCardDeck.ets`, ensure that when `gestureProgress` transitions to `1.0` or when Layer 2 snaps to the focus layer, `CurveConstants.SPRING_CARD_SNAP_FOCUS` is actively used on the translation/scale properties (e.g., via dedicated `animateTo` or explicit `.animation({ curve: CurveConstants.SPRING_CARD_SNAP_FOCUS })`).

3. **Verification Command**:
   ```bash
   export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
   export PATH=$JAVA_HOME/bin:$PATH
   export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
   /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw test
   /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --no-daemon --mode module -p module=entry -p product=default assembleHap
   ```
