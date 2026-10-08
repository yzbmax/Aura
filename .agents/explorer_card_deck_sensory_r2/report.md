# Sensory Feedback Deduplication & Single Source of Truth Report

**Target Milestone**: M1 (Parallax Card Deck Core Implementation)  
**Author**: Explorer Sensory R2 (`explorer_card_deck_sensory_r2`)  
**Target Files**:
- `entry/src/main/ets/components/NowActionCard.ets`
- `entry/src/main/ets/views/TodayFlowView.ets`

---

## 1. Executive Summary

- **Defect Investigated**: In Milestone M1, task completion and task skipping trigger duplicate auditory and haptic feedback across `NowActionCard.ets` (lines 43-48) and `TodayFlowView.ets` (lines 147-148, 168).
- **Acoustic Consequence**: `AudioService.playChordStep()` is called twice per task completion, cycling 2 chord steps per task (e.g., C4 then E4 260ms later), exhausting the 4-note chord progression (Do $\to$ Mi $\to$ Sol $\to$ High Do') in just 2 tasks instead of 4 tasks.
- **Tactile Consequence**: Users experience an initial haptic pulse upon gesture release, followed 260ms later by an unexpected second pulse (tactile double-click stutter/glitch).
- **Decision & Single Source of Truth**: **`NowActionCard.executeFlyout` MUST BE the Single Source of Truth.** Sensory feedback must trigger immediately ($t = 0\text{ms}$) upon commit (gesture release past threshold or button click). Duplicate calls in `TodayFlowView.ets` (`handleComplete` lines 147-148, `handleSkip` line 168) and the now-redundant `AudioService` import (line 18) must be eliminated.

---

## 2. Root Cause & Architectural Flow

```
[User Action: Swipe past ±100vp / velocity ≥ 650 OR Button Click "完成"/"稍后"]
                               │
                               ▼
        ┌────────────────────────────────────────────────────────┐
        │        NowActionCard.executeFlyout(isComplete)         │
        │                                                        │
        │  t = 0ms (Commit Moment):                              │
        │  ✓ If isComplete:                                      │
        │      • AudioService.playChordStep()  [1st Call - CHIME]│
        │      • HapticService.triggerClick()   [1st Call - POP]  │
        │  ✓ Else (Skip):                                        │
        │      • HapticService.triggerTick()    [1st Call - TICK] │
        │                                                        │
        │  ✓ animateTo(SPRING_CARD_FLYOUT) initiates (260ms)     │
        └────────────────────────────────────────────────────────┘
                               │
                               │ 260ms transition finishes
                               ▼
        ┌────────────────────────────────────────────────────────┐
        │  onFinish callback in NowActionCard                    │
        │  calls this.onComplete() or this.onSkip()              │
        └────────────────────────────────────────────────────────┘
                               │
                               ▼
        ┌────────────────────────────────────────────────────────┐
        │  TodayFlowView.handleComplete() / handleSkip()         │
        │                                                        │
        │  t = 260ms (Model / DB Write):                         │
        │  ✗ Lines 147-148:                                      │
        │      • AudioService.playChordStep()  [DUPLICATE #2]    │
        │      • HapticService.triggerClick()   [DUPLICATE #2]    │
        │  ✗ Line 168:                                           │
        │      • HapticService.triggerTick()    [DUPLICATE #2]    │
        │                                                        │
        │  ✓ engine.completeActive() / skipActive()               │
        │  ✓ TodoDao.update(completed)                           │
        │  ✓ UndoService.showUndo(...)                           │
        └────────────────────────────────────────────────────────┘
```

---

## 3. Tradeoff Analysis: Where Should the Single Source of Truth Live?

We evaluated the two competing options against Human Factors, micro-interaction ergonomics, and architecture:

| Dimension | Option A: In `NowActionCard.executeFlyout` (Commit Moment) | Option B: In `TodayFlowView.handleComplete` (Callback / onFinish) |
|---|---|---|
| **Perceptual Latency** | **$0\text{ms}$ (Instantaneous)**: Immediate tactile & auditory reward at the moment of finger release or button tap. | **$260\text{ms}$ Lag**: Card has already flown completely off screen before the sound and vibration occur. |
| **Tactile Synesthesia** | **High**: Matches physical card-deck metaphor (flicking a physical card snaps right under your fingertips). | **Disconnected**: Delayed vibration feels like an accidental phantom vibration or lag artifact. |
| **Button Click Response** | **Instant**: Pressing "完成" or "稍后" button immediately clicks and chimes. | **Unresponsive**: Pressing "完成" produces total silence for 260ms while the card slides away. |
| **Hysteresis Continuity** | **Seamless**: Directly follows the 100vp detent tick from `hapticHysteresis` in the same component. | **Split**: Detent tick occurs in `NowActionCard`, but commit click occurs 260ms later in `TodayFlowView`. |
| **Reentrancy Protection** | **Guaranteed**: Protected by `isAnimatingTransition = true`, preventing double triggers from rapid clicks. | **Guaranteed**: Called once after `onFinish`. |
| **Separation of Concerns** | **Clean**: `NowActionCard` handles sensory presentation & physical kinetics; `TodayFlowView` handles domain state, DAO persistence, and Undo. | **Conflated**: UI animation timing is coupled with domain persistence timing. |

### Verdict
**Option A is unanimously selected.** Sensory feedback must reside strictly in `NowActionCard.executeFlyout(isComplete)`.

---

## 4. Exact Code Modification Specification

### 4.1 Changes in `TodayFlowView.ets`

**File**: `entry/src/main/ets/views/TodayFlowView.ets`

#### Change 1: Remove unused `AudioService` import (Line 18)

**Before**:
```typescript
17: import { StreakFreezeRevivalCard } from '../components/StreakFreezeRevivalCard';
18: import { AudioService } from '../common/media/AudioService';
19: import { HapticService } from '../common/media/HapticService';
20: import { UndoService } from '../common/utils/UndoService';
```

**After**:
```typescript
17: import { StreakFreezeRevivalCard } from '../components/StreakFreezeRevivalCard';
18: import { HapticService } from '../common/media/HapticService';
19: import { UndoService } from '../common/utils/UndoService';
```
*(Note: Keep `HapticService` because it is still required for `handleParkingSubmit`, `handlePromote`, `handleTriageCryo`, Sunset button, Settings button, and FAB).*

---

#### Change 2: Remove duplicate audio and haptic calls in `handleComplete` (Lines 146-148)

**Before**:
```typescript
140:   private async handleComplete(): Promise<void> {
141:     const completed = this.engine.completeActive();
142:     if (!completed) {
143:       return;
144:     }
145: 
146:     // 1. 多感官即时反馈
147:     AudioService.getInstance().playChordStep();
148:     HapticService.getInstance().triggerClick();
149: 
150:     // 2. 数据层持久化更新
151:     await TodoDao.update(completed);
152: 
153:     // 3. 触发 5 秒无痛撤销胶囊
154:     UndoService.getInstance().showUndo(`已完成「${completed.title}」`, async () => {
```

**After**:
```typescript
  private async handleComplete(): Promise<void> {
    const completed = this.engine.completeActive();
    if (!completed) {
      return;
    }

    // 1. 数据层持久化更新 (多感官即时反馈已由 NowActionCard.executeFlyout 在提交瞬间触发)
    await TodoDao.update(completed);

    // 2. 触发 5 秒无痛撤销胶囊
    UndoService.getInstance().showUndo(`已完成「${completed.title}」`, async () => {
```

---

#### Change 3: Remove duplicate haptic tick in `handleSkip` (Line 168)

**Before**:
```typescript
162:   private async handleSkip(): Promise<void> {
163:     const skipped = this.engine.skipActive();
164:     if (!skipped) {
165:       return;
166:     }
167: 
168:     HapticService.getInstance().triggerTick();
169:     await TodoDao.update(skipped);
170:   }
```

**After**:
```typescript
  private async handleSkip(): Promise<void> {
    const skipped = this.engine.skipActive();
    if (!skipped) {
      return;
    }

    // 数据层持久化更新 (跳过微震反馈已由 NowActionCard.executeFlyout 在提交瞬间触发)
    await TodoDao.update(skipped);
  }
```

---

### 4.2 Affirmation of `NowActionCard.ets` Implementation

**File**: `entry/src/main/ets/components/NowActionCard.ets`

Lines 36-49 remain the authoritative implementation:
```typescript
  private executeFlyout(isComplete: boolean): void {
    if (this.isAnimatingTransition) {
      return;
    }
    this.isAnimatingTransition = true;

    // 即时多感官反馈: 完成(升阶和弦+清脆微震), 跳过(静默微气雾脉冲) - 单事实源 (Single Source of Truth)
    if (isComplete) {
      AudioService.getInstance().playChordStep();
      HapticService.getInstance().triggerClick();
    } else {
      HapticService.getInstance().triggerTick();
    }

    const targetX: number = isComplete ? CardDeckKinematics.EXIT_TRANSLATE_X : -CardDeckKinematics.EXIT_TRANSLATE_X;
    const targetAngle: number = isComplete ? CardDeckKinematics.EXIT_ROTATE_ANGLE : -CardDeckKinematics.EXIT_ROTATE_ANGLE;
    ...
```

**Key Invariants Preserved**:
1. `isAnimatingTransition` lock protects against double-clicks or repeated gesture triggers.
2. Complete action: exactly 1 `playChordStep()` call + 1 `triggerClick()` call.
3. Skip action: exactly 0 audio calls + 1 `triggerTick()` call (peaceful and non-intrusive).
4. SubTask clicks inside the card remain independent (`triggerClick()` per checkbox toggle).
5. Focus button click remains independent (`triggerClick()` per focus launch).
6. Gesture threshold crossing retains `triggerTick()` from `hapticHysteresis.update(event.offsetX)`.

---

## 5. Verification Matrix

| Test Scenario | Expected Sensory Events | Verification Method |
|---|---|---|
| **Right Swipe Flyout (Complete)** | 1x `triggerTick` at 100vp detent, 1x `triggerClick` + 1x `playChordStep` at release | Manual / Unit test validation |
| **Button "完成" Click (Complete)** | 1x `triggerClick` + 1x `playChordStep` immediately at click ($t=0\text{ms}$) | Manual / Code audit |
| **Left Swipe Flyout (Skip)** | 1x `triggerTick` at -100vp detent, 1x `triggerTick` at release, 0x audio | Manual / Unit test validation |
| **Button "稍后" Click (Skip)** | 1x `triggerTick` immediately at click ($t=0\text{ms}$), 0x audio | Manual / Code audit |
| **Drag Cancel / Snap Back (<100vp)** | 0x `playChordStep`, 0x `triggerClick` (detent tick may fire if >100vp then pulled back, but reset safely) | Unit test #28 & #30 |
| **Chord Ladder Progression** | Exactly 1 note advance per completed task: Task 1 (C4) $\to$ Task 2 (E4) $\to$ Task 3 (G4) $\to$ Task 4 (C5) | AudioService state tracking |
| **Compilation Gate** | `BUILD SUCCESSFUL`, 0 errors, 0 warnings from unused imports | `hvigorw --mode module -p module=entry assembleHap` |
| **Unit Test Suite Gate** | 31/31 tests PASS | `hvigorw test` |
