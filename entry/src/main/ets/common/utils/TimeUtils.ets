/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Time Utilities & Timestamp Helpers for Scheduling
 */

import { util } from '@kit.ArkTS';

export class TimeUtils {
  /**
   * 生成全局唯一 UUID (符合 RFC 4122 v4)
   */
  public static generateUUID(): string {
    return util.generateRandomUUID(true);
  }

  /**
   * 获取今日 00:00:00.000 毫秒时间戳
   */
  public static getTodayStartTimestamp(): number {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0).getTime();
  }

  /**
   * 获取指定时间戳所在日的 00:00:00.000 毫秒时间戳
   */
  public static getDayStart(timestamp: number): number {
    const d = new Date(timestamp);
    return new Date(d.getFullYear(), d.getMonth(), d.getDate(), 0, 0, 0, 0).getTime();
  }

  /**
   * 获取今日 23:59:59.999 毫秒时间戳
   */
  public static getTodayEndTimestamp(): number {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999).getTime();
  }

  /**
   * 获取今日指定时分的毫秒时间戳
   */
  public static getTodayTimestampAt(hour: number, minute: number): number {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate(), hour, minute, 0, 0).getTime();
  }

  /**
   * 格式化时间为 HH:mm
   */
  public static formatTime(timestamp: number): string {
    if (timestamp <= 0) {
      return '--:--';
    }
    const d = new Date(timestamp);
    const h = d.getHours().toString().padStart(2, '0');
    const m = d.getMinutes().toString().padStart(2, '0');
    return `${h}:${m}`;
  }

  /**
   * 格式化时间槽为 HH:mm - HH:mm (Xm)
   */
  public static formatSlotRange(startMs: number, endMs: number): string {
    if (startMs <= 0 || endMs <= 0) {
      return '未排期';
    }
    const startStr = TimeUtils.formatTime(startMs);
    const endStr = TimeUtils.formatTime(endMs);
    const diffMinutes = Math.max(0, Math.round((endMs - startMs) / (1000 * 60)));
    return `${startStr} - ${endStr} (${diffMinutes}m)`;
  }

  /**
   * 格式化分钟数为时长字符串 (例如 45m, 2.5h)
   */
  public static formatDurationHours(minutes: number): string {
    const hours = (minutes / 60).toFixed(1);
    return `${hours}h`;
  }

  /**
   * 计算与当前时间相差的天数 (以 86400000 换算)
   */
  public static getDaysAgo(timestamp: number): number {
    if (timestamp <= 0) {
      return 0;
    }
    const diffMs = Date.now() - timestamp;
    return Math.floor(diffMs / (1000 * 60 * 60 * 24));
  }

  /**
   * 获取今日 00:00:00 的时间戳
   */
  public static getCurrentDateTimestamp(): number {
    const now = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();
  }

  /**
   * 判断两个时间戳是否为同一天
   */
  public static isSameDay(ts1: number, ts2: number): boolean {
    const d1 = new Date(ts1);
    const d2 = new Date(ts2);
    return d1.getFullYear() === d2.getFullYear() &&
      d1.getMonth() === d2.getMonth() &&
      d1.getDate() === d2.getDate();
  }
}
