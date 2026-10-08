/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Parallax Card Deck Kinematics & Physical Dynamic Equations
 * Strict ArkTS implementation with zero any and zero emoji
 */

export class HapticHysteresisState {
  public hasTriggered: boolean = false;

  public update(offsetX: number): boolean {
    const absX: number = Math.abs(offsetX);
    if (absX >= CardDeckKinematics.THRESHOLD_ENGAGE && !this.hasTriggered) {
      this.hasTriggered = true;
      return true;
    } else if (absX <= CardDeckKinematics.THRESHOLD_RELEASE && this.hasTriggered) {
      this.hasTriggered = false;
    }
    return false;
  }

  public reset(): void {
    this.hasTriggered = false;
  }
}

export class CardDeckKinematics {
  // 手势物理判定常量
  public static readonly THRESHOLD_DISPLACEMENT: number = 110.0;
  public static readonly THRESHOLD_ENGAGE: number = 100.0;
  public static readonly THRESHOLD_RELEASE: number = 75.0;
  public static readonly VELOCITY_COMMIT: number = 650.0;
  public static readonly VELOCITY_MIN_DISPLACEMENT: number = 30.0;

  // 飞牌终点常量
  public static readonly EXIT_TRANSLATE_X: number = 520.0;
  public static readonly EXIT_ROTATE_ANGLE: number = 20.0;

  // 次层 (Layer 2) 静态与动态变换基准
  public static readonly LAYER2_BASE_SCALE: number = 0.93;
  public static readonly LAYER2_TARGET_SCALE: number = 1.00;
  public static readonly LAYER2_BASE_TRANSLATE_Y: number = 22.0;

  // 底层 (Layer 3) 静态与动态变换基准
  public static readonly LAYER3_BASE_SCALE: number = 0.88;
  public static readonly LAYER3_TARGET_SCALE: number = 0.95;
  public static readonly LAYER3_BASE_TRANSLATE_Y: number = 38.0;
  public static readonly LAYER3_TARGET_TRANSLATE_Y: number = 22.0;

  // 弹簧物理动力学参数基准
  public static readonly SPRING_SNAP_RESPONSE: number = 0.34;
  public static readonly SPRING_SNAP_DAMPING: number = 0.62;
  public static readonly SPRING_FLYOUT_RESPONSE: number = 0.30;
  public static readonly SPRING_FLYOUT_DAMPING: number = 0.82;
  public static readonly SPRING_RESET_RESPONSE: number = 0.28;
  public static readonly SPRING_RESET_DAMPING: number = 0.76;

  /**
   * 计算手势位移的归一化连续进度 [0.0, 1.0]
   */
  public static calcGestureProgress(offsetX: number): number {
    return Math.min(1.0, Math.max(0.0, Math.abs(offsetX) / CardDeckKinematics.THRESHOLD_DISPLACEMENT));
  }

  /**
   * 计算带方向的手势归一化进度 [-1.0, 1.0]
   */
  public static calcSignedGestureProgress(offsetX: number): number {
    if (offsetX === 0) {
      return 0;
    }
    const sign: number = offsetX > 0 ? 1 : -1;
    return sign * CardDeckKinematics.calcGestureProgress(offsetX);
  }

  /**
   * 计算次层 (Layer 2) 动态缩放比: 0.93 -> 1.00
   */
  public static calcLayer2Scale(progress: number): number {
    const clampedProgress: number = Math.min(1.0, Math.max(0.0, progress));
    return CardDeckKinematics.LAYER2_BASE_SCALE +
      ((CardDeckKinematics.LAYER2_TARGET_SCALE - CardDeckKinematics.LAYER2_BASE_SCALE) * clampedProgress);
  }

  /**
   * 计算次层 (Layer 2) 垂直位移衰减: 22vp -> 0vp
   */
  public static calcLayer2TranslateY(progress: number, baseY: number = CardDeckKinematics.LAYER2_BASE_TRANSLATE_Y): number {
    const clampedProgress: number = Math.min(1.0, Math.max(0.0, progress));
    return baseY * (1.0 - clampedProgress);
  }

  /**
   * 计算次层外露微指示条渐隐不透明度
   */
  public static calcLayer2PeekBarOpacity(progress: number): number {
    const clampedProgress: number = Math.min(1.0, Math.max(0.0, progress));
    return Math.max(0.0, 1.0 - (2.5 * clampedProgress));
  }

  /**
   * 计算底层 (Layer 3) 动态缩放比: 0.88 -> 0.95
   */
  public static calcLayer3Scale(progress: number): number {
    const clampedProgress: number = Math.min(1.0, Math.max(0.0, progress));
    return CardDeckKinematics.LAYER3_BASE_SCALE +
      ((CardDeckKinematics.LAYER3_TARGET_SCALE - CardDeckKinematics.LAYER3_BASE_SCALE) * clampedProgress);
  }

  /**
   * 计算底层 (Layer 3) 垂直位移衰减: 38vp -> 22vp
   */
  public static calcLayer3TranslateY(
    progress: number,
    baseY: number = CardDeckKinematics.LAYER3_BASE_TRANSLATE_Y,
    targetY: number = CardDeckKinematics.LAYER3_TARGET_TRANSLATE_Y
  ): number {
    const clampedProgress: number = Math.min(1.0, Math.max(0.0, progress));
    return baseY - ((baseY - targetY) * clampedProgress);
  }

  /**
   * 计算底层 (Layer 3) 不透明度连续演进: 0.72 -> 0.95
   */
  public static calcLayer3Opacity(progress: number): number {
    const clampedProgress: number = Math.min(1.0, Math.max(0.0, progress));
    return 0.72 + (0.23 * clampedProgress);
  }

  /**
   * 计算顶层 (Layer 1) 旋转倾角 (每 100vp 约 4 度，限制在 ±16 度内)
   */
  public static calcLayer1Rotation(offsetX: number): number {
    return Math.max(-16.0, Math.min(16.0, offsetX * 0.04));
  }

  /**
   * 计算顶层 (Layer 1) 拖拽拉伸不透明度: 1.0 -> 0.85
   */
  public static calcLayer1Opacity(progress: number): number {
    const clampedProgress: number = Math.min(1.0, Math.max(0.0, progress));
    return 1.0 - (0.15 * clampedProgress);
  }

  /**
   * 动态阴影扩散半径插值
   */
  public static calcShadowRadius(baseRadius: number, deltaRadius: number, progress: number): number {
    const clampedProgress: number = Math.min(1.0, Math.max(0.0, progress));
    return baseRadius + (deltaRadius * clampedProgress);
  }

  /**
   * 动态阴影垂直偏移量插值
   */
  public static calcShadowOffsetY(baseOffsetY: number, deltaOffsetY: number, progress: number): number {
    const clampedProgress: number = Math.min(1.0, Math.max(0.0, progress));
    return baseOffsetY + (deltaOffsetY * clampedProgress);
  }

  /**
   * 判定手势释放是否满足滑出飞离条件
   */
  public static isCommitFlyout(offsetX: number, velocityX: number): boolean {
    return CardDeckKinematics.isCommitRight(offsetX, velocityX) || CardDeckKinematics.isCommitLeft(offsetX, velocityX);
  }

  /**
   * 判定是否满足向右飞离 (完成)
   */
  public static isCommitRight(offsetX: number, velocityX: number): boolean {
    return offsetX >= CardDeckKinematics.THRESHOLD_ENGAGE ||
      (offsetX >= CardDeckKinematics.VELOCITY_MIN_DISPLACEMENT && velocityX >= CardDeckKinematics.VELOCITY_COMMIT);
  }

  /**
   * 判定是否满足向左飞离 (跳过/稍后)
   */
  public static isCommitLeft(offsetX: number, velocityX: number): boolean {
    return offsetX <= -CardDeckKinematics.THRESHOLD_ENGAGE ||
      (offsetX <= -CardDeckKinematics.VELOCITY_MIN_DISPLACEMENT && velocityX <= -CardDeckKinematics.VELOCITY_COMMIT);
  }

  /**
   * 欠阻尼二阶弹簧最大理论超调比率 Mp = exp(-pi * zeta / sqrt(1 - zeta^2))
   */
  public static calcSpringOvershootRatio(zeta: number = 0.62): number {
    const exponent: number = -Math.PI * zeta / Math.sqrt(1.0 - (zeta * zeta));
    return Math.exp(exponent);
  }

  /**
   * 计算位移行程中的过冲距离 (vp)
   */
  public static calcOvershootDistance(travelDistance: number, zeta: number = 0.62): number {
    return travelDistance * CardDeckKinematics.calcSpringOvershootRatio(zeta);
  }

  /**
   * 计算二阶弹簧固有角频率 omega_n = 2 * pi / response
   */
  public static calcNaturalFrequency(response: number = CardDeckKinematics.SPRING_SNAP_RESPONSE): number {
    return (2.0 * Math.PI) / response;
  }

  /**
   * 计算二阶弹簧阻尼角频率 omega_d = omega_n * sqrt(1 - zeta^2)
   */
  public static calcDampedFrequency(
    response: number = CardDeckKinematics.SPRING_SNAP_RESPONSE,
    zeta: number = CardDeckKinematics.SPRING_SNAP_DAMPING
  ): number {
    const wn: number = CardDeckKinematics.calcNaturalFrequency(response);
    return wn * Math.sqrt(1.0 - (zeta * zeta));
  }

  /**
   * 计算首次过冲峰值时间 (秒) tp = pi / omega_d
   */
  public static calcPeakOvershootTime(
    response: number = CardDeckKinematics.SPRING_SNAP_RESPONSE,
    zeta: number = CardDeckKinematics.SPRING_SNAP_DAMPING
  ): number {
    const wd: number = CardDeckKinematics.calcDampedFrequency(response, zeta);
    return Math.PI / wd;
  }

  /**
   * 计算二阶弹簧在任意时间 t (秒) 的阶跃响应比例 [0, 1 + Mp]
   */
  public static calcSpringStepResponse(
    t: number,
    response: number = CardDeckKinematics.SPRING_SNAP_RESPONSE,
    zeta: number = CardDeckKinematics.SPRING_SNAP_DAMPING
  ): number {
    if (t <= 0) {
      return 0.0;
    }
    const wn: number = CardDeckKinematics.calcNaturalFrequency(response);
    const wd: number = CardDeckKinematics.calcDampedFrequency(response, zeta);
    const decay: number = Math.exp(-zeta * wn * t);
    const harmonic: number = Math.cos(wd * t) + ((zeta / Math.sqrt(1.0 - (zeta * zeta))) * Math.sin(wd * t));
    return 1.0 - (decay * harmonic);
  }

  /**
   * 计算弹簧运动在时间 t (秒) 下的实际卡片位移 Y (vp)
   */
  public static calcSpringOffsetY(
    t: number,
    startY: number,
    targetY: number = 0.0,
    response: number = CardDeckKinematics.SPRING_SNAP_RESPONSE,
    zeta: number = CardDeckKinematics.SPRING_SNAP_DAMPING
  ): number {
    const step: number = CardDeckKinematics.calcSpringStepResponse(t, response, zeta);
    return startY + ((targetY - startY) * step);
  }

  /**
   * 计算在给定垂直缩放锚点比例下卡片的视觉底边缘绝对位置 (vp)
   * anchorCenterYRatio: 1.0 代表 '100%' 底部锚点, 0.0 代表 '0%' 顶部锚点
   */
  public static calcCardVisualBottom(
    height: number,
    scaleY: number,
    translateY: number,
    anchorCenterYRatio: number = 1.0
  ): number {
    const anchorY: number = height * anchorCenterYRatio;
    const scaledBottom: number = anchorY + ((height - anchorY) * scaleY);
    return scaledBottom + translateY;
  }

  /**
   * 计算次层 (Layer 2) 相比于顶层 (Layer 1) 的底边缘外露净高度 (vp)
   */
  public static calcLayer2BottomExposure(
    height: number,
    progress: number = 0.0,
    anchorCenterYRatio: number = 1.0
  ): number {
    const layer1Bottom: number = height;
    const scale2: number = CardDeckKinematics.calcLayer2Scale(progress);
    const transY2: number = CardDeckKinematics.calcLayer2TranslateY(progress);
    const layer2Bottom: number = CardDeckKinematics.calcCardVisualBottom(height, scale2, transY2, anchorCenterYRatio);
    return layer2Bottom - layer1Bottom;
  }

  /**
   * 计算底层 (Layer 3) 相比于次层 (Layer 2) 的底边缘外露净高度 (vp)
   */
  public static calcLayer3BottomExposure(
    height: number,
    progress: number = 0.0,
    anchorCenterYRatio: number = 1.0
  ): number {
    const scale2: number = CardDeckKinematics.calcLayer2Scale(progress);
    const transY2: number = CardDeckKinematics.calcLayer2TranslateY(progress);
    const layer2Bottom: number = CardDeckKinematics.calcCardVisualBottom(height, scale2, transY2, anchorCenterYRatio);

    const scale3: number = CardDeckKinematics.calcLayer3Scale(progress);
    const transY3: number = CardDeckKinematics.calcLayer3TranslateY(progress);
    const layer3Bottom: number = CardDeckKinematics.calcCardVisualBottom(height, scale3, transY3, anchorCenterYRatio);

    return layer3Bottom - layer2Bottom;
  }
}

