/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * Time Slot Model for Bin-Packing Scheduler & Timeline
 */

import { TodoItem } from './TodoItem';

export enum SlotType {
  TASK = 0,       // 普通或切片任务块
  BUFFER = 1,     // 15m 留白呼吸缓冲带
  LOCKED = 2      // 锁定外部会议日程
}

@ObservedV2
export class TimeSlot {
  @Trace public id: string = '';
  @Trace public startMs: number = 0;
  @Trace public endMs: number = 0;
  @Trace public type: SlotType = SlotType.TASK;
  @Trace public taskItem: TodoItem | null = null;
  @Trace public title: string = '';

  constructor(id: string, startMs: number, endMs: number, type: SlotType = SlotType.TASK, taskItem: TodoItem | null = null, title: string = '') {
    this.id = id;
    this.startMs = startMs;
    this.endMs = endMs;
    this.type = type;
    this.taskItem = taskItem;
    this.title = title;
  }

  public get durationMinutes(): number {
    return Math.max(0, Math.round((this.endMs - this.startMs) / (1000 * 60)));
  }
}
