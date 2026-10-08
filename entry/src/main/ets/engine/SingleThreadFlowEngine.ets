/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Single-Thread Minimal Flow Engine (Now Only Pipeline)
 */

import { Priority, TodoItem, TodoSource, TodoStatus } from '../models/TodoItem';
import { MildAgingEngine } from './MildAgingEngine';
import { Logger } from '../common/utils/Logger';

@ObservedV2
export class SingleThreadFlowEngine {
  /**
   * 屏幕中央独占的当前唯一微动作 (Now Only)
   */
  @Trace public activeTask: TodoItem | null = null;

  /**
   * 就绪流水线队列；索引 0 为主舞台底部微露 12~16vp 的“下一项”卡片
   */
  @Trace public nextQueue: TodoItem[] = [];

  /**
   * 杂念快录与机动备选池
   */
  @Trace public parkingQueue: TodoItem[] = [];

  /**
   * 冷冻舱休眠池 (逾期 8+ 天或手动移入，反内疚保护)
   */
  @Trace public frozenTasks: TodoItem[] = [];

  /**
   * 今日微步心流轨迹 (已完成事项)
   */
  @Trace public completedToday: TodoItem[] = [];

  /**
   * 从数据库全量数据加载并重构单线程流水线
   */
  public load(allItems: TodoItem[]): void {
    const completed: TodoItem[] = [];
    const frozen: TodoItem[] = [];
    const parking: TodoItem[] = [];
    const activeCandidates: TodoItem[] = [];

    for (let i: number = 0; i < allItems.length; i++) {
      const item: TodoItem = allItems[i];
      if (item.isDeleted || item.status === TodoStatus.CANCELLED) {
        continue;
      }

      if (item.status === TodoStatus.COMPLETED) {
        completed.push(item);
        continue;
      }

      // 评估温和老化与冷冻判定
      MildAgingEngine.evaluateAging(item);

      if (item.isFrozen || item.status === TodoStatus.FROZEN || item.agingLevel >= 3) {
        item.isFrozen = true;
        item.status = TodoStatus.FROZEN;
        frozen.push(item);
        continue;
      }

      if (item.source === TodoSource.PARKING_LOT) {
        parking.push(item);
      }

      activeCandidates.push(item);
    }

    // 确定性加权排序 (分数高者排前，分数相同以 id 字典序稳定排序)
    activeCandidates.sort((a: TodoItem, b: TodoItem): number => {
      const scoreA: number = this.calculatePriorityScore(a);
      const scoreB: number = this.calculatePriorityScore(b);
      if (scoreB !== scoreA) {
        return scoreB - scoreA;
      }
      return a.id.localeCompare(b.id);
    });

    if (activeCandidates.length > 0) {
      this.activeTask = activeCandidates[0];
      this.activeTask.status = TodoStatus.IN_PROGRESS;
      this.nextQueue = activeCandidates.slice(1);
    } else {
      this.activeTask = null;
      this.nextQueue = [];
    }

    this.parkingQueue = parking;
    this.frozenTasks = frozen;
    this.completedToday = completed;

    Logger.info('SingleThreadFlowEngine',
      'Loaded flow pipeline: activeTask=%{public}s, nextQueue=%{public}d, parking=%{public}d, frozen=%{public}d',
      this.activeTask ? this.activeTask.id : 'none',
      this.nextQueue.length,
      this.parkingQueue.length,
      this.frozenTasks.length
    );
  }

  /**
   * 完成当前活跃任务，进入今日心流轨迹，推进下一项至活跃
   */
  public completeActive(): TodoItem | null {
    if (!this.activeTask) {
      return null;
    }

    const completed: TodoItem = this.activeTask;
    const now: number = Date.now();
    completed.status = TodoStatus.COMPLETED;
    completed.completedAt = now;
    completed.updatedAt = now;

    // 清理可能在 parkingQueue 中的引用
    const pIdx: number = this.parkingQueue.findIndex((t: TodoItem): boolean => t.id === completed.id);
    if (pIdx !== -1) {
      this.parkingQueue.splice(pIdx, 1);
    }

    this.completedToday.unshift(completed);

    if (this.nextQueue.length > 0) {
      const next: TodoItem = this.nextQueue.shift() as TodoItem;
      next.status = TodoStatus.IN_PROGRESS;
      next.updatedAt = now;
      this.activeTask = next;
    } else {
      this.activeTask = null;
    }

    return completed;
  }

  /**
   * 撤回今日已完成任务：从 completedToday 移除，恢复为待办状态并置入流水线；若当前无 activeTask 则直接作为活跃任务
   */
  public uncomplete(id: string): TodoItem | null {
    const idx: number = this.completedToday.findIndex((t: TodoItem): boolean => t.id === id);
    if (idx === -1) {
      return null;
    }

    const item: TodoItem = this.completedToday.splice(idx, 1)[0];
    const now: number = Date.now();
    item.completedAt = 0;
    item.updatedAt = now;

    if (!this.activeTask) {
      item.status = TodoStatus.IN_PROGRESS;
      this.activeTask = item;
    } else {
      item.status = TodoStatus.PENDING;
      this.nextQueue.unshift(item);
    }

    return item;
  }

  /**
   * 跳过当前活跃任务：推至就绪队列末尾，推进下一项至活跃
   */
  public skipActive(): TodoItem | null {
    if (!this.activeTask) {
      return null;
    }

    const skipped: TodoItem = this.activeTask;
    const now: number = Date.now();
    skipped.status = TodoStatus.PENDING;
    skipped.updatedAt = now;

    if (this.nextQueue.length > 0) {
      const next: TodoItem = this.nextQueue.shift() as TodoItem;
      next.status = TodoStatus.IN_PROGRESS;
      next.updatedAt = now;
      this.nextQueue.push(skipped);
      this.activeTask = next;
    }

    return skipped;
  }

  /**
   * 置顶指定任务：从就绪队列或机动池提取，将当前 activeTask 挤入 nextQueue[0]，被置顶项成为 activeTask
   */
  public promoteToTop(id: string): boolean {
    if (this.activeTask && this.activeTask.id === id) {
      return true;
    }

    let target: TodoItem | null = null;
    const nIdx: number = this.nextQueue.findIndex((t: TodoItem): boolean => t.id === id);
    if (nIdx !== -1) {
      target = this.nextQueue.splice(nIdx, 1)[0];
      const pIdx: number = this.parkingQueue.findIndex((t: TodoItem): boolean => t.id === id);
      if (pIdx !== -1) {
        this.parkingQueue.splice(pIdx, 1);
      }
    } else {
      const pIdx: number = this.parkingQueue.findIndex((t: TodoItem): boolean => t.id === id);
      if (pIdx !== -1) {
        target = this.parkingQueue.splice(pIdx, 1)[0];
      }
    }

    if (!target) {
      return false;
    }

    const now: number = Date.now();
    if (this.activeTask) {
      this.activeTask.status = TodoStatus.PENDING;
      this.activeTask.updatedAt = now;
      this.nextQueue.unshift(this.activeTask);
    }

    target.status = TodoStatus.IN_PROGRESS;
    target.updatedAt = now;
    this.activeTask = target;
    return true;
  }

  /**
   * 杂念快录秒存：直接追加至 parkingQueue 和 nextQueue，不抢占当前 activeTask 焦点
   */
  public pushToParking(item: TodoItem): void {
    item.source = TodoSource.PARKING_LOT;
    item.status = TodoStatus.PENDING;
    item.updatedAt = Date.now();

    this.parkingQueue.push(item);
    this.nextQueue.push(item);

    if (!this.activeTask) {
      const next: TodoItem = this.nextQueue.shift() as TodoItem;
      next.status = TodoStatus.IN_PROGRESS;
      this.activeTask = next;
    }
  }

  /**
   * 将指定任务移入冷冻舱休眠 (isFrozen = true, status = FROZEN)
   */
  public triageToCryo(id: string): boolean {
    let target: TodoItem | null = null;

    if (this.activeTask && this.activeTask.id === id) {
      target = this.activeTask;
      const parkingIdx: number = this.parkingQueue.findIndex((t: TodoItem): boolean => t.id === id);
      if (parkingIdx !== -1) {
        this.parkingQueue.splice(parkingIdx, 1);
      }
      if (this.nextQueue.length > 0) {
        const next: TodoItem = this.nextQueue.shift() as TodoItem;
        next.status = TodoStatus.IN_PROGRESS;
        this.activeTask = next;
      } else {
        this.activeTask = null;
      }
    } else {
      const nIdx: number = this.nextQueue.findIndex((t: TodoItem): boolean => t.id === id);
      if (nIdx !== -1) {
        target = this.nextQueue.splice(nIdx, 1)[0];
      }
      const pIdx: number = this.parkingQueue.findIndex((t: TodoItem): boolean => t.id === id);
      if (pIdx !== -1) {
        this.parkingQueue.splice(pIdx, 1);
      }
    }

    if (!target) {
      return false;
    }

    MildAgingEngine.freeze(target);
    this.frozenTasks.unshift(target);
    return true;
  }

  /**
   * 从冷冻舱一键唤醒任务回流水线 (isFrozen = false, status = PENDING, 重置逾期状态)
   */
  public reviveFromCryo(id: string): boolean {
    const fIdx: number = this.frozenTasks.findIndex((t: TodoItem): boolean => t.id === id);
    if (fIdx === -1) {
      return false;
    }

    const item: TodoItem = this.frozenTasks.splice(fIdx, 1)[0];
    MildAgingEngine.unfreeze(item);
    item.dueDate = 0; // 重置逾期状态
    item.agingLevel = 0;
    item.status = TodoStatus.PENDING;

    if (!this.activeTask) {
      item.status = TodoStatus.IN_PROGRESS;
      this.activeTask = item;
    } else {
      this.nextQueue.push(item);
    }

    return true;
  }

  /**
   * 计算综合推力打分 (优先级 HIGH > MEDIUM > LOW，钉住加权，逾期加权，温和老化加成)
   */
  public calculatePriorityScore(item: TodoItem): number {
    return SingleThreadFlowEngine.calculatePriorityScore(item);
  }

  /**
   * 静态计算方法，便于纯函数调用
   */
  public static calculatePriorityScore(item: TodoItem): number {
    // 1. 基础优先级层级权重 (HIGH=1000, MEDIUM=500, LOW=100，确保优先级绝对主导)
    let priorityWeight: number = 500;
    if (item.priority === Priority.HIGH) {
      priorityWeight = 1000;
    } else if (item.priority === Priority.LOW) {
      priorityWeight = 100;
    }

    // 2. 手动钉住/置顶星标加权
    const starWeight: number = item.isPinned ? 50 : 0;

    // 3. 逾期天数与紧急度加权
    let urgencyWeight: number = 0;
    if (item.dueDate > 0) {
      const now: number = Date.now();
      if (now > item.dueDate) {
        const overdueDays: number = Math.max(1, Math.floor((now - item.dueDate) / (1000 * 60 * 60 * 24)));
        urgencyWeight = 50 + Math.min(100, overdueDays * 10);
      } else {
        const diffHours: number = (item.dueDate - now) / (1000 * 3600);
        if (diffHours <= 12) {
          urgencyWeight = 40;
        } else if (diffHours <= 24) {
          urgencyWeight = 30;
        } else if (diffHours <= 48) {
          urgencyWeight = 20;
        } else {
          urgencyWeight = 10;
        }
      }
    }

    // 4. 温和老化等级加权
    const agingWeight: number = (item.agingLevel || 0) * 10;

    return priorityWeight + starWeight + urgencyWeight + agingWeight;
  }
}
