/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Streak Freeze & Anti-Guilt Revival Card (Apple-style Frosted Acrylic)
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { CurveConstants } from '../common/constants/CurveConstants';
import { HapticService } from '../common/media/HapticService';
import { AudioService } from '../common/media/AudioService';

@ComponentV2
export struct StreakFreezeRevivalCard {
  @Param streakDays: number = 7;
  @Param frozenTaskCount: number = 0;
  @Event onIgnite: () => void = () => {};

  build() {
    Column({ space: 12 }) {
      // 顶部护盾胶囊与状态标题
      Row({ space: 8 }) {
        Stack() {
          Circle({ width: 32, height: 32 })
            .fill('rgba(110, 140, 160, 0.15)')
          Image($r('app.media.ic_shield'))
            .width(16)
            .height(16)
            .fillColor(ColorConstants.FROZEN_CRYSTAL)
        }

        Column({ space: 2 }) {
          Row({ space: 6 }) {
            Text(`连续同频 ${this.streakDays} 天 · 节律护盾已生效`)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
              .letterSpacing(0.2)

            Image($r('app.media.ic_flame'))
              .width(13)
              .height(13)
              .fillColor(ColorConstants.ACCENT_CORAL)
          }

          Text('休息是节律呼吸的自然留白，而非中断')
            .fontSize(11)
            .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
            .letterSpacing(0.2)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')

      // 护盾保护详情说明
      Row({ space: 10 }) {
        Column({ space: 4 }) {
          Text('护盾自动守护')
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorConstants.LIGHT_TEXT_SECONDARY)
            .letterSpacing(0.2)
          Text(this.frozenTaskCount > 0
            ? `已将 ${this.frozenTaskCount} 项逾期待办温和收纳至「冷冻舱」，告别满屏逾期红点`
            : '你的专注历史与连续成就已被安全冻结保护，随时轻松无感续接')
            .fontSize(12)
            .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
            .lineHeight(18)
            .letterSpacing(0.2)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding(10)
      .borderRadius(12)
      .backgroundColor('rgba(255, 255, 255, 0.6)')

      // 底部低压点亮唤醒按钮 (Apple-grade 微晶按钮 + 物理触感反馈)
      Button({ type: ButtonType.Normal }) {
        Row({ space: 6 }) {
          Image($r('app.media.ic_sparkle'))
            .width(14)
            .height(14)
            .fillColor(Color.White)
          Text('点亮今日心流')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .letterSpacing(0.4)
        }
        .width('100%')
        .height(38)
        .justifyContent(FlexAlign.Center)
      }
      .width('100%')
      .borderRadius(14)
      .backgroundColor(ColorConstants.ACCENT_CORAL)
      .shadow({ radius: 8, color: 'rgba(217, 107, 78, 0.25)', offsetY: 2 })
      .onClick(() => {
        HapticService.getInstance().triggerClick();
        AudioService.getInstance().playChordStep();
        this.onIgnite();
      })
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor('rgba(255, 255, 255, 0.88)')
    .backgroundBlurStyle(BlurStyle.Regular)
    .border({ width: 0.5, color: 'rgba(110, 140, 160, 0.25)' })
    .shadow({ radius: 16, color: 'rgba(85, 70, 50, 0.05)', offsetY: 4 })
    .transition(TransitionEffect.OPACITY.combine(TransitionEffect.scale({ x: 0.95, y: 0.95 })).animation({ curve: CurveConstants.SPRING_REVIVAL_EXPAND }))
  }
}
