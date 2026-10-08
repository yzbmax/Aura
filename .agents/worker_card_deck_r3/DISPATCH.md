## 2026-09-23T01:48:42Z
You are the Implementation Worker for Milestone M1 Iteration 3 (Parallax Card Deck Bottom Exposure Invariance).
Your working directory is: /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/worker_card_deck_r3

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

MANDATORY: You MUST read the authoritative user request at /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/ORIGINAL_REQUEST.md before starting work (specifically the section under ## 2026-09-23T01:11:35Z).

Also read:
- /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/orchestrator_card_deck/PROJECT.md
- /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/orchestrator_card_deck/handoff.md
- /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/challenger_card_deck_2_r2/handoff.md (detailed derivation of F-CH2-01)

Owned files:
- entry/src/main/ets/components/NextPeekCard.ets
- entry/src/test/LocalUnit.test.ets
- entry/src/main/ets/components/CardDeckKinematics.ets

Task Scope:
1. Fix Defect F-CH2-01 in entry/src/main/ets/components/NextPeekCard.ets:
   - In NextPeekCard.ets, change the scale anchor from centerY: '0%' to bottom anchor centerY: '100%':
     .scale({ x: this.calcLayer2Scale(), y: this.calcLayer2Scale(), centerX: '50%', centerY: '100%' })
     and
     .scale({ x: this.calcLayer3Scale(), y: this.calcLayer3Scale(), centerX: '50%', centerY: '100%' })
     (or if preferred, scale only horizontally .scale({ x: this.calcLayer2Scale(), y: 1.0, centerX: '50%' })).
   - Ensure that bottom peek exposure of Layer 2 (22vp) and Layer 3 (16vp below Layer 2) is strictly invariant across ANY card height H in [100vp, 600vp], so that long cards (multiline titles, subtasks) NEVER occlude Layer 2 or Layer 3.
2. Add Unit Test #35 in entry/src/test/LocalUnit.test.ets:
   - Add testCardDeckBottomExposureHeightInvariance: test card heights 120vp, 240vp, 360vp, 480vp under bottom-anchored scaling, and assert that the exposed bottom margin is strictly positive and invariant to H, ensuring zero occlusion.
3. Verification & Governance:
   - Run tests:
     export JAVA_HOME=/Applications/DevEco-Studio.app/Contents/jbr/Contents/Home
     export PATH=$JAVA_HOME/bin:$PATH
     export DEVECO_SDK_HOME=/Applications/DevEco-Studio.app/Contents/sdk
     /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw test
     Verify 35/35 PASS (100%).
   - Run HAP assemble:
     /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --no-daemon --mode module -p module=entry -p product=default assembleHap
     /Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw --no-daemon --mode module -p module=entry@ohosTest -p product=default assembleHap
     Ensure BUILD SUCCESSFUL with 0 errors.
   - Strict 0 Emoji across entire codebase.
   - Strict 0 `any` and 0 `@ts-ignore`.
4. Write handoff report to /Users/qiuhaiqin/DevEcoStudioProjects/Aura/.agents/worker_card_deck_r3/handoff.md and report back via send_message.
