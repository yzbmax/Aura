/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Ultradian Wave Canvas: BRAC 90/20 Ultradian Rhythm Energy Flow Canvas
 * Based on Nathaniel Kleitman's Basic Rest-Activity Cycle (110m periodicity)
 */

import { ColorConstants } from '../../common/constants/ColorConstants';

export enum BRACPhase {
  AWAKENING = 'AWAKENING',         // 0~15m: 唤醒破冰
  HIGH_FLOW = 'HIGH_FLOW',         // 15~75m: 高频心流
  REFRACTORY = 'REFRACTORY',       // 75~90m: 难降减速
  RESTORATION = 'RESTORATION'      // 90~110m: 神圣补给窗
}

@ObservedV2
export class BRACState {
  @Trace public cycleProgress: number = 0; // 0.0 ~ 1.0
  @Trace public currentPhase: BRACPhase = BRACPhase.HIGH_FLOW;
  @Trace public estimatedEnergy: number = 85; // 0 ~ 100
  @Trace public isRestorationLocked: boolean = false;

  constructor() {
    this.updateByCurrentTime();
  }

  /**
   * 根据当日经过的分钟数，计算当前在 110m BRAC 循环中的相位
   */
  public updateByCurrentTime(): void {
    const now = new Date();
    const minutesSinceMidnight = now.getHours() * 60 + now.getMinutes();
    const cycleLen = 110;
    const cycleMin = minutesSinceMidnight % cycleLen;
    this.cycleProgress = cycleMin / cycleLen;

    if (cycleMin < 15) {
      this.currentPhase = BRACPhase.AWAKENING;
      this.estimatedEnergy = 50 + Math.round((cycleMin / 15) * 35); // 50 -> 85
      this.isRestorationLocked = false;
    } else if (cycleMin < 75) {
      this.currentPhase = BRACPhase.HIGH_FLOW;
      this.estimatedEnergy = 85 + Math.round(Math.sin(((cycleMin - 15) / 60) * Math.PI) * 15); // 85 -> 100 -> 85
      this.isRestorationLocked = false;
    } else if (cycleMin < 90) {
      this.currentPhase = BRACPhase.REFRACTORY;
      this.estimatedEnergy = 85 - Math.round(((cycleMin - 75) / 15) * 45); // 85 -> 40
      this.isRestorationLocked = false;
    } else {
      this.currentPhase = BRACPhase.RESTORATION;
      this.estimatedEnergy = 40 + Math.round(((cycleMin - 90) / 20) * 10); // 40 -> 50
      this.isRestorationLocked = true;
    }
  }
}

@ComponentV2
export struct UltradianWaveCanvas {
  @Param state: BRACState = new BRACState();
  @Param isPaperMode: boolean = false;
  @Param scheduledMinutes: number = 0;
  @Param maxDeepWorkMinutes: number = 270;
  @Event onOpenSunset: () => void = () => {};

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private wavePhase: number = 0;
  private timerId: number = -1;

  aboutToAppear(): void {
    if (!this.isPaperMode) {
      this.startAnimationLoop();
    }
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private startAnimationLoop(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
    }
    this.timerId = setInterval(() => {
      this.wavePhase += 0.035;
      this.state.updateByCurrentTime();
      this.drawWave();
    }, 33); // ~30fps 节能静默渲染
  }

  private drawWave(): void {
    const ctx = this.context;
    const width = ctx.width;
    const height = ctx.height;
    if (width <= 0 || height <= 0) {
      return;
    }
    ctx.clearRect(0, 0, width, height);

    const baseAmplitude = 8 * (this.state.estimatedEnergy / 100);
    const wavelength = width * 0.85;

    // 绘制双正弦叠加流体波浪
    ctx.beginPath();
    ctx.moveTo(0, height);

    for (let x = 0; x <= width; x += 4) {
      const y = height * 0.55 +
        baseAmplitude * Math.sin((x / wavelength) * 2 * Math.PI + this.wavePhase) +
        (baseAmplitude * 0.35) * Math.sin((x / (wavelength * 0.5)) * 2 * Math.PI - this.wavePhase * 0.6);
      ctx.lineTo(x, y);
    }

    ctx.lineTo(width, height);
    ctx.lineTo(0, height);
    ctx.closePath();

    // 渐变填充：神圣补给期呈暖琥珀，心流期呈柔和珊瑚橙
    const grad = ctx.createLinearGradient(0, 0, 0, height);
    if (this.state.currentPhase === BRACPhase.RESTORATION) {
      grad.addColorStop(0, 'rgba(214, 154, 86, 0.18)');
      grad.addColorStop(1, 'rgba(214, 154, 86, 0.02)');
    } else {
      grad.addColorStop(0, 'rgba(232, 122, 100, 0.16)');
      grad.addColorStop(1, 'rgba(90, 125, 154, 0.02)');
    }
    ctx.fillStyle = grad;
    ctx.fill();
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 1. 底层静默流体波浪画布
      Canvas(this.context)
        .width('100%')
        .height(44)
        .borderRadius(14)
        .backgroundColor('#FFFFFF')
        .border({ width: 0.9, color: 'rgba(36, 32, 29, 0.12)' })

      // 2. 前景克制信息行
      Row() {
        // 左侧：相位与心流负载
        Row({ space: 6 }) {
          Circle({ width: 6, height: 6 })
            .fill(this.state.currentPhase === BRACPhase.RESTORATION
              ? ColorConstants.BLOCK_WARM_AMBER
              : ColorConstants.ACCENT_CORAL)

          Text(this.getShortPhaseLabel())
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)

          Text(`${((this.scheduledMinutes || 0) / 60).toFixed(1)}h / ${((this.maxDeepWorkMinutes || 270) / 60).toFixed(1)}h`)
            .fontSize(11)
            .fontWeight(FontWeight.Normal)
            .fontColor(ColorConstants.LIGHT_TEXT_TERTIARY)
        }
        .alignItems(VerticalAlign.Center)

        Blank()

        // 右侧：留白额度与打烊动作
        Row({ space: 6 }) {
          Text(`留白 ${(Math.max(0, (this.maxDeepWorkMinutes || 270) - (this.scheduledMinutes || 0)) / 60).toFixed(1)}h`)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor(ColorConstants.BLOCK_WARM_AMBER)

          Button({ type: ButtonType.Capsule }) {
            Text('打烊 ›')
              .fontSize(10)
              .fontWeight(FontWeight.Medium)
              .fontColor(ColorConstants.LIGHT_TEXT_PRIMARY)
              .padding({ left: 7, right: 7, top: 2, bottom: 2 })
          }
          .height(20)
          .backgroundColor('rgba(36, 32, 29, 0.06)')
          .border({ width: 0.6, color: 'rgba(36, 32, 29, 0.10)' })
          .onClick(() => {
            this.onOpenSunset();
          })
        }
        .alignItems(VerticalAlign.Center)
      }
      .width('100%')
      .padding({ left: 14, right: 14 })

      // 3. 底部 1.5vp 纤细光轨
      Column() {
        Blank()
        Progress({
          value: Math.min(this.scheduledMinutes, this.maxDeepWorkMinutes),
          total: this.maxDeepWorkMinutes,
          type: ProgressType.Linear
        })
          .color(this.state.currentPhase === BRACPhase.RESTORATION
            ? ColorConstants.BLOCK_WARM_AMBER
            : ColorConstants.ACCENT_CORAL)
          .backgroundColor('rgba(0, 0, 0, 0.03)')
          .width('100%')
          .height(1.5)
      }
      .width('100%')
      .height(44)
    }
    .width('100%')
    .height(44)
    .borderRadius(14)
    .shadow({ radius: 8, color: 'rgba(40, 32, 24, 0.06)', offsetY: 1 })
    .clip(true)
  }

  private getShortPhaseLabel(): string {
    const energy = Math.round(this.state.estimatedEnergy);
    switch (this.state.currentPhase) {
      case BRACPhase.AWAKENING:
        return `晨曦破冰 · ${energy}%`;
      case BRACPhase.HIGH_FLOW:
        return `深潜心流 · ${energy}%`;
      case BRACPhase.REFRACTORY:
        return `减速整理 · ${energy}%`;
      case BRACPhase.RESTORATION:
        return `神圣补给 · ${energy}%`;
    }
  }
}
