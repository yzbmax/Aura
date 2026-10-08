# BRIEFING — 2026-09-22T08:44:40Z

## Mission
Investigate current UI architecture, views, components, timestamps, animations, and sound/haptics in Aura, and propose the UI architecture for "Now Only" Single-Thread stage refactoring.

## 🔒 My Identity
- Archetype: Teamwork explorer (UI & Interaction Explorer)
- Roles: UI/UX Architecture Analysis, Animation & Interaction Survey, ArkUI V2 Transition Planning
- Working directory: /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/explorer_survey_2
- Original parent: 91a055fa-ed83-4e5f-987b-510453b6ad9d
- Milestone: Explorer Phase - UI & Interaction Survey Completed

## 🔒 Key Constraints
- Read-only investigation — do NOT implement or modify source code
- Strictly write only within assigned working directory: /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/explorer_survey_2
- Follow HarmonyOS ArkTS/ArkUI V2 rules and Ponytail simplicity principles

## Current Parent
- Conversation ID: 91a055fa-ed83-4e5f-987b-510453b6ad9d
- Updated: 2026-09-22T08:44:40Z

## Investigation State
- **Explored paths**:
  - `entry/src/main/ets/views/TodayFlowView.ets`
  - `entry/src/main/ets/components/FlowSpineAxis.ets`
  - `entry/src/main/ets/components/MistMorphingCard.ets`
  - `entry/src/main/ets/components/CushionCard.ets`
  - `entry/src/main/ets/components/WeekCalendarBar.ets`
  - `entry/src/main/ets/components/ParkingLotInputBar.ets`
  - `entry/src/main/ets/components/FloatingDeckDrawer.ets`
  - `entry/src/main/ets/components/HdsFloatingDock.ets`
  - `entry/src/main/ets/components/GlobalUndoCapsule.ets`
  - `entry/src/main/ets/views/FocusImmersionPage.ets`
  - `entry/src/main/ets/views/SunsetCeremonyPage.ets`
  - `entry/src/main/ets/pages/Index.ets`
  - `entry/src/main/ets/common/media/AudioService.ets`
  - `entry/src/main/ets/common/media/HapticService.ets`
  - `entry/src/main/ets/common/constants/CurveConstants.ets`
  - `entry/src/main/ets/common/utils/LiquidGlassHelper.ets`
  - `entry/src/main/ets/models/TodoItem.ets`
- **Key findings**:
  - `TodayFlowView` is heavily bound to `BinPackingScheduler` and `timelineSlots: TimeSlot[]`, rendering `FlowSpineAxis`.
  - `FlowSpineAxis` contains 42vp left time scale (`formatTime(scheduledStartAt)`), 28vp vertical axis nodes, `CushionCard`, and Live Now indicator red line. All must be decommissioned.
  - `MistMorphingCard` only implements touch down/move/up squash-stretch using `LiquidGlassState`, lacking horizontal `PanGesture` swipe mechanics.
  - `AudioService` has 4-step chord ladder (`playChordStep`), and `HapticService` has 35ms/18ms/70ms vibration profiles ready to hook into card swipe/complete.
  - Complete architecture designed: central `NowActionStageCard`, bottom layered `NextPeekCard` (12~16vp peek), spring physics snap, 36vp `ParkingLotInputBar`, and collapsible `QueueDrawer`.
- **Unexplored areas**: None within UI scope.

## Key Decisions Made
- Decommission `FlowSpineAxis` and `CushionCard` from today's flow.
- Extract `getTaskVisual` helper into a shared file to avoid breaking imports in `MistMorphingCard` / `FloatingDeckDrawer`.
- Map horizontal swipe: right-swipe = complete with C4-E4-G4-C5 chord + 35ms haptic + undo capsule; left-swipe = skip/re-queue with 18ms tick.
- Restrict max card width to 520vp for wide-screen / foldable / tablet ergonomics.

## Artifact Index
- DISPATCH.md — incoming dispatch instructions
- progress.md — task liveness and progress heartbeat
- ui_interaction_survey.md — final comprehensive survey report (7.5KB)
- handoff.md — 5-component handoff report
