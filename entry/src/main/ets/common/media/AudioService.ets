/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Low-Latency Chord Audio Pool Service using soundPool
 */

import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { common } from '@kit.AbilityKit';
import { Logger } from '../utils/Logger';

import { UserSettingsDao } from '../../database/dao/UserSettingsDao';

export class AudioService {
  private static instance: AudioService | null = null;
  private soundPool: media.SoundPool | null = null;
  private soundIds: number[] = [];
  private currentStepIndex: number = 0;
  private isLoaded: boolean = false;

  private constructor() {}

  public static getInstance(): AudioService {
    if (!AudioService.instance) {
      AudioService.instance = new AudioService();
    }
    return AudioService.instance;
  }

  /**
   * 预加载 4 个纯净和弦音阶采样
   */
  public async init(context: common.Context): Promise<void> {
    if (this.isLoaded) {
      return;
    }

    try {
      const audioRendererInfo: audio.AudioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_NOTIFICATION,
        rendererFlags: 0
      };

      this.soundPool = await media.createSoundPool(4, audioRendererInfo);

      const files = [
        'audio/sound_chord_c4.wav',
        'audio/sound_chord_e4.wav',
        'audio/sound_chord_g4.wav',
        'audio/sound_chord_c5.wav'
      ];

      this.soundIds = [];
      for (const f of files) {
        try {
          const rawFd = await context.resourceManager.getRawFd(f);
          const soundId = await this.soundPool.load(rawFd.fd, rawFd.offset, rawFd.length);
          this.soundIds.push(soundId);
        } catch (loadErr) {
          Logger.warn('AudioService', 'Could not load raw audio %{public}s: %{public}s', f, JSON.stringify(loadErr));
        }
      }

      this.isLoaded = true;
      Logger.info('AudioService', 'AudioService initialized with %{public}d sound samples', this.soundIds.length);
    } catch (err) {
      Logger.warn('AudioService', 'Failed to initialize soundPool: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * 播放多巴胺和弦阶梯音效 (Do -> Mi -> Sol -> High Do')
   */
  public async playChordStep(): Promise<void> {
    if (!this.soundPool || this.soundIds.length === 0) {
      return;
    }

    try {
      const settings = await UserSettingsDao.getSettings();
      if (!settings.isChordAudioEnabled) {
        return;
      }
    } catch {
      // 容错降级
    }

    const targetSoundId = this.soundIds[this.currentStepIndex % this.soundIds.length];
    this.currentStepIndex++;

    const playParams: media.PlayParameters = {
      loop: 0,
      rate: audio.AudioRendererRate.RENDER_RATE_NORMAL,
      leftVolume: 0.9,
      rightVolume: 0.9,
      priority: 1
    };

    try {
      this.soundPool.play(targetSoundId, playParams);
    } catch (playErr) {
      Logger.warn('AudioService', 'Failed to play sound: %{public}s', JSON.stringify(playErr));
    }
  }

  /**
   * 晚间打烊仪式钟鸣
   */
  public async playSunsetGong(): Promise<void> {
    await this.playChordStep();
  }

  /**
   * 重置阶梯计数器
   */
  public resetLadder(): void {
    this.currentStepIndex = 0;
  }
}
