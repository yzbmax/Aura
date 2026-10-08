/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Linear Motor Haptic Feedback Service using vibrator
 */

import { vibrator } from '@kit.SensorServiceKit';
import { Logger } from '../utils/Logger';
import { UserSettingsDao } from '../../database/dao/UserSettingsDao';

export class HapticService {
  private static instance: HapticService | null = null;

  private constructor() {}

  public static getInstance(): HapticService {
    if (!HapticService.instance) {
      HapticService.instance = new HapticService();
    }
    return HapticService.instance;
  }

  /**
   * 勾选待办：泡泡纸破裂解压微震 (35ms)
   */
  public triggerClick(): void {
    this.vibrate(35);
  }

  /**
   * 杂念秒停泊：轻柔气雾微脉冲 (18ms)
   */
  public triggerTick(): void {
    this.vibrate(18);
  }

  /**
   * 打烊仪式落锁：厚重仪式感微震 (70ms)
   */
  public triggerHeavy(): void {
    this.vibrate(70);
  }

  /**
   * 打烊仪式悠远回响
   */
  public triggerSunsetChime(): void {
    this.triggerHeavy();
  }

  private async vibrate(durationMs: number): Promise<void> {
    try {
      const settings = await UserSettingsDao.getSettings();
      if (!settings.isHapticEnabled) {
        return;
      }
      const effect: vibrator.VibrateEffect = {
        type: 'time',
        duration: durationMs
      };
      const attribute: vibrator.VibrateAttribute = {
        usage: 'physicalFeedback'
      };
      vibrator.startVibration(effect, attribute).catch((err: Object) => {
        Logger.debug('HapticService', 'Vibration skipped or not supported: %{public}s', JSON.stringify(err));
      });
    } catch (e) {
      Logger.debug('HapticService', 'Vibrator invocation ignored');
    }
  }
}
