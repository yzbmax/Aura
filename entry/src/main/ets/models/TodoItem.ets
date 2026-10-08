/*
 * Copyright (c) 2026 Huawei Technologies Co., Ltd. & Aura Contributors
 * ArkUI V2 Core Todo & Time-Box Entity Model
 */

import { SubTaskItem } from './SubTaskItem';

export enum Priority {
  LOW = 1,
  MEDIUM = 2,
  HIGH = 3
}

export enum TodoStatus {
  PENDING = 0,
  IN_PROGRESS = 1,
  COMPLETED = 2,
  FROZEN = 3,
  CANCELLED = 4
}

export enum TodoSource {
  MANUAL = 0,
  CALENDAR = 1,
  INTENT = 2,
  REMINDER = 3,
  DELEGATED = 4,
  PARKING_LOT = 5
}

export enum TimingMode {
  COUNTDOWN = 0,  // 预估倒计时
  STOPWATCH = 1   // 开放流体正计时
}

@ObservedV2
export class TodoItem {
  @Trace public id: string = '';                          // UUID (主键)
  @Trace public title: string = '';                       // 待办/时间块标题
  @Trace public description: string = '';                 // 详细描述
  @Trace public priority: Priority = Priority.MEDIUM;     // 优先级 (1-低, 2-中, 3-高)
  @Trace public status: TodoStatus = TodoStatus.PENDING;  // 状态
  @Trace public dueDate: number = 0;                      // 截止时间戳
  @Trace public createdAt: number = 0;                    // 创建时间戳
  @Trace public updatedAt: number = 0;                    // 毫秒级时间戳 (LWW 裁决基准)
  @Trace public completedAt: number = 0;                  // 完成时间戳
  @Trace public estimatedMinutes: number = 25;            // 预估耗时 / 探索切片时长
  @Trace public actualMinutes: number = 0;                // 实际累计耗时 (分钟)
  @Trace public timingMode: TimingMode = TimingMode.COUNTDOWN; // 计时模式
  @Trace public source: TodoSource = TodoSource.MANUAL;   // 来源 (含 PARKING_LOT 杂念停机坪)
  @Trace public agingLevel: number = 0;                   // 老化等级 0~4
  @Trace public isFrozen: boolean = false;                // 是否冷冻

  // 【自适应时间块与机动池核心字段】
  @Trace public scheduledStartAt: number = 0;             // 算法排期起始时间戳 (0 表示在机动备选池)
  @Trace public scheduledEndAt: number = 0;               // 算法排期结束时间戳
  @Trace public isPinned: boolean = false;                // 用户是否手动钉住（锁定禁止算法重排）
  @Trace public isExplorationSlice: boolean = false;      // 是否为 45m 探索切片

  @Trace public tags: string[] = [];                      // 标签列表
  @Trace public subTasks: SubTaskItem[] = [];             // 独立子任务实体列表
  @Trace public assignedTo: string = '';                  // 甩单接收设备
  @Trace public deviceId: string = '';                    // 来源设备标识

  // 分布式软删除墓碑
  @Trace public isDeleted: boolean = false;
  @Trace public deletedAt: number = 0;

  // 同步状态脏标记
  @Trace public isDirty: boolean = true;
  @Trace public lastSyncedAt: number = 0;

  constructor(id: string = '', title: string = '', estimatedMinutes: number = 25) {
    this.id = id;
    this.title = title;
    this.estimatedMinutes = estimatedMinutes;
    const now = Date.now();
    this.createdAt = now;
    this.updatedAt = now;
  }
}
