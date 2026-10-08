/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Next Peek Card: Multi-tier 3D Physical Card Deck / Layered Stack
 * Real physical deck visibly peeking out underneath active task with gestural dynamics
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { TodoItem } from '../models/TodoItem';
import { getTaskVisual } from './TaskVisualHelper';
import { CardDeckKinematics } from './CardDeckKinematics';

@ComponentV2
export struct NextPeekCard {
  @Param item: TodoItem | null = null;
  @Param secondItem: TodoItem | null = null;
  @Param isVisible: boolean = true;
  @Param activeCardHeight: number = 240;
  @Param gestureProgress: number = 0.0;

  private getEffectiveHeight(): number {
    return this.activeCardHeight > 80 ? this.activeCardHeight : 240;
  }

  build() {
    if (this.isVisible && this.item) {
      Stack({ alignContent: Alignment.Top }) {
        // 1. 底层卡片 Layer 3 (队列第 3 项，90% 宽度，下沉 38vp -> 22vp)
        if (this.secondItem) {
          Stack({ alignContent: Alignment.Bottom }) {
            // 底部外露边缘 (16vp 宽带)
            Row({ space: 8 }) {
              Circle({ width: 5, height: 5 })
                .fill(getTaskVisual(this.secondItem).color)
                .opacity(0.85)

              Text(`后续 · ${this.secondItem.title}`)
                .fontSize(11)
                .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .layoutWeight(1)

              Text(`${this.secondItem.estimatedMinutes}m`)
                .fontSize(10)
                .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
            }
            .width('100%')
            .height(18)
            .padding({ left: 16, right: 16, bottom: 2 })
          }
          .width('90%')
          .height(this.getEffectiveHeight())
          .borderRadius(24)
          .backgroundColor('rgba(242, 237, 228, 0.95)')
          .border({ width: 1, color: 'rgba(85, 70, 50, 0.08)' })
          .shadow({
            radius: CardDeckKinematics.calcShadowRadius(8, 6, this.gestureProgress),
            color: 'rgba(85, 70, 50, 0.05)',
            offsetY: CardDeckKinematics.calcShadowOffsetY(2, 2, this.gestureProgress)
          })
          .translate({ y: CardDeckKinematics.calcLayer3TranslateY(this.gestureProgress, 38.0, 22.0) })
          .scale({
            x: CardDeckKinematics.calcLayer3Scale(this.gestureProgress),
            y: CardDeckKinematics.calcLayer3Scale(this.gestureProgress),
            centerX: '50%',
            centerY: '100%'
          })
          .opacity(CardDeckKinematics.calcLayer3Opacity(this.gestureProgress))
          .zIndex(1)
        }

        // 2. 次层卡片 Layer 2 (队列第 2 项，95% 宽度，下沉 22vp -> 0vp，外露 20~24vp)
        Stack({ alignContent: Alignment.Bottom }) {
          // 底部外露 24vp 拟物操作条 (带分类色彩、指示标签、微标题与耗时)
          Row({ space: 8 }) {
            // 分类色彩微圆点
            Circle({ width: 7, height: 7 })
              .fill(getTaskVisual(this.item).color)

            // 下一项指示微标
            Text('下一项')
              .fontSize(11)
              .fontWeight(FontWeight.Bold)
              .fontColor(getTaskVisual(this.item).color)

            // 任务标题极简预览
            Text(this.item.title)
              .fontSize(12)
              .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)

            // 预估时长微晶胶囊
            Text(`${this.item.estimatedMinutes}m`)
              .fontSize(11)
              .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
              .padding({ left: 6, right: 6, top: 2, bottom: 2 })
              .borderRadius(6)
              .backgroundColor('rgba(85, 70, 50, 0.06)')
          }
          .width('100%')
          .height(24)
          .padding({ left: 18, right: 18, bottom: 3 })
          .backgroundColor(getTaskVisual(this.item).softColor)
          .borderRadius({ bottomLeft: 24, bottomRight: 24 })
          .opacity(CardDeckKinematics.calcLayer2PeekBarOpacity(this.gestureProgress))
        }
        .width('95%')
        .height(this.getEffectiveHeight())
        .borderRadius(24)
        .backgroundColor(ColorConstants.LIGHT_CARD_BG)
        .border({ width: 1, color: 'rgba(255, 255, 255, 0.95)' })
        .shadow({
          radius: CardDeckKinematics.calcShadowRadius(14, 10, this.gestureProgress),
          color: 'rgba(85, 70, 50, 0.08)',
          offsetY: CardDeckKinematics.calcShadowOffsetY(4, 4, this.gestureProgress)
        })
        .translate({ y: CardDeckKinematics.calcLayer2TranslateY(this.gestureProgress, 22.0) })
        .scale({
          x: CardDeckKinematics.calcLayer2Scale(this.gestureProgress),
          y: CardDeckKinematics.calcLayer2Scale(this.gestureProgress),
          centerX: '50%',
          centerY: '100%'
        })
        .zIndex(2)
      }
      .width('100%')
      .constraintSize({ maxWidth: 520 })
      .height(this.getEffectiveHeight() + 50)
    }
  }
}
