/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * HarmonyOS Native Droplet Distortion & Liquid Glass Motion Dynamics
 */

import { HapticService } from '../media/HapticService';

@ObservedV2
export class LiquidGlassState {
  @Trace public isPressed: boolean = false;
  @Trace public sphericalValue: number = 0.0;
  @Trace public lightUpValue: number = 0.0;
  @Trace public offsetX: number = 0.0;
  @Trace public offsetY: number = 0.0;
  @Trace public scaleX: number = 1.0;
  @Trace public scaleY: number = 1.0;

  private startX: number = 0.0;
  private startY: number = 0.0;
  private isMoved: boolean = false;

  public handleTouchDown(x: number, y: number): void {
    this.startX = x;
    this.startY = y;
    this.isPressed = true;
    this.isMoved = false;
    this.sphericalValue = 0.18;
    this.lightUpValue = 0.15;
    this.scaleX = 0.97;
    this.scaleY = 0.97;
    HapticService.getInstance().triggerTick();
  }

  public handleTouchMove(x: number, y: number): void {
    if (!this.isPressed) {
      return;
    }
    const dx = x - this.startX;
    const dy = y - this.startY;
    if (Math.abs(dx) > 2 || Math.abs(dy) > 2) {
      this.isMoved = true;
    }

    // 非线性橡皮筋位移阻尼
    this.offsetX = dx * 0.28;
    this.offsetY = dy * 0.28;

    // 轴向果冻切变拉伸 (Squash & Stretch)
    const stretchFactor = Math.min(0.08, (Math.abs(dx) + Math.abs(dy)) * 0.0012);
    if (Math.abs(dx) > Math.abs(dy)) {
      this.scaleX = 0.97 + stretchFactor;
      this.scaleY = Math.max(0.90, 0.97 - stretchFactor * 0.6);
    } else {
      this.scaleY = 0.97 + stretchFactor;
      this.scaleX = Math.max(0.90, 0.97 - stretchFactor * 0.6);
    }
  }

  public handleTouchUp(): boolean {
    const wasMoved = this.isMoved;
    this.isPressed = false;
    this.sphericalValue = 0.0;
    this.lightUpValue = 0.0;
    this.offsetX = 0.0;
    this.offsetY = 0.0;
    this.scaleX = 1.0;
    this.scaleY = 1.0;
    this.isMoved = false;
    return !wasMoved; // 返回 true 说明是纯点击，非大范围拖拽
  }
}
