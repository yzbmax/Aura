/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Global Undo Floating Micro-Capsule Component (Deep Frosted Glass & Spring Bounce)
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { CurveConstants } from '../common/constants/CurveConstants';
import { HapticService } from '../common/media/HapticService';
import { UndoService } from '../common/utils/UndoService';

@ComponentV2
export struct GlobalUndoCapsule {
  @Local undoService: UndoService = UndoService.getInstance();
  @Local private progressPercent: number = 100;
  @Local private progressTimer: number = -1;

  @Monitor('undoService.isVisible')
  onVisibleChanged(): void {
    if (this.undoService.isVisible) {
      this.progressPercent = 100;
      if (this.progressTimer !== -1) {
        clearInterval(this.progressTimer);
      }
      const startTime = Date.now();
      const totalDuration = 5000;
      this.progressTimer = setInterval(() => {
        const elapsed = Date.now() - startTime;
        const remaining = Math.max(0, 100 - (elapsed / totalDuration) * 100);
        this.progressPercent = remaining;
        if (remaining <= 0 && this.progressTimer !== -1) {
          clearInterval(this.progressTimer);
          this.progressTimer = -1;
        }
      }, 50);
    } else {
      if (this.progressTimer !== -1) {
        clearInterval(this.progressTimer);
        this.progressTimer = -1;
      }
    }
  }

  build() {
    if (this.undoService.isVisible) {
      Stack({ alignContent: Alignment.BottomStart }) {
        Row({ space: 10 }) {
          Image($r('app.media.ic_sparkle'))
            .width(14)
            .height(14)
            .fillColor(ColorConstants.ACCENT_CORAL)

          Text(this.undoService.message)
            .fontSize(13)
            .fontColor(Color.White)
            .letterSpacing(0.2)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)

          Button({ type: ButtonType.Normal }) {
            Text('撤销')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorConstants.ACCENT_CORAL)
              .letterSpacing(0.3)
          }
          .backgroundColor('rgba(232, 122, 100, 0.12)')
          .borderRadius(14)
          .height(28)
          .padding({ left: 10, right: 10 })
          .onClick(() => {
            HapticService.getInstance().triggerClick();
            this.undoService.executeUndo();
          })
        }
        .width('100%')
        .height(44)
        .padding({ left: 14, right: 10 })

        // 底部 1.5vp 均匀消融倒计时微导轨
        Row()
          .width(`${this.progressPercent}%`)
          .height(2)
          .backgroundColor(ColorConstants.ACCENT_CORAL)
          .opacity(0.8)
          .borderRadius(1)
      }
      .width('88%')
      .height(44)
      .borderRadius(22)
      .clip(true)
      .backgroundColor('rgba(36, 32, 29, 0.85)')
      .backgroundBlurStyle(BlurStyle.Regular, { colorMode: ThemeColorMode.DARK, adaptiveColor: AdaptiveColor.DEFAULT })
      .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.18)' })
      .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.35)', offsetY: 6 })
      .position({ x: '6%', y: '80%' })
      .zIndex(999)
      .transition(
        TransitionEffect.asymmetric(
          TransitionEffect.move(TransitionEdge.BOTTOM)
            .combine(TransitionEffect.OPACITY)
            .combine(TransitionEffect.scale({ x: 0.88, y: 0.88 })),
          TransitionEffect.move(TransitionEdge.BOTTOM)
            .combine(TransitionEffect.OPACITY)
        ).animation({ curve: CurveConstants.SPRING_UNDO_BOUNCE })
      )
    }
  }
}
