# Handoff Report: UI Animation & Gesture Dynamics Fix Formulation (Milestone M1 Round 2)

- **Agent**: `explorer_card_deck_ui_r2`
- **Role**: Explorer (UI Animation, Gesture Dynamics, Kinematics & Fix Formulation)
- **Target Milestone**: Milestone M1 (Parallax Card Deck Core Implementation)
- **Date**: 2026-09-23

---

## 1. Observation

1. **Orphaned `SPRING_CARD_SNAP_FOCUS` Definition**:
   - In `entry/src/main/ets/common/constants/CurveConstants.ets:77`:
     ```typescript
     77:   public static readonly SPRING_CARD_SNAP_FOCUS = curves.springMotion(0.34, 0.62);
     ```
   - In `entry/src/main/ets/components/NowActionCard.ets:54-75`:
     ```typescript
     54:     animateTo({
     55:       curve: CurveConstants.SPRING_CARD_FLYOUT,
     56:       onFinish: () => { ... }
     70:     }, () => {
     71:       this.offsetX = targetX;
     72:       this.rotateAngle = targetAngle;
     73:       this.cardOpacity = 0.0;
     74:       this.onGestureProgressChange(1.0, targetX, 0);
     75:     });
     ```
     `onGestureProgressChange(1.0, targetX, 0)` is trapped within the `SPRING_CARD_FLYOUT` (`curves.springMotion(0.30, 0.82)`) animation closure.
   - In `entry/src/main/ets/components/ParallaxCardDeck.ets:42-44`:
     ```typescript
     42:           onGestureProgressChange: (progress: number) => {
     43:             this.gestureProgress = progress;
     44:           },
     ```
     `ParallaxCardDeck` passes `progress` straight through without curve association.
   - In `entry/src/main/ets/components/NextPeekCard.ets:61-68, 117-123`:
     Neither Layer 2 nor Layer 3 has an `.animation(...)` curve bound to `.translate()` or `.scale()`. `CurveConstants` is not even imported.

2. **Missing `PanGesture.onActionCancel`**:
   - In `entry/src/main/ets/components/NowActionCard.ets:376-413`:
     `PanGesture` defines `.onActionUpdate` (lines 377-394) and `.onActionEnd` (lines 395-412).
     There is no `.onActionCancel` callback.
   - DevEco SDK definition at `/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/ets/component/gesture.d.ts:2670`:
     `onActionCancel(event: () => void): PanGestureInterface;` is supported.

3. **Scale Transform Anchor & Vertical Contraction (F-03)**:
   - In `entry/src/main/ets/components/NextPeekCard.ets:62-65, 118-121`:
     `.scale({ x: ..., y: ... })` omits `centerX` and `centerY`.
     DevEco SDK definition in `common.d.ts:5820, 5855` defines `centerX?: number | string` and `centerY?: number | string`.
     Defaulting to center causes top alignment drift during scaling.

4. **Sensory Triggering Duplication (F-01)**:
   - In `entry/src/main/ets/components/NowActionCard.ets:43-48`:
     `AudioService.getInstance().playChordStep()` and `HapticService.getInstance().triggerClick()` execute at $t=0$ upon commit.
   - In `entry/src/main/ets/views/TodayFlowView.ets:147-148, 168`:
     `AudioService.getInstance().playChordStep()` and `HapticService.getInstance().triggerClick()` execute again at $t=260\text{ms}$ upon callback completion.

---

## 2. Logic Chain

1. **Logic for Spring Snap Focus Wiring (Objective 1, F-02)**:
   - Requirement R3 and `PROJECT.md` mandate that when the active card flies out, the rising secondary card snaps to focus governed by `curves.springMotion(0.34, 0.62)`, producing an ~8.35% overshoot bounce ($M_p \approx 8.353\% \approx 2\text{vp}$).
   - Because `NowActionCard` bundled `onGestureProgressChange(1.0)` into `animateTo({ curve: SPRING_CARD_FLYOUT })`, the secondary card was coerced into deadbeat motion ($\zeta = 0.82$).
   - By decoupling `NowActionCard` into dual `animateTo` calls (`SPRING_CARD_FLYOUT` for top card dismissal, `SPRING_CARD_SNAP_FOCUS` for progress 1.0 transition), and concurrently coordinating in `ParallaxCardDeck` (`animateTo` with `SPRING_CARD_SNAP_FOCUS`) and binding in `NextPeekCard` (`.animation(this.isSnapping ? { curve: CurveConstants.SPRING_CARD_SNAP_FOCUS } : null)`), the secondary card rising transition executes with the required overshoot bounce.
   - Inactive state (`isSnapping: false`) leaves `.animation(null)`, guaranteeing zero input lag during continuous 120Hz finger dragging.

2. **Logic for Transform Anchor Alignment (F-03)**:
   - Setting `centerX: '50%', centerY: '0%'` locks the card's top edge to the container stack's top edge. Scaling from $0.93 \to 1.00$ expands downward and laterally rather than shifting the top edge downward, maintaining geometric continuity with the Layer 1 card.

3. **Logic for `PanGesture.onActionCancel` Snap-Back (Objective 2)**:
   - When system gestures (back swipe, notification panel) or app interruptions intercept the drag, ArkUI invokes `onActionCancel`.
   - Without `onActionCancel`, `this.isDragging` remains true and `offsetX` remains non-zero, permanently stalling the UI.
   - Implementing `.onActionCancel(() => { if (this.isAnimatingTransition) return; this.isDragging = false; this.onDragStateChange(false); this.executeSnapBack(); })` resets all internal state machines and smoothly snaps the card back to $(0, 0)$ with `SPRING_CARD_CANCEL_RESET`.

4. **Logic for Sensory Deduplication (F-01)**:
   - Zero-latency tactile responsiveness requires audio and haptics to trigger at the instant of release ($t=0$).
   - Triggering again at $t=260\text{ms}$ in `TodayFlowView` advances the chord step twice and emits an unwanted secondary vibration. Removing lines 147-148 and 168 from `TodayFlowView.ets` preserves the clean 1-action-1-chord-step progression.

---

## 3. Caveats

- **Device Motor Variance**: While `vibrator.startVibration` and `soundPool` calls are verified syntactically and logically, physical haptic motor feel and sound timbre on physical HarmonyOS NEXT hardware may vary slightly between phone and tablet form factors.
- **Gesture Priority**: System back navigation gesture at the left/right screen edge may take precedence depending on window configuration; `onActionCancel` ensures complete safety under such edge interruptions.

---

## 4. Conclusion

The formulation provides a comprehensive, minimal, and fully verifiable fix across five files:
1. `entry/src/main/ets/components/NowActionCard.ets`: Dual `animateTo` separation + `.onActionCancel` registration.
2. `entry/src/main/ets/components/ParallaxCardDeck.ets`: Coordination of `SPRING_CARD_SNAP_FOCUS` on `progress >= 1.0` + `isSnapping` flag.
3. `entry/src/main/ets/components/NextPeekCard.ets`: Import `CurveConstants`, bind `.animation(...)` when `isSnapping` is true, and anchor scale center at `centerX: '50%', centerY: '0%'`.
4. `entry/src/main/ets/views/TodayFlowView.ets`: Remove redundant duplicate sensory calls in `handleComplete` and `handleSkip`.
5. `entry/src/test/LocalUnit.test.ets`: Add unit test #32 verifying gesture cancellation recovery kinematics.

All proposed changes strictly preserve ArkTS strong typing (0 `any`, 0 `@ts-ignore`), strict 0 Emoji constraints, and ArkUI V2 decorator standards.

---

## 5. Verification Method

To verify the proposed implementation once applied:

1. **Automated Unit Tests**:
   ```bash
   export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
   export PATH=$JAVA_HOME/bin:$PATH
   export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
   /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw test
   ```
   **Expected**: 32/32 tests pass (0 failures, 0 errors).

2. **Module Compilation**:
   ```bash
   /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --no-daemon --mode module -p module=entry -p product=default assembleHap
   ```
   **Expected**: `BUILD SUCCESSFUL` (0 errors).

3. **Orphaned Curve Scan**:
   ```bash
   grep -rn "SPRING_CARD_SNAP_FOCUS" entry/src/
   ```
   **Expected**: Found in `CurveConstants.ets`, `NowActionCard.ets`, `ParallaxCardDeck.ets`, and `NextPeekCard.ets`.

4. **Zero Emoji & Strict Typing Check**:
   ```bash
   grep -rn ": any" entry/src/
   grep -rn "@ts-ignore" entry/src/
   ```
   **Expected**: Exactly 0 occurrences.
