/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Minimalist Spacer Guide with 0.8Hz Breathing Pulse (Anti-Overcrowding)
 */

import { ColorConstants } from '../common/constants/ColorConstants';
import { CurveConstants } from '../common/constants/CurveConstants';
import { TimeUtils } from '../common/utils/TimeUtils';
import { HapticService } from '../common/media/HapticService';

@ComponentV2
export struct CushionCard {
  @Param startMs: number = 0;
  @Param endMs: number = 0;
  @Param text: string = '留白蓄力 · 慢呼吸';

  @Local private breathingOpacity: number = 0.4;
  @Local private isBubbleHint: boolean = false;

  aboutToAppear(): void {
    // 0.8Hz (周期 2.5s，交替 1.25s) 仿生慢节律深呼吸透明度动效
    setTimeout(() => {
      this.breathingOpacity = 0.9;
    }, 50);
  }

  private get freeMinutes(): number {
    if (this.endMs > this.startMs) {
      return Math.max(15, Math.round((this.endMs - this.startMs) / 60000));
    }
    return 15;
  }

  private formatFreeTimeText(): string {
    const m = this.freeMinutes;
    if (m < 60) {
      return `${m}m 留白蓄力`;
    }
    const h = Math.floor(m / 60);
    const rem = m % 60;
    if (rem === 0) {
      return `${h}h 留白蓄力`;
    }
    return `${h}h ${rem}m 留白蓄力`;
  }

  build() {
    Row({ space: 8 }) {
      // 1. 左侧 42vp 时间刻度标尺 (留白带保持呼吸纯净，不堆叠重复时间)
      Column()
        .width(42)

      // 2. 纵向轴线贯通 + 0.8Hz 慢节律呼吸光晕点
      Stack({ alignContent: Alignment.Center }) {
        Line()
          .width(2.0)
          .height(28)
          .backgroundColor('rgba(36, 32, 29, 0.20)')

        // 呼吸外晕
        Circle({ width: 14, height: 14 })
          .fill(ColorConstants.BLOCK_SAGE_SOFT)
          .opacity(this.breathingOpacity)
          .animation({
            duration: 1250,
            curve: CurveConstants.CURVE_BREATHING,
            iterations: -1,
            playMode: PlayMode.Alternate
          })

        // 核心实心微晶点
        Circle({ width: 6, height: 6 })
          .fill('#2F5E34')
      }
      .width(28)
      .height(28)

      // 3. 纯净自然留白微注 (无底色卡片，消解斑马线横条压迫感)
      Row({ space: 5 }) {
        Image($r('app.media.ic_sprout'))
          .width(12)
          .height(12)
          .fillColor('#2F5E34')
          .opacity(1.0)

        Text(this.formatFreeTimeText())
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#2F5E34')
          .letterSpacing(0.2)

        Text(this.isBubbleHint ? '· 放空沉淀' : '· 留白透气')
          .fontSize(11)
          .fontColor('#5E564F')
          .fontWeight(FontWeight.Normal)
          .letterSpacing(0.2)
      }
      .height(22)
      .padding({ left: 4 })
      .layoutWeight(1)
      .onClick(() => {
        HapticService.getInstance().triggerTick();
        this.isBubbleHint = !this.isBubbleHint;
      })
    }
    .width('100%')
    .height(28)
    .alignItems(VerticalAlign.Center)
    .margin({ top: 2, bottom: 2 })
  }
}
