/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Mild Aging & Frozen Cabin Engine (Anti-Guilt Psychology)
 */

import { AppConstants } from '../common/constants/AppConstants';
import { TodoItem, TodoStatus } from '../models/TodoItem';
import { TimeUtils } from '../common/utils/TimeUtils';

export class MildAgingEngine {
  /**
   * 计算待办温和老化等级与冷冻状态
   * - 0: 正常态
   * - 1: 逾期 1~3 天 (褪淡 20%)
   * - 2: 逾期 4~7 天 (秋叶黄沉底)
   * - 3: 逾期 8+ 天 (自动进入冷冻舱休眠)
   */
  public static evaluateAging(item: TodoItem): void {
    if (item.status === TodoStatus.COMPLETED || item.status === TodoStatus.CANCELLED) {
      return;
    }

    if (item.dueDate <= 0) {
      // 无截止时间按创建时间超过 14 天做轻微老化提示
      const daysSinceCreated = TimeUtils.getDaysAgo(item.createdAt);
      if (daysSinceCreated >= 14) {
        item.agingLevel = 1;
      }
      return;
    }

    const now = Date.now();
    if (now <= item.dueDate) {
      item.agingLevel = 0;
      return;
    }

    const overdueDays = Math.floor((now - item.dueDate) / (1000 * 60 * 60 * 24));
    if (overdueDays >= AppConstants.FROZEN_DAYS_THRESHOLD) {
      item.agingLevel = 3;
      item.isFrozen = true;
      item.status = TodoStatus.FROZEN;
      item.scheduledStartAt = 0;
      item.scheduledEndAt = 0;
    } else if (overdueDays >= 4) {
      item.agingLevel = 2;
    } else if (overdueDays >= 1) {
      item.agingLevel = 1;
    }
  }

  /**
   * 手动移入冷冻舱休眠
   */
  public static freeze(item: TodoItem): void {
    item.isFrozen = true;
    item.status = TodoStatus.FROZEN;
    item.agingLevel = 3;
    item.scheduledStartAt = 0;
    item.scheduledEndAt = 0;
  }

  /**
   * 一键解冻
   */
  public static unfreeze(item: TodoItem): void {
    item.isFrozen = false;
    item.status = TodoStatus.PENDING;
    item.agingLevel = 0;
    item.scheduledStartAt = 0;
    item.scheduledEndAt = 0;
    item.updatedAt = Date.now();
  }
}
