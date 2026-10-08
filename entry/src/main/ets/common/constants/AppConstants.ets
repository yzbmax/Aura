/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Application Core Domain Thresholds & Defaults
 */

export class AppConstants {
  // 算法三大边界默认值
  public static readonly DEFAULT_WORK_START_HOUR: number = 9;
  public static readonly DEFAULT_WORK_START_MINUTE: number = 30;
  public static readonly DEFAULT_WORK_END_HOUR: number = 18;
  public static readonly DEFAULT_WORK_END_MINUTE: number = 30;

  // 每日高认知专注脑力硬上限 (分钟，默认 4.5 小时 = 270 分钟)
  public static readonly DEFAULT_MAX_DEEP_WORK_MINUTES: number = 270;

  // 任务块之间强制留白缓冲带时长 (分钟)
  public static readonly DEFAULT_BUFFER_MINUTES: number = 15;

  // 未知时长大任务探索切片时长 (分钟)
  public static readonly EXPLORATION_SLICE_MINUTES: number = 45;

  // 流体正计时晨间预留占位时长 (分钟)
  public static readonly STOPWATCH_PLACEHOLDER_MINUTES: number = 25;

  // 5 分钟破冰船倒计时期限 (秒)
  public static readonly ICEBREAKER_DURATION_SECONDS: number = 300;

  // 视口停留触发破冰微脉动的阈值 (毫秒)
  public static readonly VIEWPORT_HOVER_THRESHOLD_MS: number = 3500;

  // 杂念停泊温和老化阈值 (小时)
  public static readonly PARKING_LOT_AGING_HOURS: number = 48;

  // 逾期任务归入冷冻舱阈值 (天)
  public static readonly FROZEN_DAYS_THRESHOLD: number = 8;

  // 分布式软删除墓碑物理清理周期 (天)
  public static readonly TOMBSTONE_CLEANUP_DAYS: number = 30;
}
