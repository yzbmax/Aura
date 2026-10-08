/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * ParallaxCardDeck: 3D Tiered Visual Stack with Real-time Gestural Dynamics
 * ArkUI V2 Component adhering strictly to R1, R2, R3, R4
 */

import { TodoItem } from '../models/TodoItem';
import { NowActionCard } from './NowActionCard';
import { NextPeekCard } from './NextPeekCard';

@ComponentV2
export struct ParallaxCardDeck {
  @Param activeTask: TodoItem | null = null;
  @Param nextTask: TodoItem | null = null;
  @Param thirdTask: TodoItem | null = null;

  @Event onComplete: () => void = () => {};
  @Event onSkip: () => void = () => {};
  @Event onOpenFocus: (item: TodoItem) => void = () => {};

  @Local private gestureProgress: number = 0.0;
  @Local private activeCardHeight: number = 240;

  build() {
    if (this.activeTask) {
      Stack({ alignContent: Alignment.Top }) {
        // 底部拟物微露 2 层卡片堆叠 (Layer 2 & Layer 3)
        NextPeekCard({
          item: this.nextTask,
          secondItem: this.thirdTask,
          isVisible: this.nextTask !== null,
          activeCardHeight: this.activeCardHeight,
          gestureProgress: this.gestureProgress
        })

        // 屏幕中央独占当前唯一微动作卡片 (Layer 1 · 手势物理主控)
        NowActionCard({
          item: this.activeTask,
          onHeightChange: (h: number) => {
            this.activeCardHeight = h;
          },
          onGestureProgressChange: (progress: number) => {
            this.gestureProgress = progress;
          },
          onComplete: () => {
            this.onComplete();
          },
          onSkip: () => {
            this.onSkip();
          },
          onOpenFocus: (item: TodoItem) => {
            this.onOpenFocus(item);
          }
        })
      }
      .width('100%')
      .constraintSize({ maxWidth: 520 })
      .height(this.activeCardHeight + 50)
      .margin({ top: 12, bottom: 20 })
    }
  }
}
