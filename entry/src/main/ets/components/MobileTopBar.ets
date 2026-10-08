/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Mobile Immersive Microcrystal Top Bar with Circular Brain Dial
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { TimeUtils } from '../common/utils/TimeUtils';

@ComponentV2
export struct MobileTopBar {
  @Param scheduledMinutes: number = 0;
  @Param maxDeepWorkMinutes: number = 270;
  @Param title: string = 'Aura · 今日心流';
  @Event onSettingClick: () => void = () => {};

  build() {
    Row() {
      // 1. 左侧品牌微晶徽标与标题
      Row({ space: 8 }) {
        Stack() {
          Circle({ width: 28, height: 28 })
            .fill(ColorConstants.ACCENT_CORAL_SOFT)
          Text('A')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorConstants.ACCENT_CORAL)
        }
        .width(28)
        .height(28)

        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
          .letterSpacing(0.3)
      }

      Blank()

      // 2. 右侧脑力负荷微晶罗盘胶囊
      Row({ space: 6 }) {
        Stack() {
          Circle({ width: 14, height: 14 })
            .stroke('rgba(232, 122, 100, 0.25)')
            .strokeWidth(2)
            .fill(Color.Transparent)

          Circle({ width: 6, height: 6 })
            .fill(ColorConstants.ACCENT_CORAL)
        }
        .width(14)
        .height(14)

        Text(`${TimeUtils.formatDurationHours(this.scheduledMinutes)} / ${TimeUtils.formatDurationHours(this.maxDeepWorkMinutes)}`)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(ColorConstants.ACCENT_CORAL)
          .letterSpacing(0.2)
      }
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .borderRadius(14)
      .backgroundColor(ColorConstants.ACCENT_CORAL_SOFT)
      .border({ width: 0.5, color: 'rgba(232, 122, 100, 0.25)' })
      .onClick(() => {
        this.onSettingClick();
      })
    }
    .width('100%')
    .height(52)
    .padding({ left: 20, right: 20 })
    .backgroundColor('rgba(247, 245, 240, 0.78)')
    .backgroundBlurStyle(BlurStyle.Thin)
    .border({ width: { bottom: 0.5 }, color: 'rgba(85, 70, 50, 0.06)' })
    .zIndex(10)
  }
}
