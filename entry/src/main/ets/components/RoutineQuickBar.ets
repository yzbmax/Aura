/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Routine Quick Action Bubbles (Structured Style Habit Circles)
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { Priority } from '../models/TodoItem';
import { HapticService } from '../common/media/HapticService';

export interface RoutineBubbleItem {
  id: string;
  name: string;
  durationMinutes: number;
  priority: Priority;
  color: string;
  softColor: string;
  icon: Resource;
}

@ComponentV2
export struct RoutineQuickBar {
  @Event onAddRoutine: (title: string, minutes: number, priority: Priority) => void = () => {};

  private bubbles: RoutineBubbleItem[] = [
    {
      id: 'routine_morning',
      name: '晨间唤醒',
      durationMinutes: 30,
      priority: Priority.MEDIUM,
      color: ColorConstants.ACCENT_CORAL,
      softColor: ColorConstants.ACCENT_CORAL_SOFT,
      icon: $r('app.media.ic_sparkle')
    },
    {
      id: 'routine_focus',
      name: '核心攻坚',
      durationMinutes: 45,
      priority: Priority.HIGH,
      color: ColorConstants.BLOCK_DENIM_BLUE,
      softColor: ColorConstants.BLOCK_DENIM_SOFT,
      icon: $r('app.media.ic_bolt')
    },
    {
      id: 'routine_break',
      name: '茶歇补水',
      durationMinutes: 15,
      priority: Priority.LOW,
      color: ColorConstants.BLOCK_SAGE_GREEN,
      softColor: ColorConstants.BLOCK_SAGE_SOFT,
      icon: $r('app.media.ic_cup')
    },
    {
      id: 'routine_review',
      name: '复盘自检',
      durationMinutes: 25,
      priority: Priority.MEDIUM,
      color: ColorConstants.BLOCK_WARM_AMBER,
      softColor: ColorConstants.BLOCK_WARM_AMBER_SOFT,
      icon: $r('app.media.ic_shield')
    }
  ];

  build() {
    Row({ space: 8 }) {
      ForEach(this.bubbles, (b: RoutineBubbleItem) => {
        Row({ space: 5 }) {
          Image(b.icon)
            .width(11)
            .height(11)
            .fillColor(ColorConstants.LIGHT_TEXT_SECONDARY)
            .opacity(0.85)

          Text(b.name)
            .fontSize(11)
            .fontWeight(FontWeight.Normal)
            .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
        }
        .layoutWeight(1)
        .height(30)
        .justifyContent(FlexAlign.Center)
        .borderRadius(15)
        .backgroundColor('rgba(85, 70, 50, 0.04)')
        .border({ width: 0.5, color: 'rgba(85, 70, 50, 0.08)' })
        .onClick(() => {
          HapticService.getInstance().triggerTick();
          this.onAddRoutine(b.name, b.durationMinutes, b.priority);
        })
      })
    }
    .width('100%')
    .padding({ left: 2, right: 2 })
  }
}
