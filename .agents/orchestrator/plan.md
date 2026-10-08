# Plan: Aura Product & UI/UX Experience Audit & Design Quality Inspection

## Objective
Lead and orchestrate a full-link, world-class, professional and rigorous product & UI/UX experience audit and design quality inspection for 'Aura · 同频' (HarmonyOS NEXT adaptive timebox & anti-guilt to-do manager), fulfilling R1-R5 with depth, honesty, and tactical redesign specifications.

## Planned Execution Steps

### Step 1: Initialization & Workgroup Setup
- Initialize BRIEFING.md, DISPATCH.md, plan.md, progress.md.
- Start recurring heartbeat cron.
- Establish subagent working directories under `.agents/`.

### Step 2: Parallel Deep Audits (3 Specialized Explorers)
- **Explorer 1 (benchmark_explorer)**: Target R1.
  - Deep benchmarking of Sunsama, Things 3, Cron/Notion Calendar, Motion, Endel, Opal/Forest, Linear.
  - Deconstruct killer UX patterns, micro-interactions, anti-patterns, and localization/adaptation to HarmonyOS NEXT.
  - Working directory: `.agents/benchmark_explorer/`
- **Explorer 2 (psychology_algo_explorer)**: Target R2 & R4.
  - Investigate Aura PRD, TODO.md, core logic, <=4.5h bin packing algorithm, anti-guilt copy & psychology, 5-min icebreaker, stray thought parking lot, sunset ceremony.
  - Uncover loss of agency / learned helplessness, guilt backfire, motivation drop-offs across day-long journey, edge case failure modes (consecutive delays, multi-day ghost backlog).
  - Working directory: `.agents/psychology_algo_explorer/`
- **Explorer 3 (ui_ux_sensory_explorer)**: Target R3 & R4.
  - Codebase inspection in `entry/src/main/ets/` (TodayFlowView, MistMorphingCard, ParkingLotInputBar, TaskMatrixView, FocusImmersionPage, SunsetCeremonyPage, soundPool, vibrator, responsive breakpoints, dark mode WCAG AA).
  - Nielsen heuristics & HarmonyOS design guidelines check; performance/rendering checks (3.5s micro-pulse, morphing jank, haptic fatigue, undo missing).
  - Working directory: `.agents/ui_ux_sensory_explorer/`

### Step 3: Synthesis, Adversarial Verification & Defect Cataloging (R4 & R5)
- Spawn **teamwork_preview_reviewer / critic** to review findings against code realities, stress-test proposed solutions, and ensure >=12 deep genuine defects.
- Synthesize all findings into structured defect cards with:
  1. Scenario & exact component/logic location
  2. Defect Type (UX Break / Cognitive Overload / Sensory Noise / Logic Flaw)
  3. Severity (Critical / High / Medium)
  4. Negative psychological impact & violated design principles
  5. Benchmark contrast & proven pattern
  6. Actionable tactical ArkTS/ArkUI V2 redesign solution & micro-copy

### Step 4: Master Deliverables & Prioritized Roadmap Generation
- Produce master comprehensive audit document.
- Prioritize P0 (Core stop-the-bleeding), P1 (Flow deepening), P2 (Ecosystem polish).
- Validate ArkTS/ArkUI V2 & Local-First feasibility without redundant dependencies.

### Step 5: Final Report to Sentinel / Parent
- Send comprehensive synthesis via `send_message` to parent agent.
- Provide clean human-readable executive summary.
