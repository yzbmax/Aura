/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * User Settings & Scheduling Preference Entity Model
 */

import { AppConstants } from '../common/constants/AppConstants';

@ObservedV2
export class UserSettings {
  @Trace public workStartHour: number = AppConstants.DEFAULT_WORK_START_HOUR;
  @Trace public workStartMinute: number = AppConstants.DEFAULT_WORK_START_MINUTE;
  @Trace public workEndHour: number = AppConstants.DEFAULT_WORK_END_HOUR;
  @Trace public workEndMinute: number = AppConstants.DEFAULT_WORK_END_MINUTE;

  @Trace public maxDeepWorkMinutes: number = AppConstants.DEFAULT_MAX_DEEP_WORK_MINUTES; // 默认 270 分钟 (4.5h)
  @Trace public bufferMinutes: number = AppConstants.DEFAULT_BUFFER_MINUTES;             // 默认 15 分钟

  @Trace public isChordAudioEnabled: boolean = true;                                     // 和弦音阶
  @Trace public isHapticEnabled: boolean = true;                                         // 泡泡纸微触感
  @Trace public isPaperMode: boolean = false;                                            // 墨水屏/纸感极简模式 (高对比防残影)
  @Trace public isAmberMode: boolean = false;                                            // 纯琥珀夜调模式 (600nm+ 零蓝光护眼)
  @Trace public isAgreedPrivacy: boolean = false;                                        // 首屏隐私协议同意状态

  @Trace public lastActiveTimestamp: number = 0;                                         // 上次活跃时间戳
  @Trace public streakShieldActive: boolean = false;                                     // 节律保护盾激活状态
  @Trace public streakDays: number = 7;                                                  // 连续同频天数 (冷启动默认保底7天)

  constructor() {}
}
