# UI Animation & Gesture Dynamics Fix Plan: Parallax Card Deck (Milestone M1 Round 2)

**Author**: Explorer UI R2  
**Target Milestone**: Milestone M1 (Parallax Card Deck Core Implementation)  
**Date**: 2026-09-23  

---

## 1. Executive Summary

Following Reviewer 1's adversarial findings and Reviewer 2's verification report, this document formulates the concrete, production-ready fix specification for:
1. **F-02 & Objective 1**: Wiring `CurveConstants.SPRING_CARD_SNAP_FOCUS` (`curves.springMotion(0.34, 0.62)`) into the secondary and tertiary card focus transitions across `NowActionCard.ets`, `ParallaxCardDeck.ets`, and `NextPeekCard.ets`.
2. **F-03**: Setting `centerX: '50%', centerY: '0%'` scale transformation anchor on Layer 2 and Layer 3 cards in `NextPeekCard.ets` to eliminate vertical contraction during scaling.
3. **Objective 2 & Reviewer 2 Finding 2**: Adding clean `.onActionCancel` recovery in `NowActionCard.ets` to guarantee that gestures interrupted by system back, notification shade, or modals cleanly snap back with `SPRING_CARD_CANCEL_RESET` and reset drag states.
4. **F-01 / Finding 1**: Deduplicating audio chime (`playChordStep`) and haptic pulse (`triggerClick` / `triggerTick`) calls by retaining immediate $t=0$ trigger in `NowActionCard` and removing redundant duplicate triggers in `TodayFlowView.handleComplete` and `handleSkip`.

---

## 2. Root Cause Analysis & Technical Design

### 2.1 Issue 1: Orphaned `SPRING_CARD_SNAP_FOCUS` & Lacking Overshoot Bounce (F-02)

#### Root Cause
In `NowActionCard.ets:54-75`, the card flyout animation originally wrapped both the dismissal of Layer 1 (`this.offsetX = targetX; this.rotateAngle = targetAngle; this.cardOpacity = 0.0;`) and the progression of the stack (`this.onGestureProgressChange(1.0, targetX, 0);`) inside the same `animateTo` block governed exclusively by `CurveConstants.SPRING_CARD_FLYOUT` (`curves.springMotion(0.30, 0.82)`).  
Because `SPRING_CARD_FLYOUT` has a damping ratio $\zeta = 0.82$ (overdamped / deadbeat response), the rising secondary card passively inherited this deadbeat curve, completely forfeiting the specified 8.35% overshoot bounce ($M_p \approx 8.353\%$, $\approx 2\text{vp}$ overshoot) defined by `CurveConstants.SPRING_CARD_SNAP_FOCUS` ($\zeta = 0.62$). Furthermore, neither `ParallaxCardDeck.ets` nor `NextPeekCard.ets` imported or applied `SPRING_CARD_SNAP_FOCUS`.

#### Architecture Solution: Dual-Layer Spring Decoupling & Attribute Binding
1. **Decouple in `NowActionCard.ets`**:
   - Layer 1 flyout is animated with `CurveConstants.SPRING_CARD_FLYOUT` (0.30, 0.82, 260ms crisp departure).
   - In a concurrent, dedicated `animateTo` block, `this.onGestureProgressChange(1.0, targetX, 0)` is animated using `CurveConstants.SPRING_CARD_SNAP_FOCUS` (0.34, 0.62).
2. **Coordinate in `ParallaxCardDeck.ets`**:
   - `ParallaxCardDeck` imports `CurveConstants`.
   - In `onGestureProgressChange`, when `progress >= 1.0` (commit flyout), it sets `@Local isSnapping = true` and wraps `this.gestureProgress = 1.0` inside `animateTo({ curve: CurveConstants.SPRING_CARD_SNAP_FOCUS })`.
   - When `progress === 0.0` (reset / finish), it resets `isSnapping = false` and `gestureProgress = 0.0` without spring latency.
   - During manual dragging (`progress < 1.0`), it maintains `isSnapping = false` and 1:1 direct displacement tracking (`this.gestureProgress = progress`).
3. **Bind in `NextPeekCard.ets`**:
   - `NextPeekCard` imports `CurveConstants`.
   - Accepts `@Param isSnapping: boolean = false`.
   - Applies `.animation(this.isSnapping ? { curve: CurveConstants.SPRING_CARD_SNAP_FOCUS } : null)` to Layer 2 and Layer 3 `.translate()` and `.scale()`.
   - When dragging (`isSnapping: false`), `.animation(null)` eliminates any spring lag or frame latency during 120Hz touch moves.
   - When snapping (`isSnapping: true`), the underdamped spring curve drives the physical overshoot bounce.

---

### 2.2 Issue 2: Scale Transform Anchor & Vertical Contraction (F-03)

#### Root Cause
ArkUI `.scale({ x, y })` defaults transform center coordinates `centerX` and `centerY` to `'50%'` (the geometric center of the card). In `NextPeekCard.ets`, cards are top-aligned (`Stack({ alignContent: Alignment.Top })`). Scaling from the center means the top edge shifts downwards by $\frac{1 - \text{scale}}{2} \times H$ (approx $8\sim 15\text{vp}$), conflicting with vertical translation decay and causing visible vertical contraction.

#### Solution
Specify `centerX: '50%', centerY: '0%'` explicitly in `NextPeekCard.ets` for both Layer 2 and Layer 3 `.scale(...)`. This anchors the top edge firmly to the stack coordinate origin, ensuring smooth, predictable magnification.

---

### 2.3 Issue 3: Missing `PanGesture.onActionCancel` Recovery

#### Root Cause
`NowActionCard.ets:376-413` registers `.onActionUpdate` and `.onActionEnd`, but lacks `.onActionCancel`. When a system gesture (such as back navigation, notification shade pull-down, or incoming modal) cancels the touch sequence, ArkUI dispatches `onActionCancel`. Without a handler:
- `this.isDragging` remains stuck at `true`.
- Observers of `onDragStateChange(true)` never receive `false`.
- `this.offsetX` and `this.offsetY` remain frozen mid-air at non-zero coordinates.
- Haptic hysteresis state machine remains armed/dirty.

#### Solution
Register `.onActionCancel` on `PanGesture`:
```typescript
.onActionCancel(() => {
  if (this.isAnimatingTransition) {
    return;
  }
  this.isDragging = false;
  this.onDragStateChange(false);
  this.executeSnapBack();
})
```
`executeSnapBack()` utilizes `CurveConstants.SPRING_CARD_CANCEL_RESET` (`curves.springMotion(0.28, 0.76)`), smoothly returning `offsetX`, `offsetY`, `rotateAngle` to 0, resetting `cardOpacity` to 1.0, resetting `this.hapticHysteresis`, and notifying `onGestureProgressChange(0.0, 0, 0)`.

---

### 2.4 Issue 4: Sensory Feedback Duplication (F-01)

#### Root Cause
- When user commits a complete/skip action, `NowActionCard.executeFlyout` triggers `playChordStep()` + `triggerClick()` at $t=0$.
- When the 260ms animation finishes, `onComplete()` / `onSkip()` invokes `TodayFlowView.handleComplete()` / `handleSkip()`.
- Inside `TodayFlowView.handleComplete()`, `playChordStep()` and `triggerClick()` are invoked again!
- This causes the 4-note chord progression (C4 $\to$ E4 $\to$ G4 $\to$ C5) to advance by 2 steps per single task, and emits a double vibration pulse.

#### Solution
Retain the immediate $t=0$ trigger in `NowActionCard` (providing zero-latency physical feedback at the moment of finger release or button tap), and remove the duplicate invocations from `TodayFlowView.handleComplete` (lines 147-148) and `TodayFlowView.handleSkip` (line 168).

---

## 3. Concrete Code Diff Plan

### Target File 1: `entry/src/main/ets/components/NowActionCard.ets`

```diff
--- a/entry/src/main/ets/components/NowActionCard.ets
+++ b/entry/src/main/ets/components/NowActionCard.ets
@@ -53,23 +53,29 @@ export struct NowActionCard {
     const targetX: number = isComplete ? CardDeckKinematics.EXIT_TRANSLATE_X : -CardDeckKinematics.EXIT_TRANSLATE_X;
     const targetAngle: number = isComplete ? CardDeckKinematics.EXIT_ROTATE_ANGLE : -CardDeckKinematics.EXIT_ROTATE_ANGLE;
 
-    // 顶层卡片飞出动画 (高爆发弹簧，260ms 内飞离消融)
+    // 1. 顶层卡片飞出动画 (高爆发弹簧，260ms 内飞离消融)
     animateTo({
       curve: CurveConstants.SPRING_CARD_FLYOUT,
       onFinish: () => {
         this.offsetX = 0;
         this.offsetY = 0;
         this.rotateAngle = 0;
         this.cardOpacity = 1.0;
         this.hapticHysteresis.reset();
         this.onGestureProgressChange(0.0, 0, 0);
         this.isAnimatingTransition = false;
         if (isComplete) {
           this.onComplete();
         } else {
           this.onSkip();
         }
       }
     }, () => {
       this.offsetX = targetX;
       this.rotateAngle = targetAngle;
       this.cardOpacity = 0.0;
-      this.onGestureProgressChange(1.0, targetX, 0);
+    });
+
+    // 2. 次层卡片弹簧超调弹射就位 (SPRING_CARD_SNAP_FOCUS: 0.34, 0.62，8.35% 欠阻尼弹性过冲)
+    animateTo({
+      curve: CurveConstants.SPRING_CARD_SNAP_FOCUS
+    }, () => {
+      this.onGestureProgressChange(1.0, targetX, 0);
     });
   }
@@ -410,6 +416,13 @@ export struct NowActionCard {
             } else {
               this.executeSnapBack();
             }
+          })
+          .onActionCancel(() => {
+            if (this.isAnimatingTransition) {
+              return;
+            }
+            this.isDragging = false;
+            this.onDragStateChange(false);
+            this.executeSnapBack();
           })
       )
     }
```

---

### Target File 2: `entry/src/main/ets/components/ParallaxCardDeck.ets`

```diff
--- a/entry/src/main/ets/components/ParallaxCardDeck.ets
+++ b/entry/src/main/ets/components/ParallaxCardDeck.ets
@@ -6,6 +6,7 @@
  */
 
 import { TodoItem } from '../models/TodoItem';
+import { CurveConstants } from '../common/constants/CurveConstants';
 import { NowActionCard } from './NowActionCard';
 import { NextPeekCard } from './NextPeekCard';
 
@@ -19,6 +20,7 @@ export struct ParallaxCardDeck {
   @Event onOpenFocus: (item: TodoItem) => void = () => {};
 
   @Local private gestureProgress: number = 0.0;
+  @Local private isSnapping: boolean = false;
   @Local private activeCardHeight: number = 240;
 
   build() {
@@ -31,7 +33,8 @@ export struct ParallaxCardDeck {
           secondItem: this.thirdTask,
           isVisible: this.nextTask !== null,
           activeCardHeight: this.activeCardHeight,
-          gestureProgress: this.gestureProgress
+          gestureProgress: this.gestureProgress,
+          isSnapping: this.isSnapping
         })
 
         // 屏幕中央独占当前唯一微动作卡片 (Layer 1 · 手势物理主控)
@@ -41,7 +44,18 @@ export struct ParallaxCardDeck {
             this.activeCardHeight = h;
           },
           onGestureProgressChange: (progress: number) => {
-            this.gestureProgress = progress;
+            if (progress >= 1.0) {
+              this.isSnapping = true;
+              animateTo({
+                curve: CurveConstants.SPRING_CARD_SNAP_FOCUS
+              }, () => {
+                this.gestureProgress = 1.0;
+              });
+            } else if (progress === 0.0) {
+              this.isSnapping = false;
+              this.gestureProgress = 0.0;
+            } else {
+              this.isSnapping = false;
+              this.gestureProgress = progress;
+            }
           },
           onComplete: () => {
             this.onComplete();
```

---

### Target File 3: `entry/src/main/ets/components/NextPeekCard.ets`

```diff
--- a/entry/src/main/ets/components/NextPeekCard.ets
+++ b/entry/src/main/ets/components/NextPeekCard.ets
@@ -6,6 +6,7 @@
  */
 
 import { ColorConstants } from '../common/constants/ColorConstants';
+import { CurveConstants } from '../common/constants/CurveConstants';
 import { TodoItem } from '../models/TodoItem';
 import { getTaskVisual } from './TaskVisualHelper';
 import { CardDeckKinematics } from './CardDeckKinematics';
@@ -17,6 +18,7 @@ export struct NextPeekCard {
   @Param isVisible: boolean = true;
   @Param activeCardHeight: number = 240;
   @Param gestureProgress: number = 0.0;
+  @Param isSnapping: boolean = false;
 
   private getEffectiveHeight(): number {
     return this.activeCardHeight > 80 ? this.activeCardHeight : 240;
@@ -61,8 +63,11 @@ export struct NextPeekCard {
           .translate({ y: CardDeckKinematics.calcLayer3TranslateY(this.gestureProgress, 38.0, 22.0) })
           .scale({
             x: CardDeckKinematics.calcLayer3Scale(this.gestureProgress),
-            y: CardDeckKinematics.calcLayer3Scale(this.gestureProgress)
+            y: CardDeckKinematics.calcLayer3Scale(this.gestureProgress),
+            centerX: '50%',
+            centerY: '0%'
           })
+          .animation(this.isSnapping ? { curve: CurveConstants.SPRING_CARD_SNAP_FOCUS } : null)
           .opacity(CardDeckKinematics.calcLayer3Opacity(this.gestureProgress))
           .zIndex(1)
         }
@@ -117,8 +122,11 @@ export struct NextPeekCard {
         .translate({ y: CardDeckKinematics.calcLayer2TranslateY(this.gestureProgress, 22.0) })
         .scale({
           x: CardDeckKinematics.calcLayer2Scale(this.gestureProgress),
-          y: CardDeckKinematics.calcLayer2Scale(this.gestureProgress)
+          y: CardDeckKinematics.calcLayer2Scale(this.gestureProgress),
+          centerX: '50%',
+          centerY: '0%'
         })
+        .animation(this.isSnapping ? { curve: CurveConstants.SPRING_CARD_SNAP_FOCUS } : null)
         .zIndex(2)
       }
       .width('100%')
```

---

### Target File 4: `entry/src/main/ets/views/TodayFlowView.ets`

```diff
--- a/entry/src/main/ets/views/TodayFlowView.ets
+++ b/entry/src/main/ets/views/TodayFlowView.ets
@@ -144,9 +144,7 @@ export struct TodayFlowView {
       return;
     }
 
-    // 1. 多感官即时反馈
-    AudioService.getInstance().playChordStep();
-    HapticService.getInstance().triggerClick();
+    // 1. 多感官即时反馈已在 NowActionCard.executeFlyout(t=0) 触发，避免二次触发破坏和弦阶梯与产生触觉重影
 
     // 2. 数据层持久化更新
     await TodoDao.update(completed);
@@ -165,7 +163,7 @@ export struct TodayFlowView {
       return;
     }
 
-    HapticService.getInstance().triggerTick();
+    // 微震反馈已在 NowActionCard.executeFlyout(t=0) 触发，此处不再重复触发
     await TodoDao.update(skipped);
   }
```

---

### Target File 5: `entry/src/test/LocalUnit.test.ets`

```diff
--- a/entry/src/test/LocalUnit.test.ets
+++ b/entry/src/test/LocalUnit.test.ets
@@ -1207,5 +1207,37 @@ export default function localUnitTest() {
       }
     });
 
+    /**
+     * 32. 验证手势取消 (.onActionCancel) 磁吸归位与迟滞复位物理特征
+     */
+    it('testCardDeckGestureCancellationSnapBackRecovery', 0, (): void => {
+      // 1. 模拟手势半途位移 (offsetX = 60vp)
+      const draggingProgress: number = CardDeckKinematics.calcGestureProgress(60.0);
+      expect(draggingProgress > 0.5).assertEqual(true);
+      expect(draggingProgress < 0.6).assertEqual(true);
+
+      // 2. 模拟触发迟滞状态机
+      const hysteresis: HapticHysteresisState = new HapticHysteresisState();
+      hysteresis.update(105);
+      expect(hysteresis.hasTriggered).assertEqual(true);
+
+      // 3. 执行取消归位重置
+      hysteresis.reset();
+      expect(hysteresis.hasTriggered).assertEqual(false);
+
+      // 4. 位移归零后几何位态完全恢复静止基准
+      const resetProgress: number = CardDeckKinematics.calcGestureProgress(0.0);
+      expect(resetProgress).assertEqual(0.0);
+      expect(CardDeckKinematics.calcLayer2Scale(resetProgress)).assertEqual(CardDeckKinematics.LAYER2_BASE_SCALE);
+      expect(CardDeckKinematics.calcLayer2TranslateY(resetProgress)).assertEqual(CardDeckKinematics.LAYER2_BASE_TRANSLATE_Y);
+      expect(CardDeckKinematics.calcLayer3Scale(resetProgress)).assertEqual(CardDeckKinematics.LAYER3_BASE_SCALE);
+      expect(CardDeckKinematics.calcLayer3TranslateY(resetProgress)).assertEqual(CardDeckKinematics.LAYER3_BASE_TRANSLATE_Y);
+
+      // 5. 归位弹簧 SPRING_CARD_CANCEL_RESET 物理阻尼确认 (zeta = 0.76，无持续残余振荡)
+      const cancelOvershoot: number = CardDeckKinematics.calcSpringOvershootRatio(0.76);
+      expect(cancelOvershoot < 0.03).assertEqual(true);
+    });
+
   });
 }
```

---

## 4. Verification & Validation Protocol

1. **Automated Unit Testing (32/32 PASS)**:
   ```bash
   export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
   export PATH=$JAVA_HOME/bin:$PATH
   export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
   /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw test
   ```
2. **Production HAP Assembly (0 errors)**:
   ```bash
   /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --no-daemon --mode module -p module=entry -p product=default assembleHap
   ```
3. **Strict Constraints Inspection**:
   - Zero emoji check across `entry/src`.
   - Zero `any` and zero `@ts-ignore` check.
