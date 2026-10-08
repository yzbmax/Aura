/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Adaptive Bin-Packing & Elastic Scheduling Engine (Local-First, <2ms)
 */

import { AppConstants } from '../common/constants/AppConstants';
import { Priority, TimingMode, TodoItem, TodoStatus } from '../models/TodoItem';
import { SlotType, TimeSlot } from '../models/TimeSlot';
import { UserSettings } from '../models/UserSettings';
import { StarvationProtector } from './StarvationProtector';
import { TimeUtils } from '../common/utils/TimeUtils';
import { Logger } from '../common/utils/Logger';

interface FreeInterval {
  startMs: number;
  endMs: number;
}

export interface ScheduleResult {
  scheduledSlots: TimeSlot[];
  totalScheduledMinutes: number;
}

export class BinPackingScheduler {
  /**
   * 执行自适应时间块区间贪心装箱
   */
  public static schedule(
    settings: UserSettings,
    allCandidates: TodoItem[],
    lockedSlots: TimeSlot[] = [],
    dayTimestamp: number = Date.now()
  ): ScheduleResult {
    const startTimePerf = Date.now();

    // 1. 计算当日工作起止边界
    const baseDate = new Date(dayTimestamp);
    const dayStartMs = new Date(
      baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate(),
      settings.workStartHour, settings.workStartMinute, 0, 0
    ).getTime();

    const dayEndMs = new Date(
      baseDate.getFullYear(), baseDate.getMonth(), baseDate.getDate(),
      settings.workEndHour, settings.workEndMinute, 0, 0
    ).getTime();

    // 2. 排序并规整锁定区间（如外部会议与午休，以及用户锁定的关键任务）
    const validLocked = lockedSlots
      .filter((s: TimeSlot) => s.endMs > dayStartMs && s.startMs < dayEndMs);

    // 收集用户明确锁定的待办，同步加入锁定区间保护
    const pinnedToday = allCandidates.filter((item: TodoItem) => {
      return !item.isDeleted &&
        !item.isFrozen &&
        item.status !== TodoStatus.COMPLETED &&
        item.status !== TodoStatus.CANCELLED &&
        item.isPinned &&
        item.scheduledStartAt >= dayStartMs &&
        item.scheduledEndAt <= dayEndMs;
    });

    for (const pin of pinnedToday) {
      validLocked.push(
        new TimeSlot(pin.id, pin.scheduledStartAt, pin.scheduledEndAt, SlotType.TASK, pin, pin.title)
      );
    }
    validLocked.sort((a: TimeSlot, b: TimeSlot) => a.startMs - b.startMs);

    // 3. 现实时间感知 (Now-Aware)：如果排期是当天，并且现实时间已推进，装箱起点必须锚定当前时刻
    const isToday = TimeUtils.isSameDay(dayTimestamp, Date.now());
    const now = Date.now();
    let effectiveStartMs = dayStartMs;
    if (isToday && now > dayStartMs) {
      // 向上对齐到最近的 5 分钟整数网格，避免零碎毫秒造成视觉毛刺
      const fiveMinMs = 5 * 60 * 1000;
      effectiveStartMs = Math.min(Math.ceil(now / fiveMinMs) * fiveMinMs, dayEndMs);
    }

    // 计算可用空闲时间区间集合 (从 effectiveStartMs 向后排布)
    const freeIntervals: FreeInterval[] = [];
    let cur = effectiveStartMs;

    for (const locked of validLocked) {
      if (locked.endMs <= cur) {
        continue; // 过去的锁定区间不参与未来计算
      }
      if (locked.startMs > cur) {
        freeIntervals.push({ startMs: cur, endMs: Math.min(locked.startMs, dayEndMs) });
      }
      cur = Math.max(cur, locked.endMs);
    }

    if (cur < dayEndMs) {
      freeIntervals.push({ startMs: cur, endMs: dayEndMs });
    }

    // 4. 收集今日已完成的任务作为历史流光槽位呈现
    const scheduledTimelineSlots: TimeSlot[] = [];
    const completedToday = allCandidates.filter((item: TodoItem) => {
      return !item.isDeleted &&
        item.status === TodoStatus.COMPLETED &&
        ((item.scheduledStartAt >= dayStartMs && item.scheduledStartAt < dayEndMs) ||
         (item.completedAt >= dayStartMs && item.completedAt < dayEndMs));
    });
    for (const comp of completedToday) {
      const startMs = comp.scheduledStartAt > 0 ? comp.scheduledStartAt : (comp.completedAt > 0 ? comp.completedAt - (comp.estimatedMinutes * 60000) : dayStartMs);
      const endMs = comp.scheduledEndAt > 0 ? comp.scheduledEndAt : startMs + (comp.estimatedMinutes * 60000);
      scheduledTimelineSlots.push(
        new TimeSlot(comp.id, startMs, endMs, SlotType.TASK, comp, comp.title)
      );
    }

    // 5. 筛选未完成且未冷冻的候选任务池
    const pool = allCandidates.filter((item: TodoItem) => {
      return !item.isDeleted &&
        !item.isFrozen &&
        item.status !== TodoStatus.COMPLETED &&
        item.status !== TodoStatus.CANCELLED &&
        !item.isPinned;
    });

    // 6. 对候选任务进行综合加权排序打分（平局时以 id 稳定排序，彻底杜绝 Ghost Shift 乱跳）
    pool.sort((a: TodoItem, b: TodoItem) => {
      const scoreA = BinPackingScheduler.calculateScore(a);
      const scoreB = BinPackingScheduler.calculateScore(b);
      if (scoreB !== scoreA) {
        return scoreB - scoreA;
      }
      return a.id.localeCompare(b.id);
    });

    // 7. 区间贪心装箱与反过载三大边界
    let totalScheduledMinutes = 0;
    const maxDeepWork = settings.maxDeepWorkMinutes > 0 ? settings.maxDeepWorkMinutes : AppConstants.DEFAULT_MAX_DEEP_WORK_MINUTES;
    const bufferMinutes = settings.bufferMinutes > 0 ? settings.bufferMinutes : AppConstants.DEFAULT_BUFFER_MINUTES;

    const assignedItemIds = new Set<string>();
    let consecutiveWorkMinutes = 0;

    for (const interval of freeIntervals) {
      let pointer = interval.startMs;
      consecutiveWorkMinutes = 0;

      while (pointer < interval.endMs) {
        const remainingMinutesInSlot = Math.floor((interval.endMs - pointer) / 60000);
        if (remainingMinutesInSlot < 15) {
          break; // 缝隙过碎，留白跳过
        }

        // 寻找符合槽位剩余时长的最佳任务 (不设4.5h强制截断，排满全天可用时段)
        let selectedIndex = -1;
        let effectiveDuration = 0;
        let isSlice = false;

        for (let i = 0; i < pool.length; i++) {
          const candidate = pool[i];
          if (assignedItemIds.has(candidate.id)) {
            continue;
          }

          const duration = candidate.timingMode === TimingMode.STOPWATCH
            ? AppConstants.STOPWATCH_PLACEHOLDER_MINUTES
            : candidate.estimatedMinutes;

          // 检查槽位是否能容纳
          if (duration <= remainingMinutesInSlot) {
            selectedIndex = i;
            effectiveDuration = duration;
            isSlice = false;
            break;
          } else if (StarvationProtector.shouldSlice(candidate, remainingMinutesInSlot)) {
            // 触发大任务 45m 探索切片防饥饿
            selectedIndex = i;
            effectiveDuration = StarvationProtector.createExplorationSlice(candidate);
            isSlice = true;
            break;
          }
        }

        if (selectedIndex === -1) {
          // 当前槽位无法装入任何剩余候选任务
          break;
        }

        const task = pool[selectedIndex];
        assignedItemIds.add(task.id);

        task.scheduledStartAt = pointer;
        task.scheduledEndAt = pointer + (effectiveDuration * 60000);
        task.isExplorationSlice = isSlice;

        totalScheduledMinutes += effectiveDuration;
        consecutiveWorkMinutes += effectiveDuration;
        pointer = task.scheduledEndAt;

        scheduledTimelineSlots.push(
          new TimeSlot(
            task.id,
            task.scheduledStartAt,
            task.scheduledEndAt,
            SlotType.TASK,
            task,
            task.title
          )
        );

        // 智能气囊模式：仅在单个任务 >=25m 或连续微任务累计工时 >=25m 时插入留白呼吸缓冲
        if (effectiveDuration >= 25 || consecutiveWorkMinutes >= 25) {
          if (pointer + (bufferMinutes * 60000) <= interval.endMs) {
            const bufEnd = pointer + (bufferMinutes * 60000);
            scheduledTimelineSlots.push(
              new TimeSlot(
                `buf_${pointer}`,
                pointer,
                bufEnd,
                SlotType.BUFFER,
                null,
                `留白蓄力 · 慢呼吸`
              )
            );
            pointer = bufEnd;
            consecutiveWorkMinutes = 0;
          }
        }
      }

      // 若当前区间装箱完毕后仍有剩余空闲（如脑力上限已满或剩余候选为空），输出真实空闲留白槽
      if (pointer < interval.endMs && (interval.endMs - pointer) >= 15 * 60000) {
        scheduledTimelineSlots.push(
          new TimeSlot(
            `free_${pointer}`,
            pointer,
            interval.endMs,
            SlotType.BUFFER,
            null,
            '自由心流留白 · 休憩充电'
          )
        );
        pointer = interval.endMs;
      }
    }

    // 7. 未装箱的候选任务归入机动备选池
    for (const item of pool) {
      if (!assignedItemIds.has(item.id)) {
        item.scheduledStartAt = 0;
        item.scheduledEndAt = 0;
        item.isExplorationSlice = false;
      }
    }

    // 8. 合并锁定会议日程
    for (const locked of validLocked) {
      scheduledTimelineSlots.push(locked);
    }

    // 按时间正序重整
    scheduledTimelineSlots.sort((a: TimeSlot, b: TimeSlot) => a.startMs - b.startMs);

    const elapsed = Date.now() - startTimePerf;
    Logger.info('BinPackingScheduler', 'Scheduled %{public}d slots in %{public}d ms. Total deep work: %{public}d min',
      scheduledTimelineSlots.length, elapsed, totalScheduledMinutes);

    const result: ScheduleResult = {
      scheduledSlots: scheduledTimelineSlots,
      totalScheduledMinutes
    };
    return result;
  }

  /**
   * 综合打分公式：Score = (Priority * 40) + (Urgency * 40) + (Aging * 20)
   */
  private static calculateScore(item: TodoItem): number {
    const priorityWeight = (item.priority || Priority.MEDIUM) * 40;

    let urgencyWeight = 20;
    if (item.dueDate > 0) {
      const now = Date.now();
      const diffHours = (item.dueDate - now) / (1000 * 3600);
      if (diffHours <= 0) {
        urgencyWeight = 120; // 已超期，高权重处理
      } else if (diffHours <= 12) {
        urgencyWeight = 100;
      } else if (diffHours <= 24) {
        urgencyWeight = 80;
      } else if (diffHours <= 48) {
        urgencyWeight = 50;
      }
    }

    const agingWeight = (item.agingLevel || 0) * 20;

    return priorityWeight + urgencyWeight + agingWeight;
  }
}
