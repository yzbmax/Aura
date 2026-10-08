# Plan: "Now Only" Single-Thread Minimal Flow Refactoring

## Objectives
1. Decouple and eliminate the schedule-based time blocking paradigm (BinPackingScheduler, TimeSlot, HH:mm timelines, rigid start/end slotting).
2. Implement `SingleThreadFlowEngine`: non-time-pressured queue, pushing/stepping flow, gentle aging, and guilt-free cryo-chamber handling.
3. Redesign `TodayFlowView` into the "Now Only" stage:
   - Central microcrystalline card displaying exclusively the current micro-action.
   - Physical bottom layered card peeking 12~16vp for the "Next" action.
   - Smooth spring physics snap on task completion / skip with chord audio cues.
4. Upgrade 36vp ParkingLotInputBar to park thoughts into the flexible queue in seconds without breaking immersion. Add lightweight collapsable drawer for sequence inspection (collapsed by default).
5. Sunset ceremony refactoring: focus on today's micro-flow trajectory without guilt.
6. ArkTS V2 strict compliance (@ComponentV2, @ObservedV2, @Trace, no any, local-first, zero sensitive permissions).
7. Full automated test suite passing and 100% forensic integrity audit pass.

## Step-by-Step Execution Plan
1. **Survey (Phase 0)**:
   - Dispatch 3 Explorers in parallel to inspect:
     - Domain & Scheduling: Current `BinPackingScheduler`, `TimeSlot`, `TaskItem`, dependencies.
     - Presentation & UI: Current `TodayFlowView`, `FlowSpineAxis`, `MistMorphingCard`, gestures, animations.
     - Persistence & Tests: Preferences / relational storage, `ParkingLotInputBar`, `SunsetCeremonyPage`, existing unit tests and mock harnesses.
2. **Architecture & Decomposition (Phase 1)**:
   - Synthesize survey findings into `PROJECT.md` and `TEST_INFRA.md`.
   - Freeze interface contracts for `SingleThreadFlowEngine`.
3. **Execution Dual Track (Phases 2-4)**:
   - Milestone 1: Engine & Domain (SingleThreadFlowEngine, task model decoupling).
   - Milestone 2: UI Main Stage & Physical Card Stacking.
   - Milestone 3: ParkingLot, Queue Drawer, Sunset Flow.
4. **Verification & Forensic Audit (Phase 5)**:
   - Run unit tests & E2E tests across all tiers.
   - Adversarial verification (Challengers).
   - Independent Forensic Integrity Audit (teamwork_preview_auditor).
5. **Final Review & Sentinel Handoff (Phase 6)**.
