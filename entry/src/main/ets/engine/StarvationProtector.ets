/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Starvation Protector: 45m Exploration Slice Strategy
 */

import { AppConstants } from '../common/constants/AppConstants';
import { Priority, TodoItem } from '../models/TodoItem';
import { Logger } from '../common/utils/Logger';

export class StarvationProtector {
  /**
   * 判断是否需要触发大任务探索切片保护
   * 规则：高优先级任务且时长超过剩余槽位，但剩余槽位充足 (>= 45m)
   */
  public static shouldSlice(item: TodoItem, slotRemainingMinutes: number): boolean {
    const effectiveDuration = item.estimatedMinutes;
    if (effectiveDuration > slotRemainingMinutes && slotRemainingMinutes >= AppConstants.EXPLORATION_SLICE_MINUTES) {
      if (item.priority === Priority.HIGH || effectiveDuration >= 90) {
        return true;
      }
    }
    return false;
  }

  /**
   * 切分任务：将原始大任务转换为首个 45m 探索切片
   */
  public static createExplorationSlice(item: TodoItem): number {
    Logger.info('StarvationProtector', 'Created 45m exploration slice for task: %{public}s', item.title);
    item.isExplorationSlice = true;
    return AppConstants.EXPLORATION_SLICE_MINUTES;
  }
}
