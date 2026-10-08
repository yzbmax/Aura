# Project: Aura Parallax Card Deck & Gestural Dynamics

## Architecture
- **Component Layer**: `ParallaxCardDeck.ets` (or enhanced `TodayFlowView.ets` + `NowActionCard.ets` + `NextPeekCard.ets`) in `entry/src/main/ets/view/`.
- **State Flow**: `SingleThreadFlowEngine.ets` provides the reactive task queue (`activeTask`, `peekTask`, `thirdTask`).
- **Gesture Dynamics**: PanGesture tracks `offsetX` and velocity `v_x` on the top card, emitting normalized `gestureProgress = min(1.0, |offsetX| / 110.0)` in real time to the stacked layers.
- **Visual Tier Stack (R2)**:
  - Layer 1 (Focus Card): 100% width, rotation `offsetX * 0.04`, scale 1.0, opacity `1 - 0.15 * gestureProgress`.
  - Layer 2 (Next Card): 95% width, static translateY `22vp` (exposing 22vp peek of category dot, bold badge "下一项", title preview, duration), dynamic scale `0.93 -> 1.0`, translateY `22vp -> 0vp`.
  - Layer 3 (Subsequent Card): 90% width, static translateY `38vp` (exposing 16vp microcrystalline contour), dynamic scale `0.88 -> 0.95`, translateY `38vp -> 22vp`.
  - Dynamic height adaptation: container height binds to Layer 1's actual measured height $H + 50\text{vp}$ with peeking strips anchored to bottom (`Alignment.Bottom`), ensuring no clipping.
- **Spring Overshoot & Sensory Polish (R3)**:
  - Fly-out threshold: $|offsetX| \ge 100\text{vp} \lor (|offsetX| \ge 30\text{vp} \land |v_x| \ge 650\text{vp/s})$.
  - Layer 1 fly-out: `curves.springMotion(0.30, 0.82)` translating to $\pm 520\text{vp}$ with fade-out.
  - Layer 2 overshoot bounce into focus: `curves.springMotion(0.34, 0.62)` producing ~8.35% overshoot bounce.
  - Multi-sensory feedback: haptic hysteresis (engage at 100vp, release at 75vp), right swipe triggers `AudioService.playChordStep()` and `triggerClick()`, left swipe triggers silent micro-vibration.
- **Engineering & Quality Gates (R4)**:
  - ArkTS strict typing: strictly 0 `any`, 0 `@ts-ignore`.
  - ArkUI V2 decorators: `@ComponentV2`, `@Local`, `@Param`, `@Event`.
  - Strict 0 Emoji across entire codebase.
  - 23/23 existing unit tests pass, plus new card deck unit tests pass.
  - HAP compilation: BUILD SUCCESSFUL (0 errors).

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Real-time Gestural Dynamics (R1) | Normalized gestureProgress calculation from drag displacement; continuous scaling (0.93->1.0) and vertical translation decay (22vp->0vp) of Layer 2; dynamic shadow & opacity interpolation | M1 | Survey (Explorer 2 & 1) |
| 2 | Tiered Visual Stack (R2) | Layer 1 100% centered, Layer 2 95% with 20~24vp peek (category dot, badge, title preview), Layer 3 90% with 16vp contour peek; dynamic height adaptation ($H + 50\text{vp}$) without clipping | M1 | Survey (Explorer 1) |
| 3 | Spring Overshoot & Haptics (R3) | Dual springMotion physics (flyout with curve (0.30, 0.82), Layer 2 overshoot bounce with curve (0.34, 0.62)); haptic dual-threshold hysteresis (100vp/75vp) and chord progression | M1 | Survey (Explorer 2) |
| 4 | Engineering & Test Governance (R4) | 100% pass of existing 23 unit tests + new card deck tests; HAP build 0 errors; zero Emoji enforcement; zero `any` | M1 | Survey (Explorer 3) |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Parallax Card Deck Core Implementation | Full implementation of R1, R2, R3, R4 in Aura card deck views and test suite | Survey Complete | IN_PROGRESS |

## Interface Contracts
### Gestural Dynamics ↔ Visual Stack
- `gestureProgress`: `number` (0.0 to 1.0) = `Math.min(1.0, Math.abs(offsetX) / 110.0)`
- `layer2Scale`: `0.93 + 0.07 * gestureProgress`
- `layer2TranslateY`: `22.0 * (1.0 - gestureProgress)`
- `layer3Scale`: `0.88 + 0.07 * gestureProgress` (or `0.88 + 0.05 * gestureProgress`)
- `layer3TranslateY`: `38.0 - 16.0 * gestureProgress`
- `flyOutThreshold`: `Math.abs(offsetX) >= 100 || (Math.abs(offsetX) >= 30 && Math.abs(velocityX) >= 650)`
- `overshootSpring`: `curves.springMotion(0.34, 0.62)`

## Code Layout
- `entry/src/main/ets/view/TodayFlowView.ets` — Main stage container integrating card stack
- `entry/src/main/ets/view/NowActionCard.ets` — Top focus card with PanGesture & physics callbacks
- `entry/src/main/ets/view/NextPeekCard.ets` — Tiered peek card with dynamic scale & translation
- `entry/src/main/ets/view/ParallaxCardDeck.ets` (if extracted) — Unified deck component
- `entry/src/test/LocalUnit.test.ets` — Automated unit test suite (maintaining 23/23 pass + deck tests)
