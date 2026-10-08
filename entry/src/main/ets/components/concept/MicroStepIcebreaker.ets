/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Micro-Step Somatosensory Icebreaker: Non-Linear Spring Damped Fidget Chamber
 * Based on Zeigarnik Effect & ADHD De-freezing (Sub-2-Minute Physical Micro-Action)
 */

import { ColorConstants } from '../../common/constants/ColorConstants';
import { HapticService } from '../../common/media/HapticService';

@ComponentV2
export struct MicroStepIcebreaker {
  @Param taskTitle: string = '核心攻坚';
  @Event onIcebroken: () => void = () => {};
  @Event onSkip: () => void = () => {};

  @Local private dragOffsetY: number = 0;
  @Local private isThresholdReached: boolean = false;
  @Local private springScale: number = 1.0;

  // 非线性弹簧阻尼动力学方程: y = MaxLimit * (1 - e^(-dy / ElasticConstant))
  private calculateDampedOffset(dy: number): number {
    const maxLimit = 160;
    const elasticConstant = 140;
    if (dy <= 0) {
      return dy * 0.15; // 向上反向极大阻抗
    }
    return maxLimit * (1 - Math.exp(-dy / elasticConstant));
  }

  build() {
    Column({ space: 18 }) {
      // 1. 破冰提示语
      Column({ space: 6 }) {
        Text('觉得沉重？先做第一颗螺丝钉')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)

        Text('下拉把玩石，敲下前三个字即可破冰')
          .fontSize(12)
          .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 12 })

      // 2. 拟真把玩陶石 (非线性物理动力学下拉)
      Stack({ alignContent: Alignment.Center }) {
        // 外围发光光圈
        Circle({ width: 96, height: 96 })
          .fill(this.isThresholdReached ? ColorConstants.ACCENT_CORAL_SOFT : 'rgba(85, 70, 50, 0.05)')

        // 粗陶触觉卵石
        Circle({ width: 78, height: 78 })
          .fill(ColorConstants.LIGHT_CARD_BG)
          .stroke(this.isThresholdReached ? ColorConstants.ACCENT_CORAL : ColorConstants.LIGHT_CARD_BORDER)
          .strokeWidth(this.isThresholdReached ? 2 : 1)
          .shadow({
            radius: 18,
            color: this.isThresholdReached ? ColorConstants.ACCENT_CORAL_SOFT : 'rgba(85, 70, 50, 0.08)',
            offsetY: 4
          })

        Column({ space: 2 }) {
          Image($r('app.media.ic_sparkle'))
            .width(18)
            .height(18)
            .fillColor(this.isThresholdReached ? ColorConstants.ACCENT_CORAL : ColorConstants.LIGHT_TEXT_SECONDARY)

          Text(this.isThresholdReached ? '松手破冰' : '下拉蓄力')
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.isThresholdReached ? ColorConstants.ACCENT_CORAL : ColorConstants.LIGHT_TEXT_TERTIARY)
        }
      }
      .scale({ x: this.springScale, y: this.springScale })
      .translate({ y: this.dragOffsetY })
      .gesture(
        PanGesture({ direction: PanDirection.Vertical })
          .onActionUpdate((event: GestureEvent) => {
            this.dragOffsetY = this.calculateDampedOffset(event.offsetY);
            this.springScale = 1.0 + (this.dragOffsetY / 800);

            // 越过 85vp 阈值时触发 170Hz 齿轮棘轮触感
            if (this.dragOffsetY > 85 && !this.isThresholdReached) {
              this.isThresholdReached = true;
              HapticService.getInstance().triggerClick();
            } else if (this.dragOffsetY <= 85 && this.isThresholdReached) {
              this.isThresholdReached = false;
            }
          })
          .onActionEnd(() => {
            if (this.isThresholdReached) {
              // 破冰成功，触发蔡加尼克自主动量
              HapticService.getInstance().triggerHeavy();
              this.onIcebroken();
            }
            animateTo({ curve: Curve.FastOutSlowIn }, () => {
              this.dragOffsetY = 0;
              this.springScale = 1.0;
              this.isThresholdReached = false;
            });
          })
      )
      .margin({ top: 16, bottom: 20 })

      // 3. 极简跳过直接专注
      Button('直接开始深度专注 ›')
        .fontSize(12)
        .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
        .backgroundColor(Color.Transparent)
        .height(32)
        .onClick(() => {
          this.onSkip();
        })
    }
    .width('100%')
    .padding(20)
    .borderRadius(22)
    .backgroundColor(ColorConstants.LIGHT_CARD_BG)
    .border({ width: 0.5, color: ColorConstants.LIGHT_CARD_BORDER })
    .shadow({ radius: 16, color: 'rgba(85, 70, 50, 0.06)', offsetY: 4 })
  }
}
